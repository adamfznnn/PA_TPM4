import 'package:flutter/material.dart';
import 'dart:async';

class GamesPage extends StatefulWidget {
  const GamesPage({super.key});

  @override
  _GamesPageState createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  final Color primaryColor = const Color(0xFF800000);
  final Color accentColor = const Color(0xFFC0A080);
  final Color bgColor = const Color(0xFFFDF5E6);

  String? modeTerpilih; // null: Menu, 'adat': Tebak Adat, 'musik': Tebak Musik
  int skor = 0;
  int indexSoal = 0;
  int nyawa = 3;
  bool? isCorrect;

  // --- DATA SOAL TERPISAH ---
  final List<Map<String, dynamic>> soalAdat = [
    {
      "pertanyaan": "Upacara pembakaran mayat di Bali disebut...",
      "icon": Icons.local_fire_department,
      "pilihan": ["Kasada", "Ngaben", "Sekaten", "Tedak Siten"],
      "jawaban": "Ngaben",
    },
    {
      "pertanyaan": "Batik Parang merupakan motif batik tertua dari...",
      "icon": Icons.brush,
      "pilihan": ["Solo", "Yogyakarta", "Pekalongan", "Cirebon"],
      "jawaban": "Solo",
    },
    {
      "pertanyaan": "Rumah adat Gadang berasal dari provinsi...",
      "icon": Icons.home,
      "pilihan": ["Riau", "Sumbar", "Jambi", "Lampung"],
      "jawaban": "Sumbar",
    },
  ];

  final List<Map<String, dynamic>> soalMusik = [
    {
      "pertanyaan": "Alat musik Sasando berasal dari daerah...",
      "icon": Icons.music_note,
      "pilihan": ["NTT", "Papua", "Maluku", "NTB"],
      "jawaban": "NTT",
    },
    {
      "pertanyaan": "Alat musik petik khas Kalimantan adalah...",
      "icon": Icons.music_video,
      "pilihan": ["Sape", "Kecapi", "Gambus", "Suling"],
      "jawaban": "Sape",
    },
    {
      "pertanyaan": "Angklung dimainkan dengan cara...",
      "icon": Icons.graphic_eq,
      "pilihan": ["Dipetik", "Ditiup", "Digoyang", "Dipukul"],
      "jawaban": "Digoyang",
    },
  ];

  // Mengambil list soal aktif berdasarkan mode
  List<Map<String, dynamic>> get soalAktif =>
      modeTerpilih == 'adat' ? soalAdat : soalMusik;

  void _pilihMode(String mode) {
    setState(() {
      modeTerpilih = mode;
      indexSoal = 0;
      skor = 0;
      nyawa = 3;
      isCorrect = null;
    });
  }

  void _cekJawaban(String jawabanUser) {
    if (isCorrect != null || nyawa <= 0) return;

    setState(() {
      if (jawabanUser == soalAktif[indexSoal]['jawaban']) {
        skor += 10;
        isCorrect = true;
      } else {
        nyawa--;
        isCorrect = false;
      }
    });

    Timer(const Duration(milliseconds: 1000), () {
      if (nyawa <= 0) {
        _showGameOver(isWin: false);
      } else if (indexSoal < soalAktif.length - 1) {
        setState(() {
          indexSoal++;
          isCorrect = null;
        });
      } else {
        _showGameOver(isWin: true);
      }
    });
  }

  void _showGameOver({required bool isWin}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isWin ? "Luar Biasa!" : "Game Over",
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isWin ? Icons.emoji_events : Icons.heart_broken,
              size: 70,
              color: isWin ? Colors.amber : Colors.red,
            ),
            const SizedBox(height: 10),
            Text(
              "Skor Akhir: $skor",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () {
                Navigator.pop(context);
                setState(() => modeTerpilih = null);
              },
              child: const Text(
                "Kembali ke Menu",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          modeTerpilih == null
              ? "Arena Budaya"
              : (modeTerpilih == 'adat' ? "Tebak Adat" : "Tebak Alat Musik"),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        leading: modeTerpilih != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => modeTerpilih = null),
              )
            : null,
      ),
      body: modeTerpilih == null ? _buildMenuGim() : _buildPlayArea(),
    );
  }

  Widget _buildMenuGim() {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pilih Kategori,",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          Text(
            "Uji Wawasanmu!",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 30),
          _menuCard(
            "Tebak Adat",
            "Pelajari tradisi & warisan luhur.",
            Icons.festival,
            Colors.orange.shade800,
            () => _pilihMode('adat'),
          ),
          const SizedBox(height: 20),
          _menuCard(
            "Tebak Alat Musik",
            "Kenali melodi khas Nusantara.",
            Icons.music_note,
            Colors.teal.shade700,
            () => _pilihMode('musik'),
          ),
        ],
      ),
    );
  }

  Widget _menuCard(
    String title,
    String desc,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Icon(Icons.play_arrow_rounded, color: color, size: 35),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayArea() {
    var soal = soalAktif[indexSoal];
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(
                  3,
                  (i) => Icon(
                    Icons.favorite,
                    color: i < nyawa ? Colors.red : Colors.grey.shade400,
                  ),
                ),
              ),
              Text(
                "Skor: $skor",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 15),
              ],
            ),
            child: Column(
              children: [
                Icon(soal['icon'], size: 60, color: primaryColor),
                const SizedBox(height: 20),
                Text(
                  soal['pertanyaan'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 2.2,
              children: List.generate(soal['pilihan'].length, (i) {
                String pil = soal['pilihan'][i];
                return ElevatedButton(
                  onPressed: () => _cekJawaban(pil),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCorrect != null && pil == soal['jawaban']
                        ? Colors.green.shade100
                        : Colors.white,
                    foregroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(
                        color: isCorrect != null && pil == soal['jawaban']
                            ? Colors.green
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    pil,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}