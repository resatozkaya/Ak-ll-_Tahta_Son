import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/board_service.dart';

class AyarlarScreen extends StatefulWidget {
  const AyarlarScreen({super.key});
  @override
  State<AyarlarScreen> createState() => _AyarlarScreenState();
}

class _AyarlarScreenState extends State<AyarlarScreen> {
  late int _w;
  late int _h;
  bool _kaydediliyor = false;

  @override
  void initState() {
    super.initState();
    final svc = context.read<BoardService>();
    _w = svc.boardW;
    _h = svc.boardH;
  }

  Future<void> _boyutuKaydet(BoardService svc) async {
    setState(() => _kaydediliyor = true);
    await svc.saveBoardSize(_w, _h);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _kaydediliyor = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Boyut kaydedildi: ${_w}×${_h} (EEPROM\'a yazıldı)'),
          backgroundColor: const Color(0xFF1A3A1A),
        ),
      );
    }
  }

  Future<void> _tumunuKaydet(BoardService svc) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Tüm Ayarları Kaydet'),
        content: const Text(
          'Tüm ayarlar (parlaklık, hız, efekt, boyut, yazı listesi) '
          'ESP32 EEPROM\'una kalıcı olarak kaydedilecek.\n\n'
          'Cihaz kapanıp açıldığında bu ayarlar korunacak.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
              svc.saveAllToEeprom();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Tüm ayarlar EEPROM\'a kaydedildi!'),
                  backgroundColor: Color(0xFF1A3A1A),
                ),
              );
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<BoardService>();
    final s   = svc.boardStatus;

    return ListView(padding: const EdgeInsets.all(16), children: [

      // ── Bağlantı Durumu ─────────────────────────────────────
      _kart('📡 Bağlantı Durumu', [
        _satir(
          Icons.circle,
          'Durum',
          svc.isConnected ? 'Bağlı' : 'Bağlı Değil',
          renk: svc.isConnected ? Colors.greenAccent : Colors.redAccent,
        ),
        _satir(
          svc.isBleConnected ? Icons.bluetooth_connected : Icons.wifi,
          'Mod',
          svc.isBleConnected ? 'Bluetooth BLE' :
          svc.isWifiConnected ? 'WiFi' : '-',
        ),
        _satir(Icons.info, 'Mesaj', svc.statusMsg),
        if (svc.isConnected)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.link_off, size: 16),
              label: const Text('Bağlantıyı Kes'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent, width: 0.5),
              ),
              onPressed: () => svc.disconnect(),
            ),
          ),
      ]),
      const SizedBox(height: 14),

      // ── Tahta Boyutu ────────────────────────────────────────
      _kart('📐 LED Panel Boyutu', [
        const Text(
          'Fiziksel LED matrisinizin satır/sütun sayısını girin.\n'
          'Kaydettiğinizde ESP32 EEPROM\'una da yazılır.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _boyutField('Sütun (Genişlik)', _w, (v) {
            if (v >= 1 && v <= 100) setState(() => _w = v);
          })),
          const SizedBox(width: 12),
          Expanded(child: _boyutField('Satır (Yükseklik)', _h, (v) {
            if (v >= 1 && v <= 100) setState(() => _h = v);
          })),
        ]),
        const SizedBox(height: 12),

        // Görsel önizleme
        Center(
          child: Container(
            width: _w.toDouble().clamp(20, 200) * 2.0,
            height: _h.toDouble().clamp(10, 100) * 2.0,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
              borderRadius: BorderRadius.circular(4),
              color: const Color(0xFF001A2E),
            ),
            child: Center(
              child: Text('${_w}×${_h}',
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                )),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Hızlı seçimler
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            _onayBoy('8×8',   8, 8,  svc),
            _onayBoy('16×8',  16, 8, svc),
            _onayBoy('20×10', 20, 10, svc),
            _onayBoy('20×20', 20, 20, svc),
            _onayBoy('30×20', 30, 20, svc),
            _onayBoy('32×8',  32, 8, svc),
          ],
        ),
        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: _kaydediliyor
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : const Icon(Icons.save),
            label: Text(_kaydediliyor ? 'Kaydediliyor...' : 'Boyutu EEPROM\'a Kaydet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _kaydediliyor ? null : () => _boyutuKaydet(svc),
          ),
        ),
      ]),
      const SizedBox(height: 14),

      // ── Mevcut ESP32 Bilgileri ───────────────────────────────
      if (s.isNotEmpty) ...[
        _kart('🔧 ESP32 Durumu', [
          _satir(Icons.brightness_6, 'Parlaklık', '${s['brightness'] ?? '-'}'),
          _satir(Icons.speed,        'Hız',       '${s['speed'] ?? '-'} ms'),
          _satir(Icons.palette,      'Ton',       '${s['hue'] ?? '-'}'),
          _satir(Icons.grid_on,      'Boyut',     '${s['boardW'] ?? _w}×${s['boardH'] ?? _h}'),
          _satir(Icons.list,         'Metin Sayısı', '${svc.textList.length}'),
          _satir(Icons.wifi,         'WiFi',
            s['wifiOk'] == true ? '✅ Bağlı' : '❌ Bağlı Değil'),
        ]),
        const SizedBox(height: 14),
      ],

      // ── EEPROM İşlemleri ─────────────────────────────────────
      _kart('💾 EEPROM İşlemleri', [
        const Text(
          'EEPROM\'a kaydetmezseniz, ESP32 yeniden başladığında '
          'ayarlar varsayılana döner.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.save_all),
            label: const Text('Tüm Ayarları EEPROM\'a Kaydet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: svc.isConnected ? () => _tumunuKaydet(svc) : null,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.restore, size: 16),
            label: const Text('Fabrika Ayarlarına Sıfırla'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent, width: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: svc.isConnected ? () => _resetOnayla(svc) : null,
          ),
        ),
      ]),
      const SizedBox(height: 14),

      // ── Uygulama Hakkında ────────────────────────────────────
      _kart('ℹ️ Hakkında', [
        _satir(Icons.app_settings_alt, 'Versiyon', 'v2.0'),
        _satir(Icons.memory, 'Donanım', 'ESP32 + NeoMatrix LED'),
        _satir(Icons.bluetooth, 'BLE', 'flutter_blue_plus'),
        _satir(Icons.wifi, 'WiFi', 'HTTP/WebSocket'),
      ]),
      const SizedBox(height: 80),
    ]);
  }

  Widget _boyutField(String label, int val, Function(int) onChanged) {
    return TextFormField(
      initialValue: val.toString(),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onChanged: (v) { final n = int.tryParse(v); if (n != null) onChanged(n); },
    );
  }

  Widget _onayBoy(String label, int w, int h, BoardService svc) {
    final aktif = _w == w && _h == h;
    return GestureDetector(
      onTap: () => setState(() { _w = w; _h = h; }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: aktif ? const Color(0xFF00E5FF).withOpacity(0.15) : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: aktif ? const Color(0xFF00E5FF) : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 12,
            color: aktif ? const Color(0xFF00E5FF) : Colors.grey,
            fontWeight: aktif ? FontWeight.bold : FontWeight.normal,
          )),
      ),
    );
  }

  Widget _kart(String baslik, List<Widget> children) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF12121F),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(baslik, style: const TextStyle(
        color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      ...children,
    ]),
  );

  Widget _satir(IconData ikon, String etiket, String deger, {Color? renk}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(ikon, size: 15, color: renk ?? Colors.grey),
        const SizedBox(width: 8),
        Text(etiket, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const Spacer(),
        Text(deger, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.bold,
          color: renk ?? Colors.white)),
      ]),
    );

  void _resetOnayla(BoardService svc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('⚠️ Fabrika Sıfırlama'),
        content: const Text(
          'Tüm ayarlar ve metin listesi sıfırlanacak. '
          'Bu işlem geri alınamaz!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () {
              Navigator.pop(context);
              svc.send({'factoryReset': true});
            },
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }
}
