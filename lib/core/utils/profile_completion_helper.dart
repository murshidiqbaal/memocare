// import 'package:memocare/models/user/patient_profile.dart';

import 'package:memocare/data/models/user/patient_profile.dart';

/// Healthcare-grade weighted profile completion
/// Designed for dementia safety prioritization
class ProfileCompletionHelper {
  // ================= WEIGHTS =================
  static const int _fullNameWeight = 15;
  static const int _dobWeight = 15;
  static const int _emergencyNameWeight = 20;
  static const int _emergencyPhoneWeight = 20;
  static const int _phoneWeight = 10;
  static const int _photoWeight = 20;

  static const int _genderWeight = 4;
  static const int _addressWeight = 3;
  static const int _medicalNotesWeight = 3;

  static const int _totalWeight = 100;

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;

  /// 🎯 Main weighted completion calculator
  static int calculateCompletion(PatientProfile profile) {
    int score = 0;

    // 🔴 CRITICAL SAFETY FIELDS
    if (_hasText(profile.fullName)) score += _fullNameWeight;
    if (profile.dateOfBirth != null) score += _dobWeight;
    if (_hasText(profile.emergencyContactName)) {
      score += _emergencyNameWeight;
    }
    if (_hasText(profile.emergencyContactPhone)) {
      score += _emergencyPhoneWeight;
    }
    if (_hasText(profile.phoneNumber)) score += _phoneWeight;
    if (_hasText(profile.profileImageUrl)) score += _photoWeight;

    // 🟡 OPTIONAL ENRICHMENT
    if (_hasText(profile.gender)) score += _genderWeight;
    if (_hasText(profile.address)) score += _addressWeight;
    if (_hasText(profile.medicalNotes)) score += _medicalNotesWeight;

    // Safety clamp
    if (score > _totalWeight) return 100;
    if (score < 0) return 0;

    return score;
  }

  /// 🧠 User-friendly message (improved)
  static String getCompletionMessage(int percentage) {
    if (percentage >= 100) return 'Profile Complete! 🎉';
    if (percentage >= 90) return 'Safety ready — great job!';
    if (percentage >= 75) return 'Almost there!';
    if (percentage >= 50) return 'Good progress';
    if (percentage >= 25) return 'Getting started';
    return 'Let’s complete your profile';
  }

  /// 🔍 Missing fields (prioritized)
  static List<String> getMissingFields(PatientProfile profile) {
    final missing = <String>[];

    // Critical first
    if (!_hasText(profile.fullName)) missing.add('Full Name');
    if (profile.dateOfBirth == null) missing.add('Date of Birth');
    if (!_hasText(profile.emergencyContactName)) {
      missing.add('Emergency Contact Name');
    }
    if (!_hasText(profile.emergencyContactPhone)) {
      missing.add('Emergency Contact Phone');
    }
    if (!_hasText(profile.phoneNumber)) missing.add('Phone Number');
    if (!_hasText(profile.profileImageUrl)) missing.add('Profile Photo');

    // Optional
    if (!_hasText(profile.gender)) missing.add('Gender');
    if (!_hasText(profile.address)) missing.add('Address');
    if (!_hasText(profile.medicalNotes)) missing.add('Medical Notes');

    return missing;
  }

  /// 🚨 Critical safety readiness (unchanged but hardened)
  static bool hasCriticalInfo(PatientProfile profile) {
    return _hasText(profile.emergencyContactName) &&
        _hasText(profile.emergencyContactPhone);
  }

  /// 🧠 NEW — Safety readiness score (very useful for dashboards)
  static bool isSafetyReady(PatientProfile profile) {
    final completion = calculateCompletion(profile);
    return completion >= 80 && hasCriticalInfo(profile);
  }
}
