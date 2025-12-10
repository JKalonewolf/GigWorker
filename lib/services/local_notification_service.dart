import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  // Singleton pattern (Professional standard)
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 1. Initialize the Service (Call this in main.dart)
  Future<void> init() async {
    // Android Setup
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        ); // Uses your app icon

    // iOS Setup (Basic)
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
  }

  // 2. The Trigger Function
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // Define Notification Details (Sound, Importance, etc.)
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'gigbank_channel_id', // Channel ID (Unique)
          'GigBank Alerts', // Channel Name (Visible to User)
          channelDescription: 'Transaction and account alerts',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(id, title, body, details);
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {}
}
