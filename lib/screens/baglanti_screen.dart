import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/board_service.dart';

class BaglantiScreen extends StatefulWidget {
  final int initialTab;
  const BaglantiScreen({super.key, this.initialTab = 0});
  @override
  State<BaglantiScreen> createState() => _BaglantiScreenState();
}

class _BaglantiScreenState extends State<BaglantiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _wifiConnecting = false;
  final _ipCtrl = TextEditingController(text: '192.168.4.1');

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    final svc = context.read<BoardService>();
    _ipCtrl.text = svc.boardStatus['wifiIP'] ?? '192.168.4.1';
  }

  @override
  void dispose() { _tabCtrl.dispose(); _ipCtrl.dispose(); super.dispose(); }

  // ── WiFi ──────────────────────────────────────────────────
  Future<void> _wifiBaglaN() async {
    setState(() { _wifiConnecting = true; });
    final svc = context.read<BoardService>();
    await svc.connectWifi(_ipCtrl.text.trim());
    if (!mounted) return;
    setState(() { _wifiConnecting = false; });
    if (svc.isConnected) Navigator.pop(context);
  }

  // ── BLE ───────────────────────────────────────────────────
  Future<void> _bleScan() async {
    await context.read<BoardService>().startBleScan();
  }

  Future<void> _bleBaglaN(ScanResult result) async {
    final svc = context.read<BoardService>();
    svc.stopBleScan();
    final ok = await svc.connectBle(result.device);
    if (!mounted) return;
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<BoardService>();
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        title: const Text('Bağlantı'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFF00E5FF),
          tabs: const [
            Tab(icon: Icon(Icons.wifi), text: 'WiFi'),
            Tab(icon: Icon(Icons.bluetooth), text: 'Bluetooth'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _wifiTab(svc),
          _bleTab(svc),
        ],
      ),
    );
  }

  // ══════════════════════════════════
  // WiFi SEKMESİ
  // ══════════════════════════════════
  Widget _wifiTab(BoardService svc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Talimatlar
        _infoKutu([
          _adim('1', 'Telefon WiFi ayarlarına gidin'),
          _adim('2', '"AkilliTahta-AP" ağını seçin'),
          _adim('3', 'Şifre: 12345678'),
          _adim('4', '"İnternetsiz ağda kal" seçin'),
          _adim('5', 'Aşağıdan IP girin ve Bağlan\'a basın'),
        ]),
        const SizedBox(height: 20),

        // IP alanı
        TextField(
          controller: _ipCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'ESP32 IP Adresi',
            hintText: '192.168.4.1',
            prefixIcon: const Icon(Icons.router, color: Color(0xFF00E5FF)),
            filled: true, fillColor: const Color(0xFF12121F),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00E5FF))),
          ),
        ),
        const SizedBox(height: 16),

        // Durum
        if (svc.statusMsg != 'Hazır' && !svc.isConnected)
          _statusKutu(svc.statusMsg, _wifiConnecting),
        const SizedBox(height: 16),

        // Bağlan butonu
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: _wifiConnecting
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : const Icon(Icons.wifi),
            label: Text(_wifiConnecting ? 'Bağlanıyor...' : 'WiFi\'ya Bağlan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _wifiConnecting ? null : _wifiBaglaN,
          ),
        ),
        const SizedBox(height: 12),

        // Otomatik bağlan
        OutlinedButton.icon(
          icon: const Icon(Icons.autorenew, size: 16),
          label: const Text('Son IP ile Otomatik Bağlan'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF00E5FF),
            side: const BorderSide(color: Color(0xFF00E5FF), width: 0.5),
          ),
          onPressed: _wifiConnecting ? null : () async {
            setState(() => _wifiConnecting = true);
            final ok = await context.read<BoardService>().autoConnect();
            if (!mounted) return;
            setState(() => _wifiConnecting = false);
            if (ok && mounted) Navigator.pop(context);
          },
        ),
      ]),
    );
  }

  // ══════════════════════════════════
  // BLE SEKMESİ
  // ══════════════════════════════════
  Widget _bleTab(BoardService svc) {
    return Column(children: [
      // Talimatlar
      Padding(
        padding: const EdgeInsets.all(16),
        child: _infoKutu([
          _adim('1', 'ESP32\'nin BLE özelliğini etkinleştirin'),
          _adim('2', 'Bluetooth\'u açın'),
          _adim('3', 'Tara butonuna basın'),
          _adim('4', 'Listede "AkilliTahta" seçin'),
        ]),
      ),

      // Tara butonu + durum
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: svc.isScanning
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.bluetooth_searching),
              label: Text(svc.isScanning ? 'Taranıyor...' : 'BLE Tara'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B2FBE),
                foregroundColor: Colors.white,
              ),
              onPressed: svc.isScanning ? svc.stopBleScan : _bleScan,
            ),
          ),
          if (svc.isScanning) ...[
            const SizedBox(width: 10),
            TextButton(
              onPressed: svc.stopBleScan,
              child: const Text('Durdur', style: TextStyle(color: Colors.red)),
            ),
          ],
        ]),
      ),

      if (svc.statusMsg.contains('BLE') || svc.statusMsg.contains('Bluetooth'))
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _statusKutu(svc.statusMsg, svc.isScanning),
        ),

      // Cihaz listesi
      Expanded(
        child: svc.bleDevices.isEmpty
          ? Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.bluetooth_disabled,
                  size: 60, color: Colors.grey.withOpacity(0.4)),
                const SizedBox(height: 16),
                Text(
                  svc.isScanning ? 'Cihazlar aranıyor...' : 'Henüz cihaz bulunamadı',
                  style: const TextStyle(color: Colors.grey),
                ),
              ]),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: svc.bleDevices.length,
              itemBuilder: (_, i) {
                final r = svc.bleDevices[i];
                final name = r.device.platformName.isEmpty
                  ? r.device.remoteId.str : r.device.platformName;
                final rssi = r.rssi;
                final signal = rssi > -60 ? '●●●' : rssi > -75 ? '●●○' : '●○○';
                return Card(
                  color: const Color(0xFF12121F),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B2FBE).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bluetooth, color: Color(0xFF7B2FBE)),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${r.device.remoteId.str}  $signal $rssi dBm',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B2FBE),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => _bleBaglaN(r),
                      child: const Text('Bağlan', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                );
              },
            ),
      ),
    ]);
  }

  // ── Yardımcı widgetlar ───────────────────────────────────────
  Widget _infoKutu(List<Widget> children) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF001A2E),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.25)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.info_outline, color: Color(0xFF00E5FF), size: 16),
        SizedBox(width: 6),
        Text('Talimatlar', style: TextStyle(
          color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
      const SizedBox(height: 10),
      ...children,
    ]),
  );

  Widget _adim(String n, String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      CircleAvatar(radius: 10, backgroundColor: const Color(0xFF00E5FF),
        child: Text(n, style: const TextStyle(
          color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold))),
      const SizedBox(width: 10),
      Expanded(child: Text(t, style: const TextStyle(fontSize: 12))),
    ]),
  );

  Widget _statusKutu(String msg, bool loading) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF12121F),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(children: [
      if (loading)
        const SizedBox(width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2))
      else
        Icon(
          msg.contains('✅') ? Icons.check_circle : Icons.error_outline,
          color: msg.contains('✅') ? Colors.greenAccent : Colors.redAccent,
          size: 16,
        ),
      const SizedBox(width: 10),
      Expanded(child: Text(msg, style: const TextStyle(fontSize: 12))),
    ]),
  );
}
