import 'package:memocare/core/services/notification/notification_permission_service.dart';
import 'package:memocare/data/models/reminder.dart';
import 'package:memocare/features/auth/providers/auth_provider.dart';
import 'package:memocare/providers/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// import '../../../../data/models/reminder.dart';
// import '../../../../providers/auth_provider.dart';
// import '../../../../providers/service_providers.dart';
// import '../../../../services/notification/notification_permission_service.dart';
import '../../../../../providers/reminder_providers_enhanced.dart';
import 'widgets/voice_recorder_widget.dart';

class AddEditReminderScreen extends ConsumerStatefulWidget {
  final Reminder? existingReminder;
  final String? targetPatientId;
  final String? initialTitle;
  final ReminderType? initialType;
  final Function(Reminder)? onSave;

  const AddEditReminderScreen({
    super.key,
    this.existingReminder,
    this.targetPatientId,
    this.initialTitle,
    this.initialType,
    this.onSave,
  });

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
  String? _localRecordingPath;
  bool _alarmEnabled = false;

  bool get _hasVoice =>
      (widget.existingReminder?.localAudioPath != null &&
          widget.existingReminder!.localAudioPath!.isNotEmpty) ||
      _localRecordingPath != null ||
      (widget.existingReminder?.voiceAudioUrl != null &&
          widget.existingReminder!.voiceAudioUrl!.isNotEmpty);

  @override
  void initState() {
    super.initState();
    final r = widget.existingReminder;
    _titleController =
        TextEditingController(text: r?.title ?? widget.initialTitle);
    _descController = TextEditingController(text: r?.description);
    _selectedDate = r?.reminderTime ?? DateTime.now();
    _selectedTime = r != null
        ? TimeOfDay(hour: r.reminderTime.hour, minute: r.reminderTime.minute)
        : TimeOfDay.now();
    _frequency = r?.repeatRule ?? ReminderFrequency.once;
    _type = r?.type ?? widget.initialType ?? ReminderType.medication;
    _localRecordingPath = r?.localAudioPath;
    _alarmEnabled = r?.alarmEnabled ?? false;
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

  // ─────────────────────────────────────────────────────────────────────────────
// PATCH: replace _saveReminder() in add_edit_reminder_screen.dart
// Uploads the local voice note to Supabase before saving the Reminder.
// ─────────────────────────────────────────────────────────────────────────────
//
// 1. Add to your service_providers.dart:
//
//   final voiceStorageServiceProvider = Provider<VoiceStorageService>((ref) {
//     return VoiceStorageService(Supabase.instance.client);
//   });
//
// 2. Replace _saveReminder() in _AddEditReminderScreenState with the one below.
// ─────────────────────────────────────────────────────────────────────────────

  Future<void> _saveReminder() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      final permService = NotificationPermissionService();
      final isReady = await permService.ensureNotificationsReady();
      if (!isReady && mounted) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Permission Required'),
            content:
                const Text('Please allow notifications to save reminders.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c), child: const Text('OK')),
            ],
          ),
        );
        return;
      }

      final finalDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final supabase = Supabase.instance.client;

      // 1. Resolve Caregiver Profile ID (caregiver_profiles.id)
      final caregiverRes = await supabase
          .from('caregiver_profiles')
          .select('id')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (caregiverRes == null) {
        throw Exception('Caregiver profile not found');
      }
      final String resolvedCaregiverId = caregiverRes['id'];

      // 2. Resolve Patient ID (patients.id)
      String resolvedPatientId;
      if (widget.targetPatientId != null) {
        resolvedPatientId = widget.targetPatientId!;
      } else if (widget.existingReminder?.patientId != null) {
        resolvedPatientId = widget.existingReminder!.patientId;
      } else {
        // Fallback for patient-owned reminders
        final patientRes = await supabase
            .from('patients')
            .select('id')
            .eq('user_id', currentUser.id)
            .maybeSingle();

        if (patientRes == null) {
          throw Exception('Patient profile not found');
        }
        resolvedPatientId = patientRes['id'];
      }

      print(
          'Resolved IDs for Reminder: Caregiver=$resolvedCaregiverId, Patient=$resolvedPatientId (Auth=${currentUser.id})');

      final int stableNotificationId =
          widget.existingReminder?.notificationId ??
              DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

      final String reminderId =
          widget.existingReminder?.id ?? const Uuid().v4();

      // ── Upload voice note if a new local recording exists ─────────────────
      String? remoteVoiceUrl = widget.existingReminder?.voiceAudioUrl;

      final newLocalPath = _localRecordingPath; // may be null
      final oldLocalPath = widget.existingReminder?.localAudioPath;
      final hasNewRecording =
          newLocalPath != null && newLocalPath != oldLocalPath;

      if (hasNewRecording) {
        // Show a brief loading indicator while uploading
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white)),
                  SizedBox(width: 12),
                  Text('Uploading voice note…'),
                ],
              ),
              duration: Duration(seconds: 10),
            ),
          );
        }

        final voiceService = ref.read(voiceStorageServiceProvider);
        remoteVoiceUrl = await voiceService.uploadVoiceNote(
          localPath: newLocalPath,
          reminderId: reminderId,
          userId: currentUser.id,
        );

        if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
      }
      // ──────────────────────────────────────────────────────────────────────

      final newReminder = Reminder(
        id: reminderId,
        title: _titleController.text,
        description: _descController.text,
        reminderTime: finalDateTime,
        repeatRule: _frequency,
        type: _type,
        localAudioPath:
            _localRecordingPath, // keep local path for offline playback
        voiceAudioUrl: remoteVoiceUrl, // synced remote URL
        patientId: resolvedPatientId,
        caregiverId: resolvedCaregiverId,
        createdAt: widget.existingReminder?.createdAt ?? DateTime.now(),
        status: widget.existingReminder?.status ?? ReminderStatus.pending,
        notificationId: stableNotificationId,
        alarmEnabled: _alarmEnabled,
      );

      try {
        if (widget.onSave != null) {
          widget.onSave!(newReminder);
        } else if (widget.existingReminder != null) {
          await ref
              .read(updateReminderProvider.notifier)
              .updateReminder(newReminder);
        } else {
          await ref.read(createReminderProvider.notifier).createReminder(
              reminder: newReminder, patientId: resolvedPatientId);
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
              onRecordingComplete: (path) =>
                  setState(() => _localRecordingPath = path),
              onDelete: () => setState(() => _localRecordingPath = null),
              existingAudioPath: _localRecordingPath,
            ),

            const SizedBox(height: 16),

            // Alarm Toggle
            SwitchListTile(
              title: const Text("Enable Full Screen Alarm",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Plays a loud alarm for this reminder"),
              value: _alarmEnabled,
              activeColor: Colors.teal,
              onChanged: (value) {
                setState(() {
                  _alarmEnabled = value;
                });
              },
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
