import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gigworker/features/earnings/widgets/earnings_chart.dart'; // IMPORT THE CHART
import '../../services/local_notification_service.dart';

class EarningsPage extends StatefulWidget {
  final String phoneNumber; // This is the User UID

  const EarningsPage({super.key, required this.phoneNumber});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();

  // 1. Define the List of Platforms
  final List<String> _platforms = [
    'Uber',
    'Ola',
    'Swiggy',
    'Zomato',
    'Rapido',
    'Porter',
    'Dunzo',
    'Amazon Flex',
    'Other',
  ];

  // 2. Variable to store selected value
  String? _selectedPlatform;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _saveEarning() async {
    final amountText = _amountController.text.trim();
    final label = _labelController.text.trim();

    if (amountText.isEmpty || _selectedPlatform == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter amount and select a platform"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final double amount = double.parse(amountText);

      // 3. Save to Firestore (Sub-collection)
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.phoneNumber);

      // Run as transaction to update Total Earnings + Add Record safely
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot userSnap = await transaction.get(userRef);

        if (userSnap.exists) {
          // Create the new Earning Record
          DocumentReference newDocRef = userRef.collection('earnings').doc();
          transaction.set(newDocRef, {
            'amount': amount,
            'platform': _selectedPlatform,
            'label': label.isEmpty ? _selectedPlatform : label,
            'date': FieldValue.serverTimestamp(),
          });

          // Also update the main Wallet Balance
          double currentBalance = 0;
          try {
            currentBalance = userSnap.get('walletBalance').toDouble();
          } catch (e) {
            currentBalance = 0;
          }
          transaction.update(userRef, {
            'walletBalance': currentBalance + amount,
          });
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Earning Added!")));

        // === TRIGGER NOTIFICATION ===
        print("Attempting to show notification..."); // Debug print
        await LocalNotificationService().showNotification(
          id: DateTime.now().millisecond,
          title: 'Credit Alert 💰',
          body:
              '₹${amount.toStringAsFixed(0)} has been added to your wallet via $_selectedPlatform.',
        );

        _amountController.clear();
        _labelController.clear();
        setState(() => _selectedPlatform = null);
      }
    } catch (e) {
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Earnings", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add earning",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // --- PLATFORM DROPDOWN ---
            const Text(
              "Platform",
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF191919),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF303030)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPlatform,
                  hint: const Text(
                    "Select Platform (e.g. Uber)",
                    style: TextStyle(color: Colors.white38),
                  ),
                  dropdownColor: const Color(0xFF252525),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white54,
                  ),
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white),
                  items: _platforms.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          Icon(
                            _getPlatformIcon(value),
                            size: 18,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 10),
                          Text(value),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedPlatform = newValue;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- AMOUNT INPUT ---
            const Text(
              "Amount",
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Amount (e.g. 500)"),
            ),

            const SizedBox(height: 16),

            // --- LABEL INPUT ---
            const Text(
              "Shift Details (Optional)",
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _labelController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("e.g. Evening Shift"),
            ),

            const SizedBox(height: 24),

            // --- SAVE BUTTON ---
            GestureDetector(
              onTap: _isLoading ? null : _saveEarning,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blueAccent, Colors.purpleAccent],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Save earning",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              "Earnings analytics",
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 12),

            // --- HISTORY LIST & CHART ---
            _buildHistoryList(),
          ],
        ),
      ),
    );
  }

  // --- UPDATED: Now includes the Chart + The List ---
  Widget _buildHistoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.phoneNumber)
          .collection('earnings')
          .orderBy('date', descending: true)
          // Removed .limit(10) so the chart gets all data to calculate correct totals
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snapshot.data!.docs;

        return Column(
          children: [
            // 1. THE NEW CHART (Passes all docs to calculate weekly data)
            if (docs.isNotEmpty) EarningsChart(earningsDocs: docs),

            if (docs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "No earnings recorded yet.",
                  style: TextStyle(color: Colors.white38),
                ),
              ),

            const SizedBox(height: 16),
            if (docs.isNotEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Recent history",
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ),
            const SizedBox(height: 12),

            // 2. THE HISTORY LIST (Manually taking top 10 for the UI)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length > 10
                  ? 10
                  : docs.length, // Limit to 10 here
              itemBuilder: (context, index) {
                var data = docs[index].data() as Map<String, dynamic>;
                String platform = data['platform'] ?? 'Other';
                double amount =
                    double.tryParse(data['amount'].toString()) ?? 0.0;
                String label = data['label'] ?? '';

                String dateStr = "Just now";
                if (data['date'] != null) {
                  DateTime dt = (data['date'] as Timestamp).toDate();
                  String period = dt.hour >= 12 ? "PM" : "AM";
                  int hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
                  if (hour == 0) hour = 12;
                  dateStr =
                      "${dt.day}/${dt.month} • $hour:${dt.minute.toString().padLeft(2, '0')} $period";
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181818),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getPlatformIcon(platform),
                          color: Colors.orangeAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "₹${amount.toStringAsFixed(0)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$platform • $label",
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Helper: Get Icon based on Platform Name
  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'uber':
        return Icons.directions_car;
      case 'ola':
        return Icons.local_taxi;
      case 'swiggy':
        return Icons.fastfood;
      case 'zomato':
        return Icons.restaurant;
      case 'rapido':
        return Icons.two_wheeler;
      case 'porter':
        return Icons.local_shipping;
      case 'amazon flex':
        return Icons.inventory_2;
      default:
        return Icons.work_outline;
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF191919),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF303030)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent),
      ),
    );
  }
}
