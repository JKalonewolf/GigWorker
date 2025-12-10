import 'package:flutter/foundation.dart'; // For kIsWeb check
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gigworker/services/local_notification_service.dart';
import 'package:gigworker/features/auth/login_page.dart'; // We use this now!
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase (Safely)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase Initialized");
  } catch (e) {
    print("⚠️ Firebase ignored: $e");
  }

  // 2. RUN APP IMMEDIATELY
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // 3. Load Notifications in Background (Only on Mobile)
    if (!kIsWeb) {
      _initNotifications();
    }
  }

  Future<void> _initNotifications() async {
    try {
      await LocalNotificationService().init();
      print("✅ Notifications Ready");
    } catch (e) {
      print("⚠️ Notifications Failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GigBank',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF101010),
        primaryColor: Colors.blueAccent,
      ),
      // SIMPLE START: Always go to Login Page
      home: const LoginPage(),
    );
  }
}
