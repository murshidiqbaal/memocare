import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/location/providers/safezone_providers.dart';
import '../providers/safe_zone_provider.dart';

/// SafetyMonitoringWrapper automatically starts the geofencing service
/// if the logged-in user is a patient and has a safe zone configured.
class SafetyMonitoringWrapper extends ConsumerWidget {
  final Widget child;

  const SafetyMonitoringWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to profile changes to start/stop monitoring
    ref.listen(userProfileProvider, (previous, next) async {
      final profile = next.value;
      if (profile == null) {
        // Logged out or no profile, stop monitoring
        ref.read(safeZoneMonitoringProvider.notifier).stop();
        return;
      }

      if (profile.role == 'patient') {
        // User is a patient, fetch their safe zone and start monitoring
        final safeZoneAsync = ref.read(patientSafeZoneProvider(profile.id));
        safeZoneAsync.whenData((zone) {
          if (zone != null) {
            ref.read(safeZoneMonitoringProvider.notifier).start(
                  patientId: profile.id,
                  safeZone: zone,
                );
          }
        });
      } else {
        // User is not a patient, ensure monitoring is stopped
        ref.read(safeZoneMonitoringProvider.notifier).stop();
      }
    });

    return child;
  }
}
