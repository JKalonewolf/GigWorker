import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gigworker/features/dashboard/dashboard_page.dart';
// Note: We don't need UserService anymore because we save directly here for better control

class OtpPage extends StatefulWidget {
  final String mobile;
  final String name; // 1. Added field to hold the name

  // 2. Updated constructor to accept 'this.name'
  const OtpPage({super.key, required this.mobile, required this.name});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;
  static const String _expectedOtp = "123456";

  Future<void> _verifyOtp() async {
    final smsCode = _otpController.text.trim();
    if (smsCode.length < 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter 6-digit OTP")));
      return;
    }

    setState(() => _isVerifying = true);

    await Future.delayed(const Duration(milliseconds: 600)); // fake delay

    if (!mounted) return;

    if (smsCode == _expectedOtp) {
      // 3. 🔹 SAVE NAME TO FIRESTORE DIRECTLY 🔹
      // We use the mobile number as the Document ID so it matches everywhere
      await FirebaseFirestore.instance.collection('users').doc(widget.mobile).set(
        {
          'name': widget.name, // <--- Saving the Name here
          'phoneNumber': widget.mobile,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      ); // 'merge: true' ensures we don't delete wallet balance if user exists

      if (!mounted) return;

      // Navigate to Dashboard
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(phoneNumber: widget.mobile),
        ),
        (route) => false,
      );
    } else {
      setState(() => _isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP. Try 123456 😉")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                "Verify OTP",
                style: TextStyle(
                  fontSize: 26,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "We (pretend to) sent an OTP to +91 ${widget.mobile}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  counterText: "",
                  hintText: "Enter 6-digit OTP (use 123456)",
                  hintStyle: TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Color(0xFF191919),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFF303030)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _isVerifying ? null : _verifyOtp,
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
                    child: _isVerifying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            "Verify OTP",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
