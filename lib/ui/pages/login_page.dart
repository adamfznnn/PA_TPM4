import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisanbudaya/database.dart';
import 'main_wrapper.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final LocalAuthentication auth = LocalAuthentication();
  final DbHelper _dbHelper = DbHelper();

  final Color primaryColor = const Color(0xFF800000);
  final Color bgColor = const Color(0xFFFDF5E6);

  // Fungsi Hash SHA-256 untuk keamanan data
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Handle Login Manual
  void _handleLogin() async {
    String username = _usernameController.text.trim();
    String rawPassword = _passwordController.text.trim();

    if (username.isNotEmpty && rawPassword.isNotEmpty) {
      String encryptedPassword = _hashPassword(rawPassword);
      var user = await _dbHelper.checkLogin(username, encryptedPassword);

      if (user != null) {
        // MENYIMPAN SESSION agar biometrik bisa mengenali user nantinya
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', user['username']);
        await prefs.setString('fullName', user['fullName']);
        await prefs.setBool('isLoggedIn', true); // Flag aktivasi biometrik

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Selamat Datang, ${user['fullName']}!"),
            backgroundColor: Colors.green,
          ),
        );
        _navigateToHome();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Username atau Password salah!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Isi semua bidang!")));
    }
  }

  // Handle Login Biometrik (Fingerprint/Face ID)
  Future<void> _authenticateBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    final bool? wasLoggedIn = prefs.getBool('isLoggedIn');

    // Cek apakah user pernah login manual sebelumnya
    if (wasLoggedIn == null || !wasLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Silakan login manual terlebih dahulu untuk mengaktifkan biometrik.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Gunakan sidik jari untuk masuk',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        _navigateToHome();
      }
    } catch (e) {
      // Menangani error jika MainActivity.kt belum diubah ke FlutterFragmentActivity
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal biometrik: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              Icon(Icons.account_balance, size: 80, color: primaryColor),
              const SizedBox(height: 20),
              Text(
                "WarisanNusantara",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const Text("Masuk untuk menjelajah budaya"),
              const SizedBox(height: 40),
              _buildInput(_usernameController, "Username", Icons.person),
              const SizedBox(height: 20),
              _buildInput(
                _passwordController,
                "Password",
                Icons.lock,
                isPass: true,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "Masuk",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Atau masuk dengan"),
              const SizedBox(height: 10),
              // Tombol Biometrik yang diperbaiki
              InkWell(
                onTap: _authenticateBiometric,
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Icon(Icons.fingerprint, size: 60, color: primaryColor),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                ),
                child: Text(
                  "Belum punya akun? Daftar Sekarang",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController ctrl,
    String lbl,
    IconData ico, {
    bool isPass = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: ctrl,
        obscureText: isPass,
        decoration: InputDecoration(
          labelText: lbl,
          prefixIcon: Icon(ico, color: primaryColor),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
