import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:gigworker/features/auth/register_page.dart';
import 'package:gigworker/features/auth/otp_page.dart';
import 'package:gigworker/features/dashboard/dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool useMobile = true;
  bool _isLoading = false; // To show loading spinner

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- LOGIC: HANDLE EMAIL LOGIN ---
  Future<void> _handleEmailLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Sign In with Firebase
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // 2. Check if User is valid
      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;

        if (mounted) {
          // 3. Navigate to Dashboard with the UID
          // We pass UID to 'phoneNumber' parameter because Dashboard uses it as Document ID
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => DashboardPage(phoneNumber: uid)),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message ?? "Login Failed")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIC: FORGOT PASSWORD ---
  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter your email first")));
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password reset email sent!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // App branding centered
                Column(
                  children: const [
                    Text(
                      "GigBank",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Smart banking for gig workers",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.white60),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Sign in",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Use your mobile number or email to continue",
                    style: TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                ),

                const SizedBox(height: 24),

                // Toggle buttons
                Row(
                  children: [
                    _buildToggleButton("Mobile", useMobile),
                    const SizedBox(width: 12),
                    _buildToggleButton("Email", !useMobile),
                  ],
                ),

                const SizedBox(height: 24),

                // Form for selected tab
                useMobile ? _buildMobileForm() : _buildEmailForm(),

                const SizedBox(height: 20),

                // Register Link
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    );
                  },
                  child: const Text(
                    "New here? Create an account",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------- TOGGLE BUTTON -----------------
  Widget _buildToggleButton(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            useMobile = (label == "Mobile");
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? Colors.blueAccent : const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ----------------- MOBILE LOGIN FORM -----------------
  Widget _buildMobileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Full Name",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration("Enter your full name"),
        ),
        const SizedBox(height: 18),

        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Mobile number",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration("Enter your 10-digit mobile number"),
        ),
        const SizedBox(height: 24),

        _buildPrimaryButton(
          _isLoading ? "Sending..." : "Send OTP",
          onTap: _isLoading ? null : _sendOtp,
        ),
      ],
    );
  }

  // ----------------- EMAIL LOGIN FORM (FIXED) -----------------
  Widget _buildEmailForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Email",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration("Enter your email"),
        ),
        const SizedBox(height: 18),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Password",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration("Enter your password"),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _handleForgotPassword, // FIXED: Now works
            child: const Text(
              "Forgot password?",
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // FIXED: Calls _handleEmailLogin instead of dummy navigation
        _buildPrimaryButton(
          _isLoading ? "Logging in..." : "Login",
          onTap: _isLoading ? null : _handleEmailLogin,
        ),
      ],
    );
  }

  // ----------------- REUSABLE WIDGETS -----------------
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF191919),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF303030)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildPrimaryButton(String text, {VoidCallback? onTap}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.7,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blueAccent, Colors.purpleAccent],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: enabled && text == "Logging in..."
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ----------------- SEND OTP (Mobile) -----------------
  Future<void> _sendOtp() async {
    final name = _nameController.text.trim();
    final mobile = _mobileController.text.trim();

    // Validate Name
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter your name")));
      return;
    }

    // Validate Mobile
    if (mobile.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid 10-digit number")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Pass BOTH name and mobile to OTP page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpPage(mobile: mobile, name: name),
      ),
    );
  }
}
