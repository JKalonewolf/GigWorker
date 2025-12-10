import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gigworker/models/kyc_model.dart';
import 'package:gigworker/services/kyc_service.dart';
import 'package:image_picker/image_picker.dart';

class KycFormPage extends StatefulWidget {
  final String phoneNumber;
  final KycModel? existingKyc;

  const KycFormPage({super.key, required this.phoneNumber, this.existingKyc});

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
  final _kycService = KycService();

  @override
  void initState() {
    super.initState();
    final kyc = widget.existingKyc;
    if (kyc != null) {
      _fullNameController.text = kyc.fullName;
      _dobController.text = kyc.dob;
      _genderController.text = kyc.gender;
      _addressController.text = kyc.address;
      _aadhaarController.text = kyc.aadhaarNumber;
      _panController.text = kyc.panNumber;
      _aadhaarImagePath = kyc.aadhaarImagePath.isNotEmpty
          ? kyc.aadhaarImagePath
          : null;
      _panImagePath = kyc.panImagePath.isNotEmpty ? kyc.panImagePath : null;
      _selfiePath = kyc.selfiePath.isNotEmpty ? kyc.selfiePath : null;
      _confirm = true; // user had already submitted once
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
    if (picked != null) {
      setState(() => _aadhaarImagePath = picked.path);
    }
  }

  Future<void> _pickPan() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _panImagePath = picked.path);
    }
  }

  Future<void> _takeSelfie() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => _selfiePath = picked.path);
    }
  }

  Future<void> _submit() async {
    if (_fullNameController.text.trim().isEmpty ||
        _dobController.text.trim().isEmpty ||
        _genderController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _aadhaarController.text.trim().isEmpty ||
        _panController.text.trim().isEmpty ||
        _aadhaarImagePath == null ||
        _panImagePath == null ||
        _selfiePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all steps & uploads")),
      );
      return;
    }

    if (!_confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please confirm details are correct")),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await _kycService.submitKyc(
        phone: widget.phoneNumber,
        fullName: _fullNameController.text.trim(),
        dob: _dobController.text.trim(),
        gender: _genderController.text.trim(),
        address: _addressController.text.trim(),
        aadhaarNumber: _aadhaarController.text.trim(),
        panNumber: _panController.text.trim(),
        aadhaarImagePath: _aadhaarImagePath!,
        panImagePath: _panImagePath!,
        selfiePath: _selfiePath!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("KYC submitted. Status: Pending")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error submitting KYC: $e")));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        elevation: 0,
        title: const Text("Complete KYC"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "1. Personal details",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _field("Full name", _fullNameController, "As per Aadhaar"),
            const SizedBox(height: 10),
            _field("Date of birth", _dobController, "YYYY-MM-DD"),
            const SizedBox(height: 10),
            _field("Gender", _genderController, "Male / Female / Other"),
            const SizedBox(height: 10),
            _field(
              "Address",
              _addressController,
              "Full residential address",
              maxLines: 3,
            ),

            const SizedBox(height: 24),
            const Text(
              "2. Document upload",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _field("Aadhaar number", _aadhaarController, "xxxx-xxxx-xxxx"),
            const SizedBox(height: 8),
            _uploadRow(
              label: "Aadhaar photo",
              path: _aadhaarImagePath,
              onTap: _pickAadhaar,
            ),
            const SizedBox(height: 12),
            _field("PAN number", _panController, "ABCDE1234F"),
            const SizedBox(height: 8),
            _uploadRow(
              label: "PAN photo",
              path: _panImagePath,
              onTap: _pickPan,
            ),

            const SizedBox(height: 24),
            const Text(
              "3. Selfie",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _uploadRow(
              label: "Capture selfie",
              path: _selfiePath,
              onTap: _takeSelfie,
              isSelfie: true,
            ),

            const SizedBox(height: 24),
            const Text(
              "4. Review & submit",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _confirm,
                  onChanged: (v) {
                    setState(() => _confirm = v ?? false);
                  },
                  side: const BorderSide(color: Colors.white54),
                  activeColor: Colors.blueAccent,
                  checkColor: Colors.white,
                ),
                const Expanded(
                  child: Text(
                    "I confirm that the details and documents provided are correct.",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            GestureDetector(
              onTap: _submitting ? null : _submit,
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
                  child: _submitting
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
                          "Submit KYC",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF191919),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF303030)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _uploadRow({
    required String label,
    required String? path,
    required VoidCallback onTap,
    bool isSelfie = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        if (path != null)
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFF191919),
              image: DecorationImage(
                image: FileImage(File(path)),
                fit: BoxFit.cover,
              ),
            ),
          ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFF191919),
              border: Border.all(color: const Color(0xFF303030)),
            ),
            child: Row(
              children: [
                Icon(
                  isSelfie ? Icons.camera_alt : Icons.upload_file,
                  color: Colors.blueAccent,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  path == null ? "Upload" : "Change",
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
