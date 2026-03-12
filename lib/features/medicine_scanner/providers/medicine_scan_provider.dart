import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dementia_care_app/core/services/medicine_ocr_service.dart';
import 'package:dementia_care_app/core/utils/medicine_name_parser.dart';

import '../data/models/medicine_model.dart';

// ---------------------------------------------------------------------------
// Service providers
// ---------------------------------------------------------------------------

final medicineOCRServiceProvider = Provider<MedicineOCRService>((ref) {
  final service = MedicineOCRService();
  ref.onDispose(() => service.dispose());
  return service;
});

// ---------------------------------------------------------------------------
// Medicine scan state notifier
// ---------------------------------------------------------------------------

class MedicineScanNotifier extends StateNotifier<MedicineScanState> {
  MedicineScanNotifier(this._ocrService) : super(const MedicineScanInitial());

  final MedicineOCRService _ocrService;
  bool _isProcessingScan = false;

  /// Called when the user selects or captures a photo.
  Future<void> analyzeImage(File imageFile) async {
    if (_isProcessingScan) return;
    _isProcessingScan = true;

    state = const MedicineScanAnalyzing();
    try {
      final rawText = await _ocrService.extractText(imageFile);
      final parsed = MedicineNameParser.parse(rawText);
      
      final result = MedicineInfo(
        name: parsed['name']!,
        dosage: parsed['dosage']!,
        isRecognized: parsed['name'] != 'Unknown Medicine',
        confidence: parsed['name'] != 'Unknown Medicine' 
            ? RecognitionConfidence.high 
            : RecognitionConfidence.low,
      );

      state = MedicineScanSuccess(result);
    } catch (e) {
      state = MedicineScanError('Something went wrong. Please try again.');
    } finally {
      _isProcessingScan = false;
    }
  }

  void reset() => state = const MedicineScanInitial();
}

final medicineScanProvider =
    StateNotifierProvider<MedicineScanNotifier, MedicineScanState>((ref) {
  return MedicineScanNotifier(ref.watch(medicineOCRServiceProvider));
});
