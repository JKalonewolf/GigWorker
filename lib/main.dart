import 'package:flutter/foundation.dart'; // For kIsWeb check
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gigworker/services/local_notification_service.dart';
import 'package:gigworker/features/auth/login_page.dart';
import 'package:gigworker/features/dashboard/dashboard_page.dart';
import 'package:gigworker/features/admin/web_admin_dashboard.dart';
import 'package:gigworker/features/auth/auth_check.dart'; // <--- IMPORT THIS
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase Initialized");
  } catch (e) {
    print("⚠️ Firebase ignored: $e");
  }

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
      // -----------------------------------------------------------------------
      // LOGIC:
      // 1. If Web -> Use Standard StreamBuilder (No Fingerprint needed for Admin)
      // 2. If Mobile -> Use AuthCheck (Enforces Fingerprint Security)
      // -----------------------------------------------------------------------
      home: kIsWeb ? _buildWebNav() : const AuthCheck(),
    );
  }

  // --- EXISTING WEB LOGIC (Kept for Admin Panel) ---
  Widget _buildWebNav() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          User user = snapshot.data!;
          // Admin Check
          if (user.email == 'admin@gigbank.com') {
            return const WebAdminDashboard();
          }
          // Regular Web User
          String phone = user.phoneNumber ?? user.uid;
          return DashboardPage(phoneNumber: phone);
        }

        return const LoginPage();
      },
    );
  }
}
