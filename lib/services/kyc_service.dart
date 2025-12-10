import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gigworker/models/kyc_model.dart';

class KycService {
  final CollectionReference _users = FirebaseFirestore.instance.collection(
    'users',
  );

  /// Stream KYC data for a user (null if not submitted yet)
  Stream<KycModel?> streamKyc(String phone) {
    final docRef = _users.doc(phone).collection('kyc').doc('main');
    return docRef.snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return KycModel.fromMap(data);
    });
  }

  /// Submit or update KYC
  Future<void> submitKyc({
    required String phone,
    required String fullName,
    required String dob,
    required String gender,
    required String address,
    required String aadhaarNumber,
    required String panNumber,
    required String aadhaarImagePath,
    required String panImagePath,
    required String selfiePath,
  }) async {
    final userRef = _users.doc(phone);
    final kycRef = userRef.collection('kyc').doc('main');

    final now = FieldValue.serverTimestamp();

    await kycRef.set({
      'fullName': fullName,
      'dob': dob,
      'gender': gender,
      'address': address,
      'aadhaarNumber': aadhaarNumber,
      'panNumber': panNumber,
      'aadhaarImagePath': aadhaarImagePath,
      'panImagePath': panImagePath,
      'selfiePath': selfiePath,

      // 🔴 For MVP we AUTO-APPROVE right after submit
      'status': 'approved',
      'rejectionReason': '',
      'submittedAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    // mirror status on user doc
    await userRef.set({
      'kycStatus': 'approved', // 🔴 directly approved for this MVP
    }, SetOptions(merge: true));
  }

  /// For future: admin or automated process to approve/reject
  Future<void> updateKycStatus({
    required String phone,
    required String status, // approved / rejected / pending
    String? rejectionReason,
  }) async {
    final userRef = _users.doc(phone);
    final kycRef = userRef.collection('kyc').doc('main');

    await kycRef.set({
      'status': status,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await userRef.set({'kycStatus': status}, SetOptions(merge: true));
  }
}
