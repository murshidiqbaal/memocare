import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/patient_selection_provider.dart';

class PatientSafetyGuard {
  /// Ensures a patient is selected before executing an action.
  /// Use this guard before navigating, creating reminders, or uploading memories!
  static bool ensurePatientSelected(BuildContext context, WidgetRef ref) {
    final patientState = ref.read(patientSelectionProvider);

    if (!patientState.isPatientSelected) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Please select a patient first.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      return false; // Action rejected
    }

    return true; // Action allowed
  }

  /// Get non-nullable patient ID safely after applying the guard.
  /// Throws StateError if called blindly without guard check.
  static String getActivePatientId(WidgetRef ref) {
    final patientId = ref.read(patientSelectionProvider).selectedPatient?.id;
    if (patientId == null || patientId.isEmpty) {
      throw StateError(
          'Attempted to access patient ID when zero valid selection exists.');
    }
    return patientId;
  }
}
