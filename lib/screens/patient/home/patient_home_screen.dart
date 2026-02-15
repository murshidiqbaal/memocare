import 'package:curved_nav_bar/curved_bar/curved_action_bar.dart';
import 'package:curved_nav_bar/fab_bar/fab_bottom_app_bar_item.dart';
import 'package:curved_nav_bar/flutter_curved_bottom_nav_bar.dart';
import 'package:dementia_care_app/screens/patient/games/games_screen.dart';
import 'package:dementia_care_app/screens/patient/memories/memories_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/emergency_alert_provider.dart';
import '../../../widgets/sos_countdown_content.dart';
import '../profile/patient_profile_screen.dart';
import 'patient_dashboard_tab.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return CurvedNavBar(
      actionButton: CurvedActionBar(
        onTab: (value) {
          // Trigger the 5-second countdown when SOS mode is activated
          ref.read(emergencySOSControllerProvider.notifier).startCountdown();
        },
        activeIcon: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.sos, size: 30, color: Colors.white),
        ),
        inActiveIcon: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.redAccent,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.sos, size: 30, color: Colors.white),
        ),
        text: 'SOS',
      ),
      activeColor: Colors.teal,
      navBarBackgroundColor: Colors.white,
      inActiveColor: Colors.grey.shade600,
      appBarItems: [
        FABBottomAppBarItem(
          activeIcon: const Icon(Icons.home, color: Colors.teal),
          inActiveIcon: const Icon(Icons.home_outlined, color: Colors.grey),
          text: 'Home',
        ),
        FABBottomAppBarItem(
          activeIcon: const Icon(Icons.photo_album, color: Colors.teal),
          inActiveIcon:
              const Icon(Icons.photo_album_outlined, color: Colors.grey),
          text: 'Memories',
        ),
        FABBottomAppBarItem(
          activeIcon: const Icon(Icons.videogame_asset, color: Colors.teal),
          inActiveIcon:
              const Icon(Icons.videogame_asset_outlined, color: Colors.grey),
          text: 'Games',
        ),
        FABBottomAppBarItem(
          activeIcon: const Icon(Icons.person, color: Colors.teal),
          inActiveIcon: const Icon(Icons.person_outline, color: Colors.grey),
          text: 'Profile',
        ),
      ],
      bodyItems: const [
        PatientDashboardTab(),
        MemoriesScreen(),
        GamesScreen(),
        PatientProfileScreen(),
      ],
      actionBarView: Container(
        color: Colors.red.shade900,
        child: SOSCountdownContent(
          onCancel: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tap any tab to return'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          onClose: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tap any tab to return'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}
