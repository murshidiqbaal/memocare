import 'package:flutter/material.dart';
import '../../../../data/models/reminder.dart';
import 'package:intl/intl.dart';

class ReminderHistoryScreen extends StatelessWidget {
  final Reminder reminder;

  const ReminderHistoryScreen({super.key, required this.reminder});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Reminder History'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            const Text('Activity Log',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications,
                    color: Colors.teal, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${reminder.frequency.name.toUpperCase()} • ${DateFormat('h:mm a').format(reminder.time)}",
                      style: TextStyle(color: Colors.teal.shade800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Snoozes', '${reminder.snoozeCount}', Icons.snooze),
              _buildStat(
                  'Missed', '${reminder.missedLogs.length}', Icons.event_busy),
              _buildStat(
                'Status',
                reminder.isCompleted ? 'Done' : 'Pending',
                reminder.isCompleted
                    ? Icons.check_circle
                    : Icons.hourglass_empty,
                color: reminder.isCompleted ? Colors.green : Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.grey.shade600),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTimeline() {
    final List<Widget> events = [];

    // Add Completion
    if (reminder.completedAt != null) {
      events.add(_buildTimelineItem(
        'Completed',
        reminder.completedAt!,
        Icons.check_circle,
        Colors.green,
      ));
    }

    // Add Missed Logs
    for (var date in reminder.missedLogs) {
      events.add(_buildTimelineItem(
        'Missed',
        date,
        Icons.warning,
        Colors.red,
      ));
    }

    // Add Creation (mock)
    events.add(_buildTimelineItem(
      'Created',
      reminder.time.subtract(const Duration(days: 1)), // Mock creation time
      Icons.add_circle,
      Colors.blue,
      isLast: true,
    ));

    return Column(children: events);
  }

  Widget _buildTimelineItem(
      String title, DateTime time, IconData icon, Color color,
      {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(
              DateFormat('MMM d, y • h:mm a').format(time),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ],
    );
  }
}
