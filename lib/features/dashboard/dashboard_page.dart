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
    if (phoneNumber.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF101010),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(phoneNumber);
    final allEarningsRef = userRef.collection('earnings');
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- TOP BAR (Greeting + Real-Time Profile Pic) ----------
                StreamBuilder<DocumentSnapshot>(
                  stream: userRef.snapshots(),
                  builder: (context, snap) {
                    String name = "Gig Worker";
                    String kycStatus = "pending";
                    String profilePic = "";

                    if (snap.hasData && snap.data!.exists) {
                      final data =
                          snap.data!.data() as Map<String, dynamic>? ?? {};
                      final rawName = (data['name'] ?? '').toString().trim();
                      name = rawName.isEmpty ? "Gig Worker" : rawName;
                      kycStatus = (data['kycStatus'] ?? 'pending').toString();
                      profilePic = data['profilePic'] ?? "";
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
                            const SizedBox(height: 12),

                            // KYC BADGE
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: const Color(0xFF181818),
                                border: Border.all(
                                  color: const Color(0xFF333333),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.verified_user,
                                    size: 14,
                                    color: kycStatus.toLowerCase() == "verified"
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

                        // PROFILE AVATAR (Clickable)
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
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFF1E1E1E),
                            backgroundImage: profilePic.isNotEmpty
                                ? NetworkImage(profilePic)
                                : null,
                            child: profilePic.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 24,
                                  )
                                : null,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // ---------- WALLET CARD (REAL MONEY) ----------
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
                          ), // Subtle gradient
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Wallet Balance (Withdrawable)",
                              style: TextStyle(color: Colors.white60),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "₹ ${walletBalance.toStringAsFixed(0)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Text(
                                  "Tap to view details",
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 12,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.blueAccent,
                                  size: 12,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // ---------- INCOME TRACKER CARD ----------
                StreamBuilder<QuerySnapshot>(
                  stream: allEarningsRef.snapshots(),
                  builder: (context, snap) {
                    double totalEarnings = 0;
                    if (snap.hasData) {
                      for (final doc in snap.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>? ?? {};
                        // Only count Verified Earnings
                        if ((data['status'] ?? 'verified') == 'verified') {
                          totalEarnings += _toDouble(data['amount']);
                        }
                      }
                    }

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181818),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.insights,
                              color: Colors.greenAccent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Verified Tracked Income",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "₹ ${totalEarnings.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
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
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2C2E),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "Add +",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
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
                  "Quick Actions",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _quickActionCard(
                        Icons.verified_user,
                        Colors.greenAccent,
                        "KYC",
                        "Status",
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KycPage(phoneNumber: phoneNumber),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _quickActionCard(
                        Icons.bar_chart,
                        Colors.orangeAccent,
                        "Stats",
                        "History",
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EarningsPage(phoneNumber: phoneNumber),
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
                        if (loan.status == 'active' ||
                            loan.status == 'pending') {
                          activeLoan = loan;
                          break;
                        }
                      }
                    }

                    String title = activeLoan != null
                        ? "Active Loan: ₹${activeLoan.amount.toStringAsFixed(0)}"
                        : "Need Quick Cash?";
                    String subtitle = activeLoan != null
                        ? "Outstanding: ₹${activeLoan.outstandingAmount.toStringAsFixed(0)}"
                        : "Apply for a loan now";
                    IconData icon = activeLoan?.status == 'pending'
                        ? Icons.hourglass_top
                        : Icons.monetization_on;
                    Color color = activeLoan?.status == 'pending'
                        ? Colors.orangeAccent
                        : Colors.cyanAccent;

                    if (activeLoan?.status == 'pending') {
                      title = "Loan Application Pending";
                      subtitle = "Waiting for admin approval";
                    }

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LoanPage(phoneNumber: phoneNumber),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF181818),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, color: color, size: 28),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // ---------- RECENT ACTIVITY ----------
                const Text(
                  "Recent Activity",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                StreamBuilder<QuerySnapshot>(
                  stream: walletTxRef.snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData || snap.data!.docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            "No recent transactions",
                            style: TextStyle(color: Colors.white38),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snap.data!.docs.length,
                      itemBuilder: (context, index) {
                        final data =
                            snap.data!.docs[index].data()
                                as Map<String, dynamic>;
                        final type = (data['type'] ?? '').toString();
                        final direction = (data['direction'] ?? '').toString();
                        final amount = _toDouble(data['amount']);
                        final note = (data['note'] ?? '').toString();

                        Color color = direction == 'debit'
                            ? Colors.redAccent
                            : Colors.greenAccent;
                        String prefix = direction == 'debit' ? "-" : "+";
                        IconData icon = type == 'loan'
                            ? Icons.request_page
                            : (type == 'earning'
                                  ? Icons.work_outline
                                  : Icons.account_balance_wallet);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF181818),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFF252525),
                                child: Icon(icon, color: color, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      note.isEmpty ? type.toUpperCase() : note,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      type.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "$prefix₹${amount.toStringAsFixed(0)}",
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickActionCard(
    IconData icon,
    Color color,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
