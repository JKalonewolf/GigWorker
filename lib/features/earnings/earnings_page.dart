import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/local_notification_service.dart';

class EarningsPage extends StatefulWidget {
  final String phoneNumber;

  const EarningsPage({super.key, required this.phoneNumber});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  // 0 = Week, 1 = Month
  int _selectedView = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Analytics",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      // --- FLOATING ADD BUTTON ---
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEarningModal(context),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      // --- MAIN BODY ---
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.phoneNumber)
            .collection('earnings')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var docs = snapshot.data!.docs;

          // --- LOGIC: FILTER & CALCULATE ---
          final now = DateTime.now();
          double periodTotal = 0;

          // Chart Data Containers
          List<double> weekData = List.filled(7, 0.0); // Mon-Sun
          List<double> monthData = List.filled(5, 0.0); // Week 1-5

          for (var doc in docs) {
            var data = doc.data() as Map<String, dynamic>;
            if (data['status'] == 'verified') {
              double amt = double.tryParse(data['amount'].toString()) ?? 0.0;

              // 🛑 FIX 1: SAFE DATE PARSING (Prevents Crash)
              Timestamp? t = data['date'] as Timestamp?;
              DateTime date = t != null ? t.toDate() : DateTime.now();

              // 1. WEEKLY LOGIC
              DateTime startOfWeek = now.subtract(
                Duration(days: now.weekday - 1),
              );
              startOfWeek = DateTime(
                startOfWeek.year,
                startOfWeek.month,
                startOfWeek.day,
              ); // Strip time

              if (date.isAfter(
                    startOfWeek.subtract(const Duration(seconds: 1)),
                  ) &&
                  date.isBefore(startOfWeek.add(const Duration(days: 7)))) {
                if (_selectedView == 0) periodTotal += amt;
                weekData[date.weekday - 1] += amt;
              }

              // 2. MONTHLY LOGIC
              if (date.month == now.month && date.year == now.year) {
                if (_selectedView == 1) periodTotal += amt;
                // Bucket into weeks (0-4)
                int weekIndex = (date.day - 1) ~/ 7;
                if (weekIndex > 4) weekIndex = 4;
                monthData[weekIndex] += amt;
              }
            }
          }

          List<double> currentChartData = _selectedView == 0
              ? weekData
              : monthData;
          String periodLabel = _selectedView == 0 ? "This Week" : "This Month";

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),

                // --- TOGGLE SWITCH ---
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _toggleBtn("Weekly", 0),
                      _toggleBtn("Monthly", 1),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- TOTAL BALANCE HEADER ---
                Text(
                  "Total Verified ($periodLabel)",
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  "₹ ${periodTotal.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                // --- BAR CHART SECTION ---
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (_selectedView == 0) {
                                // WEEK LABELS
                                const days = [
                                  'M',
                                  'T',
                                  'W',
                                  'T',
                                  'F',
                                  'S',
                                  'S',
                                ];
                                if (value.toInt() < days.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      days[value.toInt()],
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                // MONTH LABELS
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    "W${value.toInt() + 1}",
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(currentChartData.length, (
                        index,
                      ) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: currentChartData[index] > 0
                                  ? currentChartData[index]
                                  : 0,
                              color: currentChartData[index] > 0
                                  ? Colors.blueAccent
                                  : const Color(0xFF2C2C2E),
                              width: _selectedView == 0
                                  ? 16
                                  : 24, // Thicker bars for month view
                              borderRadius: BorderRadius.circular(4),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY:
                                    _getMax(currentChartData) *
                                    1.2, // dynamic max height background
                                color: const Color(0xFF181818),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --- LIST HEADER ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Recent History",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.more_horiz, color: Colors.white54),
                  ],
                ),
                const SizedBox(height: 16),

                // --- TRANSACTIONS LIST ---
                if (docs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      "No earnings yet.",
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String platform = data['platform'] ?? 'Other';
                    double amount =
                        double.tryParse(data['amount'].toString()) ?? 0.0;
                    String status = data['status'] ?? 'verified';

                    // 🛑 FIX 2: SAFE DATE PARSING (Prevents Crash in List)
                    Timestamp? t = data['date'] as Timestamp?;
                    DateTime date = t != null ? t.toDate() : DateTime.now();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              _getPlatformIcon(platform),
                              color: _getPlatformColor(platform),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  platform,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('dd MMM • hh:mm a').format(date),
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "+₹${amount.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (status == 'pending')
                                const Text(
                                  "PENDING",
                                  style: TextStyle(
                                    color: Colors.orangeAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.check_circle,
                                  size: 12,
                                  color: Colors.blueAccent,
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET: TOGGLE BUTTON ---
  Widget _toggleBtn(String text, int index) {
    bool isSelected = _selectedView == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedView = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // --- HELPER: GET MAX FOR CHART BACKGROUND ---
  double _getMax(List<double> data) {
    double max = 0;
    for (var d in data) {
      if (d > max) max = d;
    }
    return max == 0 ? 1000 : max; // Default scale if empty
  }

  // --- HELPER: ADD EARNING MODAL ---
  void _showAddEarningModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF181818),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AddEarningSheet(phoneNumber: widget.phoneNumber),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'uber':
        return Icons.directions_car;
      case 'swiggy':
        return Icons.fastfood;
      case 'zomato':
        return Icons.restaurant;
      case 'amazon flex':
        return Icons.inventory_2;
      default:
        return Icons.work_outline;
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'uber':
        return Colors.white;
      case 'swiggy':
        return Colors.orange;
      case 'zomato':
        return Colors.redAccent;
      case 'amazon flex':
        return Colors.blueAccent;
      default:
        return Colors.purpleAccent;
    }
  }
}

// ... (AddEarningSheet class remains exactly same)
class AddEarningSheet extends StatefulWidget {
  final String phoneNumber;
  const AddEarningSheet({super.key, required this.phoneNumber});

  @override
  State<AddEarningSheet> createState() => _AddEarningSheetState();
}

class _AddEarningSheetState extends State<AddEarningSheet> {
  final _amountCtrl = TextEditingController();
  String? _selectedPlatform;
  File? _image;
  bool _loading = false;

  final List<String> _platforms = [
    'Uber',
    'Ola',
    'Swiggy',
    'Zomato',
    'Rapido',
    'Amazon Flex',
    'Other',
  ];

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _image = File(file.path));
  }

  Future<void> _submit() async {
    if (_amountCtrl.text.isEmpty || _selectedPlatform == null) return;
    double amount = double.parse(_amountCtrl.text);

    if (amount > 1000 && _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Screenshot required for > ₹1000")),
      );
      return;
    }

    setState(() => _loading = true);

    // SAVE LOGIC (TRACKER ONLY)
    String status = amount > 1000 ? 'pending' : 'verified';
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.phoneNumber)
        .collection('earnings')
        .add({
          'amount': amount,
          'platform': _selectedPlatform,
          'date': FieldValue.serverTimestamp(),
          'status': status,
          'proofUploaded': _image != null,
        });

    if (mounted) {
      Navigator.pop(context); // Close Modal
      LocalNotificationService().showNotification(
        id: 999,
        title: 'Logged 📉',
        body: '₹${amount.toStringAsFixed(0)} logged. (Status: $status)',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Log New Earning",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPlatform,
                hint: const Text(
                  "Select Platform",
                  style: TextStyle(color: Colors.white54),
                ),
                dropdownColor: const Color(0xFF2C2C2E),
                isExpanded: true,
                style: const TextStyle(color: Colors.white),
                items: _platforms
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedPlatform = v),
              ),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Amount (₹)",
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF2C2C2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white24,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _image != null ? Icons.check : Icons.camera_alt,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _image != null
                        ? "Screenshot Added"
                        : "Upload Proof (Optional < ₹1000)",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Add to Tracker",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
