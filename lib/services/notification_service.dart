import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gigworker/models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _userNotifs(String phone) =>
      _db.collection('users').doc(phone).collection('notifications');

  /// Add a notification for user
  Future<void> addNotification({
    required String phone,
    required String type, // kyc, loan, emi, system
    required String title,
    required String message,
    Map<String, dynamic>? meta,
  }) async {
    await _userNotifs(phone).add({
      'type': type,
      'title': title,
      'message': message,
      'read': false,
      'createdAt': DateTime.now().toIso8601String(),
      'meta': meta ?? {},
    });
  }

  /// Stream latest notifications (newest first)
  Stream<List<AppNotification>> streamNotifications(String phone) {
    return _userNotifs(phone)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => AppNotification.fromDoc(d)).toList(),
        );
  }

  /// Mark single notification as read
  Future<void> markAsRead(String phone, String notifId) async {
    await _userNotifs(phone).doc(notifId).update({'read': true});
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String phone) async {
    final snap = await _userNotifs(phone).where('read', isEqualTo: false).get();
    for (final d in snap.docs) {
      d.reference.update({'read': true});
    }
  }
}
