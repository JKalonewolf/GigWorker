import 'package:flutter/material.dart';
import 'package:gigworker/features/kyc/kyc_form_page.dart'; // We will create this next
import 'package:gigworker/models/kyc_model.dart';
import 'package:gigworker/services/kyc_service.dart';

class KycPage extends StatelessWidget {
  final String phoneNumber;

  const KycPage({super.key, required this.phoneNumber});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.greenAccent;
      case 'rejected':
        return Colors.redAccent;
      case 'pending':
        return Colors.amberAccent;
      default:
        return Colors.grey; // Unverified color
    }
  }

  String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return "KYC Approved ✅";
      case 'rejected':
        return "KYC Rejected ❌";
      case 'pending':
        return "Verification Pending ⏳";
      default:
        return "Not Started ⚠️";
    }
  }

  @override
  Widget build(BuildContext context) {
    final kycService = KycService();

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("KYC Status"),
      ),
      body: StreamBuilder<KycModel?>(
        stream: kycService.streamKyc(phoneNumber),
        builder: (context, kycSnap) {
          final kyc = kycSnap.data;

          // ✅ FIX 1: Default to 'unverified' if null
          final status = kyc?.status ?? 'unverified';

          final color = _statusColor(status);
          final text = _statusText(status);

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // STATUS CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181818),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Current Status",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            status == 'approved'
                                ? Icons.check_circle
                                : (status == 'rejected'
                                      ? Icons.cancel
                                      : (status == 'pending'
                                            ? Icons.access_time
                                            : Icons.info_outline)),
                            color: color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            text,
                            style: TextStyle(
                              color: color,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (status == 'pending') ...[
                        const SizedBox(height: 6),
                        const Text(
                          "Your documents are with the admin for review.",
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                      if (kyc?.rejectionReason.isNotEmpty == true &&
                          status == 'rejected') ...[
                        const SizedBox(height: 8),
                        Text(
                          "Reason: ${kyc!.rejectionReason}",
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  "KYC Steps",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // ✅ FIX 2: Only mark steps as "done" if status is NOT unverified
                _stepTile(
                  index: 1,
                  title: "Personal details",
                  subtitle: "Name, DOB, gender, address",
                  done: status != 'unverified',
                ),
                _stepTile(
                  index: 2,
                  title: "Document upload",
                  subtitle: "Aadhaar & PAN",
                  done: status != 'unverified',
                ),
                _stepTile(
                  index: 3,
                  title: "Selfie capture",
                  subtitle: "Liveliness check",
                  done: status != 'unverified',
                ),
                _stepTile(
                  index: 4,
                  title: "Review & submit",
                  subtitle: "Sent to admin for approval",
                  // Done only if Pending, Approved, or Rejected
                  done:
                      status == 'pending' ||
                      status == 'approved' ||
                      status == 'rejected',
                  isLast: true,
                ),

                const Spacer(),

                // ACTION BUTTON
                // Show button if Unverified OR Rejected
                if (status == 'unverified' || status == 'rejected')
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => KycFormPage(
                            phoneNumber: phoneNumber,
                          ), // Navigate to Form
                        ),
                      );
                    },
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
                        child: Text(
                          status == 'rejected' ? "Resubmit KYC" : "Start KYC",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _stepTile({
    required int index,
    required String title,
    required String subtitle,
    required bool done,
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: done
                ? Colors.greenAccent.withOpacity(0.2)
                : const Color(0xFF222222),
            child: done
                ? const Icon(Icons.check, size: 16, color: Colors.greenAccent)
                : Text(
                    "$index",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
