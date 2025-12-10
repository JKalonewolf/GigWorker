import 'package:flutter/material.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        elevation: 0,
        title: const Text("Help & Support"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "How can we help you?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Choose a category or contact our team directly.",
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // --- CONTACT OPTIONS ---
            Row(
              children: [
                _contactCard(
                  context,
                  Icons.call,
                  "Call Us",
                  "+91 98765 43210",
                  Colors.greenAccent,
                ),
                const SizedBox(width: 12),
                _contactCard(
                  context,
                  Icons.email,
                  "Email",
                  "support@gigbank.in",
                  Colors.blueAccent,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _contactCard(
              context,
              Icons.chat,
              "WhatsApp Support",
              "Chat with us instantly",
              Colors.green,
              isFullWidth: true,
            ),

            const SizedBox(height: 32),

            // --- FAQ SECTION ---
            const Text(
              "Frequently Asked Questions",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildFaqTile(
              "How do I apply for a loan?",
              "Go to the 'Loans' tab on the dashboard. If you are eligible based on your earnings, you will see a 'Get Loan' button.",
            ),
            _buildFaqTile(
              "How long does withdrawal take?",
              "Withdrawals are usually processed instantly. In rare cases, it might take up to 24 hours.",
            ),
            _buildFaqTile(
              "Why was my KYC rejected?",
              "Ensure your Aadhaar and PAN photos are clear and match your profile name. You can resubmit anytime.",
            ),
            _buildFaqTile(
              "Is my wallet money safe?",
              "Yes! GigBank uses bank-grade security to protect your hard-earned money.",
            ),
          ],
        ),
      ),
    );
  }

  // Helper for Contact Cards
  Widget _contactCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color, {
    bool isFullWidth = false,
  }) {
    return Expanded(
      flex: isFullWidth ? 0 : 1,
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("$title action simulated!")));
        },
        child: Container(
          width: isFullWidth ? double.infinity : null,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for FAQ Tiles
  Widget _buildFaqTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
