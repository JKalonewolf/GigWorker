import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class KycFormPage extends StatefulWidget {
  final String phoneNumber;
  // ✅ ADDED: This variable receives the old data for resubmission
  final Map<String, dynamic>? existingData;

  const KycFormPage({
    super.key,
    required this.phoneNumber,
    this.existingData, // ✅ ADDED to constructor
  });

  @override
  State<KycFormPage> createState() => _KycFormPageState();
}

class _KycFormPageState extends State<KycFormPage> {
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _genderController = TextEditingController();
  final _addressController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();

  String? _aadhaarImagePath;
  String? _panImagePath;
  String? _selfiePath;

  bool _confirm = false;
  bool _submitting = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // ✅ LOGIC: Pre-fill the form if existingData is passed (Resubmit Mode)
    if (widget.existingData != null) {
      final data = widget.existingData!;
      _fullNameController.text = data['fullName'] ?? '';
      _dobController.text = data['dob'] ?? '';
      _genderController.text = data['gender'] ?? '';
      _addressController.text = data['address'] ?? '';
      _aadhaarController.text = data['aadhaarNumber'] ?? '';
      _panController.text = data['panNumber'] ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    _aadhaarController.dispose();
    _panController.dispose();
    super.dispose();
  }

  Future<void> _pickAadhaar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _aadhaarImagePath = picked.path);
  }

  Future<void> _pickPan() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _panImagePath = picked.path);
  }

  Future<void> _takeSelfie() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) setState(() => _selfiePath = picked.path);
  }

  Future<void> _submit() async {
    // 1. Validation
    if (_fullNameController.text.trim().isEmpty ||
        _dobController.text.trim().isEmpty ||
        _aadhaarController.text.trim().isEmpty ||
        _panController.text.trim().isEmpty ||
        _aadhaarImagePath == null ||
        _panImagePath == null ||
        _selfiePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please upload all documents again to verify."),
        ),
      );
      return;
    }

    if (!_confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please confirm details")));
      return;
    }

    setState(() => _submitting = true);

    try {
      // 2. Submit to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.phoneNumber)
          .update({
            'kycStatus':
                'pending', // 🔄 Reset status to Pending so Admin sees it
            'kycRejectionReason':
                FieldValue.delete(), // 🗑️ Remove the error message
            'kycSubmittedAt': FieldValue.serverTimestamp(),

            // Save fields
            'fullName': _fullNameController.text.trim(),
            'dob': _dobController.text.trim(),
            'gender': _genderController.text.trim(),
            'address': _addressController.text.trim(),
            'aadhaarNumber': _aadhaarController.text.trim(),
            'panNumber': _panController.text.trim(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("KYC Resubmitted Successfully!")),
      );
      Navigator.pop(context); // Go back to Status Page
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        title: const Text("Submit KYC"),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _field("Full Name", _fullNameController),
            const SizedBox(height: 10),
            _field("Date of Birth", _dobController),
            const SizedBox(height: 10),
            _field("Gender", _genderController),
            const SizedBox(height: 10),
            _field("Address", _addressController, maxLines: 2),
            const SizedBox(height: 20),

            _field("Aadhaar Number", _aadhaarController),
            _uploadRow("Aadhaar Photo", _aadhaarImagePath, _pickAadhaar),
            const SizedBox(height: 10),

            _field("PAN Number", _panController),
            _uploadRow("PAN Photo", _panImagePath, _pickPan),
            const SizedBox(height: 20),

            _uploadRow("Take Selfie", _selfiePath, _takeSelfie, isSelfie: true),
            const SizedBox(height: 20),

            // Checkbox
            Row(
              children: [
                Checkbox(
                  value: _confirm,
                  onChanged: (v) => setState(() => _confirm = v!),
                  side: const BorderSide(color: Colors.white54),
                ),
                const Expanded(
                  child: Text(
                    "I confirm the details are correct.",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit KYC"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF191919),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _uploadRow(
    String label,
    String? path,
    VoidCallback onTap, {
    bool isSelfie = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isSelfie ? Icons.camera_alt : Icons.upload_file,
                color: Colors.blueAccent,
              ),
              const SizedBox(width: 10),
              Text(
                path != null ? "Photo Selected" : label,
                style: TextStyle(
                  color: path != null ? Colors.green : Colors.blueAccent,
                ),
              ),
              const Spacer(),
              if (path != null)
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
