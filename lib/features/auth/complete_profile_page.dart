import 'package:flutter/material.dart';
import 'package:gigworker/services/user_service.dart';
import 'package:gigworker/features/dashboard/dashboard_page.dart';

class CompleteProfilePage extends StatefulWidget {
  final String phone;
  const CompleteProfilePage({super.key, required this.phone});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  bool _loading = false;

  Future<void> _save() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter your name")));
      return;
    }

    setState(() => _loading = true);

    await UserService().updateBasicProfile(
      phone: widget.phone,
      name: _nameController.text.trim(),
      city: _cityController.text.trim(),
    );

    setState(() => _loading = false);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardPage(phoneNumber: widget.phone),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("Complete Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Before continuing, please complete your profile",
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Full Name",
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _cityController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "City",
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),

            const SizedBox(height: 40),

            GestureDetector(
              onTap: _loading ? null : _save,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blueAccent, Colors.purpleAccent],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : const Text(
                          "Continue",
                          style: TextStyle(
                            color: Colors.white,
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
    );
  }
}
