import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../services/realtime_service.dart';

class RealtimeInitializer extends ConsumerStatefulWidget {
  final Widget child;

  const RealtimeInitializer({super.key, required this.child});

  @override
  ConsumerState<RealtimeInitializer> createState() =>
      _RealtimeInitializerState();
}

class _RealtimeInitializerState extends ConsumerState<RealtimeInitializer> {
  @override
  void initState() {
    super.initState();
    // Initial check
    _initRealtime();
  }

  void _initRealtime() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      ref.read(realtimeServiceProvider).initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth changes to re-init on login
    ref.listen(authStateChangesProvider, (prev, next) {
      next.whenData((authState) {
        if (authState.session != null) {
          // Small delay to ensure profile might be ready?
          // RealtimeService fetches profile internally anyway.
          ref.read(realtimeServiceProvider).initialize();
        }
      });
    });

    return widget.child;
  }
}
