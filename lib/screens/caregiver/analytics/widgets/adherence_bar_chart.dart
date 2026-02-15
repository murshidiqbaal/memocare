import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AdherenceBarChart extends StatelessWidget {
  final List<double> weeklyData; // 7 days

  const AdherenceBarChart({super.key, required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Adherence',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          color: Color(0xff7589a2),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        );
                        String text;
                        switch (value.toInt()) {
                          case 0:
                            text = 'M';
                            break;
                          case 1:
                            text = 'T';
                            break;
                          case 2:
                            text = 'W';
                            break;
                          case 3:
                            text = 'T';
                            break;
                          case 4:
                            text = 'F';
                            break;
                          case 5:
                            text = 'S';
                            break;
                          case 6:
                            text = 'S';
                            break;
                          default:
                            text = '';
                        }
                        return SideTitleWidget(
                          meta: meta,
                          space: 4.0,
                          child: Text(text, style: style),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: weeklyData.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
                        color: e.value >= 80
                            ? Colors.teal
                            : (e.value >= 50 ? Colors.orange : Colors.red),
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
