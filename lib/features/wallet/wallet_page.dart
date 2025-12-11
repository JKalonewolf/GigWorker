import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gigworker/features/wallet/add_money_page.dart';
import 'package:gigworker/features/wallet/statements_page.dart'; // Ensure this file exists

class WalletPage extends StatefulWidget {
  final String phoneNumber;

  const WalletPage({super.key, required this.phoneNumber});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  String _filter = 'all'; // all, earning, loan, credit, debit

  double _toDouble(dynamic v) {
    if (v is int) return v.toDouble();
    if (v is double) return v;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.phoneNumber);

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        elevation: 0,
        title: const Text("Wallet"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: "Download Statement",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      StatementsPage(phoneNumber: widget.phoneNumber),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // --- BALANCE CARD ---
          StreamBuilder<DocumentSnapshot>(
            stream: userRef.snapshots(),
            builder: (context, snap) {
              double balance = 0;
              String kyc = "PENDING";

              if (snap.hasData && snap.data!.exists) {
                final data = snap.data!.data() as Map<String, dynamic>? ?? {};
                balance = _toDouble(data['walletBalance']);
                kyc = (data['kycStatus'] ?? "PENDING").toString().toUpperCase();
              }

              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Wallet Balance",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₹${balance.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "KYC: $kyc",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddMoneyPage(
                                  phoneNumber: widget.phoneNumber,
                                ),
                              ),
                            );
                          },
                          child: const Text("Deposit From Bank"),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // --- FILTER CHIPS ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip("All", "all"),
                _filterChip("Credits", "credit"),
                _filterChip("Debits", "debit"),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // --- TRANSACTIONS LIST ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // DIRECT FIRESTORE CONNECTION (Fixes "No Data" bug)
              stream: userRef
                  .collection('walletTransactions')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snap.data?.docs ?? [];

                // Manual Filtering logic
                if (_filter != 'all') {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final direction = (data['direction'] ?? '')
                        .toString()
                        .toLowerCase();
                    // Basic filter: does the direction match the selected chip?
                    return direction.contains(_filter);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.history,
                          size: 50,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "No transactions found",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    final amount = _toDouble(data['amount']);
                    final type = (data['type'] ?? 'Transaction')
                        .toString()
                        .toUpperCase();
                    final note = (data['note'] ?? data['label'] ?? type)
                        .toString();

                    // Handle Date safely
                    Timestamp? ts = data['createdAt'] ?? data['date'];
                    String dateStr = "Just now";
                    if (ts != null) {
                      dateStr = ts.toDate().toString().split('.')[0];
                    }

                    // Determine Color
                    String direction = (data['direction'] ?? '')
                        .toString()
                        .toLowerCase();
                    // Fallback if direction is missing
                    if (direction == '') {
                      if (type == 'EARNING' || type == 'LOAN')
                        direction = 'credit';
                      else
                        direction = 'debit';
                    }

                    final isCredit = direction == 'credit';
                    final color = isCredit
                        ? Colors.greenAccent
                        : Colors.redAccent;
                    final sign = isCredit ? "+" : "-";

                    return Card(
                      color: const Color(0xFF1C1C1E),
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.1),
                          child: Icon(
                            isCredit
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: color,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          "₹${amount.toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "$note\n$dateStr",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                        trailing: Text(
                          "$sign₹${amount.toStringAsFixed(0)}",
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
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
    );
  }

  Widget _filterChip(String label, String value) {
    bool isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            _filter = value;
          });
        },
        selectedColor: Colors.blueAccent,
        backgroundColor: const Color(0xFF181818),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.white60,
        ),
      ),
    );
  }
}
