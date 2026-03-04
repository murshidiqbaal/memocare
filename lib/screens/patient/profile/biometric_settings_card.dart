import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/biometric_providers.dart';

/// Card widget shown in the Patient Profile settings section.
///
/// Allows patients to:
///  - See whether fingerprint login is ON or OFF
///  - Toggle it on (triggers device biometric prompt)
///  - Toggle it off (clears trusted device from Supabase + local storage)
class BiometricSettingsCard extends ConsumerWidget {
  final String patientId;

  const BiometricSettingsCard({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricAvailable = ref.watch(biometricAvailableProvider);
    final biometricEnabled = ref.watch(biometricEnabledProvider);
    final controllerState = ref.watch(biometricControllerProvider);

    final isLoading = controllerState is AsyncLoading;

    return biometricAvailable.when(
      data: (available) {
        if (!available) {
          // Device doesn't support biometrics — don't show the card at all
          return const SizedBox.shrink();
        }

        return biometricEnabled.when(
          data: (enabled) => _buildCard(context, ref, enabled, isLoading),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCard(
      BuildContext context, WidgetRef ref, bool enabled, bool isLoading) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: enabled ? Colors.teal.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.fingerprint,
              size: 28,
              color: enabled ? Colors.teal.shade700 : Colors.grey.shade500,
            ),
          ),

          const SizedBox(width: 16),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fingerprint Login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  enabled
                      ? 'You can open MemoCare with your fingerprint.'
                      : 'Turn on to skip your password.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Toggle
          isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.teal),
                  ),
                )
              : Switch(
                  value: enabled,
                  activeColor: Colors.teal,
                  onChanged: (newVal) =>
                      _onToggle(context, ref, enabled, newVal),
                ),
        ],
      ),
    );
  }

  Future<void> _onToggle(
    BuildContext context,
    WidgetRef ref,
    bool currentlyEnabled,
    bool newValue,
  ) async {
    if (newValue) {
      // Enable biometric
      final error = await ref
          .read(biometricControllerProvider.notifier)
          .enableBiometric(patientId);

      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fingerprint login is now ON 🎉'),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Disable biometric
      await ref
          .read(biometricControllerProvider.notifier)
          .disableBiometric(patientId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fingerprint login has been turned off.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    // Refresh the enabled state
    ref.invalidate(biometricEnabledProvider);
  }
}
