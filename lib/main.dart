import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:warisanbudaya/ui/pages/login_page.dart';
import 'package:warisanbudaya/services/notification_services.dart';
import 'package:warisanbudaya/database.dart';
import 'package:timezone/data/latest.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 INIT TIMEZONE
  tz.initializeTimeZones();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Error loading .env: $e");
  }

  // 🔔 INIT NOTIFICATION
  final notificationService = NotificationService();
  await notificationService.scheduleDailyRandomNotification();

  // 🔥 AMBIL DATA DARI DATABASE
  final db = DbHelper();
  final facts = await db.getFacts();

  // 🔥 DEFAULT (kalau DB kosong)
  String selectedFact = "Indonesia kaya akan budaya 🇮🇩";

  // 🔥 RANDOM DARI DATABASE
  if (facts.isNotEmpty) {
    final random = Random();
    final randomData = facts[random.nextInt(facts.length)];

    selectedFact = randomData['content'];
  }

  // 🔥 SET NOTIF HARIAN
  await notificationService.scheduleDailyNotification(
    hour: 8,
    minute: 0,
    title: "Tahukah Kamu? 🇮🇩",
    body: selectedFact, // ✅ dari database
  );

  runApp(const WarisanNusantaraApp());
}

class WarisanNusantaraApp extends StatelessWidget {
  const WarisanNusantaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF800000);
    final Color bgColor = const Color(0xFFFDF5E6);

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
        fontFamily: 'Georgia',

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF800000),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),

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

      home: const LoginPage(),

      routes: {'/login': (context) => const LoginPage()},
    );
  }
}
