import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String phone;
  final String name;
  final String city;
  final String kycStatus;
  final double walletBalance;
  final DateTime joined;

  UserModel({
    required this.phone,
    required this.name,
    required this.city,
    required this.kycStatus,
    required this.walletBalance,
    required this.joined,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    // ---- joined field: can be Timestamp or String or null ----
    final joinedRaw = data['joined'];
    DateTime joined;

    if (joinedRaw is Timestamp) {
      // If you ever store as Firestore Timestamp
      joined = joinedRaw.toDate();
    } else if (joinedRaw is String) {
      joined = DateTime.tryParse(joinedRaw) ?? DateTime.now();
    } else {
      joined = DateTime.now();
    }

    // ---- walletBalance: handle int/double/null safely ----
    final walletRaw = data['walletBalance'];
    double walletBalance;
    if (walletRaw is int) {
      walletBalance = walletRaw.toDouble();
    } else if (walletRaw is double) {
      walletBalance = walletRaw;
    } else {
      walletBalance = 0.0;
    }

    return UserModel(
      phone: data['phone'] ?? '',
      name: data['name'] ?? 'Gig Worker',
      city: data['city'] ?? 'Bangalore',
      kycStatus: data['kycStatus'] ?? 'pending',
      walletBalance: walletBalance,
      joined: joined,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'name': name,
      'city': city,
      'kycStatus': kycStatus,
      'walletBalance': walletBalance,
      // save as ISO string for now
      'joined': joined.toIso8601String(),
    };
  }
}
