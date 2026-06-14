import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/board_service.dart';
import 'baglanti_screen.dart';
import 'kontrol_screen.dart';
import 'yazi_screen.dart';
import 'efekt_screen.dart';
import 'ayarlar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<BoardService>();
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: Row(children: [
          // Bağlantı indikatörü
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: svc.isConnected ? Colors.greenAccent : Colors.redAccent,
              shape: BoxShape.circle,
              boxShadow: svc.isConnected ? [
                BoxShadow(color: Colors.greenAccent.withOpacity(0.6),
                  blurRadius: 6, spreadRadius: 1)
              ] : [],
            ),
          ),
          const SizedBox(width: 8),
          const Text('Akıllı Tabela',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          if (svc.isConnected) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: svc.isBleConnected
                  ? const Color(0xFF7B2FBE).withOpacity(0.2)
                  : const Color(0xFF00E5FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: svc.isBleConnected
                    ? const Color(0xFF7B2FBE)
                    : const Color(0xFF00E5FF),
                  width: 0.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  svc.isBleConnected ? Icons.bluetooth : Icons.wifi,
                  size: 10,
                  color: svc.isBleConnected
                    ? const Color(0xFF7B2FBE)
                    : const Color(0xFF00E5FF),
                ),
                const SizedBox(width: 4),
                Text(
                  svc.isBleConnected ? 'BLE' : 'WiFi',
                  style: TextStyle(
                    fontSize: 10,
                    color: svc.isBleConnected
                      ? const Color(0xFF7B2FBE)
                      : const Color(0xFF00E5FF),
                  ),
                ),
              ]),
            ),
          ],
        ]),
        actions: [
          // Bağlantı butonu
          IconButton(
            icon: Icon(
              svc.isConnected ? Icons.link : Icons.link_off,
              color: svc.isConnected ? Colors.greenAccent : Colors.grey,
            ),
            tooltip: svc.isConnected ? 'Bağlı - değiştirmek için tıkla' : 'Bağlan',
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BaglantiScreen())),
          ),
        ],
      ),

      body: svc.isConnected
        ? IndexedStack(index: _tab, children: _pages())
        : _bagliDegil(context, svc),

      bottomNavigationBar: svc.isConnected
        ? NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            backgroundColor: const Color(0xFF0D0D1A),
            indicatorColor: const Color(0xFF00E5FF).withOpacity(0.15),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.tune),
                selectedIcon: Icon(Icons.tune, color: Color(0xFF00E5FF)),
                label: 'Kontrol',
              ),
              NavigationDestination(
                icon: Icon(Icons.text_fields),
                selectedIcon: Icon(Icons.text_fields, color: Color(0xFF00E5FF)),
                label: 'Yazılar',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_awesome),
                selectedIcon: Icon(Icons.auto_awesome, color: Color(0xFF00E5FF)),
                label: 'Efektler',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings),
                selectedIcon: Icon(Icons.settings, color: Color(0xFF00E5FF)),
                label: 'Ayarlar',
              ),
            ],
          )
        : null,
    );
  }

  List<Widget> _pages() => const [
    KontrolScreen(),
    YaziScreen(),
    EfektScreen(),
    AyarlarScreen(),
  ];

  Widget _bagliDegil(BuildContext context, BoardService svc) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        // Animasyonlu ikon
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3), width: 2),
            color: const Color(0xFF001A2E),
          ),
          child: const Icon(Icons.wifi_off, size: 50, color: Color(0xFF00E5FF)),
        ),
        const SizedBox(height: 24),
        const Text('Tahtaya Bağlı Değilsiniz',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(svc.statusMsg,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
          textAlign: TextAlign.center),
        const SizedBox(height: 32),
        // WiFi bağlan
        SizedBox(
          width: 220,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.wifi),
            label: const Text('WiFi ile Bağlan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BaglantiScreen())),
          ),
        ),
        const SizedBox(height: 12),
        // BLE bağlan
        SizedBox(
          width: 220,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.bluetooth),
            label: const Text('Bluetooth ile Bağlan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF7B2FBE),
              side: const BorderSide(color: Color(0xFF7B2FBE)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BaglantiScreen(initialTab: 1))),
          ),
        ),
        const SizedBox(height: 24),
        // Bilgi
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D1A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Column(children: [
            Text('WiFi: AkilliTahta-AP',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
            Text('Şifre: 12345678',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}
