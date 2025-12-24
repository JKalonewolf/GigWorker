import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gigworker/features/admin/admin_login_page.dart'; // ✅ IMPORT LOGIN PAGE
// import 'package:gigworker/features/admin/web_admin_dashboard.dart'; // (Optional: Can remove if not used here directly)
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GigBank Admin',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF111111),
        primaryColor: Colors.blueAccent,
      ),
      // 🛑 CHANGED: Start with Login Page, not Dashboard
      home: const AdminLoginPage(),
    );
  }
}
