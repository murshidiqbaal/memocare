import 'package:dementia_care_app/screens/caregiver/analytics/models/analytics_stats.dart';
import 'package:dementia_care_app/screens/caregiver/analytics/viewmodels/analytics_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/adherence_bar_chart.dart';
import 'widgets/adherence_pie_chart.dart';
import 'widgets/game_engagement_chart.dart';
import 'widgets/insight_card.dart';
import 'widgets/safety_breach_chart.dart';
import 'widgets/stat_card.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsProvider);
    final viewModel = ref.read(analyticsProvider.notifier);
    final stats = state.stats;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Caregiver Analytics'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => viewModel.loadData(),
          )
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time Filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: TimeRange.values.map((range) {
                        final isSelected = state.selectedRange == range;
                        String label = range.toString().split('.').last;
                        // Format Label "thisWeek" -> "This Week"
                        label = label.replaceFirstMapped(
                            RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}');
                        label = label[0].toUpperCase() + label.substring(1);

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: isSelected,
                            onSelected: (_) => viewModel.setTimeRange(range),
                            selectedColor: Colors.teal.shade100,
                            labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.teal.shade900
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Overview Cards Grid
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.4,
                    children: [
                      AnalyticsStatCard(
                        label: 'Adherence',
                        value: '${stats.reminderAdherencePercent}%',
                        icon: Icons.check_circle_outline,
                        color: Colors.teal,
                        trend: stats.reminderAdherencePercent >= 80
                            ? 'up'
                            : 'down',
                      ),
                      AnalyticsStatCard(
                        label: 'Missed',
                        value: '${stats.remindersMissedCount}',
                        icon: Icons.warning_amber,
                        color: Colors.orange,
                        trend: stats.remindersMissedCount == 0 ? 'flat' : 'up',
                      ),
                      AnalyticsStatCard(
                        label: 'Games Score',
                        value: '${stats.gamesScore}',
                        icon: Icons.videogame_asset,
                        color: Colors.purple,
                        trend: 'up',
                      ),
                      AnalyticsStatCard(
                        label: 'Breaches',
                        value: '${stats.safeZoneBreaches}',
                        icon: Icons.location_off,
                        color: Colors.red,
                        trend: stats.safeZoneBreaches == 0 ? 'flat' : 'down',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Insights Section
                  if (stats.insights.isNotEmpty) ...[
                    const Text('Smart Insights',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...stats.insights
                        .map((i) => InsightCard(text: i.text, type: i.type)),
                    const SizedBox(height: 24),
                  ],

                  // REMINDERS
                  const Text('Reminder Performance',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  AdherenceBarChart(
                      weeklyData: stats.weeklyAdherence
                          .map((e) => e.toDouble())
                          .toList()),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: AdherencePieChart(
                              completed: stats.completedReminders,
                              missed: stats.missedReminders)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                      child: Text(
                          'Voice Reminders Played: ${stats.voiceRemindersPlayed}',
                          style: TextStyle(color: Colors.grey.shade600))),

                  const SizedBox(height: 24),

                  // Cognitive & Safety
                  Row(
                    children: [
                      Expanded(
                          child: GameEngagementChart(
                              dailySessions: stats.dailyGameSessions)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: SafetyBreachChart(
                              weeklyBreaches: stats.weeklyBreaches)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Memory Journal
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.photo_album, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Memory Journal',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blue)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMiniStat(
                                'Active Days', '${stats.journalEntryDays}'),
                            _buildMiniStat(
                                'Photos', '${stats.journalPhotoCount}'),
                            _buildMiniStat('Consistency',
                                '${stats.journalConsistencyPercent}%'),
                          ],
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Suggestions
                  if (stats.suggestions.isNotEmpty) ...[
                    const Text('Recommended Actions',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...stats.suggestions.map((s) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200)),
                          child: Row(
                            children: [
                              const Icon(Icons.lightbulb_outline,
                                  color: Colors.teal),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(s,
                                      style: const TextStyle(fontSize: 14))),
                            ],
                          ),
                        )),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}
