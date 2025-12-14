import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatefulWidget {
  final String phoneNumber;

  const SupportPage({super.key, required this.phoneNumber});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _ticketController = TextEditingController();
  bool _isSending = false;

  // --- ACTIONS ---
  Future<void> _makeCall() async {
    final Uri url = Uri(scheme: 'tel', path: '+919876543210');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _sendEmail() async {
    final Uri url = Uri(
      scheme: 'mailto',
      path: 'support@gigbank.in',
      query: 'subject=Support Request&body=Hi GigBank Team,',
    );
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _openWhatsApp() async {
    var whatsappUrl =
        "whatsapp://send?phone=919876543210&text=Hi, I need help with GigBank.";
    var uri = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      var webUrl = Uri.parse("https://wa.me/919876543210?text=Hi");
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _submitTicket() async {
    if (_ticketController.text.isEmpty) return;
    setState(() => _isSending = true);

    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.phoneNumber)
          .get();
      String userName = userDoc.data()?['name'] ?? 'Gig Worker';

      await FirebaseFirestore.instance.collection('support_tickets').add({
        'userId': widget.phoneNumber,
        'phone': widget.phoneNumber,
        'name': userName,
        'message': _ticketController.text.trim(),
        'status': 'open',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _ticketController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Ticket Sent to Admin!"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        elevation: 0,
        title: const Text("Help & Support"),
        centerTitle: true,
      ),
      // --- SCROLLABLE WRAPPER ---
      body: SingleChildScrollView(
        // This makes it always scrollable with a nice bounce effect
        physics: const BouncingScrollPhysics(),
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
            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.call,
                    color: Colors.green,
                    title: "Call Us",
                    subtitle: "+91 98765 43210",
                    onTap: _makeCall,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.email,
                    color: Colors.blue,
                    title: "Email",
                    subtitle: "support@gigbank.in",
                    onTap: _sendEmail,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            _buildWhatsAppCard(),

            const SizedBox(height: 35),

            const Text(
              "Frequently Asked Questions",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            _buildFaqItem(
              "How do I apply for a loan?",
              "Go to the Dashboard and click 'Apply Now' on the loan slider.",
            ),
            _buildFaqItem(
              "How long does withdrawal take?",
              "Withdrawals are processed instantly via IMPS to your linked bank account.",
            ),
            _buildFaqItem(
              "Why was my KYC rejected?",
              "Usually due to blurry photos. Please re-upload clear images of your Aadhaar and PAN.",
            ),
            _buildFaqItem(
              "Is my wallet money safe?",
              "Yes, 100%. We use bank-grade security and your funds are insured.",
            ),

            const SizedBox(height: 35),

            const Text(
              "Still need help? Raise a Ticket",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ticketController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Describe your issue...",
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: _submitTicket,
                  ),
                ],
              ),
            ),
            // Extra space at bottom so keyboard doesn't hide the input
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              radius: 22,
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppCard() {
    return GestureDetector(
      onTap: _openWhatsApp,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.green.withOpacity(0.2),
              radius: 22,
              child: const Icon(
                Icons.chat_bubble,
                color: Colors.green,
                size: 22,
              ),
            ),
            const SizedBox(width: 15),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "WhatsApp Support",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Chat with us instantly",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white24,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
