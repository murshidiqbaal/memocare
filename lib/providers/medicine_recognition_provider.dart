// // lib/features/medicine_recognition/providers/medicine_recognition_provider.dart

// import 'dart:io';

// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:uuid/uuid.dart';

// import '../features/medicine/models/medicine_models.dart';
// import '../features/medicine/services/medicine_recognition_service.dart';

// // ---------------------------------------------------------------------------
// // Configuration – swap with your actual env/config injection
// // ---------------------------------------------------------------------------

// const String _geminiApiKey = String.fromEnvironment(
//   'GEMINI_API_KEY',
//   defaultValue: 'YOUR_GEMINI_API_KEY_HERE',
// );

// // ---------------------------------------------------------------------------
// // Service providers
// // ---------------------------------------------------------------------------

// final medicineRecognitionServiceProvider =
//     Provider<MedicineRecognitionService>((ref) {
//   return MedicineRecognitionService(geminiApiKey: _geminiApiKey);
// });

// final supabaseClientProvider = Provider<SupabaseClient>((ref) {
//   return Supabase.instance.client;
// });

// // ---------------------------------------------------------------------------
// // Medicine scan state notifier
// // ---------------------------------------------------------------------------

// class MedicineScanNotifier extends StateNotifier<MedicineScanState> {
//   MedicineScanNotifier(this._service)
//       : super(const MedicineScanState.initial());

//   final MedicineRecognitionService _service;

//   /// Called when the user selects or captures a photo.
//   Future<void> analyzeImage(File imageFile) async {
//     state = const MedicineScanState.analyzing();
//     try {
//       final result = await _service.recognizeMedicine(imageFile);
//       state = MedicineScanState.success(result);
//     } on MedicineRecognitionException catch (e) {
//       state = MedicineScanState.error(e.message);
//     } catch (e) {
//       state =
//           MedicineScanState.error('Something went wrong. Please try again.');
//     }
//   }

//   void reset() => state = const MedicineScanState.initial();
// }

// final medicineScanProvider =
//     StateNotifierProvider<MedicineScanNotifier, MedicineScanState>((ref) {
//   return MedicineScanNotifier(ref.read(medicineRecognitionServiceProvider));
// });

// // ---------------------------------------------------------------------------
// // Reminder creation notifier
// // ---------------------------------------------------------------------------

// class ReminderCreationNotifier extends StateNotifier<ReminderCreationState> {
//   ReminderCreationNotifier(this._supabase)
//       : super(const ReminderCreationState.idle());

//   final SupabaseClient _supabase;
//   final _uuid = const Uuid();

//   Future<void> createReminder({
//     required MedicineInfo medicine,
//     required List<ReminderTime> times,
//     ReminderFrequency frequency = ReminderFrequency.daily,
//     String notes = '',
//   }) async {
//     state = const ReminderCreationState.saving();

//     try {
//       final user = _supabase.auth.currentUser;
//       if (user == null) throw Exception('User not authenticated');

//       final reminder = MedicineReminder(
//         id: _uuid.v4(),
//         medicineName: medicine.name,
//         dosage: medicine.dosage,
//         times: times,
//         frequency: frequency,
//         startDate: DateTime.now(),
//         notes: notes,
//         patientId: user.id,
//         isActive: true,
//       );

//       // Persist to Supabase medicine_reminders table
//       await _supabase.from('medicine_reminders').insert({
//         'id': reminder.id,
//         'patient_id': user.id,
//         'medicine_name': reminder.medicineName,
//         'dosage': reminder.dosage,
//         'times': reminder.times
//             .map((t) => {'hour': t.hour, 'minute': t.minute, 'label': t.label})
//             .toList(),
//         'frequency': reminder.frequency.name,
//         'start_date': reminder.startDate?.toIso8601String(),
//         'notes': reminder.notes,
//         'is_active': true,
//         'created_at': DateTime.now().toIso8601String(),
//       });

//       state = ReminderCreationState.saved(reminder);
//     } catch (e) {
//       state = ReminderCreationState.error(
//         'Could not save reminder. Please try again.',
//       );
//     }
//   }

//   void reset() => state = const ReminderCreationState.idle();
// }

// final reminderCreationProvider =
//     StateNotifierProvider<ReminderCreationNotifier, ReminderCreationState>(
//         (ref) {
//   return ReminderCreationNotifier(ref.read(supabaseClientProvider));
// });

// // ---------------------------------------------------------------------------
// // Existing reminders list – useful for the result screen to show existing ones
// // ---------------------------------------------------------------------------

// final medicineRemindersProvider =
//     FutureProvider<List<MedicineReminder>>((ref) async {
//   final supabase = ref.read(supabaseClientProvider);
//   final user = supabase.auth.currentUser;
//   if (user == null) return [];

//   final rows = await supabase
//       .from('medicine_reminders')
//       .select()
//       .eq('patient_id', user.id)
//       .eq('is_active', true)
//       .order('created_at', ascending: false);

//   return (rows as List)
//       .map((row) => MedicineReminder(
//             id: row['id'] as String,
//             medicineName: row['medicine_name'] as String,
//             dosage: row['dosage'] as String,
//             times: ((row['times'] as List?) ?? [])
//                 .map((t) => ReminderTime(
//                       hour: t['hour'] as int,
//                       minute: t['minute'] as int,
//                       label: t['label'] as String? ?? '',
//                     ))
//                 .toList(),
//             frequency: ReminderFrequency.values.firstWhere(
//               (f) => f.name == row['frequency'],
//               orElse: () => ReminderFrequency.daily,
//             ),
//             notes: row['notes'] as String? ?? '',
//             patientId: row['patient_id'] as String,
//             isActive: row['is_active'] as bool? ?? true,
//           ))
//       .toList();
// });
