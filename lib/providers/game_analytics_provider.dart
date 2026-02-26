import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/game_analytics_summary.dart';
import '../data/repositories/game_analytics_repository.dart';

/// Provider for per-patient game analytics
///
/// Ensures lightweight realtime UI fetching with proper null safety,
/// cancellation detection, and automatic cache invalidation/cleanup.
final patientGameAnalyticsProvider = FutureProvider.autoDispose
    .family<GameAnalyticsSummary, String?>((ref, patientId) async {
  if (patientId == null || patientId.isEmpty) {
    return const GameAnalyticsSummary(hasData: false);
  }

  // Caching mechanism: prevent refetch storms when navigating off screen
  // by keeping the provider alive for 2 minutes before destroying it.
  final keepAliveLink = ref.keepAlive();
  Timer? timer;

  ref.onDispose(() {
    timer?.cancel();
  });

  ref.onCancel(() {
    // When the UI stops watching this family index (e.g. they switch patients)
    // we queue it to be destroyed in 2 minutes.
    timer = Timer(const Duration(minutes: 2), () {
      keepAliveLink.close();
    });
  });

  ref.onResume(() {
    timer?.cancel();
  });

  // Watch the repository (which itself watches Supabase client)
  final repository = ref.watch(gameAnalyticsRepositoryProvider);

  // Use the cancellation token abstraction if supported by request,
  // though Supabase Dart currently doesn't easily surface raw cancel tokens on standard selects.
  // The timeout in the repository inherently limits hanging.
  return await repository.getWeeklyAnalytics(patientId);
});
