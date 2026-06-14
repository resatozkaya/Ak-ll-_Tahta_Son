import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/board_service.dart';

class YaziScreen extends StatefulWidget {
  const YaziScreen({super.key});
  @override
  State<YaziScreen> createState() => _YaziScreenState();
}

class _YaziScreenState extends State<YaziScreen> {
  final _ctrl = TextEditingController();
  int _duzenleIdx = -1;
  bool _kayitEdiliyor = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _ekle(BoardService svc) {
    final txt = _ctrl.text.trim().toUpperCase();
    if (txt.isEmpty) return;
    final son = txt.endsWith(' ') ? txt : '$txt ';
    if (_duzenleIdx >= 0) {
      svc.send({'setText': {'idx': _duzenleIdx, 'text': son}});
      setState(() => _duzenleIdx = -1);
    } else {
      svc.send({'addText': son});
    }
    _ctrl.clear();
    setState(() {});
  }

  void _sil(BoardService svc, int idx) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Metni Sil'),
        content: Text('${svc.textList[idx]}\nsilinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('İptal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              svc.send({'delText': idx});
            },
            child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _eepromKaydet(BoardService svc) async {
    setState(() => _kayitEdiliyor = true);
    svc.saveTextsToEeprom();
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _kayitEdiliyor = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Yazılar EEPROM\'a kaydedildi!'),
          backgroundColor: Color(0xFF1A3A1A),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc   = context.watch<BoardService>();
    final s     = svc.boardStatus;
    final liste = svc.textList;
    final aktif = (s['activeIdx'] ?? 0) as int;

    return Column(children: [
      // ── Giriş alanı ──────────────────────────────────────
      Container(
        color: const Color(0xFF0D0D1A),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: _duzenleIdx >= 0
                  ? '${_duzenleIdx + 1}. metni düzenle...'
                  : 'Yeni metin yaz...',
                filled: true, fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
                suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                      _ctrl.clear();
                      setState(() => _duzenleIdx = -1);
                    })
                  : null,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _ekle(svc),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _ctrl.text.trim().isEmpty ? null : () => _ekle(svc),
            child: Text(_duzenleIdx >= 0 ? 'Güncelle' : 'Ekle',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ]),
      ),

      // ── Aksiyonlar ───────────────────────────────────────
      Container(
        color: const Color(0xFF0D0D1A),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Row(children: [
          // Tümünü sil
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_sweep, size: 16),
              label: const Text('Tümünü Sil', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent, width: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onPressed: liste.isEmpty ? null : () => _tumunuSil(svc),
            ),
          ),
          const SizedBox(width: 8),
          // EEPROM Kaydet
          Expanded(
            child: ElevatedButton.icon(
              icon: _kayitEdiliyor
                ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.save, size: 16),
              label: const Text('EEPROM\'a Kaydet', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onPressed: _kayitEdiliyor || liste.isEmpty
                ? null : () => _eepromKaydet(svc),
            ),
          ),
        ]),
      ),

      // ── Bilgi bandı ──────────────────────────────────────
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        color: const Color(0xFF0A0A15),
        child: Row(children: [
          const Icon(Icons.info_outline, size: 13, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${liste.length} metin • Sürükle-bırak ile sıralayabilirsiniz',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          // Playlist toggle
          Row(children: [
            const Text('Playlist', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(width: 4),
            Switch(
              value: s['playlist'] ?? false,
              onChanged: (v) => svc.send({'playlist': v}),
              activeColor: const Color(0xFF00E5FF),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ]),
        ]),
      ),

      // ── Liste ────────────────────────────────────────────
      Expanded(
        child: liste.isEmpty
          ? Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.text_fields,
                  size: 64, color: Colors.grey.withOpacity(0.3)),
                const SizedBox(height: 16),
                const Text('Metin listesi boş',
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Yukarıdan yeni metin ekleyin',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 80),
              itemCount: liste.length,
              onReorder: (oldIdx, newIdx) {
                if (newIdx > oldIdx) newIdx--;
                svc.send({'moveText': {'from': oldIdx, 'to': newIdx}});
              },
              itemBuilder: (_, i) {
                final isAktif = i == aktif;
                return _metin(context, svc, i, liste[i], isAktif);
              },
            ),
      ),
    ]);
  }

  Widget _metin(BuildContext ctx, BoardService svc, int i,
      String text, bool isAktif) {
    return Card(
      key: ValueKey('text_$i'),
      color: isAktif ? const Color(0xFF0D2840) : const Color(0xFF12121F),
      margin: const EdgeInsets.symmetric(vertical: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isAktif
          ? const BorderSide(color: Color(0xFF00E5FF), width: 1.5)
          : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Row(mainAxisSize: MainAxisSize.min, children: [
          // Sürükleme tutacağı
          const Icon(Icons.drag_handle, color: Colors.grey, size: 18),
          const SizedBox(width: 6),
          // Numara
          CircleAvatar(
            radius: 14,
            backgroundColor: isAktif
              ? const Color(0xFF00E5FF) : const Color(0xFF2A2A3E),
            child: Text('${i + 1}',
              style: TextStyle(
                color: isAktif ? Colors.black : Colors.white,
                fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ]),
        title: Text(
          text,
          style: TextStyle(
            fontWeight: isAktif ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: isAktif
          ? const Text('▶ Şu an gösteriliyor',
              style: TextStyle(fontSize: 10, color: Color(0xFF00E5FF)))
          : null,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          // Düzenle
          IconButton(
            icon: const Icon(Icons.edit_note, size: 20, color: Colors.orange),
            tooltip: 'Düzenle',
            onPressed: () => setState(() {
              _duzenleIdx = i;
              _ctrl.text  = text.trim();
            }),
          ),
          // Oynat
          IconButton(
            icon: Icon(Icons.play_circle,
              color: isAktif ? const Color(0xFF00E5FF) : Colors.grey,
              size: 22),
            tooltip: 'Bu metni göster',
            onPressed: () => svc.send({'activeIdx': i}),
          ),
          // Sil
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
            tooltip: 'Sil',
            onPressed: () => _sil(svc, i),
          ),
        ]),
      ),
    );
  }

  void _tumunuSil(BoardService svc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Tüm Metinleri Sil'),
        content: const Text('Tüm metin listesi silinecek. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('İptal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              svc.send({'clearTexts': true});
            },
            child: const Text('Tümünü Sil',
              style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
