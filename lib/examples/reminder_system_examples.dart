// ============================================================================
// REMINDER SYSTEM - USAGE EXAMPLES
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/models/reminder.dart';
import '../providers/reminder_providers_enhanced.dart';
import '../widgets/reminder_card_state_wrapper.dart';

// ============================================================================
// EXAMPLE 1: Patient Dashboard with Realtime Updates
// ============================================================================

class PatientDashboardExample extends ConsumerWidget {
  const PatientDashboardExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Watch realtime stream - auto-updates when caregiver creates/updates
    final remindersAsync = ref.watch(patientRemindersStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Reminders')),
      body: remindersAsync.when(
        data: (reminders) {
          // Filter today's reminders
          final today = _getTodayReminders(reminders);

          if (today.isEmpty) {
            return const Center(
              child: Text('No reminders for today! 🎉'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: today.length,
            itemBuilder: (context, index) {
              final reminder = today[index];

              // ✅ Use ReminderCardStateWrapper for automatic expired styling
              return ReminderCardStateWrapper(
                reminder: reminder,
                onTap: () => _navigateToDetail(context, reminder),
                builder: (context, isExpired, isDisabled) {
                  return Card(
                    color:
                        isExpired ? Colors.grey.shade200 : Colors.teal.shade50,
                    child: ListTile(
                      leading: Icon(
                        Icons.alarm,
                        color: reminder.statusColor,
                        size: 40,
                      ),
                      title: Text(
                        reminder.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isExpired ? Colors.grey : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat('h:mm a').format(reminder.remindAt),
                        style: TextStyle(
                          color: isExpired ? Colors.grey : Colors.teal,
                        ),
                      ),
                      trailing: ElevatedButton(
                        onPressed: isDisabled
                            ? null
                            : () => _completeReminder(ref, reminder.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Complete'),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading reminders: $error'),
        ),
      ),
    );
  }

  List<Reminder> _getTodayReminders(List<Reminder> reminders) {
    final now = DateTime.now();
    return reminders.where((r) {
      return r.remindAt.year == now.year &&
          r.remindAt.month == now.month &&
          r.remindAt.day == now.day;
    }).toList();
  }

  void _navigateToDetail(BuildContext context, Reminder reminder) {
    // Navigate to detail screen
  }

  Future<void> _completeReminder(WidgetRef ref, String reminderId) async {
    await ref
        .read(completeReminderProvider.notifier)
        .completeReminder(reminderId);
    // UI auto-refreshes via stream!
    // Caregiver sees completion instantly!
  }
}

// ============================================================================
// EXAMPLE 2: Caregiver Reminder Management with Realtime Updates
// ============================================================================

class CaregiverReminderManagementExample extends ConsumerWidget {
  final String selectedPatientId;

  const CaregiverReminderManagementExample({
    super.key,
    required this.selectedPatientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Watch caregiver's linked patient reminders - auto-updates when patient completes
    final remindersAsync = ref.watch(caregiverRemindersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateReminderDialog(context, ref),
          ),
        ],
      ),
      body: remindersAsync.when(
        data: (reminders) {
          // Filter for selected patient
          final patientReminders =
              reminders.where((r) => r.patientId == selectedPatientId).toList();

          if (patientReminders.isEmpty) {
            return const Center(
              child: Text('No reminders for this patient'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: patientReminders.length,
            itemBuilder: (context, index) {
              final reminder = patientReminders[index];

              // ✅ Use ReminderCardStateWrapper
              return ReminderCardStateWrapper(
                reminder: reminder,
                onTap: () => _viewHistory(context, reminder),
                builder: (context, isExpired, isDisabled) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  reminder.title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isExpired
                                        ? Colors.grey
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              // Status badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: reminder.statusColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  reminder.statusLabel,
                                  style: TextStyle(
                                    color: reminder.statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Time: ${DateFormat('MMM d, h:mm a').format(reminder.remindAt)}',
                            style: TextStyle(
                              color: isExpired ? Colors.grey : Colors.teal,
                            ),
                          ),
                          if (reminder.description!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              reminder.description.toString(),
                              style: TextStyle(
                                color: isExpired ? Colors.grey : Colors.black54,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: isDisabled
                                    ? null
                                    : () =>
                                        _editReminder(context, ref, reminder),
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit'),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () =>
                                    _deleteReminder(ref, reminder.id),
                                icon: const Icon(Icons.delete),
                                label: const Text('Delete'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading reminders: $error'),
        ),
      ),
    );
  }

  void _showCreateReminderDialog(BuildContext context, WidgetRef ref) {
    // Show dialog to create reminder
    showDialog(
      context: context,
      builder: (context) => CreateReminderDialog(
        patientId: selectedPatientId,
        onSave: (reminder) async {
          await ref.read(createReminderProvider.notifier).createReminder(
                reminder: reminder,
                patientId: selectedPatientId,
              );
          // UI auto-refreshes via stream!
          // Patient sees it instantly!
        },
      ),
    );
  }

  void _editReminder(BuildContext context, WidgetRef ref, Reminder reminder) {
    // Show edit dialog
  }

  Future<void> _deleteReminder(WidgetRef ref, String reminderId) async {
    await ref.read(deleteReminderProvider.notifier).deleteReminder(reminderId);
    // UI auto-refreshes via stream!
  }

  void _viewHistory(BuildContext context, Reminder reminder) {
    // Navigate to history screen
  }
}

// ============================================================================
// EXAMPLE 3: Create Reminder Dialog
// ============================================================================

class CreateReminderDialog extends StatefulWidget {
  final String patientId;
  final Function(Reminder) onSave;

  const CreateReminderDialog({
    super.key,
    required this.patientId,
    required this.onSave,
  });

  @override
  State<CreateReminderDialog> createState() => _CreateReminderDialogState();
}

class _CreateReminderDialogState extends State<CreateReminderDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  ReminderFrequency _selectedRepeatRule = ReminderFrequency.once;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Reminder'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., Take Medicine',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Time'),
              subtitle:
                  Text(DateFormat('MMM d, h:mm a').format(_selectedDateTime)),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selectDateTime(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ReminderFrequency>(
              initialValue: _selectedRepeatRule,
              decoration: const InputDecoration(
                labelText: 'Repeat',
              ),
              items: const [
                DropdownMenuItem(
                  value: ReminderFrequency.once,
                  child: Text('Once'),
                ),
                DropdownMenuItem(
                  value: ReminderFrequency.daily,
                  child: Text('Daily'),
                ),
                DropdownMenuItem(
                  value: ReminderFrequency.weekly,
                  child: Text('Weekly'),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedRepeatRule = value!);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _save() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final reminder = Reminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: widget.patientId,
      title: _titleController.text,
      description: _descriptionController.text,
      remindAt: _selectedDateTime,
      repeatRule: _selectedRepeatRule,
      status: ReminderStatus.pending,
      type: ReminderType.medication, // or other type
      completionHistory: [],
      isSynced: false,
      notificationId:
          DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      createdAt: DateTime.now(),
    );

    widget.onSave(reminder);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

// ============================================================================
// EXAMPLE 4: Using Extension Methods
// ============================================================================

class ReminderStatusExample extends StatelessWidget {
  final Reminder reminder;

  const ReminderStatusExample({super.key, required this.reminder});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // ✅ Use statusColor extension
        color: reminder.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // ✅ Use statusLabel extension
          Text(
            reminder.statusLabel,
            style: TextStyle(
              color: reminder.statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // ✅ Use isExpired extension
          if (reminder.isExpired)
            const Text(
              'This reminder was missed',
              style: TextStyle(color: Colors.red),
            ),
          // ✅ Use isMissed extension
          if (reminder.isMissed) const Icon(Icons.error, color: Colors.red),
        ],
      ),
    );
  }
}
