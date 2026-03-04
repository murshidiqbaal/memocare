import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Generates and returns a stable, unique device identifier.
///
/// Uses [DeviceInfoPlugin] to read platform hardware identifiers.
/// On Android: androidId
/// On iOS: identifierForVendor
/// Other platforms: fallback string
class DeviceIdService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Returns a unique device ID for this installation.
  /// This is used to verify that biometric login is happening on the
  /// trusted device that was enrolled — not a new or stolen device.
  Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return info.id; // Stable Android ID
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return info.identifierForVendor ?? _fallbackId();
      }
      return _fallbackId();
    } catch (_) {
      return _fallbackId();
    }
  }

  String _fallbackId() =>
      'memocare_device_${DateTime.now().millisecondsSinceEpoch}';
}
