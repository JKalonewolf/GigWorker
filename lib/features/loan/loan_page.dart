import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gigworker/models/loan_model.dart';
import 'package:gigworker/services/loan_service.dart';
import 'package:gigworker/services/local_notification_service.dart';

class LoanPage extends StatefulWidget {
  final String phoneNumber;

  const LoanPage({super.key, required this.phoneNumber});

  @override
  State<LoanPage> createState() => _LoanPageState();
}

class _LoanPageState extends State<LoanPage> {
  final LoanService _loanService = LoanService();

  double _selectedAmount = 5000;
  int _selectedTenure = 6;
  double _interestRate = 0.18; // 18% p.a.

  @override
  Widget build(BuildContext context) {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.phoneNumber);

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        elevation: 0,
        title: const Text("Loans"),
      ),
      body: StreamBuilder<List<LoanModel>>(
        stream: _loanService.streamLoans(widget.phoneNumber),
        builder: (context, snap) {
          final loans = snap.data ?? [];

          // find active or pending loan if any
          LoanModel? activeLoan;
          for (final l in loans) {
            if (l.status == 'active' || l.status == 'pending') {
              activeLoan = l;
              break;
            }
          }
          final hasActiveLoan = activeLoan != null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KYC / eligibility info
                StreamBuilder<DocumentSnapshot>(
                  stream: userRef.snapshots(),
                  builder: (context, userSnap) {
                    String kycStatus = "pending";
                    if (userSnap.hasData && userSnap.data!.exists) {
                      final data =
                          userSnap.data!.data() as Map<String, dynamic>? ?? {};
                      kycStatus = (data['kycStatus'] ?? 'pending').toString();
                    }

                    return _buildEligibilityCard(kycStatus);
                  },
                ),

                const SizedBox(height: 20),

                if (!hasActiveLoan)
                  _buildCalculatorSection()
                else
                  _buildActiveLoanSection(activeLoan!), // active loan UI

                const SizedBox(height: 24),

                const Text(
                  "Loan history",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                if (loans.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Center(
                      child: Text(
                        "No loans yet",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  )
                else
                  Column(
                    children: loans
                        .map((loan) => _buildLoanHistoryTile(loan))
                        .toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------- WIDGETS (EXACT DESIGN KEPT) ----------

  Widget _buildEligibilityCard(String kycStatus) {
    final isKycApproved = kycStatus.toLowerCase() == 'approved';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user,
            size: 22,
            color: isKycApproved ? Colors.greenAccent : Colors.amberAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Loan eligibility",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isKycApproved
                      ? "Your KYC is approved. We’ll check your recent earnings to decide how much you can borrow."
                      : "Complete KYC to become eligible for loans.",
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorSection() {
    final emi = _loanService.calculateEmi(
      principal: _selectedAmount,
      annualRate: _interestRate,
      months: _selectedTenure,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Check eligibility",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Amount slider
          const Text(
            "Loan amount",
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "₹ 1,000",
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              Text(
                "₹ ${_selectedAmount.toStringAsFixed(0)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                "₹ 20,000",
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          Slider(
            value: _selectedAmount,
            min: 1000,
            max: 20000,
            divisions: 19,
            label: "₹${_selectedAmount.toStringAsFixed(0)}",
            activeColor: Colors.blueAccent,
            onChanged: (v) {
              setState(() => _selectedAmount = v);
            },
          ),

          const SizedBox(height: 8),

          // Tenure dropdown
          const Text(
            "Tenure (months)",
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            value: _selectedTenure,
            dropdownColor: const Color(0xFF181818),
            iconEnabledColor: Colors.white70,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF191919),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF303030)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.blueAccent),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 3, child: Text("3 months")),
              DropdownMenuItem(value: 6, child: Text("6 months")),
              DropdownMenuItem(value: 9, child: Text("9 months")),
              DropdownMenuItem(value: 12, child: Text("12 months")),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedTenure = v);
              }
            },
          ),

          const SizedBox(height: 16),

          // EMI preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF202020),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments, color: Colors.greenAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Estimated EMI",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "₹ ${emi.toStringAsFixed(0)} / month",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "At ${(_interestRate * 100).toStringAsFixed(1)}% p.a. (approx.)",
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Check eligibility button
          GestureDetector(
            onTap: _onCheckEligibility,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blueAccent, Colors.purpleAccent],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  "Check eligibility",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLoanSection(LoanModel loan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Active loan",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "₹${loan.amount.toStringAsFixed(0)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Outstanding: ₹${loan.outstandingAmount.toStringAsFixed(0)}",
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            "EMI: ₹${loan.emiAmount.toStringAsFixed(0)} • Tenure: ${loan.tenureMonths} months",
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 4),
          if (loan.nextDueDate != null)
            Text(
              "Next EMI: ${loan.nextDueDate!.toLocal().toString().split(' ').first}",
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LoanStatusPage(
                          phoneNumber: widget.phoneNumber,
                          loan: loan,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF202020),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        "Loan status",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RepaymentSchedulePage(
                          phoneNumber: widget.phoneNumber,
                          loan: loan,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blueAccent, Colors.purpleAccent],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        "Repayment schedule",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoanHistoryTile(LoanModel loan) {
    Color statusColor;
    String statusLabel;

    switch (loan.status) {
      case 'active':
        statusColor = Colors.amberAccent;
        statusLabel = "Active";
        break;
      case 'closed':
        statusColor = Colors.greenAccent;
        statusLabel = "Closed";
        break;
      case 'pending':
        statusColor = Colors.blueAccent;
        statusLabel = "Pending";
        break;
      case 'rejected':
        statusColor = Colors.redAccent;
        statusLabel = "Rejected";
        break;
      default:
        statusColor = Colors.white70;
        statusLabel = loan.status;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF202020),
            child: Icon(Icons.request_page, color: statusColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "₹${loan.amount.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Status: $statusLabel",
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
        ],
      ),
    );
  }

  // ---------- LOGIC: CHECK ELIGIBILITY WITH KYC CHECK ----------

  Future<void> _onCheckEligibility() async {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.phoneNumber);

    final userSnapshot = await userRef.get();
    String kycStatus = "pending";
    if (userSnapshot.exists) {
      final data = userSnapshot.data() as Map<String, dynamic>;
      kycStatus = (data['kycStatus'] ?? 'pending').toString();
    }

    // === ADDED LOGIC: PREVENT LOAN IF KYC NOT APPROVED ===
    if (kycStatus.toLowerCase() != 'approved') {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Icon(Icons.lock, color: Colors.redAccent, size: 50),
          content: const Text(
            "KYC Approval Required\nYou cannot apply for a loan until your KYC is verified and approved by the admin.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    // 1) Fetch last 30 days earnings
    final earningsSnap = await userRef
        .collection('earnings')
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 30)),
          ),
        )
        .get();

    double totalEarnings = 0;
    for (final doc in earningsSnap.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final rawAmount = data['amount'];
      if (rawAmount is int) {
        totalEarnings += rawAmount.toDouble();
      } else if (rawAmount is double) {
        totalEarnings += rawAmount;
      }
    }

    // 2) Simple eligibility logic
    bool eligible = totalEarnings >= 3000; // arbitrary threshold
    double maxAmount = eligible ? totalEarnings * 2 : 0;
    if (maxAmount > 20000) maxAmount = 20000;
    if (maxAmount < 1000 && eligible) maxAmount = 1000;

    String risk;
    if (totalEarnings >= 15000) {
      risk = "Low";
    } else if (totalEarnings >= 7000) {
      risk = "Medium";
    } else {
      risk = "High";
    }

    final double planAmount = _selectedAmount.clamp(
      1000,
      maxAmount == 0 ? 1000 : maxAmount,
    );
    final int planTenure = _selectedTenure;

    final emi = _loanService.calculateEmi(
      principal: planAmount,
      annualRate: _interestRate,
      months: planTenure,
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoanEligibilityResultPage(
          phoneNumber: widget.phoneNumber,
          eligible: eligible,
          totalEarnings30d: totalEarnings,
          maxAmount: maxAmount,
          suggestedTenure: planTenure,
          riskLevel: risk,
          planAmount: planAmount,
          planTenure: planTenure,
          planEmi: emi,
          interestRate: _interestRate,
        ),
      ),
    );
  }
}

// ====================== ELIGIBILITY RESULT PAGE ======================

class LoanEligibilityResultPage extends StatelessWidget {
  final String phoneNumber;
  final bool eligible;
  final double totalEarnings30d;
  final double maxAmount;
  final int suggestedTenure;
  final String riskLevel;

  final double planAmount;
  final int planTenure;
  final double planEmi;
  final double interestRate;

  const LoanEligibilityResultPage({
    super.key,
    required this.phoneNumber,
    required this.eligible,
    required this.totalEarnings30d,
    required this.maxAmount,
    required this.suggestedTenure,
    required this.riskLevel,
    required this.planAmount,
    required this.planTenure,
    required this.planEmi,
    required this.interestRate,
  });

  @override
  Widget build(BuildContext context) {
    Color riskColor;
    switch (riskLevel.toLowerCase()) {
      case 'low':
        riskColor = Colors.greenAccent;
        break;
      case 'medium':
        riskColor = Colors.amberAccent;
        break;
      default:
        riskColor = Colors.redAccent;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        elevation: 0,
        title: const Text("Eligibility result"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eligible ? "You’re eligible 🎉" : "Not eligible right now",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Last 30 days earnings: ₹${totalEarnings30d.toStringAsFixed(0)}",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF181818),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Summary",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _row("Eligibility", eligible ? "Eligible" : "Not eligible"),
                  _row(
                    "Max loan amount",
                    eligible ? "₹${maxAmount.toStringAsFixed(0)}" : "-",
                  ),
                  _row("Suggested tenure", "$suggestedTenure months"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Risk level",
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                      Text(
                        riskLevel,
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              "Recommended plan",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF181818),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "₹${planAmount.toStringAsFixed(0)} • $planTenure months",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Estimated EMI: ₹${planEmi.toStringAsFixed(0)} / month",
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Rate: ${(interestRate * 100).toStringAsFixed(1)}% p.a. (approx.)",
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),

            const Spacer(),

            if (eligible)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LoanApplicationPage(
                        phoneNumber: phoneNumber,
                        amount: planAmount,
                        tenureMonths: planTenure,
                        interestRate: interestRate,
                        riskLevel: riskLevel,
                        emi: planEmi,
                      ),
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
                  child: const Center(
                    child: Text(
                      "Apply for loan",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
            else
              const Text(
                "Tip: Increase your last 30 days earnings to improve eligibility.",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  static Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ====================== LOAN APPLICATION PAGE ======================

class LoanApplicationPage extends StatefulWidget {
  final String phoneNumber;
  final double amount;
  final int tenureMonths;
  final double interestRate;
  final String riskLevel;
  final double emi;

  const LoanApplicationPage({
    super.key,
    required this.phoneNumber,
    required this.amount,
    required this.tenureMonths,
    required this.interestRate,
    required this.riskLevel,
    required this.emi,
  });

  @override
  State<LoanApplicationPage> createState() => _LoanApplicationPageState();
}

class _LoanApplicationPageState extends State<LoanApplicationPage> {
  bool _acceptTerms = false;
  bool _isSubmitting = false;
  final LoanService _loanService = LoanService();

  Future<void> _submit() async {
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept terms to continue.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _loanService.applyForLoan(
        phone: widget.phoneNumber,
        amount: widget.amount,
        tenureMonths: widget.tenureMonths,
        interestRate: widget.interestRate,
        riskLevel: widget.riskLevel.toLowerCase(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Loan approved and added to wallet.")),
      );

      LocalNotificationService().showNotification(
        id: DateTime.now().millisecond,
        title: 'Loan Approved! ✅',
        body:
            '₹${widget.amount.toStringAsFixed(0)} has been credited to your wallet instantly.',
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error applying for loan: $e")));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        elevation: 0,
        title: const Text("Loan application"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Review your loan",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF181818),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow("Amount", "₹${widget.amount.toStringAsFixed(0)}"),
                  _infoRow("Tenure", "${widget.tenureMonths} months"),
                  _infoRow(
                    "EMI (approx)",
                    "₹${widget.emi.toStringAsFixed(0)} / month",
                  ),
                  _infoRow(
                    "Rate",
                    "${(widget.interestRate * 100).toStringAsFixed(1)}% p.a.",
                  ),
                  _infoRow("Risk profile", widget.riskLevel),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _acceptTerms,
                  onChanged: (v) {
                    setState(() => _acceptTerms = v ?? false);
                  },
                  activeColor: Colors.blueAccent,
                ),
                const Expanded(
                  child: Text(
                    "I confirm that the above details are correct and I agree to repay the EMIs on time.",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: _isSubmitting ? null : _submit,
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
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          "Confirm & apply",
                          style: TextStyle(
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
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== LOAN STATUS PAGE (FIXED LOGIC) ======================

class LoanStatusPage extends StatelessWidget {
  final String phoneNumber;
  final LoanModel loan;

  const LoanStatusPage({
    super.key,
    required this.phoneNumber,
    required this.loan,
  });

  @override
  Widget build(BuildContext context) {
    final status = loan.status.toLowerCase();
    Color statusColor;
    String statusText;

    switch (status) {
      case 'active':
        statusColor = Colors.amberAccent;
        statusText = "Active";
        break;
      case 'closed':
        statusColor = Colors.greenAccent;
        statusText = "Closed";
        break;
      case 'pending':
        statusColor = Colors.blueAccent;
        statusText = "Pending";
        break;
      case 'rejected':
        statusColor = Colors.redAccent;
        statusText = "Rejected";
        break;
      default:
        statusColor = Colors.white70;
        statusText = loan.status;
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        elevation: 0,
        title: const Text("Loan status"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "₹${loan.amount.toStringAsFixed(0)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF181818),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _row(
                    "Outstanding",
                    "₹${loan.outstandingAmount.toStringAsFixed(0)}",
                  ),
                  _row("EMI", "₹${loan.emiAmount.toStringAsFixed(0)} / month"),
                  _row("Tenure", "${loan.tenureMonths} months"),
                  _row(
                    "Rate",
                    "${(loan.interestRate * 100).toStringAsFixed(1)}% p.a.",
                  ),
                  if (loan.disbursedAt != null)
                    _row(
                      "Disbursed on",
                      loan.disbursedAt!.toLocal().toString().split(' ').first,
                    ),
                  if (loan.nextDueDate != null)
                    _row(
                      "Next EMI date",
                      loan.nextDueDate!.toLocal().toString().split(' ').first,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Where did the money go?",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF181818),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: const [
                  Icon(Icons.account_balance_wallet, color: Colors.cyanAccent),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Disbursed to: GigBank wallet\nYou can use this balance for your daily expenses.",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            if (loan.status == 'active' && loan.outstandingAmount > 0)
              Column(
                children: [
                  GestureDetector(
                    onTap: () => _payEmi(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.orangeAccent, Colors.redAccent],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          "Pay EMI from wallet",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RepaymentSchedulePage(
                      phoneNumber: phoneNumber,
                      loan: loan,
                    ),
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
                child: const Center(
                  child: Text(
                    "View repayment schedule",
                    style: TextStyle(
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
      ),
    );
  }

  static Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // --- 🛑 FIXED PAY EMI FUNCTION 🛑 ---
  Future<void> _payEmi(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber);
      final loanRef = userRef.collection('loans').doc(loan.id);

      // 1. Get Fresh Loan Data to find correct Installment Index
      DocumentSnapshot loanSnap = await loanRef.get();
      int paidCount =
          (loanSnap.data() as Map<String, dynamic>)['installmentsPaid'] ?? 0;
      int nextIndex = paidCount + 1;

      // 2. Find specific Repayment Doc for this month (Where index == nextIndex)
      QuerySnapshot repayQuery = await loanRef
          .collection('repayments')
          .where('index', isEqualTo: nextIndex)
          .limit(1)
          .get();
      DocumentReference? repayRef;
      if (repayQuery.docs.isNotEmpty) {
        repayRef = repayQuery.docs.first.reference;
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 3. Check Wallet
        DocumentSnapshot userSnap = await transaction.get(userRef);
        double currentWallet =
            (userSnap.data() as Map<String, dynamic>)['walletBalance']
                ?.toDouble() ??
            0.0;

        if (currentWallet < loan.emiAmount) {
          throw Exception("Insufficient Wallet Balance");
        }

        // 4. Deduct Money
        transaction.update(userRef, {
          'walletBalance': currentWallet - loan.emiAmount,
        });

        // 5. Update Loan status
        bool isLast = nextIndex >= loan.tenureMonths;
        transaction.update(loanRef, {
          'installmentsPaid': nextIndex,
          'status': isLast ? 'closed' : 'active',
        });

        // 6. UPDATE REPAYMENT SCHEDULE DOC TO 'PAID' (This was missing!)
        if (repayRef != null) {
          transaction.update(repayRef, {
            'status': 'paid',
            'paidAt': FieldValue.serverTimestamp(),
          });
        }

        // 7. Log Transaction
        transaction.set(userRef.collection('walletTransactions').doc(), {
          'amount': loan.emiAmount,
          'type': 'loan_repayment',
          'direction': 'debit',
          'description': 'EMI Payment ($nextIndex/${loan.tenureMonths})',
          'status': 'success',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("EMI Paid Successfully!"),
        ),
      );

      // Check if finished
      if (nextIndex >= loan.tenureMonths) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}

// ====================== REPAYMENT SCHEDULE PAGE ======================

class RepaymentSchedulePage extends StatelessWidget {
  final String phoneNumber;
  final LoanModel loan;

  const RepaymentSchedulePage({
    super.key,
    required this.phoneNumber,
    required this.loan,
  });

  @override
  Widget build(BuildContext context) {
    final loanRef = FirebaseFirestore.instance
        .collection('users')
        .doc(phoneNumber)
        .collection('loans')
        .doc(loan.id);

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        elevation: 0,
        title: const Text("Repayment schedule"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // Keep your Summary Card Design
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF181818),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Summary",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Principal: ₹${loan.amount.toStringAsFixed(0)}",
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  Text(
                    "Outstanding: ₹${loan.outstandingAmount.toStringAsFixed(0)}",
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  Text(
                    "EMI: ₹${loan.emiAmount.toStringAsFixed(0)} x ${loan.tenureMonths}",
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: loanRef
                  .collection('repayments')
                  .orderBy('index')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No repayment schedule found",
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                final docs = snap.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                        docs[index].data() as Map<String, dynamic>? ?? {};
                    final idx = (data['index'] ?? (index + 1)) as int;
                    final rawAmount = data['amount'];
                    double amount;
                    if (rawAmount is int) {
                      amount = rawAmount.toDouble();
                    } else if (rawAmount is double) {
                      amount = rawAmount;
                    } else {
                      amount = 0;
                    }
                    final status = (data['status'] ?? 'upcoming') as String;
                    final due = data['dueDate'];
                    DateTime dueDate;
                    if (due is String) {
                      try {
                        dueDate = DateTime.parse(due);
                      } catch (_) {
                        dueDate = DateTime.now();
                      }
                    } else if (due is Timestamp) {
                      dueDate = due.toDate();
                    } else {
                      dueDate = DateTime.now();
                    }

                    Color statusColor;
                    switch (status) {
                      case 'paid':
                        statusColor = Colors.greenAccent;
                        break;
                      case 'overdue':
                        statusColor = Colors.redAccent;
                        break;
                      default:
                        statusColor = Colors.amberAccent;
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF181818),
                        child: Text(
                          "$idx",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      title: Text(
                        "₹${amount.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        "Due: ${dueDate.toLocal().toString().split(' ').first}",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
