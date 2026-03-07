import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../providers/service_providers.dart';
import 'disable_battery_optimization_dialog.dart';

class ReliabilityWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const ReliabilityWrapper({super.key, required this.child});

  @override
  ConsumerState<ReliabilityWrapper> createState() => _ReliabilityWrapperState();
}

class _ReliabilityWrapperState extends ConsumerState<ReliabilityWrapper> {
  static const _kPromptShownKey = 'battery_opt_prompt_shown';
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkReliability();
      });
    }
  }

  Future<void> _checkReliability() async {
    final reliabilityService = ref.read(reminderReliabilityServiceProvider);
    final batteryService = ref.read(batteryOptimizationServiceProvider);

    // Check if the prompt was already shown to avoid annoying the user
    final shownStr = await _storage.read(key: _kPromptShownKey);
    if (shownStr == 'true') return;

    final status = await reliabilityService.checkReliability();

    // If battery is optimized, show the dialog once
    if (status['battery_optimized'] == true && mounted) {
      final manufacturer = await batteryService.getManufacturer();

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false, // Force an action or "Later"
          builder: (context) => DisableBatteryOptimizationDialog(
            manufacturer: manufacturer,
          ),
        );

        // Save that we've shown it
        await _storage.write(key: _kPromptShownKey, value: 'true');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
