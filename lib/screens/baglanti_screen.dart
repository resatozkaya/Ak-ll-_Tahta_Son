import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/board_service.dart';

class BaglantiScreen extends StatefulWidget {
  const BaglantiScreen({super.key});
  @override
  State<BaglantiScreen> createState() => _BaglantiScreenState();
}

class _BaglantiScreenState extends State<BaglantiScreen> {
  bool _connecting = false;
  final _ipCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ipCtrl.text = context.read<BoardService>().savedIP;
  }

  @override
  void dispose() { _ipCtrl.dispose(); super.dispose(); }

  Future<void> _baglaN() async {
    setState(() => _connecting = true);
    final svc = context.read<BoardService>();
    final ok  = await svc.connectWifi(_ipCtrl.text.trim());
    if (!mounted) return;
    setState(() => _connecting = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<BoardService>();
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(title: const Text('WiFi Bağlantısı')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Talimatlar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF001A2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF00E5FF).withOpacity(0.25)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Row(children: [
                Icon(Icons.info_outline, color: Color(0xFF00E5FF), size: 16),
                SizedBox(width: 6),
                Text('Bağlantı Talimatları',
                    style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ]),
              const SizedBox(height: 10),
              _adim('1', 'Telefon WiFi ayarlarına gidin'),
              _adim('2', '"AkilliTahta-AP" ağını seçin'),
              _adim('3', 'Şifre: 12345678'),
              _adim('4', '"İnternetsiz ağda kal" seçin'),
              _adim('5', 'Geri gelip Bağlan butonuna basın'),
            ]),
          ),
          const SizedBox(height: 20),

          // IP alanı
          TextField(
            controller: _ipCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'ESP32 IP Adresi',
              hintText: '192.168.4.1',
              prefixIcon: const Icon(Icons.router, color: Color(0xFF00E5FF)),
              filled: true,
              fillColor: const Color(0xFF12121F),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF00E5FF))),
            ),
          ),
          const SizedBox(height: 16),

          // Durum mesajı
          if (svc.statusMsg != 'Hazır' && !svc.isConnected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF12121F),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                if (_connecting)
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Icon(
                    svc.statusMsg.contains('✅')
                        ? Icons.check_circle
                        : Icons.error_outline,
                    color: svc.statusMsg.contains('✅')
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    size: 16,
                  ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(svc.statusMsg,
                        style: const TextStyle(fontSize: 12))),
              ]),
            ),
          const SizedBox(height: 16),

          // Bağlan butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _connecting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.wifi),
              label: Text(_connecting ? 'Bağlanıyor...' : 'Bağlan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _connecting ? null : _baglaN,
            ),
          ),
          const SizedBox(height: 12),

          // Otomatik bağlan
          OutlinedButton.icon(
            icon: const Icon(Icons.autorenew, size: 16),
            label: const Text('Son IP ile Otomatik Bağlan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00E5FF),
              side: const BorderSide(
                  color: Color(0xFF00E5FF), width: 0.5),
            ),
            onPressed: _connecting
                ? null
                : () async {
                    setState(() => _connecting = true);
                    final ok =
                        await context.read<BoardService>().autoConnect();
                    if (!mounted) return;
                    setState(() => _connecting = false);
                    if (ok && mounted) Navigator.pop(context);
                  },
          ),
        ]),
      ),
    );
  }

  Widget _adim(String n, String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          CircleAvatar(
              radius: 10,
              backgroundColor: const Color(0xFF00E5FF),
              child: Text(n,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold))),
          const SizedBox(width: 10),
          Expanded(child: Text(t, style: const TextStyle(fontSize: 12))),
        ]),
      );
}
