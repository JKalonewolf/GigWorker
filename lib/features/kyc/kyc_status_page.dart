import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gigworker/features/kyc/kyc_form_page.dart';

class KycStatusPage extends StatelessWidget {
  final String phoneNumber;

  const KycStatusPage({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505), // Your dark background
      appBar: AppBar(
        title: const Text("KYC Status"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(phoneNumber)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User data not found"));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          // 🛑 STRICT STATUS CHECK
          // If the field is missing, we assume 'unverified'
          final status = userData['kycStatus'] ?? 'unverified';
          final rejectionReason =
              userData['kycRejectionReason'] ?? 'Document invalid.';

          // --- 1. REJECTED STATE (Red Screen) ---
          if (status == 'rejected') {
            return _buildRejectedView(context, userData, rejectionReason);
          }

          // --- 2. DETERMINE EXACT STATE VARIABLES ---
          bool isVerified =
              (status == 'verified'); // Only true if Admin approved
          bool isPending = (status == 'pending'); // True if user just submitted
          bool isNew = (status == 'unverified' || status == 'new');

          // --- 3. CONFIGURE UI COLORS & TEXT BASED ON STATE ---
          Color statusColor;
          String statusTitle;
          IconData statusIcon;

          if (isVerified) {
            // ADMIN APPROVED
            statusColor = const Color(0xFF00C853); // Bright Green
            statusTitle = "KYC Approved ✅";
            statusIcon = Icons.check_circle;
          } else if (isPending) {
            // WAITING FOR ADMIN
            statusColor = Colors.orangeAccent;
            statusTitle = "Verification Pending";
            statusIcon = Icons.hourglass_bottom; // Hourglass icon
          } else {
            // NOT STARTED
            statusColor = Colors.blueAccent;
            statusTitle = "Not Started";
            statusIcon = Icons.info_outline;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- STATUS CARD ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Current Status",
                        style: TextStyle(color: statusColor, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(statusIcon, color: statusColor, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            statusTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                const Text(
                  "KYC Steps",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 15),

                // --- STEPS LIST ---

                // Steps 1, 2, 3: Completed if 'Pending' OR 'Verified'
                _buildStepTile(
                  "1",
                  "Personal details",
                  "Name, DOB, gender, address",
                  isPending || isVerified,
                ),
                _buildStepTile(
                  "2",
                  "Document upload",
                  "Aadhaar & PAN",
                  isPending || isVerified,
                ),
                _buildStepTile(
                  "3",
                  "Selfie capture",
                  "Liveness check",
                  isPending || isVerified,
                ),

                // Step 4: Completed ONLY if 'Verified' (Admin Approved)
                _buildStepTile(
                  "4",
                  "Review & submit",
                  isVerified
                      ? "Approved by Admin"
                      : (isPending
                            ? "Sent to admin for approval"
                            : "Not submitted yet"),
                  isVerified, // Checked ONLY if Admin Approved
                  isPending: isPending, // Shows 'Clock' icon if Pending
                ),

                const SizedBox(height: 40),

                // --- START BUTTON (Visible ONLY if New) ---
                if (isNew)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                KycFormPage(phoneNumber: phoneNumber),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Start KYC",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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

  // --- HELPER: REJECTED SCREEN ---
  Widget _buildRejectedView(
    BuildContext context,
    Map<String, dynamic> userData,
    String reason,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cancel, color: Colors.redAccent, size: 80),
          const SizedBox(height: 20),
          const Text(
            "KYC Rejected",
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: Text(
              "Reason: $reason\n\nPlease check your details and try again.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => KycFormPage(
                      phoneNumber: phoneNumber,
                      existingData: userData,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text(
                "Fix & Resubmit",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER: STEPS TILE ---
  Widget _buildStepTile(
    String stepNum,
    String title,
    String subtitle,
    bool isCompleted, {
    bool isPending = false,
  }) {
    Color iconColor;
    Color iconBg;
    IconData iconData;

    if (isCompleted) {
      // Completed (Green Check)
      iconColor = const Color(0xFF00C853);
      iconBg = const Color(0xFF00C853).withOpacity(0.1);
      iconData = Icons.check;
    } else if (isPending) {
      // Pending (Orange Clock)
      iconColor = Colors.orangeAccent;
      iconBg = Colors.orangeAccent.withOpacity(0.1);
      iconData = Icons.access_time_filled;
    } else {
      // Not Started (Grey Circle)
      iconColor = Colors.white24;
      iconBg = Colors.transparent;
      iconData = Icons.circle_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Step Background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted || isPending
                    ? Colors.transparent
                    : iconColor,
                width: 2,
              ),
            ),
            child: Icon(
              isCompleted ? Icons.check : (isPending ? Icons.more_horiz : null),
              color: iconColor,
              size: 20,
            ),
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
        ],
      ),
    );
  }
}
