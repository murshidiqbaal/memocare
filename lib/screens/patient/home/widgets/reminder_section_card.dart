import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/reminder.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/reminder_card_widget.dart';

/// Enhanced reminder section with primary focus design
///
/// Healthcare-grade improvements:
/// - Fetches "Today's Reminders" directly from HomeViewModel
/// - Soft teal-tinted container for visual anchor
/// - Prominent next reminder time display
/// - Friendly empty-state with supportive messaging
/// - Increased elevation and spacing
/// - Minimum 72px card heights
/// - Strong contrast and readability
class ReminderSectionCard extends ConsumerStatefulWidget {
  final VoidCallback onAddPressed;
  final VoidCallback onViewAllPressed;

  const ReminderSectionCard({
    super.key,
    required this.onAddPressed,
    required this.onViewAllPressed,
  });

  @override
  ConsumerState<ReminderSectionCard> createState() =>
      _ReminderSectionCardState();
}

class _ReminderSectionCardState extends ConsumerState<ReminderSectionCard> {
  bool _isExpanded = false;
  static const int _initialItemCount = 3;

  /// Get the next upcoming reminder
  Reminder? _getNextReminder(List<Reminder> reminders) {
    if (reminders.isEmpty) return null;

    final now = DateTime.now();
    final upcoming = reminders
        .where((r) =>
            r.reminderTime.isAfter(now) && r.status == ReminderStatus.pending)
        .toList()
      ..sort((a, b) => a.reminderTime.compareTo(b.reminderTime));

    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Fetch from HomeViewModel (Single Source of Truth)
    final homeState = ref.watch(homeViewModelProvider);
    final reminders = homeState.todayReminders; // Filtered for Today via getter

    final scale = MediaQuery.of(context).size.width / 475.0;

    // Use reminders directly. VM guarantees these are for today.
    final nextReminder = _getNextReminder(reminders);

    return Container(
      decoration: BoxDecoration(
        // Soft teal tint for visual anchor
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.teal.shade50.withOpacity(0.4),
            Colors.teal.shade50.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(
          color: Colors.teal.shade100,
          width: 2,
        ),
        // Increased elevation
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.12),
            blurRadius: 16 * scale,
            offset: Offset(0, 6 * scale),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and next reminder time
          Padding(
            padding: EdgeInsets.fromLTRB(
                24 * scale, 24 * scale, 16 * scale, 12 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Title - takes available space
                    Expanded(
                      child: Text(
                        "Today's Reminders",
                        style: TextStyle(
                          fontSize: 18 * scale,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Action buttons - compact on small screens
                    Flexible(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Show icon-only buttons on very small screens
                          final showLabels =
                              constraints.maxWidth > (140 * scale);

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Add button
                              _ActionButton(
                                icon: Icons.add_circle_outline,
                                label: showLabels ? 'Add' : null,
                                onPressed: widget.onAddPressed,
                                scale: scale,
                              ),
                              // View All button
                              _ActionButton(
                                icon: Icons.list_alt,
                                label: showLabels ? 'View All' : null,
                                onPressed: widget.onViewAllPressed,
                                scale: scale,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // Progress Indicator
                Builder(builder: (context) {
                  final total = reminders.length;
                  final completed = reminders
                      .where((r) => r.status == ReminderStatus.completed)
                      .length;
                  final progress = total == 0 ? 0.0 : completed / total;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4 * scale),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.teal.shade100,
                          color: Colors.teal,
                          minHeight: 6 * scale,
                        ),
                      ),
                      SizedBox(height: 4 * scale),
                      Text(
                        '$completed of $total completed',
                        style: TextStyle(
                            fontSize: 12 * scale,
                            color: Colors.teal.shade800,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  );
                }),

                // Next reminder time (if exists)
                if (nextReminder != null) ...[
                  SizedBox(height: 12 * scale),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 16 * scale, vertical: 10 * scale),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade600,
                      borderRadius: BorderRadius.circular(16 * scale),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_filled,
                          color: Colors.white,
                          size: 20 * scale,
                        ),
                        SizedBox(width: 8 * scale),
                        Flexible(
                          child: Text(
                            'Next: ${DateFormat('h:mm a').format(nextReminder.reminderTime)}',
                            style: TextStyle(
                              fontSize: 16 * scale,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Reminder list or empty state
          Padding(
            padding: EdgeInsets.fromLTRB(24 * scale, 0, 24 * scale,
                _isExpanded ? 12 * scale : 24 * scale),
            child: Builder(
              builder: (context) {
                if (reminders.isEmpty) {
                  return _buildEmptyState(scale, false);
                }

                return _buildReminderList(context, scale, reminders);
              },
            ),
          ),

          // View More / View Less Toggle
          if (reminders.length > _initialItemCount)
            Padding(
              padding: EdgeInsets.only(bottom: 12 * scale),
              child: Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  icon: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.teal.shade700,
                  ),
                  label: Text(
                    _isExpanded
                        ? 'View Less'
                        : 'View More (${reminders.length - _initialItemCount} more)',
                    style: TextStyle(
                      color: Colors.teal.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 14 * scale,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        horizontal: 16 * scale, vertical: 8 * scale),
                    backgroundColor: Colors.teal.shade50.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20 * scale),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double scale, bool hasReminders) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 40 * scale),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Friendly illustration
          Container(
            padding: EdgeInsets.all(20 * scale),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 64 * scale,
              color: Colors.teal.shade400,
            ),
          ),
          SizedBox(height: 20 * scale),

          // Supportive message
          Text(
            hasReminders ? 'All Caught Up! 🎉' : 'No Reminders',
            style: TextStyle(
              fontSize: 22 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8 * scale),
          Text(
            hasReminders
                ? 'You have no upcoming reminders.\nGreat job!'
                : 'No reminders set for today.\nEnjoy your day!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17 * scale,
              height: 1.4,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderList(
      BuildContext context, double scale, List<Reminder> reminders) {
    final displayedReminders =
        _isExpanded ? reminders : reminders.take(_initialItemCount).toList();

    return Column(
      children: displayedReminders.map((reminder) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12 * scale),
          child: ReminderCard(
            reminder: reminder,
            onToggle: () {
              ref
                  .read(homeViewModelProvider.notifier)
                  .toggleReminder(reminder.id);
            },
          ),
        );
      }).toList(),
    );
  }
}

/// Compact action button for reminder section header
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onPressed;
  final double scale;

  const _ActionButton({
    required this.icon,
    this.label,
    required this.onPressed,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    // Minimum touch target size for accessibility
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12 * scale),
        child: Container(
          constraints:
              BoxConstraints(minHeight: 48 * scale, minWidth: 48 * scale),
          padding: EdgeInsets.symmetric(
            horizontal: (label != null ? 12 : 8) * scale,
            vertical: 8 * scale,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20 * scale,
                color: Colors.teal.shade700,
              ),
              if (label != null) ...[
                SizedBox(width: 6 * scale),
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
