import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AdherencePieChart extends StatelessWidget {
  final int completed;
  final int missed;

  const AdherencePieChart(
      {super.key, required this.completed, required this.missed});

  @override
  Widget build(BuildContext context) {
    final total = completed + missed;
    final completedPercent = total == 0 ? 0 : (completed / total * 100).round();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status Breakdown',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                _buildLegendItem(Colors.green, 'Taken ($completed)'),
                const SizedBox(height: 8),
                _buildLegendItem(Colors.red, 'Missed ($missed)'),
                const Spacer(),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        color: Colors.green,
                        value: completed.toDouble(),
                        title: '',
                        radius: 20,
                      ),
                      PieChartSectionData(
                        color: Colors.red,
                        value: missed.toDouble(),
                        title: '',
                        radius: 20,
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Text(
                    '$completedPercent%',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      ],
    );
  }
}
