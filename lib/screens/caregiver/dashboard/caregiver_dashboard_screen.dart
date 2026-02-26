// lib/screens/caregiver/dashboard/caregiver_dashboard_screen.dart
//
// ─── LAYER 1: Navigation Shell ───────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/sos_alert.dart';
import '../../../features/patient_selection/presentation/widgets/patient_bottom_sheet_picker.dart';
import '../../../features/patient_selection/providers/patient_selection_provider.dart';
import '../../../services/realtime_service.dart';
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
    extends ConsumerState<CaregiverDashboardScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  // SOS guard: prevents stacking multiple emergency dialogs
  bool _sosDialogVisible = false;

  // ProviderSubscription lives outside build() → no re-attachment risk
  ProviderSubscription<AsyncValue<SosAlert?>>? _sosSubscription;

  // ── Screens ── created once, IndexedStack keeps them alive ─────────────────
  late final List<Widget> _screens = const [
    CaregiverDashboardTab(), // index 0 — main dashboard
    CaregiverPatientsScreen(), // index 1
    CaregiverMemoriesScreen(), // index 2
    CaregiverRemindersScreen(), // index 3
    CaregiverProfileScreen(), // index 4
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ── Patient list bootstrap ─────────────────────────────────────────────
    // Defer until after first frame so the Provider container is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(patientSelectionProvider.notifier).fetchLinkedPatients();

      // ── Attach SOS listener ONCE, here in initState ────────────────────
      // Using listenManual so it is never re-attached on rebuild.
      _sosSubscription = ref.listenManual(
        realtimeSosStreamProvider,
        (previous, next) {
          next.whenData((alert) {
            if (alert == null || alert.status != 'active') return;
            if (_sosDialogVisible) return; // deduplicate dialogs
            if (!mounted) return;
            _showEmergencyDialog(alert);
          });
        },
        fireImmediately: false,
      );
    });
  }

  @override
  void dispose() {
    _sosSubscription?.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _onTabSelected(int index) {
    if (_currentIndex == index) return; // no-op same tab
    setState(() => _currentIndex = index);
  }

  // ── SOS Dialog ─────────────────────────────────────────────────────────────

  void _showEmergencyDialog(SosAlert alert) {
    _sosDialogVisible = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SosAlertDialog(
        alert: alert,
        onViewDetails: () {
          Navigator.of(ctx).pop();
          // Placeholder for emergency alert screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Navigating to Emergency Alert Screen...')),
          );
        },
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    ).then((_) {
      _sosDialogVisible = false;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Watch ONLY the unread-alert count — no other data needed at shell level.
    // Using .select() to prevent rebuild when unrelated state changes.
    final unreadAlerts = ref.watch(
      patientSelectionProvider
          .select((_) => 0), // placeholder: wire to real badge count
    );

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _CaregiverNavBar(
        currentIndex: _currentIndex,
        unreadAlerts: unreadAlerts,
        onDestinationSelected: _onTabSelected,
        onLongPress: () => PatientBottomSheetPicker.show(context, ref),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Extracted NavigationBar — keeps build() leanest possible
// ─────────────────────────────────────────────────────────────────────────────
class _CaregiverNavBar extends StatelessWidget {
  final int currentIndex;
  final int unreadAlerts;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onLongPress;

  const _CaregiverNavBar({
    required this.currentIndex,
    required this.unreadAlerts,
    required this.onDestinationSelected,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      indicatorColor: Colors.teal.shade50,
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard, color: Colors.teal),
          label: 'Dashboard',
        ),
        _longPressDestination(
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          label: 'Patients',
          onLongPress: onLongPress,
        ),
        _longPressDestination(
          icon: Icons.photo_library_outlined,
          selectedIcon: Icons.photo_library,
          label: 'Memories',
          onLongPress: onLongPress,
        ),
        _longPressDestination(
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment,
          label: 'Reminders',
          onLongPress: onLongPress,
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: Colors.teal),
          label: 'Profile',
        ),
      ],
    );
  }

  NavigationDestination _longPressDestination({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required VoidCallback onLongPress,
  }) {
    return NavigationDestination(
      icon: GestureDetector(
        onLongPress: onLongPress,
        child: Icon(icon),
      ),
      selectedIcon: GestureDetector(
        onLongPress: onLongPress,
        child: Icon(selectedIcon, color: Colors.teal),
      ),
      label: label,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SOS Alert Dialog — extracted widget, no state leaks
// ─────────────────────────────────────────────────────────────────────────────
class _SosAlertDialog extends StatelessWidget {
  final SosAlert alert;
  final VoidCallback onViewDetails;
  final VoidCallback onDismiss;

  const _SosAlertDialog({
    required this.alert,
    required this.onViewDetails,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.red.shade800, size: 32),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'SOS EMERGENCY',
              style: TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A patient has triggered an emergency alert!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Triggered at ${_formatTime(alert.triggeredAt)}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          if (alert.locationLat != null && alert.locationLng != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.red.shade700),
                  const SizedBox(width: 4),
                  Text(
                    '${alert.locationLat!.toStringAsFixed(4)}, '
                    '${alert.locationLng!.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: Text('Dismiss', style: TextStyle(color: Colors.grey.shade600)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          onPressed: onViewDetails,
          child: const Text('VIEW DETAILS'),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
