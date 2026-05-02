import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import '../database.dart';
import 'dart:math';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // ================= INIT =================
  Future<void> initNotification() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (details.payload != null) {
          debugPrint("Klik notifikasi: ${details.payload}");
        }
      },
    );

    // 🔥 CHANNEL ANDROID
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notifikasi Budaya',
      description: 'Informasi budaya harian',
      importance: Importance.max,
    );

    final androidPlugin = notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(channel);

    // 🔥 ANDROID 13+ PERMISSION
    await androidPlugin?.requestNotificationsPermission();

    _isInitialized = true;
  }

  Future<void> scheduleDailyRandomNotification() async {
    final db = DbHelper();
    final facts = await db.getFacts();

    if (facts.isEmpty) return;

    final random = Random();
    final fact = facts[random.nextInt(facts.length)];

    await scheduleDailyNotification(
      hour: 8,
      minute: 0,
      title: "Tahukah Kamu? 🇮🇩",
      body: fact['content'], // 🔥 ambil dari DB
    );
  }

  // ================= DETAIL =================
  NotificationDetails _notificationDetails({String? bigText}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'Notifikasi Budaya',
        channelDescription: 'Informasi edukasi budaya nusantara',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        ticker: 'ticker',
        styleInformation: BigTextStyleInformation(bigText ?? ''),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // ================= NOTIF LANGSUNG =================
  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
  }) async {
    await initNotification();

    await notificationsPlugin.show(
      id,
      title ?? "Daily Insight Budaya 🏛️",
      body ?? "Jelajahi budaya Indonesia hari ini 🇮🇩",
      _notificationDetails(bigText: body),
      payload: payload,
    );
  }

  // ================= NOTIF GAMBAR =================
  Future<void> showBigPictureNotification({
    required String title,
    required String body,
    required String androidImagePath,
  }) async {
    await initNotification();

    final bigPictureStyle = BigPictureStyleInformation(
      DrawableResourceAndroidBitmap(androidImagePath),
      contentTitle: title,
      summaryText: body,
    );

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'big_picture_channel',
        'Notifikasi Bergambar',
        channelDescription: 'Notifikasi dengan gambar budaya',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: bigPictureStyle,
      ),
    );

    await notificationsPlugin.show(2, title, body, details);
  }

  // ================= DELAY =================
  Future<void> showDelayedNotification({
    required int seconds,
    required String title,
    required String body,
  }) async {
    await Future.delayed(Duration(seconds: seconds));
    await showNotification(id: 1, title: title, body: body);
  }

  // ================= NOTIF HARIAN =================
  Future<void> scheduleDailyNotification({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await initNotification();

    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
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

    await notificationsPlugin.zonedSchedule(
      10,
      title,
      body,
      scheduledDate,
      _notificationDetails(bigText: body),

      // 🔥 FIX ERROR ANDROID (WAJIB)
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,

      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
