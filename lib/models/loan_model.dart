import 'package:cloud_firestore/cloud_firestore.dart';

class LoanModel {
  final String id;
  final double amount;
  final int tenureMonths;
  final double interestRate;
  final String status; // pending / approved / active / closed / rejected
  final double outstandingAmount;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? disbursedAt;
  final double emiAmount;
  final DateTime? nextDueDate;
  final String riskLevel; // low / medium / high
  final String note;

  LoanModel({
    required this.id,
    required this.amount,
    required this.tenureMonths,
    required this.interestRate,
    required this.status,
    required this.outstandingAmount,
    required this.createdAt,
    required this.approvedAt,
    required this.disbursedAt,
    required this.emiAmount,
    required this.nextDueDate,
    required this.riskLevel,
    required this.note,
  });

  factory LoanModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    double _toDouble(dynamic v) {
      if (v is int) return v.toDouble();
      if (v is double) return v;
      return 0.0;
    }

    DateTime _toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) {
        try {
          return DateTime.parse(v);
        } catch (_) {}
      }
      return DateTime.now();
    }

    DateTime? _toDateOrNull(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is String) {
        try {
          return DateTime.parse(v);
        } catch (_) {}
      }
      return null;
    }

    return LoanModel(
      id: doc.id,
      amount: _toDouble(data['amount']),
      tenureMonths: (data['tenureMonths'] ?? 0) as int,
      interestRate: _toDouble(data['interestRate']),
      status: (data['status'] ?? 'pending') as String,
      outstandingAmount: _toDouble(data['outstandingAmount']),
      createdAt: _toDate(data['createdAt']),
      approvedAt: _toDateOrNull(data['approvedAt']),
      disbursedAt: _toDateOrNull(data['disbursedAt']),
      emiAmount: _toDouble(data['emiAmount']),
      nextDueDate: _toDateOrNull(data['nextDueDate']),
      riskLevel: (data['riskLevel'] ?? 'medium') as String,
      note: (data['note'] ?? '') as String,
    );
  }
}
