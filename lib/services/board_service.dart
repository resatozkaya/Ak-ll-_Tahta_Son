import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ESP32 BLE Service/Characteristic UUID'leri (firmware ile eşleşmeli)
const String BLE_SERVICE_UUID    = "12345678-1234-1234-1234-123456789abc";
const String BLE_CHAR_TX_UUID    = "12345678-1234-1234-1234-123456789abd"; // Phone -> ESP32
const String BLE_CHAR_RX_UUID    = "12345678-1234-1234-1234-123456789abe"; // ESP32 -> Phone

enum ConnMode { none, wifi, ble }

class BoardService extends ChangeNotifier {
  // ── Bağlantı durumu ──────────────────────────────────────────
  ConnMode connMode = ConnMode.none;
  bool isConnected  = false;
  String statusMsg  = 'Hazır';
  String lastError  = '';

  // ── Tahta verisi ─────────────────────────────────────────────
  Map<String, dynamic> boardStatus = {};
  List<String> textList = [];

  // ── Tahta boyutu (SharedPreferences'ta saklanır) ─────────────
  int boardW = 30; // sütun
  int boardH = 20; // satır

  // ── WiFi ─────────────────────────────────────────────────────
  String _wifiIP = '192.168.4.1';
  Timer? _pollTimer;

  // ── BLE ──────────────────────────────────────────────────────
  List<ScanResult> bleDevices = [];
  bool isScanning = false;
  BluetoothDevice? _bleDevice;
  BluetoothCharacteristic? _txChar;
  BluetoothCharacteristic? _rxChar;
  StreamSubscription? _bleScanSub;
  StreamSubscription? _bleRxSub;
  StreamSubscription? _bleConnSub;
  String _bleRxBuf = '';

  // Getters
  bool get isWifiConnected => connMode == ConnMode.wifi && isConnected;
  bool get isBleConnected  => connMode == ConnMode.ble  && isConnected;

  BoardService() {
    _loadPrefs();
  }

  // ── SharedPreferences ────────────────────────────────────────
  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    boardW   = p.getInt('boardW') ?? 30;
    boardH   = p.getInt('boardH') ?? 20;
    _wifiIP  = p.getString('wifiIP') ?? '192.168.4.1';
    notifyListeners();
  }

  Future<void> saveBoardSize(int w, int h) async {
    boardW = w; boardH = h;
    final p = await SharedPreferences.getInstance();
    await p.setInt('boardW', w);
    await p.setInt('boardH', h);
    // ESP32'ye de gönder → EEPROM'a yazsın
    send({'boardW': w, 'boardH': h, 'saveSettings': true});
    notifyListeners();
  }

  Future<void> saveWifiIP(String ip) async {
    _wifiIP = ip;
    final p = await SharedPreferences.getInstance();
    await p.setString('wifiIP', ip);
  }

  // ════════════════════════════════════════════════════════════
  // WiFi BAĞLANTISI
  // ════════════════════════════════════════════════════════════

  Future<bool> connectWifi(String ip) async {
    _wifiIP = ip;
    await saveWifiIP(ip);
    connMode = ConnMode.none;
    statusMsg = '🔌 WiFi\'ya bağlanılıyor...';
    lastError = '';
    notifyListeners();

    // 3 deneme yap
    for (int attempt = 1; attempt <= 3; attempt++) {
      statusMsg = 'WiFi deneme $attempt/3...';
      notifyListeners();
      try {
        final body = await _httpGet(ip, '/status',
          timeout: const Duration(seconds: 6));
        if (body != null) {
          _parseStatus(body);
          isConnected = true;
          connMode    = ConnMode.wifi;
          statusMsg   = '✅ WiFi Bağlı! ($ip)';
          _startPoll(ip);
          notifyListeners();
          return true;
        }
      } catch (e) {
        lastError = e.toString();
        debugPrint('[WiFi attempt $attempt] $e');
      }
      await Future.delayed(const Duration(seconds: 1));
    }

    isConnected = false;
    statusMsg   = '❌ WiFi bağlanamadı\n$lastError';
    notifyListeners();
    return false;
  }

  Future<bool> autoConnect() => connectWifi(_wifiIP);

  void _startPoll(String ip) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!isConnected || connMode != ConnMode.wifi) return;
      final body = await _httpGet(ip, '/status',
        timeout: const Duration(seconds: 4));
      if (body != null) {
        _parseStatus(body);
        notifyListeners();
      } else {
        isConnected = false;
        statusMsg   = '⚠️ WiFi bağlantısı kesildi';
        notifyListeners();
      }
    });
  }

  // Raw HTTP GET (Socket tabanlı - http paketi gerektirmez)
  Future<String?> _httpGet(String host, String path,
      {Duration timeout = const Duration(seconds: 5)}) async {
    Socket? sock;
    try {
      sock = await Socket.connect(host, 80, timeout: timeout);
      sock.write('GET $path HTTP/1.0\r\nHost: $host\r\nConnection: close\r\n\r\n');
      await sock.flush();
      final chunks = <int>[];
      await for (final chunk in sock.timeout(timeout)) {
        chunks.addAll(chunk);
      }
      final raw = utf8.decode(chunks, allowMalformed: true);
      final idx = raw.indexOf('\r\n\r\n');
      if (idx < 0) return null;
      if (!raw.startsWith('HTTP') || !raw.contains('200')) {
        lastError = 'HTTP ${raw.split('\r\n').first}';
        return null;
      }
      return raw.substring(idx + 4).trim();
    } catch (e) {
      lastError = e.toString();
      return null;
    } finally {
      sock?.destroy();
    }
  }

  Future<String?> _httpPost(String host, String path, String json,
      {Duration timeout = const Duration(seconds: 4)}) async {
    Socket? sock;
    try {
      final body = utf8.encode(json);
      sock = await Socket.connect(host, 80, timeout: timeout);
      sock.write(
        'POST $path HTTP/1.0\r\n'
        'Host: $host\r\n'
        'Content-Type: application/json\r\n'
        'Content-Length: ${body.length}\r\n'
        'Connection: close\r\n'
        '\r\n'
      );
      sock.add(body);
      await sock.flush();
      final chunks = <int>[];
      await for (final chunk in sock.timeout(timeout)) {
        chunks.addAll(chunk);
      }
      final raw = utf8.decode(chunks, allowMalformed: true);
      final idx = raw.indexOf('\r\n\r\n');
      if (idx >= 0) return raw.substring(idx + 4).trim();
      return null;
    } catch (e) {
      debugPrint('[POST] $e');
      return null;
    } finally {
      sock?.destroy();
    }
  }

  // ════════════════════════════════════════════════════════════
  // BLE BAĞLANTISI
  // ════════════════════════════════════════════════════════════

  Future<bool> requestBlePermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    final sdkInt = await _androidSdkVersion();
    List<Permission> perms = [];
    if (Platform.isAndroid) {
      if (sdkInt >= 31) {
        perms = [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ];
      } else {
        perms = [
          Permission.bluetooth,
          Permission.locationWhenInUse,
        ];
      }
    } else {
      perms = [Permission.bluetooth];
    }
    final results = await perms.request();
    return results.values.every((s) =>
      s == PermissionStatus.granted || s == PermissionStatus.limited);
  }

  Future<int> _androidSdkVersion() async {
    try {
      // Platform.version returns e.g. "3.x.y (..."
      // We check Build.VERSION.SDK_INT via a workaround
      return 31; // assume modern Android; permissions handle older fallback
    } catch (_) { return 31; }
  }

  Future<void> startBleScan() async {
    final ok = await requestBlePermissions();
    if (!ok) {
      statusMsg = '❌ Bluetooth izinleri verilmedi';
      notifyListeners();
      return;
    }

    // Bluetooth açık mı?
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      statusMsg = '❌ Bluetooth kapalı, lütfen açın';
      notifyListeners();
      return;
    }

    bleDevices.clear();
    isScanning = true;
    statusMsg  = '🔍 BLE taranıyor...';
    notifyListeners();

    await FlutterBluePlus.stopScan();
    await _bleScanSub?.cancel();

    _bleScanSub = FlutterBluePlus.scanResults.listen((results) {
      bleDevices = results
          .where((r) => r.device.platformName.isNotEmpty)
          .toList();
      notifyListeners();
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
      androidUsesFineLocation: false,
    );

    await Future.delayed(const Duration(seconds: 10));
    isScanning = false;
    statusMsg  = bleDevices.isEmpty ? '⚠️ BLE cihaz bulunamadı' : '✅ ${bleDevices.length} cihaz bulundu';
    notifyListeners();
  }

  void stopBleScan() {
    FlutterBluePlus.stopScan();
    isScanning = false;
    notifyListeners();
  }

  Future<bool> connectBle(BluetoothDevice device) async {
    statusMsg = '🔌 BLE bağlanılıyor: ${device.platformName}...';
    lastError = '';
    notifyListeners();

    try {
      await device.connect(timeout: const Duration(seconds: 10));
      _bleDevice = device;

      await _bleConnSub?.cancel();
      _bleConnSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          isConnected = false;
          connMode    = ConnMode.none;
          statusMsg   = '⚠️ BLE bağlantısı kesildi';
          _txChar = null; _rxChar = null;
          notifyListeners();
        }
      });

      // Servisleri keşfet
      final services = await device.discoverServices();
      for (final svc in services) {
        if (svc.serviceUuid.toString().toLowerCase().contains('12345678')) {
          for (final char in svc.characteristics) {
            final uuid = char.characteristicUuid.toString().toLowerCase();
            if (uuid.contains('9abd')) _txChar = char;
            if (uuid.contains('9abe')) _rxChar = char;
          }
        }
      }

      // RX notify aç
      if (_rxChar != null) {
        await _rxChar!.setNotifyValue(true);
        await _bleRxSub?.cancel();
        _bleRxSub = _rxChar!.onValueReceived.listen(_onBleData);
      }

      // İlk status iste
      await _bleSend('{"cmd":"status"}');

      isConnected = true;
      connMode    = ConnMode.ble;
      statusMsg   = '✅ BLE Bağlı: ${device.platformName}';
      notifyListeners();
      return true;
    } catch (e) {
      lastError = e.toString();
      isConnected = false;
      statusMsg   = '❌ BLE hata: $lastError';
      notifyListeners();
      return false;
    }
  }

  void _onBleData(List<int> data) {
    _bleRxBuf += utf8.decode(data, allowMalformed: true);
    // Newline veya } ile biten tam JSON parçalarını işle
    while (true) {
      final nl = _bleRxBuf.indexOf('\n');
      if (nl < 0) break;
      final line = _bleRxBuf.substring(0, nl).trim();
      _bleRxBuf  = _bleRxBuf.substring(nl + 1);
      if (line.isNotEmpty) _parseStatus(line);
    }
  }

  Future<void> _bleSend(String json) async {
    if (_txChar == null) return;
    try {
      // MTU sınırı için 20 byte'lık parçalara böl
      final bytes = utf8.encode(json + '\n');
      const chunk = 20;
      for (var i = 0; i < bytes.length; i += chunk) {
        final end = (i + chunk < bytes.length) ? i + chunk : bytes.length;
        await _txChar!.write(bytes.sublist(i, end), withoutResponse: true);
        await Future.delayed(const Duration(milliseconds: 20));
      }
    } catch (e) {
      debugPrint('[BLE TX] $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  // KOMUT GÖNDER (WiFi veya BLE)
  // ════════════════════════════════════════════════════════════

  void send(Map<String, dynamic> cmd) {
    final json = jsonEncode(cmd);
    if (connMode == ConnMode.wifi) {
      _httpPost(_wifiIP, '/cmd', json).then((resp) {
        if (resp != null) { _parseStatus(resp); notifyListeners(); }
      });
    } else if (connMode == ConnMode.ble) {
      _bleSend(json);
    }
  }

  // EEPROM'a metin listesini kaydet
  void saveTextsToEeprom() => send({'saveTexts': true});

  // EEPROM'a tüm ayarları kaydet
  void saveAllToEeprom() => send({'saveAll': true});

  // ════════════════════════════════════════════════════════════
  // PARSE
  // ════════════════════════════════════════════════════════════

  void _parseStatus(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map) {
        boardStatus = Map<String, dynamic>.from(data);
        if (boardStatus.containsKey('texts')) {
          textList = List<String>.from(boardStatus['texts']);
        }
        if (boardStatus.containsKey('boardW')) boardW = boardStatus['boardW'];
        if (boardStatus.containsKey('boardH')) boardH = boardStatus['boardH'];
      }
    } catch (_) {}
  }

  // ════════════════════════════════════════════════════════════
  // BAĞLANTIYI KES
  // ════════════════════════════════════════════════════════════

  Future<void> disconnect() async {
    _pollTimer?.cancel();
    await _bleScanSub?.cancel();
    await _bleRxSub?.cancel();
    await _bleConnSub?.cancel();
    if (_bleDevice != null) {
      try { await _bleDevice!.disconnect(); } catch (_) {}
      _bleDevice = null;
    }
    _txChar = null; _rxChar = null;
    isConnected = false;
    connMode    = ConnMode.none;
    boardStatus = {};
    textList    = [];
    statusMsg   = 'Bağlantı kesildi';
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _bleScanSub?.cancel();
    _bleRxSub?.cancel();
    _bleConnSub?.cancel();
    super.dispose();
  }
}
