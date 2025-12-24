import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String phone;
  final String name;
  final String email;
  final String city;
  final String kycStatus;
  final double walletBalance;
  final DateTime joined;
  final String profilePic;

  UserModel({
    required this.uid,
    required this.phone,
    required this.name,
    required this.email,
    required this.city,
    required this.kycStatus,
    required this.walletBalance,
    required this.joined,
    required this.profilePic,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    // ---- DATE PARSING (Safe for Timestamp or String) ----
    // We check 'createdAt' (from AuthService) OR 'joined'
    final joinedRaw = data['createdAt'] ?? data['joined'];
    DateTime joinedDate;

    if (joinedRaw is Timestamp) {
      joinedDate = joinedRaw.toDate();
    } else if (joinedRaw is String) {
      joinedDate = DateTime.tryParse(joinedRaw) ?? DateTime.now();
    } else {
      joinedDate = DateTime.now();
    }

    // ---- WALLET PARSING (Safe for int or double) ----
    final walletRaw = data['walletBalance'];
    double walletVal;
    if (walletRaw is int) {
      walletVal = walletRaw.toDouble();
    } else if (walletRaw is double) {
      walletVal = walletRaw;
    } else {
      walletVal = 0.0;
    }

    return UserModel(
      uid: data['uid'] ?? '',
      // Check both 'phoneNumber' (from Auth) and 'phone'
      phone: data['phoneNumber'] ?? data['phone'] ?? '',
      name: data['name'] ?? 'Gig Worker',
      email: data['email'] ?? '',
      city: data['city'] ?? '',
      kycStatus: data['kycStatus'] ?? 'pending',
      walletBalance: walletVal,
      joined: joinedDate,
      profilePic: data['profilePic'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phone, // Standardizing on 'phoneNumber' for Firestore
      'name': name,
      'email': email,
      'city': city,
      'kycStatus': kycStatus,
      'walletBalance': walletBalance,
      'createdAt': joined, // Standardizing on 'createdAt'
      'profilePic': profilePic,
    };
  }
}
