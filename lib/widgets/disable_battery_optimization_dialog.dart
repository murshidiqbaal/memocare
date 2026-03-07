import 'package:flutter/material.dart';
import '../services/battery_optimization_service.dart';

class DisableBatteryOptimizationDialog extends StatelessWidget {
  final BatteryOptimizationService _batteryService =
      BatteryOptimizationService();
  final String manufacturer;

  DisableBatteryOptimizationDialog({super.key, required this.manufacturer});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.battery_alert, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          const Text('Background Access'),
        ],
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            const Text(
              'Allow MemoCare to run in background',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'MemoCare needs background access to ensure medication reminders arrive on time. '
              'Some Android devices delay notifications when battery optimization is enabled.',
            ),
            if (_isOEMDevice()) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Special instructions for $manufacturer:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getOEMInstructions(),
                      style: TextStyle(
                          color: Colors.orange.shade900, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () async {
            await _batteryService.requestDisableBatteryOptimization();
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Allow'),
        ),
      ],
    );
  }

  bool _isOEMDevice() {
    final m = manufacturer.toLowerCase();
    return m.contains('xiaomi') ||
        m.contains('oppo') ||
        m.contains('vivo') ||
        m.contains('huawei') ||
        m.contains('oneplus') ||
        m.contains('samsung');
  }

  String _getOEMInstructions() {
    final m = manufacturer.toLowerCase();
    if (m.contains('samsung')) {
      return 'Go to App Info > Battery > Select "Unrestricted"';
    } else if (m.contains('xiaomi')) {
      return 'Enable "Autostart" and set Battery Saver to "No restrictions"';
    } else if (m.contains('oppo') || m.contains('vivo')) {
      return 'Enable "Auto-launch" and ensure background power usage is allowed';
    } else {
      return 'Ensure the app is not restricted in Battery settings to receive timely alerts.';
    }
  }
}
