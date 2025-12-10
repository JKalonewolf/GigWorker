import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gigworker/models/loan_model.dart';
import 'package:gigworker/services/wallet_service.dart';
import 'package:gigworker/services/notification_service.dart';
import 'package:gigworker/services/local_notification_service.dart';

class LoanService {
  final CollectionReference _users = FirebaseFirestore.instance.collection(
    'users',
  );

  final WalletService _walletService = WalletService();
  final NotificationService _notifService = NotificationService();

  /// Stream all loans for a user
  Stream<List<LoanModel>> streamLoans(String phone) {
    return _users
        .doc(phone)
        .collection('loans')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => LoanModel.fromDoc(d)).toList());
  }

  /// Stream repayments for a loan
  Stream<QuerySnapshot> streamRepayments(String phone, String loanId) {
    return _users
        .doc(phone)
        .collection('loans')
        .doc(loanId)
        .collection('repayments')
        .orderBy('dueDate')
        .snapshots();
  }

  /// Simple EMI calculator
  double calculateEmi({
    required double principal,
    required double annualRate,
    required int months,
  }) {
    if (months <= 0) return 0;
    if (annualRate <= 0) {
      return principal / months;
    }

    final r = annualRate / 12;
    final powVal = pow(1 + r, months);
    final emi = principal * r * powVal / (powVal - 1);
    return emi;
  }

  /// Apply for loan + create schedule + credit wallet + notifications
  Future<String> applyForLoan({
    required String phone,
    required double amount,
    required int tenureMonths,
    double interestRate = 0.18,
    String riskLevel = 'medium',
  }) async {
    final userRef = _users.doc(phone);
    final loanRef = userRef.collection('loans').doc();

    final emiAmount = calculateEmi(
      principal: amount,
      annualRate: interestRate,
      months: tenureMonths,
    );

    final now = DateTime.now();
    final firstEmiDate = DateTime(
      now.year,
      now.month + 1,
      now.day,
    ); // next month

    // 1. Create loan & schedule in transaction
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final loanData = {
        'amount': amount,
        'tenureMonths': tenureMonths,
        'interestRate': interestRate,
        'status': 'active', // auto-approved in MVP
        'outstandingAmount': amount,
        'createdAt': now.toIso8601String(),
        'approvedAt': now.toIso8601String(),
        'disbursedAt': now.toIso8601String(),
        'emiAmount': emiAmount,
        'nextDueDate': firstEmiDate.toIso8601String(),
        'riskLevel': riskLevel,
        'note': 'GigBank loan',
      };

      tx.set(loanRef, loanData);

      // repayment schedule
      for (int i = 0; i < tenureMonths; i++) {
        final dueDate = DateTime(
          firstEmiDate.year,
          firstEmiDate.month + i,
          firstEmiDate.day,
        );

        final repaymentRef = loanRef
            .collection('repayments')
            .doc('emi_${i + 1}');

        tx.set(repaymentRef, {
          'index': i + 1,
          'amount': emiAmount,
          'dueDate': dueDate.toIso8601String(),
          'status': 'upcoming', // upcoming / paid / overdue
          'paidAt': null,
        });
      }
    });

    // 2. Credit wallet (outside transaction)
    await _walletService.addTransaction(
      phone: phone,
      amount: amount,
      type: 'loan',
      direction: 'credit',
      method: 'GigBank Loan',
      note: 'Loan disbursed',
    );

    // 3. Notifications
    await _notifService.addNotification(
      phone: phone,
      type: 'loan',
      title: 'Loan approved',
      message:
          '₹${amount.toStringAsFixed(0)} has been disbursed to your GigBank wallet.',
      meta: {'amount': amount, 'tenure': tenureMonths},
    );

    await _notifService.addNotification(
      phone: phone,
      type: 'emi',
      title: 'EMI schedule created',
      message:
          'Your first EMI of ₹${emiAmount.toStringAsFixed(0)} is due on ${firstEmiDate.toLocal().toString().split(' ').first}.',
      meta: {'emi': emiAmount, 'firstDue': firstEmiDate.toIso8601String()},
    );
    await LocalNotificationService().showInstantNotification(
      title: 'Loan approved',
      body:
          '₹${amount.toStringAsFixed(0)} has been added to your GigBank wallet.',
    );
    return loanRef.id;
  }

  /// Repay part of a loan + debit wallet + mark EMIs + notification
  Future<void> repayLoan({
    required String phone,
    required String loanId,
    required double amount,
  }) async {
    final userRef = _users.doc(phone);
    final loanRef = userRef.collection('loans').doc(loanId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      final loanSnap = await tx.get(loanRef);

      if (!loanSnap.exists) {
        throw Exception("Loan not found");
      }

      final userData = userSnap.data() as Map<String, dynamic>? ?? {};
      final loanData = loanSnap.data() as Map<String, dynamic>? ?? {};

      double _toDouble(dynamic v) {
        if (v is int) return v.toDouble();
        if (v is double) return v;
        return 0.0;
      }

      final rawBalance = userData['walletBalance'] ?? 0;
      double walletBalance = _toDouble(rawBalance);

      if (walletBalance < amount) {
        throw Exception("Insufficient wallet balance");
      }

      final outstandingAmount = _toDouble(loanData['outstandingAmount']);
      final newOutstanding = (outstandingAmount - amount).clamp(0.0, 1e12);

      // update loan core fields
      tx.update(loanRef, {
        'outstandingAmount': newOutstanding,
        if (newOutstanding <= 0) 'status': 'closed',
      });

      // update wallet balance
      tx.update(userRef, {'walletBalance': walletBalance - amount});

      // mark EMIs as paid as far as this payment covers
      final repaymentsSnap = await loanRef
          .collection('repayments')
          .orderBy('index')
          .get();

      double remainingPayment = amount;

      for (final doc in repaymentsSnap.docs) {
        final data = doc.data();
        final status = (data['status'] ?? 'upcoming') as String;
        if (status != 'upcoming') continue;

        final emiAmount = _toDouble(data['amount']);

        if (remainingPayment >= emiAmount - 1) {
          remainingPayment -= emiAmount;
          tx.update(doc.reference, {
            'status': 'paid',
            'paidAt': DateTime.now().toIso8601String(),
          });
        } else {
          break;
        }
      }
    });

    // wallet transaction record
    await _walletService.addTransaction(
      phone: phone,
      amount: amount,
      type: 'repayment',
      direction: 'debit',
      method: 'Loan repayment',
      note: 'Loan repayment',
    );

    // notification
    await _notifService.addNotification(
      phone: phone,
      type: 'emi',
      title: 'EMI paid',
      message:
          'Your loan repayment of ₹${amount.toStringAsFixed(0)} has been received.',
      meta: {'amount': amount},
    );
  }
}
