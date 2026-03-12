// lib/features/medicine_scanner/data/models/medicine_model.dart

enum RecognitionConfidence { high, medium, low }

class MedicineInfo {
  final String name;
  final String dosage;
  final String activeIngredient;
  final String manufacturer;
  final String instructions;
  final List<String> warnings;
  final RecognitionConfidence confidence;
  final bool isRecognized;

  const MedicineInfo({
    required this.name,
    required this.dosage,
    this.activeIngredient = '',
    this.manufacturer = '',
    this.instructions = '',
    this.warnings = const [],
    this.confidence = RecognitionConfidence.medium,
    this.isRecognized = false,
  });

  factory MedicineInfo.unrecognized() => const MedicineInfo(
        name: 'Unknown Medicine',
        dosage: 'Not detected',
        isRecognized: false,
        confidence: RecognitionConfidence.low,
      );
}

abstract class MedicineScanState {
  const MedicineScanState();

  T maybeWhen<T>({
    T Function()? initial,
    T Function()? capturing,
    T Function()? analyzing,
    T Function(MedicineInfo medicine)? success,
    T Function(String message)? error,
    required T Function() orElse,
  }) {
    if (this is MedicineScanInitial && initial != null) return initial();
    if (this is MedicineScanCapturing && capturing != null) return capturing();
    if (this is MedicineScanAnalyzing && analyzing != null) return analyzing();
    if (this is MedicineScanSuccess && success != null) {
      return success((this as MedicineScanSuccess).medicine);
    }
    if (this is MedicineScanError && error != null) {
      return error((this as MedicineScanError).message);
    }
    return orElse();
  }

  T? whenOrNull<T>({
    T Function()? initial,
    T Function()? capturing,
    T Function()? analyzing,
    T Function(MedicineInfo medicine)? success,
    T Function(String message)? error,
  }) {
    if (this is MedicineScanInitial && initial != null) return initial();
    if (this is MedicineScanCapturing && capturing != null) return capturing();
    if (this is MedicineScanAnalyzing && analyzing != null) return analyzing();
    if (this is MedicineScanSuccess && success != null) {
      return success((this as MedicineScanSuccess).medicine);
    }
    if (this is MedicineScanError && error != null) {
      return error((this as MedicineScanError).message);
    }
    return null;
  }
}

class MedicineScanInitial extends MedicineScanState {
  const MedicineScanInitial();
}

class MedicineScanCapturing extends MedicineScanState {
  const MedicineScanCapturing();
}

class MedicineScanAnalyzing extends MedicineScanState {
  const MedicineScanAnalyzing();
}

class MedicineScanSuccess extends MedicineScanState {
  final MedicineInfo medicine;
  const MedicineScanSuccess(this.medicine);
}

class MedicineScanError extends MedicineScanState {
  final String message;
  const MedicineScanError(this.message);
}
