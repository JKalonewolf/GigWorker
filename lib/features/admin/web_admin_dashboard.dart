import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // ✅ IMPORTED FOR DATE FORMATTING

class WebAdminDashboard extends StatefulWidget {
  const WebAdminDashboard({super.key});

  @override
  State<WebAdminDashboard> createState() => _WebAdminDashboardState();
}

class _WebAdminDashboardState extends State<WebAdminDashboard> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const AnalyticsSection(), // 0
      const KycManagementSection(), // 1
      const EarningsApprovalSection(), // 2
      const LoanManagementSection(), // 3
      const WithdrawalManagementSection(), // 4
      const UserDatabaseSection(), // 5
      const SupportTicketSection(), // 6
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Row(
        children: [
          // --- SIDEBAR ---
          Container(
            width: 250,
            color: const Color(0xFF1A1A1A),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.security, size: 50, color: Colors.blueAccent),
                const SizedBox(height: 10),
                const Text(
                  "GigWorker Ops",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "LIVE ADMIN DATA",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                _navItem(0, "Dashboard", Icons.dashboard),
                _navItem(1, "KYC Requests", Icons.verified_user),
                _navItem(2, "Earnings Approval", Icons.image_search),
                _navItem(3, "Loan Manager", Icons.credit_score),
                _navItem(4, "Withdrawals", Icons.payments),
                _navItem(5, "User Database", Icons.people),
                _navItem(6, "Support Desk", Icons.headset_mic),
              ],
            ),
          ),

          // --- MAIN CONTENT ---
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(30),
              child: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, String title, IconData icon) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blueAccent : Colors.white54,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white54,
          fontWeight: FontWeight.bold,
        ),
      ),
      tileColor: isSelected ? Colors.blueAccent.withOpacity(0.1) : null,
      onTap: () => setState(() => _selectedIndex = index),
    );
  }
}

// =============================================================================
// 1. ANALYTICS SECTION
// =============================================================================
class AnalyticsSection extends StatelessWidget {
  const AnalyticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Platform Overview",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),

          // --- 1. KPI CARDS ---
          _buildRealTimeKPIs(),

          const SizedBox(height: 40),

          // --- 2. CHARTS ---
          SizedBox(
            height: 400,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _chartContainer(
                    "Loan Disbursement (Last 7 Days)",
                    const _RealTimeLoanChart(),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _chartContainer(
                    "Income Sources",
                    const _RealTimeEarningsPieChart(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeKPIs() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        String totalUsers = "...";
        String pendingKyc = "...";
        String totalWallet = "...";

        if (userSnapshot.hasData) {
          var docs = userSnapshot.data!.docs;
          totalUsers = docs.length.toString();
          pendingKyc = docs
              .where((d) => (d.data() as Map)['kycStatus'] == 'pending')
              .length
              .toString();

          double walletSum = 0;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            walletSum += (data['walletBalance'] ?? 0).toDouble();
          }
          totalWallet = "₹${(walletSum / 1000).toStringAsFixed(1)}k";
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collectionGroup('loans')
              .where('status', isEqualTo: 'active')
              .snapshots(),
          builder: (context, loanSnapshot) {
            String activeLoans = loanSnapshot.hasData
                ? loanSnapshot.data!.docs.length.toString()
                : "...";

            return Row(
              children: [
                _kpiCard(
                  "Total Users",
                  totalUsers,
                  "Registered",
                  Colors.blue,
                  Icons.people,
                ),
                _kpiCard(
                  "Pending KYC",
                  pendingKyc,
                  "Action Needed",
                  Colors.orange,
                  Icons.warning_amber,
                ),
                _kpiCard(
                  "Wallet Float",
                  totalWallet,
                  "User Money",
                  Colors.green,
                  Icons.account_balance_wallet,
                ),
                _kpiCard(
                  "Active Loans",
                  activeLoans,
                  "Generating Interest",
                  Colors.purple,
                  Icons.monetization_on,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _kpiCard(
    String title,
    String value,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            Text(
              subtitle,
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartContainer(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          Expanded(child: chart),
        ],
      ),
    );
  }
}

// =============================================================================
// HELPER CHARTS
// =============================================================================
class _RealTimeLoanChart extends StatelessWidget {
  const _RealTimeLoanChart();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collectionGroup('loans').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        List<double> dailyTotals = List.filled(7, 0.0);
        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          if (data['status'] == 'active' || data['status'] == 'closed') {
            double amount = (data['amount'] ?? 0).toDouble();
            dynamic rawDate = data['disbursedAt'] ?? data['createdAt'];
            DateTime? date;
            if (rawDate is Timestamp) {
              date = rawDate.toDate();
            } else if (rawDate is String) {
              date = DateTime.tryParse(rawDate);
            }
            if (date != null) {
              int dayIndex = date.weekday - 1;
              if (dayIndex >= 0 && dayIndex < 7)
                dailyTotals[dayIndex] += amount;
            }
          }
        }
        double maxY = 0;
        for (var val in dailyTotals) if (val > maxY) maxY = val;
        if (maxY == 0) maxY = 1000;
        return BarChart(
          BarChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, _) => Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      ["M", "T", "W", "T", "F", "S", "S"][val.toInt() % 7],
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(
              7,
              (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: dailyTotals[i],
                    color: dailyTotals[i] > 0
                        ? Colors.blueAccent
                        : const Color(0xFF2C2C2E),
                    width: 20,
                    borderRadius: BorderRadius.circular(4),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY * 1.2,
                      color: Colors.white.withOpacity(0.02),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RealTimeEarningsPieChart extends StatelessWidget {
  const _RealTimeEarningsPieChart();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('earnings')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty)
          return const Center(
            child: Text(
              "No earning data",
              style: TextStyle(color: Colors.white38),
            ),
          );
        Map<String, double> platformCounts = {};
        int total = 0;
        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          String platform = (data['platform'] ?? 'Other').toString();
          if (!platformCounts.containsKey(platform))
            platformCounts[platform] = 0;
          platformCounts[platform] = platformCounts[platform]! + 1;
          total++;
        }
        List<Color> colors = [
          Colors.blue,
          Colors.purple,
          Colors.orange,
          Colors.red,
          Colors.green,
        ];
        int colorIndex = 0;
        List<PieChartSectionData> sections = [];
        platformCounts.forEach((key, count) {
          double percentage = (count / total) * 100;
          if (percentage > 5) {
            sections.add(
              PieChartSectionData(
                value: percentage,
                title: "${percentage.toStringAsFixed(0)}%",
                color: colors[colorIndex % colors.length],
                radius: 40,
                titleStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 10,
                ),
                badgeWidget: _badge(key),
                badgePositionPercentageOffset: 1.3,
              ),
            );
            colorIndex++;
          }
        });
        return PieChart(
          PieChartData(
            sectionsSpace: 4,
            centerSpaceRadius: 40,
            sections: sections,
          ),
        );
      },
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 8),
      ),
    );
  }
}

// =============================================================================
// 2. KYC MANAGEMENT SECTION (WITH DATE)
// =============================================================================
class KycManagementSection extends StatelessWidget {
  const KycManagementSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "KYC Manager",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Manage verification. You can Approve, Reject, or Revoke status at any time.",
          style: TextStyle(color: Colors.white54),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                return const Center(
                  child: Text(
                    "No users found.",
                    style: TextStyle(color: Colors.white38),
                  ),
                );
              var docs = snapshot.data!.docs;
              docs.sort((a, b) {
                var statusA = (a.data() as Map)['kycStatus'] ?? 'new';
                var statusB = (b.data() as Map)['kycStatus'] ?? 'new';
                if (statusA == 'pending' && statusB != 'pending') return -1;
                if (statusA != 'pending' && statusB == 'pending') return 1;
                return 0;
              });

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var doc = docs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  String uid = doc.id;
                  String name = data['name'] ?? 'Unknown';
                  String status = data['kycStatus'] ?? 'new';
                  String aadhaar = data['aadhaarNumber'] ?? '-';
                  String pan = data['panNumber'] ?? '-';

                  Color statusColor;
                  IconData statusIcon;
                  switch (status) {
                    case 'approved':
                      statusColor = Colors.greenAccent;
                      statusIcon = Icons.check_circle;
                      break;
                    case 'rejected':
                      statusColor = Colors.redAccent;
                      statusIcon = Icons.cancel;
                      break;
                    case 'pending':
                      statusColor = Colors.orangeAccent;
                      statusIcon = Icons.hourglass_full;
                      break;
                    default:
                      statusColor = Colors.grey;
                      statusIcon = Icons.person_outline;
                  }

                  return Card(
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: status == 'pending'
                          ? const BorderSide(
                              color: Colors.orangeAccent,
                              width: 1,
                            )
                          : BorderSide.none,
                    ),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.2),
                        child: Icon(statusIcon, color: statusColor),
                      ),
                      title: Text(
                        "$name  •  ${status.toUpperCase()}",
                        style: TextStyle(
                          color: status == 'pending'
                              ? Colors.white
                              : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "ID: $uid",
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      childrenPadding: const EdgeInsets.all(20),
                      children: [
                        Row(
                          children: [
                            _detailColumn("Aadhaar Number", aadhaar),
                            const SizedBox(width: 40),
                            _detailColumn("PAN Number", pan),
                            const SizedBox(width: 40),
                            // ✅ ADDED DATE
                            _detailColumn(
                              "Submitted On",
                              formatTimestamp(data['kycSubmittedAt']),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (status != 'rejected')
                              TextButton.icon(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.redAccent,
                                ),
                                label: Text(
                                  status == 'approved'
                                      ? "Revoke / Reject"
                                      : "Reject",
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                                onPressed: () =>
                                    _updateStatus(context, uid, 'rejected'),
                              ),
                            const SizedBox(width: 12),
                            if (status != 'approved')
                              ElevatedButton.icon(
                                icon: const Icon(Icons.check),
                                label: Text(
                                  status == 'rejected'
                                      ? "Re-Approve"
                                      : "Approve",
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () =>
                                    _updateStatus(context, uid, 'approved'),
                              ),
                            if (status != 'pending')
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: TextButton.icon(
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: Colors.blue,
                                  ),
                                  label: const Text("Reset"),
                                  onPressed: () =>
                                      _updateStatus(context, uid, 'pending'),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _updateStatus(BuildContext context, String uid, String status) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({
          'kycStatus': status,
          'kycVerifiedAt': status == 'approved'
              ? FieldValue.serverTimestamp()
              : FieldValue.delete(),
        })
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Updated status to ${status.toUpperCase()}"),
              backgroundColor: status == 'approved'
                  ? Colors.green
                  : Colors.grey[800],
            ),
          );
        });
  }

  Widget _detailColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 3. EARNINGS APPROVAL SECTION (WITH DATE)
// =============================================================================
class EarningsApprovalSection extends StatelessWidget {
  const EarningsApprovalSection({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Earnings Verification",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Review income proofs. Pending requests appear at the top.",
          style: TextStyle(color: Colors.white54),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                return const Center(
                  child: Text(
                    "No data found.",
                    style: TextStyle(color: Colors.white38),
                  ),
                );
              return ListView(
                children: snapshot.data!.docs.map((userDoc) {
                  return _UserEarningsList(
                    userId: userDoc.id,
                    userName: userDoc['name'] ?? 'Unknown',
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UserEarningsList extends StatelessWidget {
  final String userId;
  final String userName;
  const _UserEarningsList({required this.userId, required this.userName});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('earnings')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const SizedBox.shrink();
        var docs = snapshot.data!.docs;
        docs.sort((a, b) {
          var statusA = (a.data() as Map)['status'] ?? 'verified';
          var statusB = (b.data() as Map)['status'] ?? 'verified';
          if (statusA == 'pending' && statusB != 'pending') return -1;
          if (statusA != 'pending' && statusB == 'pending') return 1;
          return 0;
        });
        int pendingCount = docs
            .where((d) => (d.data() as Map)['status'] == 'pending')
            .length;
        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: pendingCount > 0
                ? const BorderSide(color: Colors.blueAccent, width: 1)
                : BorderSide.none,
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: pendingCount > 0
                  ? Colors.blueAccent.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              child: Icon(
                Icons.image_search,
                color: pendingCount > 0 ? Colors.blueAccent : Colors.grey,
              ),
            ),
            title: Text(
              userName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              pendingCount > 0
                  ? "$pendingCount Pending Review(s)"
                  : "All records verified",
              style: TextStyle(
                color: pendingCount > 0 ? Colors.blueAccent : Colors.white54,
              ),
            ),
            iconColor: Colors.white,
            childrenPadding: const EdgeInsets.all(20),
            children: docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              double amount = (data['amount'] ?? 0).toDouble();
              String status = data['status'] ?? 'verified';
              bool hasImage = data['proofUploaded'] == true;
              String? imageUrl = data['imageUrl'];
              String platform = data['platform'] ?? 'Other';
              Color stColor;
              switch (status) {
                case 'pending':
                  stColor = Colors.orange;
                  break;
                case 'rejected':
                  stColor = Colors.red;
                  break;
                default:
                  stColor = Colors.green;
              }
              return Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            _showProofDialog(context, hasImage, imageUrl),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: hasImage
                                  ? Colors.blueAccent
                                  : Colors.white10,
                            ),
                          ),
                          child: Icon(
                            hasImage ? Icons.visibility : Icons.broken_image,
                            color: hasImage ? Colors.white : Colors.white24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "₹${amount.toStringAsFixed(0)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$platform  •  ${status.toUpperCase()}",
                              style: TextStyle(
                                color: stColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // ✅ ADDED DATE
                            Text(
                              formatTimestamp(data['date']),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (status == 'pending') ...[
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          tooltip: "Reject",
                          onPressed: () => FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('earnings')
                              .doc(doc.id)
                              .update({'status': 'rejected'}),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text("Verify"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[800],
                          ),
                          onPressed: () => FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('earnings')
                              .doc(doc.id)
                              .update({
                                'status': 'verified',
                                'verifiedAt': FieldValue.serverTimestamp(),
                              }),
                        ),
                      ] else ...[
                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.white24,
                          ),
                          tooltip: "Reset to Pending",
                          onPressed: () => FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('earnings')
                              .doc(doc.id)
                              .update({'status': 'pending'}),
                        ),
                      ],
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 30),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showProofDialog(BuildContext context, bool hasImage, String? imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Proof of Work",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: hasImage
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.image,
                            size: 80,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Simulation Mode",
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "User uploaded a file locally.\n(Real storage requires Firebase Storage setup)",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: Text(
                          "No Proof Uploaded",
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              if (hasImage)
                Container(
                  padding: const EdgeInsets.all(10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Proof Status: ATTACHED ✅",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.green),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 4. LOAN MANAGEMENT SECTION (WITH DATE)
// =============================================================================
class LoanManagementSection extends StatelessWidget {
  const LoanManagementSection({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Loan Manager",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Monitor Active loans and Approve Pending requests.",
          style: TextStyle(color: Colors.white54),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              return ListView(
                children: snapshot.data!.docs.map((userDoc) {
                  return _UserLoanList(
                    userId: userDoc.id,
                    userName: userDoc['name'] ?? 'Unknown User',
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UserLoanList extends StatelessWidget {
  final String userId;
  final String userName;
  const _UserLoanList({required this.userId, required this.userName});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('loans')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const SizedBox.shrink();
        var docs = snapshot.data!.docs;
        docs.sort((a, b) {
          String sA = (a.data() as Map)['status'] ?? '';
          String sB = (b.data() as Map)['status'] ?? '';
          if (sA == 'pending' && sB != 'pending') return -1;
          if (sA != 'pending' && sB == 'pending') return 1;
          return 0;
        });
        int pendingCount = docs
            .where((d) => (d.data() as Map)['status'] == 'pending')
            .length;
        int activeCount = docs
            .where((d) => (d.data() as Map)['status'] == 'active')
            .length;
        Color borderColor = Colors.transparent;
        if (pendingCount > 0)
          borderColor = Colors.orangeAccent;
        else if (activeCount > 0)
          borderColor = Colors.greenAccent;
        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor, width: 1),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: pendingCount > 0
                  ? Colors.orange.withOpacity(0.2)
                  : (activeCount > 0
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1)),
              child: Icon(
                Icons.monetization_on,
                color: pendingCount > 0
                    ? Colors.orange
                    : (activeCount > 0 ? Colors.green : Colors.grey),
              ),
            ),
            title: Text(
              "$userName ($userId)",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Row(
              children: [
                if (pendingCount > 0) ...[
                  _statusTag("$pendingCount Pending", Colors.orange),
                  const SizedBox(width: 8),
                ],
                if (activeCount > 0)
                  _statusTag("$activeCount Active", Colors.green),
              ],
            ),
            childrenPadding: const EdgeInsets.all(20),
            children: docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              double amount = (data['amount'] ?? 0).toDouble();
              String status = data['status'] ?? 'pending';
              return Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "₹${amount.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // ✅ ADDED DATE
                    subtitle: Text(
                      "Status: ${status.toUpperCase()}\nDate: ${formatTimestamp(data['createdAt'])}",
                      style: TextStyle(color: _getStatusColor(status)),
                    ),
                    trailing: _buildActionButtons(doc.id, status, amount),
                  ),
                  const Divider(color: Colors.white10),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.greenAccent;
      case 'pending':
        return Colors.orangeAccent;
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.white54;
    }
  }

  Widget _statusTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons(String docId, String status, double amount) {
    if (status == 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            child: const Text("Reject", style: TextStyle(color: Colors.red)),
            onPressed: () => FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('loans')
                .doc(docId)
                .update({'status': 'rejected'}),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Approve"),
            onPressed: () => _approveLoan(docId, amount),
          ),
        ],
      );
    } else if (status == 'active') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          "Active Running",
          style: TextStyle(color: Colors.green),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _approveLoan(String docId, double amount) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final loanRef = userRef.collection('loans').doc(docId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot userSnap = await transaction.get(userRef);
      double currentBal =
          (userSnap.data() as Map<String, dynamic>)['walletBalance']
              ?.toDouble() ??
          0.0;
      transaction.update(loanRef, {
        'status': 'active',
        'approvedAt': FieldValue.serverTimestamp(),
        'disbursedAt': FieldValue.serverTimestamp(),
        'startDate': FieldValue.serverTimestamp(),
      });
      transaction.update(userRef, {'walletBalance': currentBal + amount});
      transaction.set(userRef.collection('walletTransactions').doc(), {
        'amount': amount,
        'type': 'loan',
        'direction': 'credit',
        'note': 'Loan Disbursal',
        'status': 'success',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

// =============================================================================
// 5. WITHDRAWAL MANAGEMENT SECTION (WITH DATE)
// =============================================================================
class WithdrawalManagementSection extends StatelessWidget {
  const WithdrawalManagementSection({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Withdrawal Requests",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Process payouts via UPI/Bank and mark as paid.",
          style: TextStyle(color: Colors.white54),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              return ListView(
                children: snapshot.data!.docs.map((userDoc) {
                  return _UserWithdrawalList(
                    userId: userDoc.id,
                    userName: userDoc['name'] ?? 'Unknown',
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UserWithdrawalList extends StatelessWidget {
  final String userId;
  final String userName;
  const _UserWithdrawalList({required this.userId, required this.userName});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('walletTransactions')
          .where('type', isEqualTo: 'withdrawal')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const SizedBox.shrink();
        var docs = snapshot.data!.docs;
        docs.sort((a, b) {
          Timestamp t1 = a['createdAt'] ?? Timestamp.now();
          Timestamp t2 = b['createdAt'] ?? Timestamp.now();
          return t2.compareTo(t1);
        });
        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.only(bottom: 10),
          child: ExpansionTile(
            title: Text(
              "$userName ($userId)",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              "${docs.length} Withdrawal Records",
              style: const TextStyle(color: Colors.blueAccent),
            ),
            iconColor: Colors.white,
            children: docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              double amount = (data['amount'] ?? 0).toDouble();
              String desc = data['description'] ?? '';
              String status = data['status'] ?? 'pending';
              bool isProcessed = status == 'processed' || status == 'success';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isProcessed
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  child: Icon(
                    Icons.payment,
                    color: isProcessed ? Colors.green : Colors.orange,
                  ),
                ),
                title: Text(
                  "₹$amount",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // ✅ ADDED DATE
                subtitle: Text(
                  "$desc\n${formatTimestamp(data['createdAt'])}\nStatus: ${status.toUpperCase()}",
                  style: const TextStyle(color: Colors.white54),
                ),
                trailing: isProcessed
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: () => FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .collection('walletTransactions')
                            .doc(doc.id)
                            .update({'status': 'processed'}),
                        child: const Text("Mark Paid"),
                      ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// =============================================================================
// 6. USER DATABASE SECTION (WITH JOINED DATE)
// =============================================================================
class UserDatabaseSection extends StatelessWidget {
  const UserDatabaseSection({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Registered Users",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      Colors.blueAccent.withOpacity(0.1),
                    ),
                    dataRowHeight: 60,
                    columns: const [
                      DataColumn(
                        label: Text(
                          "Name",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Phone / ID",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      // ✅ ADDED JOINED COLUMN
                      DataColumn(
                        label: Text(
                          "Joined",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Wallet",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Status",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Action",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                    rows: snapshot.data!.docs.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      String uid = doc.id;
                      bool isSuspended = data['isSuspended'] ?? false;
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              data['name'] ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              uid,
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ),
                          // ✅ ADDED DATE CELL
                          DataCell(
                            Text(
                              formatTimestamp(data['createdAt']),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              "₹${data['walletBalance'] ?? 0}",
                              style: const TextStyle(color: Colors.greenAccent),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: (data['kycStatus'] == 'approved')
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                (data['kycStatus'] ?? 'PENDING')
                                    .toString()
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: (data['kycStatus'] == 'approved')
                                      ? Colors.green
                                      : Colors.orange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Tooltip(
                              message: isSuspended
                                  ? "Unfreeze Account"
                                  : "Freeze Account",
                              child: IconButton(
                                icon: Icon(
                                  isSuspended ? Icons.lock : Icons.lock_open,
                                  color: isSuspended
                                      ? Colors.redAccent
                                      : Colors.greenAccent,
                                ),
                                onPressed: () => FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .update({'isSuspended': !isSuspended}),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 7. SUPPORT TICKET SECTION (WITH DATE)
// =============================================================================
class SupportTicketSection extends StatelessWidget {
  const SupportTicketSection({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Support Desk",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('support_tickets')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty)
                return const Center(
                  child: Text(
                    "No Open Tickets",
                    style: TextStyle(color: Colors.white38, fontSize: 18),
                  ),
                );
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var data =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  String ticketId = snapshot.data!.docs[index].id;
                  String userName = data['name'] ?? 'Unknown User';
                  String userPhone = data['phone'] ?? 'No Phone';
                  return Card(
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white10,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        data['message'] ?? 'No Message',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // ✅ UPDATED DATE FORMAT
                      subtitle: Text(
                        "$userName ($userPhone)\n${formatTimestamp(data['timestamp'])}",
                        style: const TextStyle(color: Colors.white54),
                      ),
                      trailing: ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text("Resolve"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () => FirebaseFirestore.instance
                            .collection('support_tickets')
                            .doc(ticketId)
                            .delete(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// ✅ HELPER FUNCTION: DATE FORMATTER
// =============================================================================
String formatTimestamp(dynamic timestamp) {
  if (timestamp == null) return "N/A";
  try {
    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      return DateFormat('dd MMM yyyy • hh:mm a').format(date);
    } else if (timestamp is String) {
      // Handle fallback string dates if any
      DateTime? date = DateTime.tryParse(timestamp);
      if (date != null) {
        return DateFormat('dd MMM yyyy • hh:mm a').format(date);
      }
    }
  } catch (e) {
    return "Invalid Date";
  }
  return "N/A";
}
