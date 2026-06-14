import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/board_service.dart';

class KontrolScreen extends StatelessWidget {
  const KontrolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<BoardService>();
    final s   = svc.boardStatus;

    final brightness  = ((s['brightness']  ?? 160) as num).toDouble();
    final speed       = ((s['speed']       ?? 40)  as num).toDouble();
    final hue         = ((s['hue']         ?? 0)   as num).toInt();
    final textY       = ((s['textY']       ?? 6)   as num).toDouble();
    final textSize    = ((s['textSize']    ?? 1)   as num).toInt();
    final blackout    = s['blackout']   ?? false;
    final playlist    = s['playlist']   ?? false;
    final rotSteps    = ((s['rotSteps']  ?? 0) as num).toInt();
    final orient      = ((s['orient']    ?? 0) as num).toInt();
    final dirLR       = ((s['dirLR']     ?? -1) as num).toInt();
    final activeIdx   = ((s['activeIdx'] ?? 0) as num).toInt();
    final staticMode  = s['staticMode'] ?? false;   // YENİ: sabit yazı
    final effectOnly  = s['effectOnly'] ?? false;   // YENİ: sadece efekt
    final dualLine    = s['dualLine']   ?? false;   // YENİ: çift satır
    final playInterval= ((s['playInterval'] ?? 5) as num).toInt();

    return ListView(padding: const EdgeInsets.all(14), children: [

      // ── Durum özeti ─────────────────────────────────────────
      _ozet(svc, activeIdx, blackout),
      const SizedBox(height: 10),

      // ── Ekran Modu (YENİ) ───────────────────────────────────
      _Kart(baslik: '🎯 Ekran Modu', child: Column(children: [
        Row(children: [
          Expanded(child: _ModeBtn(
            etiket: '📜 Yazı\nKayan',
            aktif: !staticMode && !effectOnly,
            renk: const Color(0xFF00E5FF),
            tiklandi: () => svc.send({'staticMode': false, 'effectOnly': false}),
          )),
          const SizedBox(width: 6),
          Expanded(child: _ModeBtn(
            etiket: '🔒 Yazı\nSabit',
            aktif: staticMode && !effectOnly,
            renk: Colors.amber,
            tiklandi: () => svc.send({'staticMode': true, 'effectOnly': false}),
          )),
          const SizedBox(width: 6),
          Expanded(child: _ModeBtn(
            etiket: '✨ Sadece\nEfekt',
            aktif: effectOnly,
            renk: Colors.pinkAccent,
            tiklandi: () => svc.send({'effectOnly': true, 'staticMode': false}),
          )),
        ]),
        const SizedBox(height: 8),
        // Çift satır modu
        Row(children: [
          Expanded(child: _ModeBtn(
            etiket: '☰ Tek\nSatır',
            aktif: !dualLine,
            renk: const Color(0xFF00E5FF),
            tiklandi: () => svc.send({'dualLine': false}),
          )),
          const SizedBox(width: 6),
          Expanded(child: _ModeBtn(
            etiket: '⚌ Çift\nSatır',
            aktif: dualLine,
            renk: Colors.greenAccent,
            tiklandi: () => svc.send({'dualLine': true}),
          )),
          const SizedBox(width: 6),
          // Güç butonu
          Expanded(child: _ModeBtn(
            etiket: blackout ? '🔴 Ekran\nKAPALI' : '🟢 Ekran\nAÇIK',
            aktif: !blackout,
            renk: blackout ? Colors.redAccent : Colors.greenAccent,
            tiklandi: () => svc.send({'blackout': !blackout}),
          )),
        ]),

        // Çift satır ikinci metin (dualLine açıksa göster)
        if (dualLine) ...[
          const SizedBox(height: 8),
          _DualLineInput(svc: svc, s: s),
        ],
      ])),
      const SizedBox(height: 10),

      // ── Kontroller ──────────────────────────────────────────
      _Kart(baslik: '🎛️ Kontroller', child: Column(children: [
        _Slider(ikon: Icons.brightness_6, etiket: 'Parlaklık',
          deger: brightness, min: 10, max: 255, renk: Colors.amber,
          degisti: (v) => svc.send({'brightness': v.round()})),
        const SizedBox(height: 6),
        _Slider(ikon: Icons.speed, etiket: 'Hız',
          deger: (305 - speed).clamp(5, 300), min: 5, max: 300,
          renk: const Color(0xFF00E5FF),
          degisti: (v) => svc.send({'speed': (305 - v).round()})),
        const SizedBox(height: 6),
        _Slider(ikon: Icons.swap_vert, etiket: 'Dikey Pos',
          deger: textY, min: 0, max: 20, renk: Colors.teal,
          degisti: (v) => svc.send({'textY': v.round()})),
      ])),
      const SizedBox(height: 10),

      // ── Yazı Boyutu (YENİ) ──────────────────────────────────
      _Kart(baslik: '🔤 Yazı Boyutu', child: Row(children: [
        Expanded(child: _ModeBtn(
          etiket: '𝗔 Küçük\n(1x)',
          aktif: textSize == 1,
          renk: const Color(0xFF00E5FF),
          tiklandi: () => svc.send({'textSize': 1}),
        )),
        const SizedBox(width: 6),
        Expanded(child: _ModeBtn(
          etiket: '𝗔 Orta\n(2x)',
          aktif: textSize == 2,
          renk: Colors.orange,
          tiklandi: () => svc.send({'textSize': 2}),
        )),
        const SizedBox(width: 6),
        Expanded(child: _ModeBtn(
          etiket: '𝗔 Büyük\n(3x)',
          aktif: textSize == 3,
          renk: Colors.deepOrange,
          tiklandi: () => svc.send({'textSize': 3}),
        )),
      ])),
      const SizedBox(height: 10),

      // ── Renk ────────────────────────────────────────────────
      _Kart(baslik: '🎨 Renk', child: Column(children: [
        _Slider(ikon: Icons.palette, etiket: 'Ton',
          deger: hue.toDouble(), min: 0, max: 255,
          renk: HSVColor.fromAHSV(1, hue / 255 * 360, 1, 1).toColor(),
          degisti: (v) => svc.send({'hue': v.round()})),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: ElevatedButton.icon(
            icon: const Icon(Icons.color_lens, size: 16),
            label: const Text('Renk Seçici'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A2E)),
            onPressed: () => _renkSec(context, svc, hue),
          )),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton.icon(
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text('Gökkuşağı'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A0A2E)),
            onPressed: () => svc.send({'textAnim': 3}),
          )),
        ]),
      ])),
      const SizedBox(height: 10),

      // ── Yön & Döndürme ──────────────────────────────────────
      _Kart(baslik: '🔄 Yön & Döndürme', child: Column(children: [
        Row(children: [
          Expanded(child: _Btn(
            etiket: orient == 0 ? '↔ Yatay ✓' : '↔ Yatay',
            renk: orient == 0 ? const Color(0xFF00E5FF) : Colors.grey,
            tiklandi: () => svc.send({'orient': 0}))),
          const SizedBox(width: 6),
          Expanded(child: _Btn(
            etiket: orient == 1 ? '↑ Yukarı ✓' : '↑ Yukarı',
            renk: orient == 1 ? Colors.greenAccent : Colors.grey,
            tiklandi: () => svc.send({'orient': 1}))),
          const SizedBox(width: 6),
          Expanded(child: _Btn(
            etiket: orient == 2 ? '↓ Aşağı ✓' : '↓ Aşağı',
            renk: orient == 2 ? Colors.orangeAccent : Colors.grey,
            tiklandi: () => svc.send({'orient': 2}))),
        ]),
        const SizedBox(height: 8),
        if (orient == 0) Row(children: [
          Expanded(child: _Btn(
            etiket: dirLR < 0 ? '← Sola ✓' : '← Sola',
            renk: dirLR < 0 ? const Color(0xFF00E5FF) : Colors.grey,
            tiklandi: () => svc.send({'dirLR': -1}))),
          const SizedBox(width: 6),
          Expanded(child: _Btn(
            etiket: dirLR >= 0 ? 'Sağa → ✓' : 'Sağa →',
            renk: dirLR >= 0 ? const Color(0xFF00E5FF) : Colors.grey,
            tiklandi: () => svc.send({'dirLR': 1}))),
        ]),
        if (orient == 0) const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _Btn(
            etiket: '🔄 Döndür (${rotSteps * 90}°)',
            renk: Colors.purple,
            tiklandi: () => svc.send({'rotSteps': (rotSteps + 1) % 4}))),
        ]),
      ])),
      const SizedBox(height: 10),

      // ── Playlist ────────────────────────────────────────────
      _Kart(baslik: '📋 Playlist', child: Column(children: [
        Row(children: [
          Expanded(child: _Btn(
            etiket: playlist ? '▶ Playlist AÇIK' : '⏸ Playlist KAPALI',
            renk: playlist ? Colors.greenAccent : Colors.grey,
            tiklandi: () => svc.send({'playlist': !playlist}))),
        ]),
        if (playlist) ...[
          const SizedBox(height: 8),
          _Slider(ikon: Icons.timer, etiket: 'Süre (sn)',
            deger: playInterval.toDouble(), min: 1, max: 60,
            renk: Colors.teal,
            degisti: (v) => svc.send({'playInterval': v.round()})),
        ],
      ])),
      const SizedBox(height: 80),
    ]);
  }

  Widget _ozet(BoardService svc, int activeIdx, bool blackout) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF001A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.dashboard, color: Color(0xFF00E5FF), size: 18),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(
            svc.textList.isNotEmpty
              ? '▶ ${svc.textList[activeIdx.clamp(0, svc.textList.length - 1)]}'
              : 'Metin yok',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          Text('Panel: ${svc.boardW}×${svc.boardH} • WiFi',
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ])),
        GestureDetector(
          onTap: () => svc.send({'blackout': !blackout}),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: blackout
                ? Colors.redAccent.withOpacity(0.15)
                : Colors.greenAccent.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: blackout ? Colors.redAccent : Colors.greenAccent),
            ),
            child: Icon(blackout ? Icons.power_off : Icons.power,
              color: blackout ? Colors.redAccent : Colors.greenAccent,
              size: 22),
          ),
        ),
      ]),
    );
  }

  void _renkSec(BuildContext ctx, BoardService svc, int hue) {
    Color c = HSVColor.fromAHSV(1, hue / 255 * 360, 1, 1).toColor();
    showDialog(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Text('Renk Seç'),
      content: SingleChildScrollView(child: ColorPicker(
        pickerColor: c,
        onColorChanged: (nc) {
          final nh = (HSVColor.fromColor(nc).hue / 360 * 255).round();
          svc.send({'hue': nh});
        },
      )),
      actions: [TextButton(
        onPressed: () => Navigator.pop(_), child: const Text('Tamam'))],
    ));
  }
}

// ── Çift satır giriş alanı ──────────────────────────────────────
class _DualLineInput extends StatefulWidget {
  final BoardService svc;
  final Map<String, dynamic> s;
  const _DualLineInput({required this.svc, required this.s});
  @override
  State<_DualLineInput> createState() => _DualLineInputState();
}
class _DualLineInputState extends State<_DualLineInput> {
  final _ctrl1 = TextEditingController();
  final _ctrl2 = TextEditingController();
  @override
  void initState() {
    super.initState();
    _ctrl1.text = (widget.s['line1'] ?? '').toString();
    _ctrl2.text = (widget.s['line2'] ?? '').toString();
  }
  @override
  void dispose() { _ctrl1.dispose(); _ctrl2.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Divider(color: Colors.white12),
      const Text('Çift Satır Metinleri',
        style: TextStyle(color: Colors.grey, fontSize: 11)),
      const SizedBox(height: 8),
      Row(children: [
        const Icon(Icons.arrow_upward, size: 14, color: Colors.teal),
        const SizedBox(width: 6),
        Expanded(child: TextField(
          controller: _ctrl1,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'Üst satır...',
            filled: true, fillColor: Color(0xFF0D1A2E),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(borderSide: BorderSide.none),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 13),
        )),
        const SizedBox(width: 6),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            minimumSize: Size.zero,
          ),
          onPressed: () {
            String t = _ctrl1.text.trim().toUpperCase();
            if (t.isNotEmpty) widget.svc.send({'line1': t});
          },
          child: const Text('Gönder', style: TextStyle(fontSize: 12)),
        ),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        const Icon(Icons.arrow_downward, size: 14, color: Colors.orange),
        const SizedBox(width: 6),
        Expanded(child: TextField(
          controller: _ctrl2,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'Alt satır...',
            filled: true, fillColor: Color(0xFF1A0D0D),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(borderSide: BorderSide.none),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 13),
        )),
        const SizedBox(width: 6),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            minimumSize: Size.zero,
          ),
          onPressed: () {
            String t = _ctrl2.text.trim().toUpperCase();
            if (t.isNotEmpty) widget.svc.send({'line2': t});
          },
          child: const Text('Gönder', style: TextStyle(fontSize: 12)),
        ),
      ]),
    ]);
  }
}

// ── Widget yardımcıları ─────────────────────────────────────────
class _Kart extends StatelessWidget {
  final String baslik; final Widget child;
  const _Kart({required this.baslik, required this.child});
  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF12121F),
      borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(baslik, style: const TextStyle(
        color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      child,
    ]),
  );
}

class _ModeBtn extends StatelessWidget {
  final String etiket; final bool aktif;
  final Color renk; final VoidCallback tiklandi;
  const _ModeBtn({required this.etiket, required this.aktif,
    required this.renk, required this.tiklandi});
  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTap: tiklandi,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: aktif ? renk.withOpacity(0.15) : Colors.transparent,
        border: Border.all(
          color: aktif ? renk : Colors.grey.withOpacity(0.3),
          width: aktif ? 1.5 : 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(etiket,
        style: TextStyle(
          color: aktif ? renk : Colors.grey,
          fontWeight: aktif ? FontWeight.bold : FontWeight.normal,
          fontSize: 11),
        textAlign: TextAlign.center),
    ),
  );
}

class _Btn extends StatelessWidget {
  final String etiket; final Color renk; final VoidCallback tiklandi;
  const _Btn({required this.etiket, required this.renk, required this.tiklandi});
  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTap: tiklandi,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: renk.withOpacity(0.08),
        border: Border.all(color: renk.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(etiket,
        style: TextStyle(color: renk, fontWeight: FontWeight.bold, fontSize: 12),
        textAlign: TextAlign.center),
    ),
  );
}

class _Slider extends StatelessWidget {
  final IconData ikon; final String etiket;
  final double deger, min, max; final Color renk;
  final ValueChanged<double> degisti;
  const _Slider({required this.ikon, required this.etiket,
    required this.deger, required this.min, required this.max,
    required this.renk, required this.degisti});
  @override
  Widget build(BuildContext ctx) => Row(children: [
    Icon(ikon, color: renk, size: 18),
    const SizedBox(width: 6),
    SizedBox(width: 72, child: Text(etiket,
      style: const TextStyle(fontSize: 11))),
    Expanded(child: SliderTheme(
      data: SliderTheme.of(ctx).copyWith(
        activeTrackColor: renk, thumbColor: renk,
        inactiveTrackColor: renk.withOpacity(0.2),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
      child: Slider(
        value: deger.clamp(min, max), min: min, max: max,
        onChanged: degisti),
    )),
    SizedBox(width: 32, child: Text(deger.round().toString(),
      style: const TextStyle(fontSize: 11), textAlign: TextAlign.right)),
  ]);
}
