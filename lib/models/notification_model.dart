import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String type; // kyc, loan, emi, system
  final String title;
  final String message;
  final bool read;
  final DateTime createdAt;
  final Map<String, dynamic> meta;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
    required this.meta,
  });

  factory AppNotification.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime _toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) {
        try {
          return DateTime.parse(v);
        } catch (_) {}
      }
      return DateTime.now();
    }

    return AppNotification(
      id: doc.id,
      type: (data['type'] ?? 'system') as String,
      title: (data['title'] ?? '') as String,
      message: (data['message'] ?? '') as String,
      read: (data['read'] ?? false) as bool,
      createdAt: _toDate(data['createdAt']),
      meta: (data['meta'] as Map<String, dynamic>?) ?? {},
    );
  }
}
