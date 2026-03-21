import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memocare/features/patient/presentation/providers/patient_navigation_provider.dart';
import 'package:memocare/features/patient/presentation/screens/games/games_screen.dart';
import 'package:memocare/features/patient/presentation/screens/home/patient_dashboard_tab.dart';
import 'package:memocare/features/patient/presentation/screens/memories/memories_screen.dart';
import 'package:memocare/features/patient/presentation/screens/profile/patient_profile_screen.dart';
import 'package:memocare/widgets/curved_bottom_nav_bar.dart';
// import 'package:memocare/t';

/// Main patient shell — hosts all four tabs with the curved bottom nav.
class PatientMainScreen extends ConsumerWidget {
  const PatientMainScreen({super.key});

  static const _screens = [
    PatientDashboardTab(),
    MemoriesScreen(),
    GamesScreen(),
    PatientProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(patientNavigationProvider);

    return Scaffold(
      // Extend body behind the nav bar so per-screen backgrounds show through
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CurvedBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) =>
            ref.read(patientNavigationProvider.notifier).state = index,
      ),
    );
  }
}
