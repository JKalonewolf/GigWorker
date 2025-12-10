import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PdfService {
  Future<void> generateStatement({
    required String userId,
    required bool isWeekly,
  }) async {
    final pdf = pw.Document();
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    // 1. Determine Dates & Title
    final DateTime now = DateTime.now();
    final DateTime startDate = isWeekly
        ? now.subtract(const Duration(days: 7))
        : now.subtract(const Duration(days: 30));

    final String reportTitle = isWeekly
        ? "WEEKLY STATEMENT"
        : "MONTHLY STATEMENT";

    // 2. FETCH ALL DATA
    final walletSnap = await userRef.collection('walletTransactions').get();
    final earningSnap = await userRef.collection('earnings').get();

    List<Map<String, dynamic>> allTransactions = [];

    // 3. Process & Merge Data
    // Wallet Transactions
    for (var doc in walletSnap.docs) {
      var data = doc.data();
      Timestamp? ts = data['createdAt'] ?? data['date'];
      if (ts == null) continue;

      data['finalDate'] = ts.toDate();
      data['displayType'] = data['type'] ?? 'Transaction';
      data['note'] = data['note'] ?? data['label'] ?? data['displayType'];
      allTransactions.add(data);
    }

    // Earnings
    for (var doc in earningSnap.docs) {
      var data = doc.data();
      Timestamp? ts = data['date'] ?? data['createdAt'];
      if (ts == null) continue;

      data['finalDate'] = ts.toDate();
      data['displayType'] = 'EARNING';
      data['direction'] = 'credit';
      String platform = data['platform'] ?? 'App';
      data['note'] = "Earning - $platform";
      allTransactions.add(data);
    }

    // 4. FILTER by Date Range
    allTransactions = allTransactions.where((tx) {
      DateTime txDate = tx['finalDate'];
      return txDate.isAfter(startDate) &&
          txDate.isBefore(now.add(const Duration(days: 1)));
    }).toList();

    // 5. Sort by Date (Newest first)
    allTransactions.sort((a, b) => b['finalDate'].compareTo(a['finalDate']));

    // 6. Calculate Totals
    double totalCredit = 0;
    double totalDebit = 0;

    for (var tx in allTransactions) {
      double amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
      String direction = (tx['direction'] ?? '').toString().toLowerCase();

      if (direction.isEmpty) {
        String type = tx['displayType'].toString().toUpperCase();
        if (type == 'EARNING' || type == 'LOAN' || type == 'CREDIT') {
          direction = 'credit';
        } else {
          direction = 'debit';
        }
      }

      if (direction == 'credit') {
        totalCredit += amount;
      } else {
        totalDebit += amount;
      }
    }

    // 7. BUILD PDF (Using MultiPage to fix overflow issues)
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        // Header appears on every page
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "GigBank",
                        style: pw.TextStyle(
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        "Smart Banking for Gig Workers",
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        reportTitle,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red800,
                        ),
                      ),
                      pw.Text(
                        "Period: ${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM yyyy').format(now)}",
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(color: PdfColors.grey),
              pw.SizedBox(height: 20),
            ],
          );
        },
        // Footer appears on every page
        footer: (pw.Context context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "Generated by GigBank App",
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
              pw.Text(
                "Page ${context.pageNumber} of ${context.pagesCount}",
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          );
        },
        // Main Content
        build: (pw.Context context) {
          return [
            // Summary Box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                color: PdfColors.grey100,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    "Total Deposits",
                    "+ Rs. ${totalCredit.toStringAsFixed(0)}",
                    PdfColors.green700,
                  ),
                  pw.Container(width: 1, height: 30, color: PdfColors.grey400),
                  _buildSummaryItem(
                    "Total Withdrawals",
                    "- Rs. ${totalDebit.toStringAsFixed(0)}",
                    PdfColors.red700,
                  ),
                  pw.Container(width: 1, height: 30, color: PdfColors.grey400),
                  _buildSummaryItem(
                    "Net Flow",
                    "Rs. ${(totalCredit - totalDebit).toStringAsFixed(0)}",
                    PdfColors.blue800,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            pw.Text(
              "Transaction History",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
            pw.SizedBox(height: 10),

            allTransactions.isEmpty
                ? pw.Container(
                    alignment: pw.Alignment.centerLeft,
                    padding: const pw.EdgeInsets.all(20),
                    child: pw.Text("No transactions found for this period."),
                  )
                : pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    columnWidths: {
                      0: const pw.FixedColumnWidth(80), // Date
                      1: const pw.FixedColumnWidth(60), // Time
                      2: const pw.FlexColumnWidth(2), // Description
                      3: const pw.FixedColumnWidth(50), // Type
                      4: const pw.FixedColumnWidth(80), // Amount
                    },
                    children: [
                      // Table Header
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.blue50,
                        ),
                        children: [
                          _buildHeaderCell("Date"),
                          _buildHeaderCell("Time"),
                          _buildHeaderCell("Description"),
                          _buildHeaderCell("Type"),
                          _buildHeaderCell("Amount"),
                        ],
                      ),
                      // Table Data
                      ...allTransactions.map((tx) {
                        final date = tx['finalDate'] as DateTime;
                        final amount =
                            double.tryParse(tx['amount'].toString()) ?? 0.0;
                        final note = tx['note'].toString();

                        String direction = (tx['direction'] ?? '')
                            .toString()
                            .toLowerCase();
                        if (direction.isEmpty) {
                          String type = tx['displayType']
                              .toString()
                              .toUpperCase();
                          if (type == 'EARNING' ||
                              type == 'LOAN' ||
                              type == 'CREDIT')
                            direction = 'credit';
                          else
                            direction = 'debit';
                        }
                        final isCredit = direction == 'credit';

                        return pw.TableRow(
                          children: [
                            _buildCell(
                              DateFormat('dd MMM yyyy').format(date),
                            ), // Date
                            _buildCell(
                              DateFormat('hh:mm a').format(date),
                            ), // Time
                            _buildCell(note), // Desc
                            _buildCell(
                              isCredit ? "CR" : "DR",
                              align: pw.TextAlign.center,
                            ), // Type
                            _buildCell(
                              "Rs. ${amount.toStringAsFixed(0)}",
                              align: pw.TextAlign.right,
                              color: isCredit
                                  ? PdfColors.green800
                                  : PdfColors.red800,
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // --- Helper Widgets ---
  pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      ),
    );
  }

  pw.Widget _buildCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 9, color: color ?? PdfColors.black),
      ),
    );
  }
}
