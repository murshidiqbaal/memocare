import 'package:curved_nav_bar/curved_bar/curved_action_bar.dart';
import 'package:curved_nav_bar/fab_bar/fab_bottom_app_bar_item.dart';
import 'package:curved_nav_bar/flutter_curved_bottom_nav_bar.dart';
import 'package:dementia_care_app/features/patient/presentation/screens/games/games_screen.dart';
import 'package:dementia_care_app/features/patient/presentation/screens/home/patient_dashboard_tab.dart';
import 'package:dementia_care_app/features/patient/presentation/screens/memories/memories_screen.dart';
import 'package:dementia_care_app/features/patient/presentation/screens/profile/patient_profile_screen.dart';
import 'package:dementia_care_app/providers/emergency_alert_provider.dart';
import 'package:dementia_care_app/widgets/sos_countdown_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CurvedNavBar(
        activeColor: Colors.teal,
        navBarBackgroundColor: Colors.white,
        inActiveColor: Colors.grey.shade600,

        /// SOS Button
        actionButton: CurvedActionBar(
          onTab: (_) {
            ref.read(emergencySOSControllerProvider.notifier).startCountdown();
          },
          activeIcon: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sos, size: 26, color: Colors.white),
          ),
          inActiveIcon: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sos, size: 26, color: Colors.white),
          ),
          text: 'SOS',
        ),

        /// Bottom Tabs
        appBarItems: [
          FABBottomAppBarItem(
            activeIcon: const Icon(Icons.home, color: Colors.teal, size: 24),
            inActiveIcon:
                const Icon(Icons.home_outlined, color: Colors.grey, size: 24),
            text: 'Home',
          ),
          FABBottomAppBarItem(
            activeIcon:
                const Icon(Icons.photo_album, color: Colors.teal, size: 24),
            inActiveIcon: const Icon(Icons.photo_album_outlined,
                color: Colors.grey, size: 24),
            text: 'Memories',
          ),
          FABBottomAppBarItem(
            activeIcon:
                const Icon(Icons.videogame_asset, color: Colors.teal, size: 24),
            inActiveIcon: const Icon(Icons.videogame_asset_outlined,
                color: Colors.grey, size: 24),
            text: 'Games',
          ),
          FABBottomAppBarItem(
            activeIcon: const Icon(Icons.person, color: Colors.teal, size: 24),
            inActiveIcon:
                const Icon(Icons.person_outline, color: Colors.grey, size: 24),
            text: 'Profile',
          ),
        ],

        /// Screens
        bodyItems: const [
          PatientDashboardTab(),
          MemoriesScreen(),
          GamesScreen(),
          PatientProfileScreen(),
        ],

        /// SOS Screen
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
      ),
    );
  }
}
