import 'package:firebase_auth/firebase_auth.dart'; // <--- Added for verification check
import 'package:flutter/material.dart';
import 'package:gigworker/features/dashboard/dashboard_page.dart';
import 'package:gigworker/features/auth/register_page.dart';
import 'package:gigworker/features/auth/forgot_password_page.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final AuthService _authService = AuthService();
  final BiometricService _bioService = BiometricService();

  bool _isLoading = false;
  bool _canUseBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  // Check if phone has fingerprint hardware
  void _checkBiometrics() async {
    bool available = await _bioService.isBiometricAvailable();
    setState(() => _canUseBiometrics = available);
  }

  // --- NORMAL LOGIN ---
  void _login() async {
    if (_emailController.text.isEmpty || _passController.text.isEmpty) return;

    setState(() => _isLoading = true);

    String? error = await _authService.signIn(
      email: _emailController.text.trim(),
      password: _passController.text.trim(),
    );

    if (error != null) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    } else {
      // 🔒 CHECK EMAIL VERIFICATION STATUS HERE 🔒
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null && !user.emailVerified) {
        // If email is NOT verified:
        await FirebaseAuth.instance.signOut(); // Log them out immediately
        setState(() => _isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "Email not verified! Please check your inbox.",
              ),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: "Resend",
                textColor: Colors.white,
                onPressed: () async {
                  await user.sendEmailVerification();
                },
              ),
            ),
          );
        }
        return; // Stop execution here
      }

      // SUCCESS: Save credentials for future fingerprint login
      await _bioService.saveCredentials(
        _emailController.text.trim(),
        _passController.text.trim(),
      );

      _navigateToDashboard(_emailController.text.trim());
    }
  }

  // --- FINGERPRINT LOGIN ---
  void _handleBiometricLogin() async {
    // 1. Check if we have saved credentials first
    Map<String, String>? credentials = await _bioService.getCredentials();

    if (credentials == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please login with password once to enable fingerprint.",
            ),
          ),
        );
      }
      return;
    }

    // 2. Scan Fingerprint
    bool authenticated = await _bioService.authenticate();

    if (authenticated) {
      setState(() => _isLoading = true);

      // 3. Auto-Login using saved credentials
      String? error = await _authService.signIn(
        email: credentials['email']!,
        password: credentials['password']!,
      );

      if (error == null) {
        // 🔒 CHECK EMAIL VERIFICATION FOR FINGERPRINT TOO 🔒
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null && !user.emailVerified) {
          await FirebaseAuth.instance.signOut();
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Email not verified! Please check your inbox."),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        _navigateToDashboard(credentials['email']!);
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Session expired. Please login again."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToDashboard(String email) async {
    String? phone = await _authService.getPhoneFromEmail(email);
    setState(() => _isLoading = false);
    if (phone != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardPage(phoneNumber: phone)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E1A47), Color(0xFF1E1E2C)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              const Text(
                "Welcome\nBack",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 60),

              _buildInput("Email", _emailController, false),
              const SizedBox(height: 20),
              _buildInput("Password", _passController, true),

              const SizedBox(height: 30),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A5ACD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Log in",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // --- FINGERPRINT ICON (Only if supported) ---
              if (_canUseBiometrics)
                Center(
                  child: GestureDetector(
                    onTap: _handleBiometricLogin,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blueAccent.withOpacity(0.5),
                        ),
                      ),
                      child: const Icon(
                        Icons.fingerprint,
                        size: 40,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordPage(),
                    ),
                  ),
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.white38),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    ),
                    child: const Text(
                      "Sign in",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String hint, TextEditingController ctrl, bool isPass) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161621).withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: isPass,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
