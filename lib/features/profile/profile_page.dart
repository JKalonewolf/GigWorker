import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gigworker/features/auth/login_page.dart';
import 'package:gigworker/models/user_model.dart';
import 'package:gigworker/services/user_service.dart';
import 'package:gigworker/features/support/support_page.dart';

class ProfilePage extends StatefulWidget {
  final String phoneNumber;

  const ProfilePage({super.key, required this.phoneNumber});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();

  bool _controllersInitialized = false;
  bool _saving = false;
  File? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // --- IMAGE PICKER ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter your name")));
      return;
    }

    setState(() => _saving = true);
    await UserService().updateBasicProfile(
      phone: widget.phoneNumber,
      name: name,
    );
    setState(() => _saving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.phoneNumber.isEmpty) return const SizedBox();

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "My Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.phoneNumber)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "User not found",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final user = UserModel.fromMap(data);

          if (!_controllersInitialized) {
            _nameController.text = user.name;
            _controllersInitialized = true;
          }

          return Column(
            children: [
              // --- 1. SCROLLABLE CONTENT (Top Part) ---
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      // PROFILE IMAGE
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.blueAccent.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 55,
                                backgroundColor: const Color(0xFF1E1E1E),
                                backgroundImage: _selectedImage != null
                                    ? FileImage(_selectedImage!)
                                          as ImageProvider
                                    : (user.profilePic.isNotEmpty
                                          ? NetworkImage(user.profilePic)
                                          : null),
                                child:
                                    (_selectedImage == null &&
                                        user.profilePic.isEmpty)
                                    ? const Icon(
                                        Icons.person,
                                        size: 55,
                                        color: Colors.white24,
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 4,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.blueAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      Text(
                        user.name.isEmpty ? "New User" : user.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // STATUS CARDS
                      Row(
                        children: [
                          Expanded(
                            child: _statusCard(
                              "Wallet",
                              "₹${user.walletBalance.toStringAsFixed(0)}",
                              Icons.account_balance_wallet,
                              Colors.greenAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statusCard(
                              "KYC",
                              user.kycStatus.toUpperCase(),
                              Icons.verified_user,
                              user.kycStatus == 'verified'
                                  ? Colors.blueAccent
                                  : Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // DETAILS FORM
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161618),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            _readOnlyRow(Icons.phone, "Phone", user.phone),
                            const Divider(color: Colors.white10, height: 24),
                            _readOnlyRow(
                              Icons.email,
                              "Email",
                              user.email.isEmpty ? "Not set" : user.email,
                            ),
                            const Divider(color: Colors.white10, height: 24),
                            _readOnlyRow(
                              Icons.location_city,
                              "City",
                              user.city.isEmpty ? "Not set" : user.city,
                            ),
                            const Divider(color: Colors.white10, height: 24),
                            _editRow(
                              Icons.person_outline,
                              "Full Name",
                              _nameController,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // SAVE BUTTON (Inside scroll because it's part of the form)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Save Name Change",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20), // Padding before bottom bar
                    ],
                  ),
                ),
              ),

              // --- 2. FIXED BOTTOM BAR (Support & Logout) ---
              Container(
                padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
                decoration: BoxDecoration(
                  color: const Color(0xFF161618),
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Support Button
                    Expanded(
                      child: _actionButton(
                        icon: Icons.headset_mic,
                        label: "Support",
                        color: Colors.white10,
                        textColor: Colors.white,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SupportPage(phoneNumber: widget.phoneNumber),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Logout Button
                    Expanded(
                      child: _actionButton(
                        icon: Icons.logout,
                        label: "Logout",
                        color: const Color(0xFF351010),
                        textColor: Colors.redAccent,
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGET HELPER: STATUS CARD ---
  Widget _statusCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER: BOTTOM ACTION BUTTONS ---
  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER: READ ONLY ROW ---
  Widget _readOnlyRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.lock, color: Colors.white10, size: 14),
      ],
    );
  }

  // --- WIDGET HELPER: EDIT ROW ---
  Widget _editRow(
    IconData icon,
    String label,
    TextEditingController controller,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
              TextField(
                controller: controller,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                  border: InputBorder.none,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.edit, color: Colors.blueAccent, size: 14),
      ],
    );
  }
}
