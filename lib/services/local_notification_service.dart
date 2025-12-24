import 'dart:io'; // Needed for Platform check
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  // Singleton pattern
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // --- 1. INITIALIZE SERVICE ---
  Future<void> init() async {
    // 🛑 FIX 1: Changed 'ic_launcher' to 'launcher_icon' to match your Manifest
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

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

    await _notificationsPlugin.initialize(settings);

    // 🛑 FIX 2: Explicitly Request Permission for Android 13+
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  // --- 2. SHOW NOTIFICATION ---
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'gigbank_channel_id',
          'GigBank Alerts',
          channelDescription: 'Transaction and account alerts',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          // 🛑 FIX 3: Ensure the icon appears in the notification tray
          icon: '@mipmap/launcher_icon',
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(id, title, body, details);
  }

  // --- 3. INSTANT HELPER ---
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    int id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await showNotification(id: id, title: title, body: body);
  }
}
