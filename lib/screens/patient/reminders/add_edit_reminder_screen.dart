import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/models/reminder.dart';
import '../../../../providers/auth_provider.dart';
import '../home/viewmodels/home_viewmodel.dart';
import 'widgets/voice_recorder_widget.dart';

class AddEditReminderScreen extends ConsumerStatefulWidget {
  final Reminder? existingReminder;
  final String? targetPatientId;
  final Function(Reminder)? onSave;

  const AddEditReminderScreen(
      {super.key, this.existingReminder, this.targetPatientId, this.onSave});

  @override
  ConsumerState<AddEditReminderScreen> createState() =>
      _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends ConsumerState<AddEditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  ReminderFrequency _frequency = ReminderFrequency.once;
  ReminderType _type = ReminderType.medication;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    final r = widget.existingReminder;
    _titleController = TextEditingController(text: r?.title);
    _descController = TextEditingController(text: r?.description);
    _selectedDate = r?.remindAt ?? DateTime.now();
    _selectedTime = r != null
        ? TimeOfDay(hour: r.remindAt.hour, minute: r.remindAt.minute)
        : TimeOfDay.now();
    _frequency = r?.repeatRule ?? ReminderFrequency.once;
    _type = r?.type ?? ReminderType.medication;
    _audioPath =
        r?.localAudioPath; // Use local path if editing locally created reminder
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveReminder() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus(); // Close keyboard

      final finalDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // We might need to handle User object properly.
      // Assuming currentUserProvider returns a Supabase User object which has an 'id'.
      final currentUser = ref.read(currentUserProvider);
      final currentUserId = currentUser?.id ?? 'offline_user';

      final effectivePatientId = widget.targetPatientId ??
          widget.existingReminder?.patientId ??
          currentUserId;

      // Generate stable notification ID
      final int stableNotificationId =
          widget.existingReminder?.notificationId ??
              DateTime.now()
                  .millisecondsSinceEpoch
                  .remainder(2147483647); // Ensure positive int32 for safety

      final newReminder = Reminder(
        id: widget.existingReminder?.id ?? const Uuid().v4(),
        title: _titleController.text,
        description: _descController.text,
        remindAt: finalDateTime,
        repeatRule: _frequency,
        type: _type,
        localAudioPath: _audioPath,
        patientId: effectivePatientId,
        createdBy: currentUserId,
        createdAt: widget.existingReminder?.createdAt ?? DateTime.now(),
        // If editing, preserve status, else pending
        status: widget.existingReminder?.status ?? ReminderStatus.pending,
        voiceAudioUrl: widget
            .existingReminder?.voiceAudioUrl, // preserve remote URL if exists
        notificationId: stableNotificationId,
      );

      try {
        if (widget.onSave != null) {
          widget.onSave!(newReminder);
        } else if (widget.existingReminder != null) {
          await ref
              .read(homeViewModelProvider.notifier)
              .updateReminder(newReminder);
        } else {
          await ref
              .read(homeViewModelProvider.notifier)
              .addReminder(newReminder);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reminder saved successfully'),
              backgroundColor: Colors.teal,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save reminder: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existingReminder == null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isNew ? 'Create Reminder' : 'Edit Reminder'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Reminder Title',
                hintText: 'E.g., Take Heart Medicine',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Type Dropdown (Replaces Priority)
            DropdownButtonFormField<ReminderType>(
              initialValue: _type,
              decoration: InputDecoration(
                labelText: 'Type',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              items: ReminderType.values.map((t) {
                String label = t.toString().split('.').last;
                label = label[0].toUpperCase() + label.substring(1);
                return DropdownMenuItem(value: t, child: Text(label));
              }).toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 24),

            // Date & Time Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Date',
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Time',
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            _selectedTime.format(context),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Frequency
            DropdownButtonFormField<ReminderFrequency>(
              initialValue: _frequency,
              decoration: InputDecoration(
                labelText: 'Repeat',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              items: ReminderFrequency.values.map((f) {
                String label = f.toString().split('.').last;
                label = label[0].toUpperCase() + label.substring(1);
                return DropdownMenuItem(value: f, child: Text(label));
              }).toList(),
              onChanged: (v) => setState(() => _frequency = v!),
            ),
            const SizedBox(height: 24),

            // Voice Recorder
            VoiceRecorderWidget(
              onRecordingComplete: (path) => setState(() => _audioPath = path),
              onDelete: () => setState(() => _audioPath = null),
              existingAudioPath: _audioPath,
            ),

            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveReminder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: const Text('Save Reminder',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
