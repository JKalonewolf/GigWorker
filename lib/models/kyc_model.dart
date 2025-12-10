import 'package:cloud_firestore/cloud_firestore.dart';

class KycModel {
  final String fullName;
  final String dob; // you can store as string "1999-01-01"
  final String gender;
  final String address;
  final String aadhaarNumber;
  final String panNumber;
  final String aadhaarImagePath;
  final String panImagePath;
  final String selfiePath;
  final String status; // pending / approved / rejected
  final String rejectionReason;
  final DateTime? submittedAt;
  final DateTime? updatedAt;

  KycModel({
    required this.fullName,
    required this.dob,
    required this.gender,
    required this.address,
    required this.aadhaarNumber,
    required this.panNumber,
    required this.aadhaarImagePath,
    required this.panImagePath,
    required this.selfiePath,
    required this.status,
    required this.rejectionReason,
    required this.submittedAt,
    required this.updatedAt,
  });

  factory KycModel.fromMap(Map<String, dynamic> data) {
    DateTime? _toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) {
        try {
          return DateTime.parse(v);
        } catch (_) {}
      }
      return null;
    }

    return KycModel(
      fullName: (data['fullName'] ?? '') as String,
      dob: (data['dob'] ?? '') as String,
      gender: (data['gender'] ?? '') as String,
      address: (data['address'] ?? '') as String,
      aadhaarNumber: (data['aadhaarNumber'] ?? '') as String,
      panNumber: (data['panNumber'] ?? '') as String,
      aadhaarImagePath: (data['aadhaarImagePath'] ?? '') as String,
      panImagePath: (data['panImagePath'] ?? '') as String,
      selfiePath: (data['selfiePath'] ?? '') as String,
      status: (data['status'] ?? 'pending') as String,
      rejectionReason: (data['rejectionReason'] ?? '') as String,
      submittedAt: _toDate(data['submittedAt']),
      updatedAt: _toDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'dob': dob,
      'gender': gender,
      'address': address,
      'aadhaarNumber': aadhaarNumber,
      'panNumber': panNumber,
      'aadhaarImagePath': aadhaarImagePath,
      'panImagePath': panImagePath,
      'selfiePath': selfiePath,
      'status': status,
      'rejectionReason': rejectionReason,
      'submittedAt': submittedAt != null
          ? Timestamp.fromDate(submittedAt!)
          : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
