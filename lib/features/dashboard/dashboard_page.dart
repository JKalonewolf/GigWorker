import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:gigworker/features/kyc/kyc_page.dart';
import 'package:gigworker/features/wallet/wallet_page.dart';
import 'package:gigworker/features/earnings/earnings_page.dart';
import 'package:gigworker/features/loan/loan_page.dart';
import 'package:gigworker/features/profile/profile_page.dart';
import 'package:gigworker/models/loan_model.dart';

class DashboardPage extends StatelessWidget {
  final String phoneNumber;

  const DashboardPage({super.key, required this.phoneNumber});

  double _toDouble(dynamic v) {
    if (v is int) return v.toDouble();
    if (v is double) return v;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    // PREVENT CRASH IF PHONE IS EMPTY
    if (phoneNumber.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF101010),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(phoneNumber);

    final earningsRef = userRef
        .collection('earnings')
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 7)),
          ),
        );

    final loansRef = userRef
        .collection('loans')
        .orderBy('createdAt', descending: true)
        .limit(5);

    final walletTxRef = userRef
        .collection('walletTransactions')
        .orderBy('createdAt', descending: true)
        .limit(5);

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- TOP BAR (Greeting + profile) ----------
              StreamBuilder<DocumentSnapshot>(
                stream: userRef.snapshots(),
                builder: (context, snap) {
                  String name = "Gig Worker";
                  String kycStatus = "pending";

                  if (snap.hasData && snap.data!.exists) {
                    final data =
                        snap.data!.data() as Map<String, dynamic>? ?? {};
                    final rawName = (data['name'] ?? '').toString().trim();
                    name = rawName.isEmpty ? "Gig Worker" : rawName;
                    kycStatus = (data['kycStatus'] ?? 'pending').toString();
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hello, $name 👋",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Welcome to GigBank",
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),

                          // === FIX: Increased Height to move KYC down ===
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical:
                                      6, // Increased vertical padding slightly
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: const Color(0xFF181818),
                                  border: Border.all(
                                    color: const Color(0xFF333333),
                                  ), // Added border for better look
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.verified_user,
                                      size: 14,
                                      color:
                                          kycStatus.toLowerCase() == "approved"
                                          ? Colors.greenAccent
                                          : Colors.amberAccent,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "KYC: ${kycStatus.toUpperCase()}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProfilePage(phoneNumber: phoneNumber),
                            ),
                          );
                        },
                        child: const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white12,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // ---------- WALLET CARD ----------
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WalletPage(phoneNumber: phoneNumber),
                    ),
                  );
                },
                child: StreamBuilder<DocumentSnapshot>(
                  stream: userRef.snapshots(),
                  builder: (context, snap) {
                    double walletBalance = 0;
                    if (snap.hasData && snap.data!.exists) {
                      final data =
                          snap.data!.data() as Map<String, dynamic>? ?? {};
                      walletBalance = _toDouble(data['walletBalance'] ?? 0);
                    }

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181818),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Wallet balance",
                            style: TextStyle(color: Colors.white60),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "₹ ${walletBalance.toStringAsFixed(0)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Tap to view wallet details & transactions",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ---------- EARNINGS CARD ----------
              StreamBuilder<QuerySnapshot>(
                stream: earningsRef.snapshots(),
                builder: (context, snap) {
                  double weekTotal = 0;
                  if (snap.hasData) {
                    for (final doc in snap.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      weekTotal += _toDouble(data['amount']);
                    }
                  }

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181818),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.show_chart, color: Colors.greenAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "This week’s earnings",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "₹ ${weekTotal.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EarningsPage(phoneNumber: phoneNumber),
                              ),
                            );
                          },
                          child: const Text(
                            "View",
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // ---------- QUICK ACTIONS ----------
              const Text(
                "Quick actions",
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KycPage(phoneNumber: phoneNumber),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF181818),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.verified_user,
                              color: Colors.greenAccent,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "KYC\nTap to manage",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EarningsPage(phoneNumber: phoneNumber),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF181818),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.attach_money,
                              color: Colors.orangeAccent,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Add earnings",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ---------- LOAN SECTION ----------
              StreamBuilder<QuerySnapshot>(
                stream: loansRef.snapshots(),
                builder: (context, snap) {
                  LoanModel? activeLoan;
                  if (snap.hasData && snap.data!.docs.isNotEmpty) {
                    for (final doc in snap.data!.docs) {
                      final loan = LoanModel.fromDoc(doc);
                      if (loan.status == 'active') {
                        activeLoan = loan;
                        break;
                      }
                    }
                  }

                  String title = activeLoan != null
                      ? "Active loan: ₹${activeLoan.amount.toStringAsFixed(0)}"
                      : "Need quick cash?";
                  String subtitle = activeLoan != null
                      ? "Outstanding ₹${activeLoan.outstandingAmount.toStringAsFixed(0)} • Tap to manage"
                      : "Apply for a small ticket loan based on your earnings";

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LoanPage(phoneNumber: phoneNumber),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181818),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.request_page,
                            color: Colors.cyanAccent,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white38,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              const Text(
                "Recent activity",
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 8),

              // ---------- RECENT ACTIVITY LIST ----------
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: walletTxRef.snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData || snap.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No transactions yet",
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: snap.data!.docs.length,
                      itemBuilder: (context, index) {
                        final data =
                            snap.data!.docs[index].data()
                                as Map<String, dynamic>;
                        final type = (data['type'] ?? '').toString();
                        final direction = (data['direction'] ?? '').toString();
                        final amount = _toDouble(data['amount']);
                        final note = (data['note'] ?? '').toString();

                        Color amountColor = direction == 'debit'
                            ? Colors.redAccent
                            : Colors.greenAccent;
                        String prefix = direction == 'debit' ? "-" : "+";

                        IconData icon = Icons.account_balance_wallet_outlined;
                        if (type == 'earning')
                          icon = Icons.work_outline;
                        else if (type == 'loan')
                          icon = Icons.request_page;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF181818),
                            child: Icon(icon, color: amountColor, size: 18),
                          ),
                          title: Text(
                            note.isEmpty ? type.toUpperCase() : note,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          trailing: Text(
                            "$prefix₹${amount.toStringAsFixed(0)}",
                            style: TextStyle(
                              color: amountColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
