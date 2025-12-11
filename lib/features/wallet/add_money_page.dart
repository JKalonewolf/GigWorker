import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gigworker/services/local_notification_service.dart';

class AddMoneyPage extends StatefulWidget {
  final String phoneNumber;

  const AddMoneyPage({super.key, required this.phoneNumber});

  @override
  State<AddMoneyPage> createState() => _AddMoneyPageState();
}

class _AddMoneyPageState extends State<AddMoneyPage> {
  final _amountController = TextEditingController();
  String _selectedMethod = "upi"; // Default method
  bool _isLoading = false;

  // Quick amounts for easy tap
  final List<int> _quickAmounts = [100, 500, 1000, 2000, 5000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setAmount(int amount) {
    _amountController.text = amount.toString();
    setState(() {});
  }

  // --- THE PROFESSIONAL PAYMENT LOGIC ---
  Future<void> _processPayment() async {
    final text = _amountController.text.trim();
    if (text.isEmpty) {
      _showSnack("Please enter an amount", Colors.redAccent);
      return;
    }
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      _showSnack("Enter a valid amount", Colors.redAccent);
      return;
    }

    // 1. Start Loading (Simulate Bank)
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2)); // Fake processing time

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.phoneNumber);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);

        if (!snapshot.exists) throw Exception("User not found!");

        double currentBalance =
            (snapshot.data() as Map<String, dynamic>)['walletBalance']
                ?.toDouble() ??
            0.0;
        double newBalance = currentBalance + amount;

        // 2. Update Balance
        transaction.update(userRef, {'walletBalance': newBalance});

        // 3. Add Transaction Record
        final newTxRef = userRef.collection('walletTransactions').doc();
        transaction.set(newTxRef, {
          'amount': amount,
          'type': 'credit', // Credit means money IN
          'description': 'Wallet Top-up via ${_getMethodName()}',
          'date': FieldValue.serverTimestamp(), // Uses Server Time
          'status': 'success',
          'method': _selectedMethod.toUpperCase(),
        });
      });

      // 4. Notification
      try {
        await LocalNotificationService().showNotification(
          id: DateTime.now().millisecond,
          title: 'Payment Successful 💰',
          body: '₹${amount.toStringAsFixed(0)} added to your wallet.',
        );
      } catch (e) {
        print("Notification skipped");
      }

      // 5. Success UI
      if (mounted) _showSuccessDialog(amount);
    } catch (e) {
      _showSnack("Transaction Failed: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getMethodName() {
    switch (_selectedMethod) {
      case 'upi':
        return 'UPI / GPay';
      case 'card':
        return 'Debit Card';
      case 'net':
        return 'Net Banking';
      default:
        return 'Bank Transfer';
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  void _showSuccessDialog(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 70),
            const SizedBox(height: 20),
            const Text(
              "Top-up Successful!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "₹${amount.toStringAsFixed(0)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Your wallet has been updated.",
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx); // Close Dialog
                  Navigator.pop(context); // Close Page
                },
                child: const Text("Done"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        title: const Text("Add Money"),
        backgroundColor: const Color(0xFF101010),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- AMOUNT INPUT SECTION ---
                const Text(
                  "Enter Amount",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    prefixText: "₹ ",
                    prefixStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                    ),
                    hintText: "1000",
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // --- QUICK CHIPS ---
                Wrap(
                  spacing: 10,
                  children: _quickAmounts.map((amt) {
                    return ActionChip(
                      label: Text("+₹$amt"),
                      backgroundColor: const Color(0xFF252525),
                      labelStyle: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                      onPressed: () => _setAmount(amt),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide.none,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 30),
                const Divider(color: Colors.white12),
                const SizedBox(height: 20),

                // --- PAYMENT METHOD SECTION ---
                const Text(
                  "Payment Method",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 15),

                _buildMethodTile(
                  "Google Pay / UPI",
                  "upi",
                  Icons.qr_code_scanner,
                ),
                _buildMethodTile(
                  "Debit / Credit Card",
                  "card",
                  Icons.credit_card,
                ),
                _buildMethodTile("Net Banking", "net", Icons.account_balance),

                const SizedBox(height: 40),

                // --- PAY BUTTON ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      "PROCEED TO PAY",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, size: 14, color: Colors.white38),
                      const SizedBox(width: 6),
                      const Text(
                        "100% Secure Payment by GigBank",
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- LOADING OVERLAY ---
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.85),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.blueAccent),
                    SizedBox(height: 20),
                    Text(
                      "Processing Secure Payment...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Please do not close the app",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMethodTile(String title, String id, IconData icon) {
    bool isSelected = _selectedMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent.withOpacity(0.15)
              : const Color(0xFF1E1E1E),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.blueAccent : Colors.white54),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.blueAccent,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
