import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BatteryOptimizationService {
  /// Detects if the app is currently optimized for battery usage (Android only).
  /// Returns false if optimization is disabled (ignored), true if enabled.
  Future<bool> isBatteryOptimizationEnabled() async {
    if (!Platform.isAndroid) return false;
    // permission_handler is reliable for this check
    final status = await Permission.ignoreBatteryOptimizations.status;
    return !status.isGranted;
  }

  /// Requests the user to disable battery optimization.
  /// Shows the system dialog if the app has the REQUEST_IGNORE_BATTERY_OPTIMIZATIONS permission.
  Future<void> requestDisableBatteryOptimization() async {
    if (!Platform.isAndroid) return;

    try {
      // Direct intent for REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
      // This requires <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
      final intent = AndroidIntent(
        action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
        data: 'package:dementia_care_app',
      );
      await intent.launch();
    } catch (e) {
      // If direct request fails (e.g. permission not in manifest), fallback to settings screen
      await openBatteryOptimizationSettings();
    }
  }

  /// Opens the battery optimization settings screen.
  Future<void> openBatteryOptimizationSettings() async {
    if (!Platform.isAndroid) return;

    final intent = AndroidIntent(
      action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
    );
    await intent.launch();
  }

  /// Gets the device manufacturer to provide OEM-specific instructions.
  Future<String> getManufacturer() async {
    if (!Platform.isAndroid) return 'Unknown';
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.manufacturer;
  }
}
