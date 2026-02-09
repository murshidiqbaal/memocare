import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/reminder.dart';
import '../widgets/reminder_card_widget.dart';

/// Enhanced reminder section with primary focus design
///
/// Healthcare-grade improvements:
/// - Soft teal-tinted container for visual anchor
/// - Prominent next reminder time display
/// - Friendly empty-state with supportive messaging
/// - Increased elevation and spacing
/// - Minimum 72px card heights
/// - Strong contrast and readability
class ReminderSectionCard extends StatelessWidget {
  final List<Reminder> reminders;
  final VoidCallback onAddPressed;
  final VoidCallback onViewAllPressed;
  final Function(String) onToggleReminder;

  const ReminderSectionCard({
    super.key,
    required this.reminders,
    required this.onAddPressed,
    required this.onViewAllPressed,
    required this.onToggleReminder,
  });

  /// Get the next upcoming reminder
  Reminder? get _nextReminder {
    if (reminders.isEmpty) return null;

    final now = DateTime.now();
    final upcoming = reminders
        .where((r) =>
            r.remindAt.isAfter(now) && r.status == ReminderStatus.pending)
        .toList()
      ..sort((a, b) => a.remindAt.compareTo(b.remindAt));

    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final nextReminder = _nextReminder;

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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.teal.shade100,
          width: 2,
        ),
        // Increased elevation
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and next reminder time
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Title - takes available space
                    const Expanded(
                      child: Text(
                        "Today's Reminders",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),

                    // Action buttons - compact on small screens
                    Flexible(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Show icon-only buttons on very small screens
                          final showLabels = constraints.maxWidth > 140;

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Add button
                              _ActionButton(
                                icon: Icons.add_circle_outline,
                                label: showLabels ? 'Add' : null,
                                onPressed: onAddPressed,
                              ),
                              const SizedBox(width: 4),
                              // View All button
                              _ActionButton(
                                icon: Icons.list_alt,
                                label: showLabels ? 'View All' : null,
                                onPressed: onViewAllPressed,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // Next reminder time (if exists)
                if (nextReminder != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade600,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_filled,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Next: ${DateFormat('h:mm a').format(nextReminder.remindAt)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child:
                reminders.isEmpty ? _buildEmptyState() : _buildReminderList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Friendly illustration
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.teal.shade400,
            ),
          ),
          const SizedBox(height: 20),

          // Supportive message
          const Text(
            'All Caught Up! 🎉',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No reminders for today.\nYou\'re doing great!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              height: 1.4,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderList() {
    return Column(
      children: reminders.map((reminder) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ReminderCard(
            reminder: reminder,
            onToggle: () => onToggleReminder(reminder.id),
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

  const _ActionButton({
    required this.icon,
    this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Minimum touch target size for accessibility
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          padding: EdgeInsets.symmetric(
            horizontal: label != null ? 12 : 8,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: Colors.teal.shade700,
              ),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 15,
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
