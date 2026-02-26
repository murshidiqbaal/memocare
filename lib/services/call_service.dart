import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

final callServiceProvider = Provider<CallService>((ref) {
  return CallService();
});

class CallService {
  /// Calls the patient using their primary phone or fallback emergency phone.
  /// Throws an exception if no valid number is found or if parsing fails.
  Future<void> callPatient({
    required String? phone,
    required String? emergencyPhone,
  }) async {
    final String? rawNumber = _resolveNumber(phone, emergencyPhone);

    if (rawNumber == null || rawNumber.trim().isEmpty) {
      throw const CallServiceException(
          'No contact number available for this patient.');
    }

    final String cleanNumber = rawNumber.replaceAll(RegExp(r'\s+'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        final launched = await launchUrl(phoneUri);
        if (!launched) {
          throw const CallServiceException('Failed to launch dialer.');
        }
      } else {
        throw const CallServiceException(
            'Device does not support phone calls or permission denied.');
      }
    } catch (e) {
      if (e is CallServiceException) rethrow;
      throw CallServiceException('Could not initiate call: $e');
    }
  }

  String? _resolveNumber(String? phone, String? emergencyPhone) {
    if (phone != null && phone.trim().isNotEmpty) {
      return phone;
    }
    if (emergencyPhone != null && emergencyPhone.trim().isNotEmpty) {
      return emergencyPhone;
    }
    return null;
  }
}

class CallServiceException implements Exception {
  final String message;
  const CallServiceException(this.message);

  @override
  String toString() => message;
}
