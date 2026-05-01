import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Wajib untuk API Key aman
import 'package:warisanbudaya/ui/pages/login_page.dart';
// Import MapPage kamu di sini agar bisa digunakan sebagai rute

Future<void> main() async {
  // Pastikan plugin diinisialisasi sebelum load .env
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Memuat API Key dari file .env (Maps & AI)
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Error loading .env file: $e");
  }

  runApp(const WarisanNusantaraApp());
}

class WarisanNusantaraApp extends StatelessWidget {
  const WarisanNusantaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definisi Warna Tema (Konsisten dengan SafeGuard branding)
    final Color primaryColor = const Color(0xFF800000); // Merah Marun
    final Color bgColor = const Color(0xFFFDF5E6); // Krem Batik

    return MaterialApp(
      title: 'WarisanNusantara',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: bgColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
        ),
        // Menggunakan font Georgia untuk kesan heritage/warisan budaya
        fontFamily: 'Georgia',

        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true, // Membuat judul di tengah agar lebih rapi
        ),

        // Tambahkan tema Button agar seragam di LoginPage & MapPage
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      // Entry point: Halaman Login
      home: const LoginPage(),

      // Definisikan Routes agar navigasi antar halaman lebih mudah
      routes: {
        '/login': (context) => const LoginPage(),
        // '/map': (context) => const MapPage(), // Uncomment jika class MapPage sudah di-import
      },
    );
  }
}
