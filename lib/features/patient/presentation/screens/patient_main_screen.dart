import 'package:memocare/features/patient/presentation/screens/games/games_screen.dart';
import 'package:memocare/features/patient/presentation/screens/home/patient_dashboard_tab.dart';
import 'package:memocare/features/patient/presentation/screens/memories/memories_screen.dart';
import 'package:memocare/features/patient/presentation/screens/profile/patient_profile_screen.dart';
import 'package:memocare/widgets/curved_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Main patient screen with curved bottom navigation
/// Integrates the central SOS button
class PatientMainScreen extends ConsumerStatefulWidget {
  const PatientMainScreen({super.key});

  @override
  ConsumerState<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends ConsumerState<PatientMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PatientDashboardTab(),
    MemoriesScreen(),
    GamesScreen(),
    PatientProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CurvedBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
