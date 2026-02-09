import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Time Context Header - Provides daily orientation for dementia patients
///
/// Displays:
/// - Dynamic greeting based on time of day
/// - Patient name
/// - Current date and time
///
/// Critical for dementia care: Helps patients orient themselves in time
class TimeContextHeader extends StatelessWidget {
  final String? patientName;

  const TimeContextHeader({
    super.key,
    this.patientName,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _getGreeting();
    final name = patientName ?? 'Friend';
    final dateTime = DateFormat('EEEE, d MMMM • h:mm a').format(now);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Colors.teal.shade100,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting with name
          Text(
            '$greeting, $name',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),

          // Date and time
          Text(
            dateTime,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
