// lib/features/caregiver/presentation/screens/analytics/analytics_dashboard_screen.dart
//
// Premium redesign — matches the MemoCare dark-teal design language.
// All chart/stat sub-widgets are inlined here; extract them to separate files
// when ready (the old widget files can be deleted).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memocare/features/caregiver/presentation/screens/analytics/models/analytics_stats.dart';
import 'package:memocare/features/caregiver/presentation/screens/analytics/viewmodels/analytics_viewmodel.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFFF4F7F9);
  static const card = Color(0xFFFFFFFF);
  static const teal900 = Color(0xFF003D36);
  static const teal700 = Color(0xFF00695C);
  static const teal500 = Color(0xFF00897B);
  static const teal200 = Color(0xFF80CBC4);
  static const teal50 = Color(0xFFE0F2F1);
  static const coral = Color(0xFFFF5252);
  static const amber = Color(0xFFFFB300);
  static const violet = Color(0xFF7C3AED);
  static const green = Color(0xFF43A047);
  static const ink900 = Color(0xFF0D1B1E);
  static const ink600 = Color(0xFF455A64);
  static const ink400 = Color(0xFF8A9EA2);
  static const ink200 = Color(0xFFCFD8DC);

  static const double r = 20.0;
  static const double rSm = 14.0;

  static BoxDecoration card20 = BoxDecoration(
    color: card,
    borderRadius: BorderRadius.circular(r),
    boxShadow: [
      BoxShadow(
        color: ink900.withOpacity(0.055),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsProvider);
    final vm = ref.read(analyticsProvider.notifier);
    final stats = state.stats;

    return Scaffold(
      backgroundColor: _C.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: _C.card,
            elevation: 0,
            shadowColor: _C.ink900.withOpacity(0.08),
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _C.ink900, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Analytics',
              style: TextStyle(
                color: _C.ink900,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: state.isLoading
                      ? const SizedBox(
                          key: ValueKey('loader'),
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _C.teal700),
                        )
                      : const Icon(Icons.refresh_rounded,
                          key: ValueKey('icon'), color: _C.teal700, size: 22),
                ),
                onPressed: state.isLoading ? null : vm.loadData,
              ),
            ],
          ),

          // ── Body ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: state.isLoading && stats == AnalyticsStats.empty
                ? const _FullLoader()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Error banner
                        if (state.error != null) ...[
                          _ErrorBanner(message: state.error!),
                          const SizedBox(height: 16),
                        ],

                        // Time range chips
                        _TimeRangeRow(
                          selected: state.selectedRange,
                          onSelect: vm.setTimeRange,
                        ),
                        const SizedBox(height: 20),

                        // ── Overview stat cards ───────────────────────────
                        _sectionLabel('Overview'),
                        const SizedBox(height: 14),
                        _OverviewGrid(stats: stats),
                        const SizedBox(height: 28),

                        // ── Insights ──────────────────────────────────────
                        if (stats.insights.isNotEmpty) ...[
                          _sectionLabel('Smart Insights'),
                          const SizedBox(height: 14),
                          ...stats.insights
                              .map((i) => _InsightCard(insight: i)),
                          const SizedBox(height: 20),
                        ],

                        // ── Reminder adherence ────────────────────────────
                        _sectionLabel('Reminder Performance'),
                        const SizedBox(height: 14),
                        _AdherenceCard(stats: stats),
                        const SizedBox(height: 20),

                        // ── Cognitive / games ─────────────────────────────
                        _sectionLabel('Cognitive Engagement'),
                        const SizedBox(height: 14),
                        _CognitiveCard(stats: stats),
                        const SizedBox(height: 20),

                        // ── Safety breaches ───────────────────────────────
                        _sectionLabel('Safety Zone Monitoring'),
                        const SizedBox(height: 14),
                        _SafetyCard(stats: stats),
                        const SizedBox(height: 20),

                        // ── Memory journal ────────────────────────────────
                        _sectionLabel('Memory Journal'),
                        const SizedBox(height: 14),
                        _JournalCard(stats: stats),
                        const SizedBox(height: 20),

                        // ── Suggestions ───────────────────────────────────
                        if (stats.suggestions.isNotEmpty) ...[
                          _sectionLabel('Recommended Actions'),
                          const SizedBox(height: 14),
                          ...stats.suggestions
                              .map((s) => _SuggestionTile(text: s)),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: _C.ink900,
          letterSpacing: -0.2,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Time range row
// ─────────────────────────────────────────────────────────────────────────────
class _TimeRangeRow extends StatelessWidget {
  const _TimeRangeRow({required this.selected, required this.onSelect});
  final TimeRange selected;
  final void Function(TimeRange) onSelect;

  static const _labels = {
    TimeRange.thisWeek: 'This Week',
    TimeRange.lastWeek: 'Last Week',
    TimeRange.thisMonth: 'This Month',
    TimeRange.last3Months: '3 Months',
  };

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: TimeRange.values.map((r) {
            final on = r == selected;
            return GestureDetector(
              onTap: () => onSelect(r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: on ? _C.teal700 : _C.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: on ? _C.teal700 : _C.ink200,
                    width: on ? 0 : 1,
                  ),
                  boxShadow: on
                      ? [
                          BoxShadow(
                              color: _C.teal700.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3))
                        ]
                      : null,
                ),
                child: Text(
                  _labels[r]!,
                  style: TextStyle(
                    color: on ? Colors.white : _C.ink600,
                    fontSize: 13,
                    fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Overview grid (4 stat cards)
// ─────────────────────────────────────────────────────────────────────────────
class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.stats});
  final AnalyticsStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(
        label: 'Adherence',
        value: '${stats.reminderAdherencePercent}%',
        icon: Icons.check_circle_outline_rounded,
        color: _C.teal700,
        bg: _C.teal50,
        trend: stats.reminderAdherencePercent >= 80 ? 1 : -1,
      ),
      _StatItem(
        label: 'Missed',
        value: '${stats.remindersMissedCount}',
        icon: Icons.notifications_off_outlined,
        color: _C.amber,
        bg: const Color(0xFFFFF8E1),
        trend: stats.remindersMissedCount == 0 ? 0 : -1,
      ),
      _StatItem(
        label: 'Games',
        value: '${stats.gamesScore}',
        icon: Icons.videogame_asset_rounded,
        color: _C.violet,
        bg: const Color(0xFFF3E8FF),
        trend: stats.gamesScore >= 5 ? 1 : 0,
      ),
      _StatItem(
        label: 'Breaches',
        value: '${stats.safeZoneBreaches}',
        icon: Icons.location_off_rounded,
        color: _C.coral,
        bg: const Color(0xFFFFEBEE),
        trend: stats.safeZoneBreaches == 0 ? 1 : -1,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: items.map((i) => _StatCard(item: i)).toList(),
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
    required this.trend, // 1 = up good, -1 = bad, 0 = neutral
  });
  final String label, value;
  final IconData icon;
  final Color color, bg;
  final int trend;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});
  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    final trendIcon = item.trend > 0
        ? Icons.trending_up_rounded
        : item.trend < 0
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded;
    final trendColor = item.trend > 0
        ? _C.green
        : item.trend < 0
            ? _C.coral
            : _C.ink400;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _C.card20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: item.bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(item.icon, color: item.color, size: 17),
            ),
            const Spacer(),
            Icon(trendIcon, color: trendColor, size: 16),
          ]),
          const Spacer(),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: item.color,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            item.label,
            style: const TextStyle(
                fontSize: 10, color: _C.ink400, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Insight card
// ─────────────────────────────────────────────────────────────────────────────
class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});
  final AnalyticsInsight insight;

  @override
  Widget build(BuildContext context) {
    final (bg, border, icon, iconColor) = switch (insight.type) {
      InsightType.positive => (
          const Color(0xFFE8F5E9),
          const Color(0xFFA5D6A7),
          Icons.check_circle_rounded,
          _C.green,
        ),
      InsightType.warning => (
          const Color(0xFFFFF3E0),
          const Color(0xFFFFCC02),
          Icons.warning_amber_rounded,
          _C.amber,
        ),
      InsightType.neutral => (
          _C.teal50,
          _C.teal200,
          Icons.info_outline_rounded,
          _C.teal500,
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_C.rSm),
        border: Border.all(color: border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(insight.text,
              style:
                  const TextStyle(fontSize: 13, color: _C.ink900, height: 1.4)),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Adherence card
// ─────────────────────────────────────────────────────────────────────────────
class _AdherenceCard extends StatelessWidget {
  const _AdherenceCard({required this.stats});
  final AnalyticsStats stats;

  @override
  Widget build(BuildContext context) {
    final pct = stats.reminderAdherencePercent / 100.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _C.card20,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Big ring + bar chart side-by-side
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // Ring
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: _RingPainter(value: pct, color: _C.teal700),
              child: Center(
                child: Text(
                  '${stats.reminderAdherencePercent}%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _C.teal900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MiniStat(
                    label: 'Completed',
                    value: '${stats.completedReminders}',
                    color: _C.teal700),
                const SizedBox(height: 8),
                _MiniStat(
                    label: 'Missed',
                    value: '${stats.missedReminders}',
                    color: _C.coral),
                const SizedBox(height: 8),
                _MiniStat(
                    label: 'Voice played',
                    value: '${stats.voiceRemindersPlayed}',
                    color: _C.violet),
              ],
            ),
          ),
        ]),

        const SizedBox(height: 20),
        const Text('Daily adherence this week',
            style: TextStyle(
                fontSize: 12, color: _C.ink400, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        _BarChart(
          values: stats.weeklyAdherence.map((v) => v / 100.0).toList(),
          color: _C.teal700,
          labels: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cognitive card
// ─────────────────────────────────────────────────────────────────────────────
class _CognitiveCard extends StatelessWidget {
  const _CognitiveCard({required this.stats});
  final AnalyticsStats stats;

  @override
  Widget build(BuildContext context) {
    final maxSessions = stats.dailyGameSessions.isEmpty
        ? 1
        : stats.dailyGameSessions
            .reduce(math.max)
            .toDouble()
            .clamp(1, double.infinity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _C.card20,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.videogame_asset_rounded,
                color: _C.violet, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${stats.gamesScore}',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _C.violet,
                    letterSpacing: -0.5)),
            const Text('Games this week',
                style: TextStyle(fontSize: 12, color: _C.ink400)),
          ]),
        ]),
        const SizedBox(height: 20),
        const Text('Sessions per day',
            style: TextStyle(
                fontSize: 12, color: _C.ink400, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        _BarChart(
          values: stats.dailyGameSessions.map((v) => v / maxSessions).toList(),
          color: _C.violet,
          labels: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Safety card
// ─────────────────────────────────────────────────────────────────────────────
class _SafetyCard extends StatelessWidget {
  const _SafetyCard({required this.stats});
  final AnalyticsStats stats;

  @override
  Widget build(BuildContext context) {
    final safe = stats.safeZoneBreaches == 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _C.card20,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: safe ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              safe ? Icons.shield_rounded : Icons.location_off_rounded,
              color: safe ? _C.green : _C.coral,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              safe ? 'All Clear' : '${stats.safeZoneBreaches} Breach(es)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: safe ? _C.green : _C.coral,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              safe ? 'No breaches this week' : 'Patient left safe zone',
              style: const TextStyle(fontSize: 12, color: _C.ink400),
            ),
          ]),
        ]),
        const SizedBox(height: 20),
        const Text('Daily breaches',
            style: TextStyle(
                fontSize: 12, color: _C.ink400, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        _BarChart(
          values: stats.weeklyBreaches
              .map((v) => v.toDouble().clamp(0.0, 1.0))
              .toList(),
          color: safe ? _C.green : _C.coral,
          labels: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Journal card
// ─────────────────────────────────────────────────────────────────────────────
class _JournalCard extends StatelessWidget {
  const _JournalCard({required this.stats});
  final AnalyticsStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFE8EAF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_C.r),
        border: Border.all(color: const Color(0xFFBBDEFB)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.photo_album_rounded, color: Colors.blue, size: 22),
          SizedBox(width: 8),
          Text('Memory Journal',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Colors.blue)),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _JournalStat(
              label: 'Active Days',
              value: '${stats.journalEntryDays}',
              icon: Icons.calendar_today_rounded,
              color: Colors.blue),
          _JournalStat(
              label: 'Photos',
              value: '${stats.journalPhotoCount}',
              icon: Icons.photo_rounded,
              color: const Color(0xFF5C6BC0)),
          _JournalStat(
              label: 'Consistency',
              value: '${stats.journalConsistencyPercent}%',
              icon: Icons.insights_rounded,
              color: const Color(0xFF3949AB)),
        ]),
        const SizedBox(height: 16),
        // Consistency mini-bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: stats.journalConsistencyPercent / 100,
            backgroundColor: Colors.white.withOpacity(0.6),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3949AB)),
            minHeight: 8,
          ),
        ),
      ]),
    );
  }
}

class _JournalStat extends StatelessWidget {
  const _JournalStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.3)),
        Text(label, style: const TextStyle(fontSize: 11, color: _C.ink400)),
      ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Suggestion tile
// ─────────────────────────────────────────────────────────────────────────────
class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(_C.rSm),
          border: Border.all(color: _C.ink200.withOpacity(0.6)),
        ),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: _C.teal50, borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.lightbulb_outline_rounded,
                color: _C.teal700, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, color: _C.ink900, height: 1.4)),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared mini widgets
// ─────────────────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: _C.ink400)),
        const SizedBox(width: 6),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Bar chart (7-day)
// ─────────────────────────────────────────────────────────────────────────────
class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.values, // 0.0–1.0 normalised
    required this.color,
    required this.labels,
  });
  final List<double> values;
  final Color color;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final safe = values.length >= 7
        ? values.sublist(0, 7)
        : [...values, ...List.filled(7 - values.length, 0.0)];

    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final h = (safe[i].clamp(0.0, 1.0) * 60).toDouble();
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 400 + i * 60),
                  curve: Curves.easeOutCubic,
                  height: h == 0 ? 4 : h,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: h == 0 ? _C.ink200 : color.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels.length > i ? labels[i] : '',
                  style: const TextStyle(
                      fontSize: 10,
                      color: _C.ink400,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ring progress painter
// ─────────────────────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 8;
    const sw = 10.0;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..color = const Color(0xFFE0F2F1);
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Error banner
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(_C.rSm),
          border: Border.all(color: _C.coral.withOpacity(0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded, color: _C.coral, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: Color(0xFFB71C1C), fontSize: 13, height: 1.4)),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-screen loader
// ─────────────────────────────────────────────────────────────────────────────
class _FullLoader extends StatelessWidget {
  const _FullLoader();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: const Center(
          child: CircularProgressIndicator(color: _C.teal700, strokeWidth: 2.5),
        ),
      );
}
