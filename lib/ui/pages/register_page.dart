import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import '../../database.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controller untuk menangkap input user
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Inisialisasi Database Helper
  final DbHelper _dbHelper = DbHelper();

  final Color primaryColor = Color(0xFF800000); // Merah Marun
  final Color bgColor = Color(0xFFFDF5E6); // Krem Batik

  // Fungsi Hashing SHA-256 untuk keamanan (Kriteria Tugas)
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Fungsi Proses Registrasi ke SQLite
  void _handleRegister() async {
    String name = _fullNameController.text;
    String user = _usernameController.text;
    String pass = _passwordController.text;

    if (name.isNotEmpty && user.isNotEmpty && pass.isNotEmpty) {
      try {
        // Menyiapkan Map data untuk dimasukkan ke tabel 'users'
        Map<String, dynamic> userData = {
          'fullName': name,
          'username': user,
          'password': _hashPassword(pass), // Simpan password terenkripsi
        };

        // Simpan ke SQLite
        await _dbHelper.saveUser(userData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Registrasi Berhasil! Silakan Login."),
            backgroundColor: Colors.green,
          ),
        );

        // Beri jeda sedikit agar user bisa baca snackbar, lalu kembali ke Login
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pop(context);
        });
      } catch (e) {
        // Menangani jika username sudah ada (karena kita set UNIQUE di DbHelper)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Username sudah digunakan!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Mohon lengkapi semua bidang!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Daftar Akun", style: TextStyle(fontFamily: 'Georgia')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: primaryColor,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(30),
          child: Column(
            children: [
              // Ilustrasi Icon
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add_alt_1,
                  size: 60,
                  color: primaryColor,
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Buat Akun Baru",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              Text("Bergabung dalam pelestarian budaya"),
              SizedBox(height: 40),

              // Field Input menggunakan helper widget agar rapi
              _buildTextField(
                _fullNameController,
                "Nama Lengkap",
                Icons.badge_outlined,
              ),
              SizedBox(height: 20),
              _buildTextField(
                _usernameController,
                "Username",
                Icons.alternate_email,
              ),
              SizedBox(height: 20),
              _buildTextField(
                _passwordController,
                "Password",
                Icons.lock_outline,
                isPassword: true,
              ),

              SizedBox(height: 40),

              // Tombol Daftar
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    "Daftar Sekarang",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              SizedBox(height: 20),
              // Link kembali ke Login
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Sudah punya akun? Masuk di sini",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Helper untuk membuat TextField yang seragam
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryColor),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}
