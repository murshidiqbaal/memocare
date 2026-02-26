import 'package:flutter/material.dart';
import '../data/models/reminder.dart';

/// Reusable wrapper that automatically handles expired reminder styling
/// across the entire app (Patient dashboard, Reminder list, Caregiver view)
///
/// UX Rules:
/// - If remind_at < current_time AND status != completed:
///   → Grey card, reduced opacity, disabled interactions, "Missed" label
/// - Else:
///   → Normal colorful card, active buttons
class ReminderCardStateWrapper extends StatelessWidget {
  final Reminder reminder;
  final Widget Function(BuildContext context, bool isExpired, bool isDisabled)
      builder;
  final VoidCallback? onTap;

  const ReminderCardStateWrapper({
    super.key,
    required this.reminder,
    required this.builder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isExpired = reminder.reminderTime.isBefore(now) &&
        reminder.status != ReminderStatus.completed;
    final isDisabled = isExpired;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isExpired ? 0.5 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: isExpired ? Colors.grey.shade200 : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              builder(context, isExpired, isDisabled),
              if (isExpired)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Text(
                      'Missed',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extension to easily check if a reminder is expired
extension ReminderExpiredExtension on Reminder {
  bool get isExpired {
    final now = DateTime.now();
    return reminderTime.isBefore(now) && status != ReminderStatus.completed;
  }

  bool get isMissed => isExpired;

  Color get statusColor {
    if (status == ReminderStatus.completed) {
      return Colors.green;
    } else if (isExpired) {
      return Colors.grey;
    } else {
      return Colors.teal;
    }
  }

  String get statusLabel {
    if (status == ReminderStatus.completed) {
      return 'Completed';
    } else if (isExpired) {
      return 'Missed';
    } else {
      return 'Active';
    }
  }
}
