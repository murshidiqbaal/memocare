import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../memories/caregiver_memories_screen.dart';
import '../patients/caregiver_patients_screen.dart';
import '../profile/caregiver_profile_screen.dart';
import '../reminders/caregiver_reminders_screen.dart';
import 'caregiver_dashboard_tab.dart';

class CaregiverDashboardScreen extends ConsumerStatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  ConsumerState<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState
    extends ConsumerState<CaregiverDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CaregiverDashboardTab(),
    const CaregiverPatientsScreen(),
    const CaregiverMemoriesScreen(),
    const CaregiverRemindersScreen(),
    const CaregiverProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        indicatorColor: Colors.teal.shade50,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Colors.teal),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: Colors.teal),
            label: 'Patients',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library, color: Colors.teal),
            label: 'Memories',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: Colors.teal),
            label: 'Reminders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Colors.teal),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
