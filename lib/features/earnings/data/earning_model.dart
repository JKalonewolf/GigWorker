import 'package:cloud_firestore/cloud_firestore.dart';

class EarningModel {
  final String id;
  final String userId;
  final double amount;
  final DateTime date;
  final String source; // e.g., "Swiggy", "Uber"
  final String? notes;

  EarningModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.date,
    required this.source,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'source': source,
      'notes': notes,
    };
  }

  factory EarningModel.fromMap(Map<String, dynamic> map) {
    return EarningModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      source: map['source'] ?? '',
      notes: map['notes'],
    );
  }
}
