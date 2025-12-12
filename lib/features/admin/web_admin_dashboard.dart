import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WebAdminDashboard extends StatefulWidget {
  const WebAdminDashboard({super.key});

  @override
  State<WebAdminDashboard> createState() => _WebAdminDashboardState();
}

class _WebAdminDashboardState extends State<WebAdminDashboard> {
  int _selectedIndex = 0;

  // Define the pages list
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const AnalyticsSection(), // 0. Pro Analytics
      const KycManagementSection(), // 1. KYC Requests
      const UserDatabaseSection(), // 2. User Database
      const SupportTicketSection(), // 3. NEW SUPPORT SECTION
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

                // MENU ITEMS
                _navItem(0, "Dashboard", Icons.dashboard),
                _navItem(1, "KYC Requests", Icons.verified_user),
                _navItem(2, "User Database", Icons.people),
                _navItem(
                  3,
                  "Support Desk",
                  Icons.headset_mic,
                ), // <--- THIS IS THE NEW TAB
              ],
            ),
          ),

          // --- MAIN CONTENT ---
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(30),
              // Use IndexedStack to keep state alive, or just switch widgets
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
// 1. ANALYTICS SECTION (PRO VERSION)
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

          // REAL-TIME CARDS
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              String totalUsers = "...";
              String pendingKyc = "...";
              String totalWallet = "...";
              String activeLoans = "12";

              if (snapshot.hasData) {
                var docs = snapshot.data!.docs;
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

              return Row(
                children: [
                  _kpiCard(
                    "Total Users",
                    totalUsers,
                    "+5 today",
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
                    "Revenue Generating",
                    Colors.purple,
                    Icons.monetization_on,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 40),

          // PRO CHARTS
          SizedBox(
            height: 400,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _chartContainer(
                    "Loan Disbursement Volume",
                    _buildBarChart(),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _chartContainer(
                    "Gig Worker Categories",
                    _buildPieChart(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) => Text(
                ["M", "T", "W", "T", "F", "S", "S"][val.toInt() % 7],
                style: const TextStyle(color: Colors.white38, fontSize: 10),
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
                toY: (i + 3) * 2.0 + 5,
                color: Colors.blueAccent,
                width: 16,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            value: 45,
            title: "45%",
            color: Colors.blueAccent,
            radius: 40,
            titleStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          PieChartSectionData(
            value: 30,
            title: "30%",
            color: Colors.purpleAccent,
            radius: 35,
            titleStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          PieChartSectionData(
            value: 25,
            title: "25%",
            color: Colors.orangeAccent,
            radius: 30,
            titleStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 2. KYC MANAGEMENT SECTION (UPDATED: SHOWS ALL)
// =============================================================================
class KycManagementSection extends StatelessWidget {
  const KycManagementSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "KYC Management (All Users)",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // FIX: Removed .where() so we see EVERYONE.
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              // Filter logic: Only show users who have actually submitted KYC (exclude 'new')
              var allDocs = snapshot.data!.docs;
              var kycDocs = allDocs.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                String status = data['kycStatus'] ?? 'new';
                return status != 'new'; // Show Pending, Approved, Rejected
              }).toList();

              if (kycDocs.isEmpty) {
                return const Center(
                  child: Text(
                    "No KYC Submissions yet.",
                    style: TextStyle(color: Colors.white38),
                  ),
                );
              }

              // Sorting: Put 'pending' at the top!
              kycDocs.sort((a, b) {
                var statusA = (a.data() as Map)['kycStatus'] ?? '';
                var statusB = (b.data() as Map)['kycStatus'] ?? '';
                if (statusA == 'pending' && statusB != 'pending') return -1;
                if (statusA != 'pending' && statusB == 'pending') return 1;
                return 0;
              });

              return ListView.builder(
                itemCount: kycDocs.length,
                itemBuilder: (context, index) {
                  var data = kycDocs[index].data() as Map<String, dynamic>;
                  String uid = kycDocs[index].id;
                  String status = (data['kycStatus'] ?? 'pending').toString();

                  Color statusColor = Colors.orange;
                  if (status == 'approved') statusColor = Colors.green;
                  if (status == 'rejected') statusColor = Colors.red;

                  return Card(
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.2),
                        child: Icon(Icons.person, color: statusColor),
                      ),
                      title: Text(
                        data['name'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Aadhaar: ${data['aadhaarNumber'] ?? 'N/A'}",
                            style: const TextStyle(color: Colors.white54),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // SHOW BOTH BUTTONS ALWAYS so you can change status anytime
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.redAccent,
                            ),
                            tooltip: "Reject",
                            onPressed: () => FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .update({'kycStatus': 'rejected'}),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            tooltip: "Approve",
                            onPressed: () => FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .update({'kycStatus': 'approved'}),
                          ),
                        ],
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
// 3. USER DATABASE SECTION (With Freeze/Unfreeze)
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
                      ), // <--- ADDED ACTION COLUMN
                    ],
                    rows: snapshot.data!.docs.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      String uid = doc.id;
                      bool isSuspended =
                          data['isSuspended'] ?? false; // Check if frozen

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
                          // --- THE FREEZE BUTTON ---
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
                                onPressed: () {
                                  // Toggle the suspension status in Firebase
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uid)
                                      .update({'isSuspended': !isSuspended});
                                },
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
// 4. SUPPORT TICKET SECTION (Updated to show Name)
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

              if (snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    "No Open Tickets",
                    style: TextStyle(color: Colors.white38, fontSize: 18),
                  ),
                );
              }

              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var data =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  String ticketId = snapshot.data!.docs[index].id;

                  Timestamp? ts = data['timestamp'];
                  String dateStr = ts != null
                      ? "${ts.toDate().day}/${ts.toDate().month} ${ts.toDate().hour}:${ts.toDate().minute}"
                      : "Just now";

                  // --- HERE WE GET THE NAME ---
                  String userName = data['name'] ?? 'Unknown User';
                  String userPhone = data['phone'] ?? 'No Phone';

                  return Card(
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white10,
                        child: Text(
                          userName[0].toUpperCase(),
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

                      // SHOW NAME AND PHONE HERE
                      subtitle: Text(
                        "$userName ($userPhone)\n$dateStr",
                        style: const TextStyle(color: Colors.white54),
                      ),

                      trailing: ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text("Resolve"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('support_tickets')
                              .doc(ticketId)
                              .delete();
                        },
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
