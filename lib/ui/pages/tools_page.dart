import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  _ToolsPageState createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  final Color primaryColor = Color(0xFF800000);
  final Color bgColor = Color(0xFFFDF5E6);

  // Variabel Mata Uang
  double inputUang = 0;
  double hasilUsd = 0;
  double hasilEur = 0;
  double hasilGbp = 0;

  // Kurs statis (Agar tidak ribet API)
  final double kursUsd = 16200;
  final double kursEur = 17300;
  final double kursGbp = 20100;

  void _hitungKonversi(String val) {
    setState(() {
      inputUang = double.tryParse(val) ?? 0;
      hasilUsd = inputUang / kursUsd;
      hasilEur = inputUang / kursEur;
      hasilGbp = inputUang / kursGbp;
    });
  }

  // Fungsi ambil waktu berdasarkan Zona
  String _getWaktu(int offset) {
    DateTime now = DateTime.now().toUtc().add(Duration(hours: offset));
    return DateFormat('HH:mm').format(now);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text("Alat Konversi", style: TextStyle(fontFamily: 'Georgia')),
          backgroundColor: primaryColor,
          bottom: TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(
                icon: Icon(Icons.money, color: Colors.white),
                text: "Mata Uang",
              ),
              Tab(
                icon: Icon(Icons.access_time, color: Colors.white),
                text: "Zona Waktu",
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- TAB 1: KONVERSI MATA UANG ---
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Masukkan Rupiah (IDR)",
                      prefixText: "Rp ",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _hitungKonversi,
                  ),
                  SizedBox(height: 20),
                  _buildResultCard("US Dollar", hasilUsd, "USD"),
                  _buildResultCard("Euro", hasilEur, "EUR"),
                  _buildResultCard("British Pound", hasilGbp, "GBP"),
                ],
              ),
            ),

            // --- TAB 2: KONVERSI WAKTU ---
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    "Waktu Saat Ini di Berbagai Wilayah:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildTimeCard("WIB (Jakarta)", _getWaktu(7), "UTC +7"),
                  _buildTimeCard("WITA (Bali)", _getWaktu(8), "UTC +8"),
                  _buildTimeCard("WIT (Papua)", _getWaktu(9), "UTC +9"),
                  _buildTimeCard("London (GMT)", _getWaktu(0), "UTC +0"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pendukung untuk kartu hasil
  Widget _buildResultCard(String label, double hasil, String kode) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(label),
        trailing: Text(
          "${hasil.toStringAsFixed(2)} $kode",
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
        ),
      ),
    );
  }

  Widget _buildTimeCard(String daerah, String jam, String utc) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(Icons.public, color: primaryColor),
        title: Text(daerah),
        subtitle: Text(utc),
        trailing: Text(
          jam,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ),
    );
  }
}
