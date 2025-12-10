import 'package:cloud_firestore/cloud_firestore.dart';

class WalletTransaction {
  final String id;
  final double amount;
  final String type;      // earning / loan / repayment / manual
  final String direction; // credit / debit
  final String method;    // Simulated Bank Transfer / Test UPI / etc.
  final String note;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.direction,
    required this.method,
    required this.note,
    required this.createdAt,
  });

  factory WalletTransaction.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final ts = data['createdAt'];
    DateTime createdAt;

    if (ts is Timestamp) {
      createdAt = ts.toDate();
    } else if (ts is String) {
      createdAt = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    final rawAmount = data['amount'];
    double amount;
    if (rawAmount is int) {
      amount = rawAmount.toDouble();
    } else if (rawAmount is double) {
      amount = rawAmount;
    } else {
      amount = 0.0;
    }

    return WalletTransaction(
      id: doc.id,
      amount: amount,
      type: data['type'] ?? 'manual',
      direction: data['direction'] ?? 'credit',
      method: data['method'] ?? '',
      note: data['note'] ?? '',
      createdAt: createdAt,
    );
  }
}
