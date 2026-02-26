import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../features/games/providers/game_analytics_provider.dart';

class CaregiverCognitiveAnalyticsWidget extends ConsumerWidget {
  final String patientId;

  const CaregiverCognitiveAnalyticsWidget({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(caregiverPatientAnalyticsProvider);

    return analyticsAsync.when(
      data: (rawData) {
        // Filter data down strictly to this patient
        final data =
            rawData.where((row) => row['patient_id'] == patientId).toList();

        if (data.isEmpty) {
          return const SizedBox
              .shrink(); // Don't show chart if no data for this patient
        }

        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.teal),
                    SizedBox(width: 8),
                    Text(
                      'Cognitive Trends',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: LineChart(
                    _createChartData(data),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ChartLegend(color: Colors.blue, label: 'Sessions'),
                    SizedBox(width: 16),
                    _ChartLegend(color: Colors.green, label: 'Best Score'),
                    SizedBox(width: 16),
                    _ChartLegend(color: Colors.orange, label: 'Avg Score'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text('Error loading charts: $e'),
    );
  }

  LineChartData _createChartData(List<Map<String, dynamic>> rawData) {
    // Sort oldest to newest for the chart X-axis
    final sortedData = List<Map<String, dynamic>>.from(rawData)
      ..sort((a, b) => DateTime.parse(a['analytics_date'])
          .compareTo(DateTime.parse(b['analytics_date'])));

    // Take up to the last 7 days available
    final recentData = sortedData.length > 7
        ? sortedData.sublist(sortedData.length - 7)
        : sortedData;

    if (recentData.isEmpty) return LineChartData();

    final List<FlSpot> sessionSpots = [];
    final List<FlSpot> bestScoreSpots = [];
    final List<FlSpot> avgScoreSpots = [];

    double maxY = 0;

    for (int i = 0; i < recentData.length; i++) {
      final row = recentData[i];
      final x = i.toDouble();
      final sessions = (row['session_count'] ?? 0).toDouble();
      final best = (row['best_score'] ?? 0).toDouble();
      final avg = (row['avg_score'] ?? 0).toDouble();

      if (sessions > maxY) maxY = sessions;
      if (best > maxY) maxY = best;
      if (avg > maxY) maxY = avg;

      sessionSpots.add(FlSpot(x, sessions));
      bestScoreSpots.add(FlSpot(x, best));
      avgScoreSpots.add(FlSpot(x, avg));
    }

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < recentData.length) {
                final dtString = recentData[index]['analytics_date'] as String;
                final dt = DateTime.parse(dtString);
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(DateFormat('MM/dd').format(dt),
                      style: const TextStyle(fontSize: 10)),
                );
              }
              return const Text('');
            },
            interval: 1,
            reservedSize: 22,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (recentData.length - 1).toDouble(),
      minY: 0,
      maxY: maxY + (maxY * 0.2), // Add 20% headroom
      lineBarsData: [
        // Play Frequency (Sessions)
        LineChartBarData(
          spots: sessionSpots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
        ),
        // Cognitive Trend (Best Score)
        LineChartBarData(
          spots: bestScoreSpots,
          isCurved: true,
          color: Colors.green,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
        ),
        // Adherence Trend (Avg Score)
        LineChartBarData(
          spots: avgScoreSpots,
          isCurved: true,
          color: Colors.orange,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
        ),
      ],
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }
}
