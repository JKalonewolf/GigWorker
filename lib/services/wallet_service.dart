import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gigworker/models/wallet_transaction_model.dart';

class WalletService {
  final CollectionReference _users = FirebaseFirestore.instance.collection(
    'users',
  );

  /// Add a credit/debit transaction and update wallet balance atomically.
  Future<void> addTransaction({
    required String phone,
    required double amount,
    required String type, // earning / loan / repayment / manual
    required String direction, // credit / debit
    required String method,
    String? note,
  }) async {
    final userRef = _users.doc(phone);
    final txRef = userRef.collection('walletTransactions').doc();

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      final data = userSnap.data() as Map<String, dynamic>? ?? {};
      final rawBalance = data['walletBalance'] ?? 0;
      double currentBalance;

      if (rawBalance is int) {
        currentBalance = rawBalance.toDouble();
      } else if (rawBalance is double) {
        currentBalance = rawBalance;
      } else {
        currentBalance = 0.0;
      }

      final newBalance = direction == 'credit'
          ? currentBalance + amount
          : currentBalance - amount;

      tx.set(txRef, {
        'amount': amount,
        'type': type,
        'direction': direction,
        'method': method,
        'note': note ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(userRef, {'walletBalance': newBalance});
    });
  }

  /// Stream all transactions for a user (optionally filtered by type).
  Stream<List<WalletTransaction>> streamTransactions(
    String phone, {
    String filterType = 'all', // all / earning / loan / repayment / manual
  }) {
    Query query = _users
        .doc(phone)
        .collection('walletTransactions')
        .orderBy('createdAt', descending: true);

    if (filterType != 'all') {
      query = query.where('type', isEqualTo: filterType);
    }

    return query.snapshots().map(
      (snap) => snap.docs.map((d) => WalletTransaction.fromDoc(d)).toList(),
    );
  }
}
