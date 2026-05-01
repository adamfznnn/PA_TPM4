import 'package:flutter/material.dart';
import 'home_page.dart';
import 'map_page.dart';
import 'tools_page.dart';
import 'games_page.dart';
import 'profile_page.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  _MainWrapperState createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  final Color primaryColor = Color(0xFF800000);

  // Daftar halaman yang akan ditampilkan
  final List<Widget> _pages = [
    HomePage(),
    MapPage(),
    ToolsPage(),
    GamesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _pages[_currentIndex], // Menampilkan halaman sesuai index yang dipilih
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType
            .fixed, // Supaya label tetap muncul jika > 3 item
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "LBS"),
          BottomNavigationBarItem(
            icon: Icon(Icons.architecture),
            label: "Tools",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.videogame_asset),
            label: "Games",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}
