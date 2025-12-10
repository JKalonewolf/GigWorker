import 'package:flutter/material.dart';
import 'package:gigworker/features/wallet/services/pdf_service.dart';

class StatementsPage extends StatefulWidget {
  final String phoneNumber; // User ID

  const StatementsPage({super.key, required this.phoneNumber});

  @override
  State<StatementsPage> createState() => _StatementsPageState();
}

class _StatementsPageState extends State<StatementsPage> {
  bool _isLoading = false;

  Future<void> _downloadStatement(bool isWeekly) async {
    setState(() => _isLoading = true);
    try {
      // Call our service
      await PdfService().generateStatement(
          userId: widget.phoneNumber,
          isWeekly: isWeekly
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        title: const Text("Account Statements", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.description, size: 80, color: Colors.white24),
            const SizedBox(height: 20),
            const Text(
              "Download your transaction history",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 40),

            // Weekly Button
            _buildStatementCard(
              title: "Weekly Statement",
              subtitle: "Last 7 Days",
              icon: Icons.calendar_view_week,
              color: Colors.blueAccent,
              onTap: () => _downloadStatement(true),
            ),

            const SizedBox(height: 20),

            // Monthly Button
            _buildStatementCard(
              title: "Monthly Statement",
              subtitle: "Last 30 Days",
              icon: Icons.calendar_month,
              color: Colors.purpleAccent,
              onTap: () => _downloadStatement(false),
            ),

            if (_isLoading) ...[
              const SizedBox(height: 40),
              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              const Text("Generating PDF...", style: TextStyle(color: Colors.white54)),
            ],
          ],
        ),
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
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 13)),
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