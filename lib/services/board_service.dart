import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BoardService extends ChangeNotifier {
  // ── Bağlantı durumu ──────────────────────────────────────────
  bool isConnected  = false;
  String statusMsg  = 'Hazır';
  String lastError  = '';

  // ── Tahta verisi ─────────────────────────────────────────────
  Map<String, dynamic> boardStatus = {};
  List<String> textList = [];

  // ── Tahta boyutu ─────────────────────────────────────────────
  int boardW = 30;
  int boardH = 20;

  // ── WiFi ─────────────────────────────────────────────────────
  String _wifiIP = '192.168.4.1';
  Timer? _pollTimer;

  bool get isWifiConnected => isConnected;
  bool get isBleConnected  => false;

  BoardService() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    boardW  = p.getInt('boardW') ?? 30;
    boardH  = p.getInt('boardH') ?? 20;
    _wifiIP = p.getString('wifiIP') ?? '192.168.4.1';
    notifyListeners();
  }

  Future<void> saveBoardSize(int w, int h) async {
    boardW = w; boardH = h;
    final p = await SharedPreferences.getInstance();
    await p.setInt('boardW', w);
    await p.setInt('boardH', h);
    send({'boardW': w, 'boardH': h, 'saveSettings': true});
    notifyListeners();
  }

  Future<void> saveWifiIP(String ip) async {
    _wifiIP = ip;
    final p = await SharedPreferences.getInstance();
    await p.setString('wifiIP', ip);
  }

  // ── WiFi BAĞLANTISI ──────────────────────────────────────────
  Future<bool> connectWifi(String ip) async {
    _wifiIP = ip;
    await saveWifiIP(ip);
    statusMsg = '🔌 Bağlanılıyor...';
    lastError = '';
    notifyListeners();

    for (int attempt = 1; attempt <= 3; attempt++) {
      statusMsg = 'Deneme $attempt/3...';
      notifyListeners();
      try {
        final body = await _httpGet(ip, '/status',
            timeout: const Duration(seconds: 6));
        if (body != null) {
          _parseStatus(body);
          isConnected = true;
          statusMsg   = '✅ Bağlı! ($ip)';
          _startPoll(ip);
          notifyListeners();
          return true;
        }
      } catch (e) {
        lastError = e.toString();
      }
      await Future.delayed(const Duration(seconds: 1));
    }

    isConnected = false;
    statusMsg   = '❌ Bağlanamadı\n$lastError';
    notifyListeners();
    return false;
  }

  Future<bool> autoConnect() => connectWifi(_wifiIP);
  String get savedIP => _wifiIP;

  void _startPoll(String ip) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!isConnected) return;
      final body = await _httpGet(ip, '/status',
          timeout: const Duration(seconds: 4));
      if (body != null) {
        _parseStatus(body);
        notifyListeners();
      } else {
        isConnected = false;
        statusMsg   = '⚠️ Bağlantı kesildi';
        notifyListeners();
      }
    });
  }

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
      if (!raw.contains('200')) { lastError = raw.split('\r\n').first; return null; }
      return raw.substring(idx + 4).trim();
    } catch (e) {
      lastError = e.toString();
      return null;
    } finally {
      sock?.destroy();
    }
  }

  Future<void> _httpPost(String host, String path, String json) async {
    Socket? sock;
    try {
      final body = utf8.encode(json);
      sock = await Socket.connect(host, 80,
          timeout: const Duration(seconds: 4));
      sock.write(
        'POST $path HTTP/1.0\r\n'
        'Host: $host\r\n'
        'Content-Type: application/json\r\n'
        'Content-Length: ${body.length}\r\n'
        'Connection: close\r\n'
        '\r\n',
      );
      sock.add(body);
      await sock.flush();
      final chunks = <int>[];
      await for (final chunk in sock.timeout(const Duration(seconds: 4))) {
        chunks.addAll(chunk);
      }
      final raw = utf8.decode(chunks, allowMalformed: true);
      final idx = raw.indexOf('\r\n\r\n');
      if (idx >= 0) { _parseStatus(raw.substring(idx + 4).trim()); notifyListeners(); }
    } catch (e) {
      debugPrint('[POST] $e');
    } finally {
      sock?.destroy();
    }
  }

  // ── KOMUT GÖNDER ─────────────────────────────────────────────
  void send(Map<String, dynamic> cmd) {
    _httpPost(_wifiIP, '/cmd', jsonEncode(cmd));
  }

  void saveTextsToEeprom() => send({'saveTexts': true});
  void saveAllToEeprom()   => send({'saveAll': true});

  // ── PARSE ─────────────────────────────────────────────────────
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

  // ── BAĞLANTIYI KES ───────────────────────────────────────────
  Future<void> disconnect() async {
    _pollTimer?.cancel();
    isConnected = false;
    boardStatus = {};
    textList    = [];
    statusMsg   = 'Bağlantı kesildi';
    notifyListeners();
  }

  @override
  void dispose() { _pollTimer?.cancel(); super.dispose(); }
}
