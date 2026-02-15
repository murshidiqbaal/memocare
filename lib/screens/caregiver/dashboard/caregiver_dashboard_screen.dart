import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/realtime_service.dart'; // Added
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
    const CaregiverMemoriesScreen(
      patientId: '',
    ),
    const CaregiverRemindersScreen(),
    const CaregiverProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Listen for Realtime SOS Alerts
    ref.listen(realtimeSosStreamProvider, (prev, next) {
      next.whenData((alert) {
        if (alert != null && alert.isActive) {
          _showEmergencyDialog(alert);
        }
      });
    });

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

  void _showEmergencyDialog(dynamic alert) {
    // Using dynamic to avoid deep import if model not convenient, but better use SosEvent
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.red.shade800, size: 30),
            const SizedBox(width: 10),
            const Text('SOS EMERGENCY',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'A patient has triggered an SOS alert! Immediate attention required.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Navigate to alert map/details if implemented
              Navigator.pop(context);
            },
            child: const Text('VIEW DETAILS',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
