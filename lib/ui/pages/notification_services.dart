import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // Singleton pattern agar service ini mudah diakses di seluruh aplikasi
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Inisialisasi Service Notifikasi
  Future<void> initNotification() async {
    // Inisialisasi data timezone untuk fitur scheduling
    tz.initializeTimeZones();

    // Pengaturan Icon untuk Android (pastikan ic_launcher ada di res/mipmap)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Pengaturan Izin untuk iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Logika saat notifikasi diklik (misalnya navigasi ke halaman tertentu)
        if (details.payload != null) {
          print("Payload diterima: ${details.payload}");
        }
      },
    );
  }

  /// Konfigurasi Detail Notifikasi (Tampilan & Prioritas)
  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'presentation_channel', // ID Channel
        'Presentasi & Insight', // Nama Channel
        channelDescription: 'Channel khusus untuk demo presentasi aplikasi',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          '',
        ), // Agar teks panjang tidak terpotong
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  /// 1. FUNGSI TRIGGER MANUAL (Langsung Muncul)
  /// Cocok untuk menunjukkan fitur secara instan saat presentasi
  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
  }) async {
    return notificationsPlugin.show(
      id,
      title ?? "Daily Insight Budaya 🏛️",
      body ??
          "Tahukah kamu? Pola candi nusantara seringkali menggunakan prinsip geometri fraktal.",
      _notificationDetails(),
      payload: payload,
    );
  }

  /// 2. FUNGSI TRIGGER DELAY (Muncul Setelah Beberapa Detik)
  /// Strategis untuk presentasi: Klik tombol -> HP ditaruh -> Notifikasi muncul otomatis
  Future<void> showDelayedNotification({
    int id = 1,
    required int seconds,
    required String title,
    required String body,
    String? payload,
  }) async {
    await Future.delayed(Duration(seconds: seconds));
    return showNotification(id: id, title: title, body: body, payload: payload);
  }

  /// 3. FUNGSI SCHEDULED (Terjadwal Waktu Tertentu)
  /// Menunjukkan bahwa aplikasi bisa mengirim pesan edukatif setiap hari
  Future<void> scheduleDailyNotification({
    int id = 2,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Berulang harian
    );
  }

  /// Helper untuk menghitung waktu terjadwal berikutnya
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
