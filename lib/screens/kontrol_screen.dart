import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/board_service.dart';

const _lineAnims = [
  {'id': 0, 'ad': '← Sola',     'ikon': Icons.arrow_back},
  {'id': 1, 'ad': 'Sağa →',     'ikon': Icons.arrow_forward},
  {'id': 2, 'ad': '↔ Zıpla',    'ikon': Icons.swap_horiz},
  {'id': 3, 'ad': '~ Dalga',    'ikon': Icons.waves},
  {'id': 4, 'ad': '🌈 Renk',    'ikon': Icons.colorize},
  {'id': 5, 'ad': '⚡ Titreme', 'ikon': Icons.vibration},
  {'id': 6, 'ad': '■ Sabit',    'ikon': Icons.crop_square},
];

class KontrolScreen extends StatelessWidget {
  const KontrolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<BoardService>();
    final s   = svc.boardStatus;

    final brightness   = ((s['brightness']   ?? 160) as num).toDouble();
    final speed        = ((s['speed']        ?? 40)  as num).toDouble();
    final hue          = ((s['hue']          ?? 0)   as num).toInt();
    final textY        = ((s['textY']        ?? 6)   as num).toDouble();
    final textSize     = ((s['textSize']     ?? 1)   as num).toInt();
    final blackout     = s['blackout']    ?? false;
    final playlist     = s['playlist']    ?? false;
    final rotSteps     = ((s['rotSteps']  ?? 0) as num).toInt();
    final orient       = ((s['orient']    ?? 0) as num).toInt();
    final dirLR        = ((s['dirLR']     ?? -1) as num).toInt();
    final activeIdx    = ((s['activeIdx'] ?? 0) as num).toInt();
    final staticMode   = s['staticMode'] ?? false;
    final effectOnly   = s['effectOnly'] ?? false;
    final dualLine     = s['dualLine']   ?? false;
    final playInterval = ((s['playInterval'] ?? 5) as num).toInt();

    return ListView(padding: const EdgeInsets.all(14), children: [
      _ozet(svc, activeIdx, blackout),
      const SizedBox(height: 10),

      _Kart(baslik: '🎯 Ekran Modu', child: Column(children: [
        Row(children: [
          Expanded(child: _ModeBtn(etiket: '📜 Kayan\nYazı',
            aktif: !staticMode && !effectOnly && !dualLine, renk: const Color(0xFF00E5FF),
            tiklandi: () => svc.send({'staticMode': false, 'effectOnly': false, 'dualLine': false}))),
          const SizedBox(width: 6),
          Expanded(child: _ModeBtn(etiket: '🔒 Sabit\nYazı',
            aktif: staticMode && !effectOnly && !dualLine, renk: Colors.amber,
            tiklandi: () => svc.send({'staticMode': true, 'effectOnly': false, 'dualLine': false}))),
          const SizedBox(width: 6),
          Expanded(child: _ModeBtn(etiket: '✨ Sadece\nEfekt',
            aktif: effectOnly, renk: Colors.pinkAccent,
            tiklandi: () => svc.send({'effectOnly': true, 'staticMode': false, 'dualLine': false}))),
          const SizedBox(width: 6),
          Expanded(child: _ModeBtn(etiket: '⚌ Çift\nSatır',
            aktif: dualLine, renk: Colors.greenAccent,
            tiklandi: () => svc.send({'dualLine': true, 'effectOnly': false, 'staticMode': false}))),
        ]),
        const SizedBox(height: 8),
        _Btn(etiket: blackout ? '🔴 Ekran KAPALI — Aç' : '🟢 Ekran AÇIK — Kapat',
          renk: blackout ? Colors.redAccent : Colors.greenAccent,
          tiklandi: () => svc.send({'blackout': !blackout})),
      ])),
      const SizedBox(height: 10),

      if (dualLine) ...[
        _dualPanel(context, svc, s, brightness, speed),
        const SizedBox(height: 80),
      ] else ...[
        _Kart(baslik: '🎛️ Kontroller', child: Column(children: [
          _Slider(ikon: Icons.brightness_6, etiket: 'Parlaklık',
            deger: brightness, min: 10, max: 255, renk: Colors.amber,
            degisti: (v) => svc.send({'brightness': v.round()})),
          const SizedBox(height: 6),
          _Slider(ikon: Icons.speed, etiket: 'Hız',
            deger: (305 - speed).clamp(5, 300), min: 5, max: 300, renk: const Color(0xFF00E5FF),
            degisti: (v) => svc.send({'speed': (305 - v).round()})),
          const SizedBox(height: 6),
          _Slider(ikon: Icons.swap_vert, etiket: 'Dikey Pos',
            deger: textY, min: 0, max: 20, renk: Colors.teal,
            degisti: (v) => svc.send({'textY': v.round()})),
        ])),
        const SizedBox(height: 10),
        _Kart(baslik: '🔤 Yazı Boyutu', child: Row(children: [
          Expanded(child: _ModeBtn(etiket: 'Küçük\n1x', aktif: textSize==1,
            renk: const Color(0xFF00E5FF), tiklandi: () => svc.send({'textSize': 1}))),
          const SizedBox(width: 6),
          Expanded(child: _ModeBtn(etiket: 'Orta\n2x', aktif: textSize==2,
            renk: Colors.orange, tiklandi: () => svc.send({'textSize': 2}))),
          const SizedBox(width: 6),
          Expanded(child: _ModeBtn(etiket: 'Büyük\n3x', aktif: textSize==3,
            renk: Colors.deepOrange, tiklandi: () => svc.send({'textSize': 3}))),
        ])),
        const SizedBox(height: 10),
        _Kart(baslik: '🎨 Renk', child: Column(children: [
          _Slider(ikon: Icons.palette, etiket: 'Ton',
            deger: hue.toDouble(), min: 0, max: 255,
            renk: HSVColor.fromAHSV(1, hue / 255 * 360, 1, 1).toColor(),
            degisti: (v) => svc.send({'hue': v.round()})),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: ElevatedButton.icon(
              icon: const Icon(Icons.color_lens, size: 16), label: const Text('Renk Seçici'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E)),
              onPressed: () => _renkSec(context, svc, hue))),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton.icon(
              icon: const Icon(Icons.auto_awesome, size: 16), label: const Text('Gökkuşağı'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A0A2E)),
              onPressed: () => svc.send({'textAnim': 3}))),
          ]),
        ])),
        const SizedBox(height: 10),
        _Kart(baslik: '🔄 Yön & Döndürme', child: Column(children: [
          Row(children: [
            Expanded(child: _Btn(etiket: orient==0?'↔ Yatay ✓':'↔ Yatay',
              renk: orient==0?const Color(0xFF00E5FF):Colors.grey, tiklandi: () => svc.send({'orient': 0}))),
            const SizedBox(width: 6),
            Expanded(child: _Btn(etiket: orient==1?'↑ Yukarı ✓':'↑ Yukarı',
              renk: orient==1?Colors.greenAccent:Colors.grey, tiklandi: () => svc.send({'orient': 1}))),
            const SizedBox(width: 6),
            Expanded(child: _Btn(etiket: orient==2?'↓ Aşağı ✓':'↓ Aşağı',
              renk: orient==2?Colors.orangeAccent:Colors.grey, tiklandi: () => svc.send({'orient': 2}))),
          ]),
          if (orient == 0) ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _Btn(etiket: dirLR<0?'← Sola ✓':'← Sola',
                renk: dirLR<0?const Color(0xFF00E5FF):Colors.grey, tiklandi: () => svc.send({'dirLR': -1}))),
              const SizedBox(width: 6),
              Expanded(child: _Btn(etiket: dirLR>=0?'Sağa → ✓':'Sağa →',
                renk: dirLR>=0?const Color(0xFF00E5FF):Colors.grey, tiklandi: () => svc.send({'dirLR': 1}))),
            ]),
          ],
          const SizedBox(height: 8),
          _Btn(etiket: '🔄 Döndür (${rotSteps * 90}°)', renk: Colors.purple,
            tiklandi: () => svc.send({'rotSteps': (rotSteps + 1) % 4})),
        ])),
        const SizedBox(height: 10),
        _Kart(baslik: '📋 Playlist', child: Column(children: [
          _Btn(etiket: playlist ? '▶ Playlist AÇIK' : '⏸ Playlist KAPALI',
            renk: playlist ? Colors.greenAccent : Colors.grey,
            tiklandi: () => svc.send({'playlist': !playlist})),
          if (playlist) ...[
            const SizedBox(height: 8),
            _Slider(ikon: Icons.timer, etiket: 'Süre (sn)',
              deger: playInterval.toDouble(), min: 1, max: 60, renk: Colors.teal,
              degisti: (v) => svc.send({'playInterval': v.round()})),
          ],
        ])),
        const SizedBox(height: 80),
      ],
    ]);
  }

  Widget _dualPanel(BuildContext ctx, BoardService svc,
      Map<String,dynamic> s, double brightness, double speed) {
    final l1Hue  = ((s['line1Hue']  ?? 0)  as num).toInt();
    final l2Hue  = ((s['line2Hue']  ?? 85) as num).toInt();
    final l1Anim = ((s['line1Anim'] ?? 0)  as num).toInt();
    final l2Anim = ((s['line2Anim'] ?? 1)  as num).toInt();
    return Column(children: [
      _Kart(baslik: '🎛️ Genel Kontrol', child: Column(children: [
        _Slider(ikon: Icons.brightness_6, etiket: 'Parlaklık',
          deger: brightness, min: 10, max: 255, renk: Colors.amber,
          degisti: (v) => svc.send({'brightness': v.round()})),
        const SizedBox(height: 6),
        _Slider(ikon: Icons.speed, etiket: 'Hız',
          deger: (305 - speed).clamp(5, 300), min: 5, max: 300, renk: const Color(0xFF00E5FF),
          degisti: (v) => svc.send({'speed': (305 - v).round()})),
      ])),
      const SizedBox(height: 10),
      _LineCard(renk: const Color(0xFF00CCFF), baslik: '⬆ Üst Satır',
        currentText: s['line1']?.toString() ?? '',
        hue: l1Hue, animId: l1Anim,
        onText: (t) => svc.send({'line1': t}),
        onHue:  (h) => svc.send({'line1Hue': h}),
        onAnim: (a) => svc.send({'line1Anim': a}),
        onRenkSec: () => _renkSecLine(ctx, svc, l1Hue, true)),
      const SizedBox(height: 10),
      _LineCard(renk: Colors.orange, baslik: '⬇ Alt Satır',
        currentText: s['line2']?.toString() ?? '',
        hue: l2Hue, animId: l2Anim,
        onText: (t) => svc.send({'line2': t}),
        onHue:  (h) => svc.send({'line2Hue': h}),
        onAnim: (a) => svc.send({'line2Anim': a}),
        onRenkSec: () => _renkSecLine(ctx, svc, l2Hue, false)),
    ]);
  }

  Widget _ozet(BoardService svc, int activeIdx, bool blackout) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF001A2E), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2))),
    child: Row(children: [
      const Icon(Icons.dashboard, color: Color(0xFF00E5FF), size: 18),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(svc.textList.isNotEmpty
          ? '▶ ${svc.textList[activeIdx.clamp(0,svc.textList.length-1)]}'
          : 'Metin yok',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis),
        Text('${svc.boardW}×${svc.boardH} • WiFi',
          style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ])),
      GestureDetector(
        onTap: () => svc.send({'blackout': !blackout}),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: blackout ? Colors.redAccent.withOpacity(0.15) : Colors.greenAccent.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: blackout ? Colors.redAccent : Colors.greenAccent)),
          child: Icon(blackout ? Icons.power_off : Icons.power,
            color: blackout ? Colors.redAccent : Colors.greenAccent, size: 22))),
    ]));

  void _renkSec(BuildContext ctx, BoardService svc, int hue) {
    Color c = HSVColor.fromAHSV(1, hue/255*360, 1, 1).toColor();
    showDialog(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E), title: const Text('Renk Seç'),
      content: SingleChildScrollView(child: ColorPicker(pickerColor: c,
        onColorChanged: (nc) => svc.send({'hue': (HSVColor.fromColor(nc).hue/360*255).round()}))),
      actions: [TextButton(onPressed: () => Navigator.pop(_), child: const Text('Tamam'))]));
  }

  void _renkSecLine(BuildContext ctx, BoardService svc, int hue, bool isLine1) {
    Color c = HSVColor.fromAHSV(1, hue/255*360, 1, 1).toColor();
    showDialog(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Text(isLine1 ? '⬆ Üst Satır Rengi' : '⬇ Alt Satır Rengi'),
      content: SingleChildScrollView(child: ColorPicker(pickerColor: c,
        onColorChanged: (nc) {
          final h = (HSVColor.fromColor(nc).hue/360*255).round();
          svc.send({isLine1 ? 'line1Hue' : 'line2Hue': h});
        })),
      actions: [TextButton(onPressed: () => Navigator.pop(_), child: const Text('Tamam'))]));
  }
}

class _LineCard extends StatefulWidget {
  final Color renk;
  final String baslik, currentText;
  final int hue, animId;
  final Function(String) onText;
  final Function(int) onHue, onAnim;
  final VoidCallback onRenkSec;
  const _LineCard({required this.renk, required this.baslik,
    required this.currentText, required this.hue, required this.animId,
    required this.onText, required this.onHue, required this.onAnim,
    required this.onRenkSec});
  @override State<_LineCard> createState() => _LineCardState();
}

class _LineCardState extends State<_LineCard> {
  late TextEditingController _ctrl;
  @override void initState() { super.initState(); _ctrl = TextEditingController(text: widget.currentText); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  void _send() {
    String t = _ctrl.text.trim().toUpperCase();
    if (t.isNotEmpty) { if (!t.endsWith(' ')) t += ' '; widget.onText(t); }
  }

  @override
  Widget build(BuildContext context) {
    final hueColor = HSVColor.fromAHSV(1, widget.hue/255*360, 1, 1).toColor();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF12121F), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.renk.withOpacity(0.4), width: 1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.baslik, style: TextStyle(color: widget.renk, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Metin yaz...', filled: true,
              fillColor: widget.renk.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true),
            style: const TextStyle(fontSize: 13), onSubmitted: (_) => _send())),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.renk, foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
            onPressed: _send,
            child: const Text('Gönder', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 12),
        const Text('Hareket', style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: _lineAnims.map((a) {
          final aktif = widget.animId == a['id'];
          return GestureDetector(
            onTap: () => widget.onAnim(a['id'] as int),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: aktif ? widget.renk.withOpacity(0.2) : const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: aktif ? widget.renk : Colors.grey.withOpacity(0.3),
                  width: aktif ? 1.5 : 0.5)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(a['ikon'] as IconData, size: 13, color: aktif ? widget.renk : Colors.grey),
                const SizedBox(width: 4),
                Text(a['ad'] as String, style: TextStyle(fontSize: 11,
                  color: aktif ? widget.renk : Colors.grey,
                  fontWeight: aktif ? FontWeight.bold : FontWeight.normal)),
              ])));
        }).toList()),
        const SizedBox(height: 10),
        Row(children: [
          const Text('Renk: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
          Expanded(child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: hueColor, thumbColor: hueColor,
              inactiveTrackColor: hueColor.withOpacity(0.2),
              trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8)),
            child: Slider(value: widget.hue.toDouble().clamp(0,255), min: 0, max: 255,
              onChanged: (v) => widget.onHue(v.round())))),
          GestureDetector(
            onTap: widget.onRenkSec,
            child: Container(width: 28, height: 28,
              decoration: BoxDecoration(color: hueColor, shape: BoxShape.circle,
                border: Border.all(color: Colors.white30, width: 1.5)))),
        ]),
      ]));
  }
}

class _Kart extends StatelessWidget {
  final String baslik; final Widget child;
  const _Kart({required this.baslik, required this.child});
  @override Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFF12121F), borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(baslik, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10), child]));
}

class _ModeBtn extends StatelessWidget {
  final String etiket; final bool aktif; final Color renk; final VoidCallback tiklandi;
  const _ModeBtn({required this.etiket, required this.aktif, required this.renk, required this.tiklandi});
  @override Widget build(BuildContext ctx) => GestureDetector(onTap: tiklandi,
    child: AnimatedContainer(duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: aktif ? renk.withOpacity(0.15) : Colors.transparent,
        border: Border.all(color: aktif ? renk : Colors.grey.withOpacity(0.3), width: aktif ? 1.5 : 0.5),
        borderRadius: BorderRadius.circular(8)),
      child: Text(etiket, style: TextStyle(color: aktif ? renk : Colors.grey,
        fontWeight: aktif ? FontWeight.bold : FontWeight.normal, fontSize: 11),
        textAlign: TextAlign.center)));
}

class _Btn extends StatelessWidget {
  final String etiket; final Color renk; final VoidCallback tiklandi;
  const _Btn({required this.etiket, required this.renk, required this.tiklandi});
  @override Widget build(BuildContext ctx) => GestureDetector(onTap: tiklandi,
    child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: renk.withOpacity(0.08),
        border: Border.all(color: renk.withOpacity(0.5)), borderRadius: BorderRadius.circular(8)),
      child: Text(etiket, style: TextStyle(color: renk, fontWeight: FontWeight.bold, fontSize: 12),
        textAlign: TextAlign.center)));
}

class _Slider extends StatelessWidget {
  final IconData ikon; final String etiket;
  final double deger, min, max; final Color renk; final ValueChanged<double> degisti;
  const _Slider({required this.ikon, required this.etiket, required this.deger,
    required this.min, required this.max, required this.renk, required this.degisti});
  @override Widget build(BuildContext ctx) => Row(children: [
    Icon(ikon, color: renk, size: 18), const SizedBox(width: 6),
    SizedBox(width: 72, child: Text(etiket, style: const TextStyle(fontSize: 11))),
    Expanded(child: SliderTheme(
      data: SliderTheme.of(ctx).copyWith(activeTrackColor: renk, thumbColor: renk,
        inactiveTrackColor: renk.withOpacity(0.2), trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7)),
      child: Slider(value: deger.clamp(min, max), min: min, max: max, onChanged: degisti))),
    SizedBox(width: 32, child: Text(deger.round().toString(),
      style: const TextStyle(fontSize: 11), textAlign: TextAlign.right))]);
}
