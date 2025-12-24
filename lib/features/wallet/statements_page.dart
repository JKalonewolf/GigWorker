import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gigworker/features/wallet/services/pdf_service.dart';

class StatementsPage extends StatefulWidget {
  final String phoneNumber;

  const StatementsPage({super.key, required this.phoneNumber});

  @override
  State<StatementsPage> createState() => _StatementsPageState();
}

class _StatementsPageState extends State<StatementsPage> {
  bool _isLoading = false;

  // 1. Update this function to accept Name and Phone
  Future<void> _downloadStatement(
    bool isWeekly,
    String name,
    String phone,
  ) async {
    setState(() => _isLoading = true);
    try {
      await PdfService().generateStatement(
        userId: widget.phoneNumber,
        userName: name, // <--- PASS NAME
        userPhone: phone, // <--- PASS PHONE
        isWeekly: isWeekly,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        title: const Text(
          "Account Statements",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.phoneNumber)
            .snapshots(),
        builder: (context, snapshot) {
          String userName = "Gig Worker";
          // Fetch the name from Firebase
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            userName = data['name'] ?? "Gig Worker";
          }

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Account Holder Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ACCOUNT HOLDER",
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "+91 ${widget.phoneNumber}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Download History",
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 15),

                // Weekly Button - PASS USERNAME HERE
                _buildStatementCard(
                  title: "Weekly Statement",
                  subtitle: "Last 7 Days",
                  icon: Icons.calendar_view_week,
                  color: Colors.blueAccent,
                  onTap: () => _downloadStatement(
                    true,
                    userName,
                    widget.phoneNumber,
                  ), // <--- PASS DATA
                ),

                const SizedBox(height: 15),

                // Monthly Button - PASS USERNAME HERE
                _buildStatementCard(
                  title: "Monthly Statement",
                  subtitle: "Last 30 Days",
                  icon: Icons.calendar_month,
                  color: Colors.purpleAccent,
                  onTap: () => _downloadStatement(
                    false,
                    userName,
                    widget.phoneNumber,
                  ), // <--- PASS DATA
                ),

                if (_isLoading) ...[
                  const Spacer(),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 10),
                  const Text(
                    "Generating PDF...",
                    style: TextStyle(color: Colors.white54),
                  ),
                  const Spacer(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatementCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.download, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
