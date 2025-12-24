import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WithdrawPage extends StatefulWidget {
  final String phoneNumber;
  final double currentBalance;

  const WithdrawPage({
    super.key,
    required this.phoneNumber,
    required this.currentBalance,
  });

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final _amountController = TextEditingController();
  final _upiController = TextEditingController();
  bool _isLoading = false;

  Future<void> _processWithdrawal() async {
    final amountText = _amountController.text.trim();
    final upiId = _upiController.text.trim();

    if (amountText.isEmpty || upiId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter Amount and UPI ID")),
      );
      return;
    }

    double amount = double.tryParse(amountText) ?? 0;

    if (amount > widget.currentBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Insufficient Wallet Balance!"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.phoneNumber);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);
        double currentBal =
            (snapshot.data() as Map<String, dynamic>)['walletBalance']
                ?.toDouble() ??
            0.0;

        if (currentBal < amount) throw Exception("Insufficient funds.");

        transaction.update(userRef, {'walletBalance': currentBal - amount});

        transaction.set(userRef.collection('walletTransactions').doc(), {
          'amount': amount,
          'type': 'withdrawal',
          'direction': 'debit',
          'description': 'Withdraw to $upiId',
          'status': 'pending', // Pending so Admin can see it
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Column(
              children: [
                Icon(Icons.check_circle, color: Colors.greenAccent, size: 60),
                SizedBox(height: 10),
                Text(
                  "Withdrawal Requested",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              "₹${amount.toInt()} request sent for $upiId.\nAdmin will process it shortly.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text(
                  "Done",
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        title: const Text("Withdraw Money"),
        backgroundColor: const Color(0xFF101010),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Available: ₹${widget.currentBalance.toStringAsFixed(0)}",
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 30),
              decoration: const InputDecoration(
                prefixText: "₹ ",
                hintText: "0",
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _upiController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Enter UPI ID (e.g. name@upi)",
                filled: true,
                fillColor: Color(0xFF1E1E1E),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processWithdrawal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("WITHDRAW NOW"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
