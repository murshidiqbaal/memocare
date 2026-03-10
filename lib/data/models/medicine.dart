// // lib/features/medicine_recognition/models/medicine_models.dart

// import 'package:freezed_annotation/freezed_annotation.dart';

// part '../../features/medicine/data/medicine_models.freezed.dart';
// part '../../features/medicine/data/medicine_models.g.dart';

// /// Result from Gemini Vision analysis of a medicine image
// @freezed
// class MedicineInfo with _$MedicineInfo {
//   const factory MedicineInfo({
//     required String name,
//     required String dosage,
//     @Default('') String activeIngredient,
//     @Default('') String manufacturer,
//     @Default('') String instructions,
//     @Default([]) List<String> warnings,
//     @Default(RecognitionConfidence.medium) RecognitionConfidence confidence,
//     @Default(false) bool isRecognized,
//     @Default('') String rawGeminiResponse,
//   }) = _MedicineInfo;

//   factory MedicineInfo.fromJson(Map<String, dynamic> json) =>
//       _$MedicineInfoFromJson(json);

//   /// Empty/unrecognized state
//   factory MedicineInfo.unrecognized() => const MedicineInfo(
//         name: 'Unknown Medicine',
//         dosage: 'Not detected',
//         isRecognized: false,
//         confidence: RecognitionConfidence.low,
//       );
// }

// enum RecognitionConfidence { high, medium, low }

// /// A scheduled medicine reminder
// @freezed
// class MedicineReminder with _$MedicineReminder {
//   const factory MedicineReminder({
//     required String id,
//     required String medicineName,
//     required String dosage,
//     required List<ReminderTime> times,
//     @Default(true) bool isActive,
//     @Default(ReminderFrequency.daily) ReminderFrequency frequency,
//     DateTime? startDate,
//     DateTime? endDate,
//     @Default('') String notes,
//     String? patientId,
//   }) = _MedicineReminder;

//   factory MedicineReminder.fromJson(Map<String, dynamic> json) =>
//       _$MedicineReminderFromJson(json);
// }

// @freezed
// class ReminderTime with _$ReminderTime {
//   const factory ReminderTime({
//     required int hour,
//     required int minute,
//     @Default('') String label, // e.g. "After breakfast"
//   }) = _ReminderTime;

//   factory ReminderTime.fromJson(Map<String, dynamic> json) =>
//       _$ReminderTimeFromJson(json);
// }

// enum ReminderFrequency { daily, weekly, custom }

// /// State for the medicine scan flow
// @freezed
// class MedicineScanState with _$MedicineScanState {
//   const factory MedicineScanState.initial() = MedicineScanInitial;
//   const factory MedicineScanState.capturing() = MedicineScanCapturing;
//   const factory MedicineScanState.analyzing() = MedicineScanAnalyzing;
//   const factory MedicineScanState.success(MedicineInfo medicine) =
//       MedicineScanSuccess;
//   const factory MedicineScanState.error(String message) = MedicineScanError;
// }

// /// State for reminder creation
// @freezed
// class ReminderCreationState with _$ReminderCreationState {
//   const factory ReminderCreationState.idle() = ReminderCreationIdle;
//   const factory ReminderCreationState.saving() = ReminderCreationSaving;
//   const factory ReminderCreationState.saved(MedicineReminder reminder) =
//       ReminderCreationSaved;
//   const factory ReminderCreationState.error(String message) =
//       ReminderCreationError;
// }
