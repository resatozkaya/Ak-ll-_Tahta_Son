import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/board_service.dart';

class EfektScreen extends StatelessWidget {
  const EfektScreen({super.key});

  // ── Yazı Animasyonları (6 adet) ─────────────────────────────
  static const _yaziAnimler = [
    {'id': 0,  'ad': 'Normal\nKayan',   'ikon': Icons.text_fields,         'renk': 0xFF00E5FF},
    {'id': 1,  'ad': 'Yanıp\nSönen',   'ikon': Icons.flash_on,            'renk': 0xFFFFEB3B},
    {'id': 2,  'ad': 'Renk\nDalgası',  'ikon': Icons.waves,               'renk': 0xFF2196F3},
    {'id': 3,  'ad': 'Gökkuşağı',      'ikon': Icons.colorize,            'renk': 0xFFE91E63},
    {'id': 4,  'ad': 'Nabız',          'ikon': Icons.favorite,            'renk': 0xFFFF9800},
    {'id': 5,  'ad': 'Yazılıyor',      'ikon': Icons.keyboard,            'renk': 0xFF4CAF50},
  ];

  // ── Çerçeve Animasyonları (8 adet) ──────────────────────────
  static const _cerceveler = [
    {'id': 0, 'ad': 'Yok',           'ikon': Icons.border_clear,          'renk': 0xFF444444},
    {'id': 1, 'ad': 'Tek\nRenk',     'ikon': Icons.border_all,            'renk': 0xFF00E5FF},
    {'id': 2, 'ad': 'Dönen\nNokta',  'ikon': Icons.rotate_right,         'renk': 0xFFFFEB3B},
    {'id': 3, 'ad': 'Gökkuşağı',     'ikon': Icons.palette,              'renk': 0xFFE91E63},
    {'id': 4, 'ad': 'Nabız',         'ikon': Icons.favorite,             'renk': 0xFFFF5722},
    {'id': 5, 'ad': 'Yılan',         'ikon': Icons.gesture,              'renk': 0xFF4CAF50},
    {'id': 6, 'ad': 'Kıvılcım',      'ikon': Icons.auto_awesome,         'renk': 0xFFFFD700},
    {'id': 7, 'ad': 'Gradyan',       'ikon': Icons.gradient,             'renk': 0xFF9C27B0},
  ];

  // ── Arkaplan Animasyonları (8 adet) ─────────────────────────
  static const _arkaPlanlar = [
    {'id': 0, 'ad': 'Yok',       'ikon': Icons.block,                    'renk': 0xFF444444},
    {'id': 1, 'ad': 'Solid',     'ikon': Icons.square,                   'renk': 0xFF00E5FF},
    {'id': 2, 'ad': 'Gökkuşağı','ikon': Icons.view_column,               'renk': 0xFFE91E63},
    {'id': 3, 'ad': 'Twinkle',  'ikon': Icons.star,                      'renk': 0xFFFFEB3B},
    {'id': 4, 'ad': 'Matrix',   'ikon': Icons.code,                      'renk': 0xFF00FF41},
    {'id': 5, 'ad': 'Ateş',     'ikon': Icons.local_fire_department,     'renk': 0xFFFF5722},
    {'id': 6, 'ad': 'Dalga',    'ikon': Icons.water,                     'renk': 0xFF2196F3},
    {'id': 7, 'ad': 'Yıldızlar','ikon': Icons.nights_stay,               'renk': 0xFF9C27B0},
  ];

  // ── Özel Figürler (yeni!) ────────────────────────────────────
  static const _figurler = [
    {'id': 0,  'ad': 'Yok',         'ikon': Icons.do_not_disturb,         'renk': 0xFF444444},
    {'id': 1,  'ad': '❤ Kalp',      'ikon': Icons.favorite,               'renk': 0xFFFF4444},
    {'id': 2,  'ad': '★ Yıldız',    'ikon': Icons.star,                   'renk': 0xFFFFD700},
    {'id': 3,  'ad': '⬡ Bal Peteği','ikon': Icons.hexagon,                'renk': 0xFFFF9800},
    {'id': 4,  'ad': '🌀 Spiral',   'ikon': Icons.cyclone,                'renk': 0xFF00E5FF},
    {'id': 5,  'ad': '✦ Kelebek',   'ikon': Icons.blur_on,                'renk': 0xFFE91E63},
    {'id': 6,  'ad': '⬆ Ok',        'ikon': Icons.arrow_upward,           'renk': 0xFF4CAF50},
    {'id': 7,  'ad': '⊕ Hedef',     'ikon': Icons.gps_fixed,              'renk': 0xFFFF5722},
    {'id': 8,  'ad': '✦ Kar Tanesi','ikon': Icons.ac_unit,                'renk': 0xFFADD8E6},
    {'id': 9,  'ad': '◉ Gözler',    'ikon': Icons.visibility,             'renk': 0xFFFFFFFF},
    {'id': 10, 'ad': '🌊 Okyanus',  'ikon': Icons.tsunami,                'renk': 0xFF006994},
    {'id': 11, 'ad': '⚡ Şimşek',   'ikon': Icons.bolt,                   'renk': 0xFFFFFF00},
  ];

  // ── Özel Sahne Modları (yeni!) ───────────────────────────────
  static const _sahneler = [
    {'id': 0,  'ad': 'Normal',       'ikon': Icons.crop_square,           'renk': 0xFF444444},
    {'id': 1,  'ad': 'Gece Kulübü', 'ikon': Icons.nightlife,              'renk': 0xFFE91E63},
    {'id': 2,  'ad': 'Sakin Okyanus','ikon': Icons.water,                 'renk': 0xFF006994},
    {'id': 3,  'ad': 'Orman',       'ikon': Icons.forest,                 'renk': 0xFF228B22},
    {'id': 4,  'ad': 'Volkan',      'ikon': Icons.volcano,                'renk': 0xFFFF4500},
    {'id': 5,  'ad': 'Gökyüzü',     'ikon': Icons.cloud,                  'renk': 0xFF87CEEB},
    {'id': 6,  'ad': 'Neon Şehir',  'ikon': Icons.location_city,          'renk': 0xFF00FFFF},
    {'id': 7,  'ad': 'Şeker Dünyası','ikon': Icons.cake,                  'renk': 0xFFFF69B4},
  ];

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<BoardService>();
    final s   = svc.boardStatus;

    final yaziAnim  = ((s['textAnim']    ?? 0) as num).toInt();
    final cerceve   = ((s['borderAnim']  ?? 0) as num).toInt();
    final cRenk     = ((s['borderHue']   ?? 0) as num).toDouble();
    final cKalinlik = ((s['borderWidth'] ?? 1) as num).toInt();
    final arka      = ((s['bgFill']      ?? 0) as num).toInt();
    final figur     = ((s['figureMode']  ?? 0) as num).toInt();
    final sahne     = ((s['sceneMode']   ?? 0) as num).toInt();

    return ListView(padding: const EdgeInsets.all(14), children: [

      // ── Yazı Animasyonu ─────────────────────────────────────
      _baslik('✍️ Yazı Animasyonu'),
      const SizedBox(height: 8),
      _izgara(_yaziAnimler, yaziAnim, (id) => svc.send({'textAnim': id})),
      const SizedBox(height: 18),

      // ── Çerçeve ─────────────────────────────────────────────
      _baslik('🖼️ Çerçeve Stili'),
      const SizedBox(height: 8),
      _izgara(_cerceveler, cerceve, (id) => svc.send({'borderAnim': id})),
      if (cerceve > 0) ...[
        const SizedBox(height: 10),
        _ayarKart('Çerçeve Ayarları', [
          _sliderSatir(Icons.palette, 'Renk', cRenk, 0, 255,
            HSVColor.fromAHSV(1, cRenk / 255 * 360, 1, 1).toColor(),
            (v) => svc.send({'borderHue': v.round()})),
          const SizedBox(height: 6),
          _sliderSatir(Icons.border_all, 'Kalınlık', cKalinlik.toDouble(), 0, 4,
            Colors.purple, (v) => svc.send({'borderWidth': v.round()})),
        ]),
      ],
      const SizedBox(height: 18),

      // ── Arkaplan ────────────────────────────────────────────
      _baslik('🌈 Arkaplan Efekti'),
      const SizedBox(height: 8),
      _izgara(_arkaPlanlar, arka, (id) => svc.send({'bgFill': id})),
      const SizedBox(height: 18),

      // ── Özel Figürler ────────────────────────────────────────
      _baslik('✦ Özel Figürler'),
      const SizedBox(height: 4),
      const Text(
        'Tabelada görüntülenecek animasyonlu figür',
        style: TextStyle(fontSize: 11, color: Colors.grey),
      ),
      const SizedBox(height: 8),
      _izgara(_figurler, figur, (id) => svc.send({'figureMode': id}),
        crossCount: 4),
      const SizedBox(height: 18),

      // ── Sahne Modları ────────────────────────────────────────
      _baslik('🎬 Sahne Modu'),
      const SizedBox(height: 4),
      const Text(
        'Tüm efektleri birlikte değiştiren hazır temalar',
        style: TextStyle(fontSize: 11, color: Colors.grey),
      ),
      const SizedBox(height: 8),
      _izgara(_sahneler, sahne, (id) => svc.send({'sceneMode': id}),
        crossCount: 4),
      const SizedBox(height: 18),

      // ── Hız & Yoğunluk ──────────────────────────────────────
      _baslik('⚡ Efekt Hızı & Yoğunluğu'),
      const SizedBox(height: 8),
      _ayarKart('Ekstra Ayarlar', [
        _sliderSatir(
          Icons.speed, 'Efekt Hızı',
          ((s['fxSpeed'] ?? 50) as num).toDouble(), 1, 100,
          const Color(0xFF00E5FF),
          (v) => svc.send({'fxSpeed': v.round()}),
        ),
        const SizedBox(height: 6),
        _sliderSatir(
          Icons.opacity, 'Efekt Yoğunluğu',
          ((s['fxIntensity'] ?? 50) as num).toDouble(), 1, 100,
          Colors.amber,
          (v) => svc.send({'fxIntensity': v.round()}),
        ),
        const SizedBox(height: 6),
        _sliderSatir(
          Icons.tune, 'Figür Boyutu',
          ((s['figureSize'] ?? 3) as num).toDouble(), 1, 8,
          Colors.pink,
          (v) => svc.send({'figureSize': v.round()}),
        ),
      ]),
      const SizedBox(height: 80),
    ]);
  }

  // ── Widget yardımcıları ──────────────────────────────────────

  Widget _baslik(String t) => Text(t,
    style: const TextStyle(
      color: Color(0xFF00E5FF), fontSize: 14, fontWeight: FontWeight.bold));

  Widget _izgara(
    List<Map<String, dynamic>> items,
    int secili,
    Function(int) tiklandi, {
    int crossCount = 4,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        childAspectRatio: 0.82,
        crossAxisSpacing: 7,
        mainAxisSpacing: 7,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item  = items[i];
        final aktif = secili == item['id'];
        final renk  = Color(item['renk'] as int);
        return GestureDetector(
          onTap: () => tiklandi(item['id'] as int),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: aktif ? renk.withOpacity(0.18) : const Color(0xFF12121F),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: aktif ? renk : const Color(0xFF2A2A3E),
                width: aktif ? 2 : 1,
              ),
              boxShadow: aktif
                ? [BoxShadow(color: renk.withOpacity(0.3),
                    blurRadius: 8, spreadRadius: 1)]
                : [],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(item['ikon'] as IconData,
                color: aktif ? renk : Colors.grey, size: 22),
              const SizedBox(height: 4),
              Text(item['ad'] as String,
                style: TextStyle(fontSize: 9,
                  color: aktif ? renk : Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _ayarKart(String baslik, List<Widget> children) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF12121F),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(baslik, style: const TextStyle(
        color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ...children,
    ]),
  );

  Widget _sliderSatir(IconData ikon, String etiket,
      double deger, double min, double max,
      Color renk, ValueChanged<double> degisti) {
    return Row(children: [
      Icon(ikon, color: renk, size: 17),
      const SizedBox(width: 6),
      SizedBox(width: 70, child: Text(etiket,
        style: const TextStyle(fontSize: 11))),
      Expanded(child: SliderTheme(
        data: SliderThemeData(
          activeTrackColor: renk,
          thumbColor: renk,
          inactiveTrackColor: renk.withOpacity(0.2),
          trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        ),
        child: Slider(
          value: deger.clamp(min, max),
          min: min, max: max,
          onChanged: degisti,
        ),
      )),
      SizedBox(width: 28, child: Text(deger.round().toString(),
        style: const TextStyle(fontSize: 11),
        textAlign: TextAlign.right)),
    ]);
  }
}
