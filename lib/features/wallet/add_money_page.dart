import 'package:flutter/material.dart';
import 'package:gigworker/services/wallet_service.dart';

class AddMoneyPage extends StatefulWidget {
  final String phoneNumber;

  const AddMoneyPage({super.key, required this.phoneNumber});

  @override
  State<AddMoneyPage> createState() => _AddMoneyPageState();
}

class _AddMoneyPageState extends State<AddMoneyPage> {
  final _amountController = TextEditingController();
  final _walletService = WalletService();
  String _method = "Simulated Bank Transfer";
  bool _loading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _amountController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter amount")));
      return;
    }

    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter a valid amount")));
      return;
    }

    setState(() => _loading = true);

    await _walletService.addTransaction(
      phone: widget.phoneNumber,
      amount: amount,
      type: "manual",
      direction: "credit",
      method: _method,
      note: "Add Money",
    );

    setState(() => _loading = false);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Money added to wallet")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        elevation: 0,
        title: const Text("Add Money"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter amount",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "e.g. 500",
                hintStyle: TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Color(0xFF191919),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF303030)),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Select method",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _method,
              dropdownColor: const Color(0xFF191919),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color(0xFF191919),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFF303030)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.blueAccent),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: "Simulated Bank Transfer",
                  child: Text(
                    "Simulated Bank Transfer",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                DropdownMenuItem(
                  value: "Test UPI",
                  child: Text(
                    "Test UPI",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _method = v);
              },
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _loading ? null : _submit,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blueAccent, Colors.purpleAccent],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          "Add Money",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
