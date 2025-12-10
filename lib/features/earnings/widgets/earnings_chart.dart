import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EarningsChart extends StatelessWidget {
  final List<QueryDocumentSnapshot> earningsDocs;

  const EarningsChart({super.key, required this.earningsDocs});

  @override
  Widget build(BuildContext context) {
    List<double> weeklyData = List.filled(7, 0.0);
    double maxEarning = 0;

    for (var doc in earningsDocs) {
      final data = doc.data() as Map<String, dynamic>;
      Timestamp? ts = data['date'] ?? data['createdAt'];
      if (ts == null) continue;

      DateTime date = ts.toDate();
      if (date.isAfter(DateTime.now().subtract(const Duration(days: 7)))) {
        int dayDiff = DateTime.now().difference(date).inDays;
        if (dayDiff >= 0 && dayDiff < 7) {
          int index = 6 - dayDiff;
          double amount = double.tryParse(data['amount'].toString()) ?? 0.0;
          weeklyData[index] += amount;
          if (weeklyData[index] > maxEarning) maxEarning = weeklyData[index];
        }
      }
    }

    if (maxEarning == 0) maxEarning = 100;

    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Last 7 Days Activity",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxEarning * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey, // FIXED LINE
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '₹${rod.toY.round()}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final DateTime date = DateTime.now().subtract(
                          Duration(days: 6 - value.toInt()),
                        );
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('E').format(date)[0],
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                barGroups: List.generate(7, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: weeklyData[index],
                        color: weeklyData[index] > 0
                            ? Colors.blueAccent
                            : const Color(0xFF2C2C2C),
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxEarning * 1.2,
                          color: const Color(0xFF222222),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
