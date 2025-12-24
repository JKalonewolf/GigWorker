import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:gigworker/features/auth/login_page.dart';
import 'package:gigworker/features/dashboard/dashboard_page.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  final AuthService _authService = AuthService();
  final BiometricService _bioService = BiometricService();

  @override
  void initState() {
    super.initState();
    // Run the check immediately when app starts
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    // 1. Check if we have saved credentials (User logged in previously)
    Map<String, String>? credentials = await _bioService.getCredentials();

    if (credentials == null) {
      // No saved user -> Go to Login Page
      _navigateToLogin();
      return;
    }

    // 2. Check if device supports Biometrics (Fingerprint/Face)
    bool canUseBio = await _bioService.isBiometricAvailable();

    if (!canUseBio) {
      // 3. NO Fingerprint hardware? -> User requirement: "Login with email/pass"
      // We do NOT auto-login. We send them to Login Page to type password.
      _navigateToLogin();
    } else {
      // 4. HAS Fingerprint -> Trigger Scanner Immediately
      bool authenticated = await _bioService.authenticate();

      if (authenticated) {
        // Bio Success -> Auto-Login silently
        String? error = await _authService.signIn(
          email: credentials['email']!,
          password: credentials['password']!,
        );

        if (error == null) {
          // Get Phone ID for Dashboard
          String? phone = await _authService.getPhoneFromEmail(
            credentials['email']!,
          );
          if (phone != null && mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardPage(phoneNumber: phone),
              ),
            );
            return;
          }
        }
      }

      // If Bio failed, cancelled, or Auth error -> Go to Login Page
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading screen/logo while we check fingerprint
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your App Logo Here
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock, size: 40, color: Colors.blueAccent),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.blueAccent),
            const SizedBox(height: 20),
            const Text(
              "Verifying Security...",
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
