import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gigworker/models/user_model.dart';
import 'package:gigworker/services/notification_service.dart';

class UserService {
  final _users = FirebaseFirestore.instance.collection('users');
  final NotificationService _notifService = NotificationService();

  Future<void> createUserIfNotExists(String phone) async {
    final doc = _users.doc(phone);
    final snap = await doc.get();

    if (!snap.exists) {
      await doc.set({
        'phone': phone,
        'name': 'Gig Worker',
        'city': 'Bangalore',
        'kycStatus': 'pending',
        'walletBalance': 0,
        'joined': DateTime.now().toIso8601String(),
      });

      // welcome notification
      await _notifService.addNotification(
        phone: phone,
        type: 'system',
        title: 'Welcome to GigBank',
        message: 'Your account is created. Complete KYC to unlock loans.',
      );
    }
  }

  Stream<UserModel> streamUser(String phone) {
    return _users.doc(phone).snapshots().map((doc) {
      final data = doc.data() ?? {};
      return UserModel.fromMap(data);
    });
  }

  Future<void> updateBasicProfile({
    required String phone,
    String? name,
    String? city,
  }) async {
    await _users.doc(phone).set({
      if (name != null) 'name': name,
      if (city != null) 'city': city,
    }, SetOptions(merge: true));
  }

  Future<void> updateKycStatus(String phone, String status) async {
    await _users.doc(phone).set({'kycStatus': status}, SetOptions(merge: true));

    String msg;
    if (status == 'approved') {
      msg = 'Your KYC has been approved. You can now apply for loans.';
    } else if (status == 'rejected') {
      msg = 'Your KYC was rejected. Please resubmit with correct details.';
    } else {
      msg = 'Your KYC has been submitted and is under review.';
    }

    await _notifService.addNotification(
      phone: phone,
      type: 'kyc',
      title: 'KYC status: $status',
      message: msg,
      meta: {'status': status},
    );
  }

  Future<void> updateWalletBalance(String phone, double balance) async {
    await _users.doc(phone).set({
      'walletBalance': balance,
    }, SetOptions(merge: true));
  }
}
