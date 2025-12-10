import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed to save Profile
import 'package:gigworker/features/dashboard/dashboard_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // 1. Add Controllers to capture input
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 2. The Real Registration Logic
  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final mobile = _mobileController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Basic Validation
    if (name.isEmpty || mobile.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // A. Create User in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        // B. Update Display Name
        await user.updateDisplayName(name);

        // C. Create Database Entry (Crucial to prevent Dashboard Crash)
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'phoneNumber': mobile,
          'email': email,
          'walletBalance': 0.00, // Start with 0
          'kycStatus': 'pending', // Default status
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          // D. Success! Go to Dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              // Pass the UID so Dashboard knows which document to load
              builder: (_) => DashboardPage(phoneNumber: user.uid),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Registration Failed")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                ),
              ),

              const SizedBox(height: 10),

              // App title centered
              Column(
                children: const [
                  Text(
                    "GigBank",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Create your gig worker account",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white60),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Name Input
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Full name",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),
              _buildInput("Enter your full name", controller: _nameController),

              const SizedBox(height: 18),

              // Mobile Input
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Mobile number",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),
              _buildInput(
                "Enter your mobile number",
                keyboardType: TextInputType.phone,
                controller: _mobileController,
              ),

              const SizedBox(height: 18),

              // Email Input
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Email",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),
              _buildInput(
                "Enter your email",
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
              ),

              const SizedBox(height: 18),

              // Password Input
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Password",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),
              _buildInput(
                "Create a password",
                obscure: true,
                controller: _passwordController,
              ),

              const SizedBox(height: 24),

              // Create account button
              _buildPrimaryButton(
                _isLoading ? "Creating..." : "Create account",
                onTap: _isLoading ? () {} : _handleRegister,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ------- Reusable widgets -------

  // Updated to accept Controller
  Widget _buildInput(
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    required TextEditingController controller, // Added this
  }) {
    return TextField(
      controller: controller, // Connected controller
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF191919),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF303030)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String text, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
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
          child: text == "Creating..."
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
    );
  }
}
