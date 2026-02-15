import 'package:dementia_care_app/data/models/patient_profile.dart';

/// Helper class for calculating patient profile completion
/// Used for gamification and encouraging complete profiles
class ProfileCompletionHelper {
  /// Calculate profile completion percentage (0-100)
  static int calculateCompletion(PatientProfile profile) {
    int totalFields = 9; // Total number of optional + required fields
    int completedFields = 0;

    // Required field (always counted as complete if profile exists)
    if (profile.fullName.isNotEmpty) completedFields++;

    // Optional but important fields
    if (profile.dateOfBirth != null) completedFields++;
    if (profile.gender != null && profile.gender!.isNotEmpty) {
      completedFields++;
    }
    if (profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty) {
      completedFields++;
    }
    if (profile.address != null && profile.address!.isNotEmpty) {
      completedFields++;
    }
    if (profile.emergencyContactName != null &&
        profile.emergencyContactName!.isNotEmpty) {
      completedFields++;
    }
    if (profile.emergencyContactPhone != null &&
        profile.emergencyContactPhone!.isNotEmpty) {
      completedFields++;
    }
    if (profile.medicalNotes != null && profile.medicalNotes!.isNotEmpty) {
      completedFields++;
    }
    if (profile.profileImageUrl != null &&
        profile.profileImageUrl!.isNotEmpty) {
      completedFields++;
    }

    return ((completedFields / totalFields) * 100).round();
  }

  /// Get a user-friendly completion status message
  static String getCompletionMessage(int percentage) {
    if (percentage == 100) {
      return 'Profile Complete! 🎉';
    } else if (percentage >= 80) {
      return 'Almost there!';
    } else if (percentage >= 50) {
      return 'Good progress';
    } else if (percentage >= 25) {
      return 'Getting started';
    } else {
      return 'Let\'s complete your profile';
    }
  }

  /// Get missing fields for better UX
  static List<String> getMissingFields(PatientProfile profile) {
    List<String> missing = [];

    if (profile.dateOfBirth == null) missing.add('Date of Birth');
    if (profile.gender == null || profile.gender!.isEmpty) {
      missing.add('Gender');
    }
    if (profile.phoneNumber == null || profile.phoneNumber!.isEmpty) {
      missing.add('Phone Number');
    }
    if (profile.address == null || profile.address!.isEmpty) {
      missing.add('Address');
    }
    if (profile.emergencyContactName == null ||
        profile.emergencyContactName!.isEmpty) {
      missing.add('Emergency Contact Name');
    }
    if (profile.emergencyContactPhone == null ||
        profile.emergencyContactPhone!.isEmpty) {
      missing.add('Emergency Contact Phone');
    }
    if (profile.medicalNotes == null || profile.medicalNotes!.isEmpty) {
      missing.add('Medical Notes');
    }
    if (profile.profileImageUrl == null || profile.profileImageUrl!.isEmpty) {
      missing.add('Profile Photo');
    }

    return missing;
  }

  /// Check if critical safety fields are complete
  /// (Emergency contact information)
  static bool hasCriticalInfo(PatientProfile profile) {
    return profile.emergencyContactName != null &&
        profile.emergencyContactName!.isNotEmpty &&
        profile.emergencyContactPhone != null &&
        profile.emergencyContactPhone!.isNotEmpty;
  }
}
