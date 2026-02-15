import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/caregiver_patient_link.dart';
import '../../../../../data/models/reminder.dart';

/// Patient Overview Card
/// Shows patient status, next reminder, and quick actions
class PatientOverviewCard extends StatelessWidget {
  final CaregiverPatientLink patient;
  final bool isInSafeZone;
  final Reminder? nextReminder;
  final DateTime? lastActivity;
  final VoidCallback onCallPressed;
  final VoidCallback onLocationPressed;

  const PatientOverviewCard({
    super.key,
    required this.patient,
    required this.isInSafeZone,
    this.nextReminder,
    this.lastActivity,
    required this.onCallPressed,
    required this.onLocationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.teal.shade50,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.teal.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient info row
          Row(
            children: [
              // Patient photo
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundImage: patient.patientPhotoUrl != null
                      ? NetworkImage(patient.patientPhotoUrl!)
                      : null,
                  child: patient.patientPhotoUrl == null
                      ? Text(
                          (patient.patientName ?? 'Patient')[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              // Patient name and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.patientName ?? 'Patient',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Safe zone status
                    Row(
                      children: [
                        Icon(
                          isInSafeZone ? Icons.check_circle : Icons.warning,
                          size: 18,
                          color: isInSafeZone ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isInSafeZone
                              ? 'Inside Safe Zone'
                              : 'Outside Safe Zone',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isInSafeZone
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Next reminder
          if (nextReminder != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.alarm, color: Colors.orange.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Next Reminder',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nextReminder!.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatTime(nextReminder!.remindAt),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.green.shade600, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'No upcoming reminders',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Last activity
          if (lastActivity != null)
            Text(
              'Last active: ${_formatLastActivity(lastActivity!)}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),

          const SizedBox(height: 16),

          // Quick actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onCallPressed,
                  icon: const Icon(Icons.phone, size: 20),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onLocationPressed,
                  icon: const Icon(Icons.location_on, size: 20),
                  label: const Text('Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final timeDate = DateTime(time.year, time.month, time.day);

    String prefix;
    if (timeDate == today) {
      prefix = 'Today';
    } else if (timeDate == tomorrow) {
      prefix = 'Tomorrow';
    } else {
      prefix = DateFormat('MMM d').format(time);
    }

    return '$prefix at ${DateFormat('h:mm a').format(time)}';
  }

  String _formatLastActivity(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
