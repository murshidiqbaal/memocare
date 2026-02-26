import 'package:flutter/material.dart';

import '../../../../../data/models/game_analytics_summary.dart';

/// Weekly Analytics Card
/// Shows key metrics and AI-generated insights
class WeeklyAnalyticsCard extends StatelessWidget {
  final double adherencePercentage;
  final GameAnalyticsSummary gameStats;
  final double journalConsistency;
  final int safeZoneBreaches;
  final String insightMessage;
  final VoidCallback onViewFullAnalytics;

  const WeeklyAnalyticsCard({
    super.key,
    required this.adherencePercentage,
    required this.gameStats,
    required this.journalConsistency,
    required this.safeZoneBreaches,
    required this.insightMessage,
    required this.onViewFullAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics,
                      color: Colors.purple.shade600, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Weekly Analytics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: onViewFullAnalytics,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Full Report'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.purple.shade700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Metrics grid
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Adherence',
                  value: '${adherencePercentage.toStringAsFixed(0)}%',
                  icon: Icons.medication,
                  color: _getAdherenceColor(adherencePercentage),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Games',
                  value: gameStats.gamesPlayedThisWeek.toString(),
                  icon: Icons.games,
                  color: Colors.purple,
                  trend: gameStats.engagementTrend,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Avg Score',
                  value: gameStats.avgScoreThisWeek.toStringAsFixed(0),
                  icon: Icons.score,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Play Time',
                  value: gameStats.formattedPlayTime,
                  icon: Icons.timer,
                  color: Colors.teal,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Journal',
                  value: '${(journalConsistency * 100).toStringAsFixed(0)}%',
                  icon: Icons.book,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Breaches',
                  value: safeZoneBreaches.toString(),
                  icon: Icons.warning,
                  color: safeZoneBreaches > 0 ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // AI Insight
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade50, Colors.blue.shade50],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.shade200, width: 2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb, color: Colors.purple.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Insight',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        insightMessage,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAdherenceColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    IconData? trendIcon;
    Color? trendColor;
    if (trend == 'up') {
      trendIcon = Icons.arrow_upward;
      trendColor = Colors.green;
    } else if (trend == 'down') {
      trendIcon = Icons.arrow_downward;
      trendColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              if (trendIcon != null) ...[
                const SizedBox(width: 4),
                Icon(trendIcon, color: trendColor, size: 14),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
