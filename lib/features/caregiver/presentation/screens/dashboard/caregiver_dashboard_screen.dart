import 'package:memocare/core/services/realtime_service.dart';
import 'package:memocare/data/models/sos_alert.dart';
import 'package:memocare/features/caregiver/presentation/screens/dashboard/caregiver_dashboard_tab.dart';
import 'package:memocare/features/caregiver/presentation/screens/dashboard/emergency_alert_screen.dart';
import 'package:memocare/features/caregiver/presentation/screens/memories/caregiver_memories_screen.dart';
import 'package:memocare/features/caregiver/presentation/screens/patients/caregiver_patients_screen.dart';
import 'package:memocare/features/caregiver/presentation/screens/profile/caregiver_profile_screen.dart';
import 'package:memocare/features/caregiver/presentation/screens/reminders/caregiver_reminders_screen.dart';
import 'package:memocare/providers/sos_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
class _DS {
  static const teal700 = Color(0xFF00695C);
  static const teal50 = Color(0xFFE0F2F1);

  static const coral = Color(0xFFFF5252);
  static const surface = Color(0xFFF8FAFB);
  static const white = Color(0xFFFFFFFF);
  static const ink900 = Color(0xFF0D1B1E);
  static const ink400 = Color(0xFF8A9EA2);
}

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
  bool _sosDialogVisible = false;
  ProviderSubscription<AsyncValue<SosAlert?>>? _sosSubscription;

  late final List<Widget> _screens = const [
    CaregiverDashboardTab(),
    CaregiverPatientsScreen(),
    CaregiverMemoriesScreen(),
    CaregiverRemindersScreen(),
    CaregiverProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sosSubscription = ref.listenManual(
        realtimeSosStreamProvider,
        (previous, next) {
          next.whenData((alert) {
            if (alert == null || alert.status != 'active') return;
            if (_sosDialogVisible || !mounted) return;
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

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  void _showEmergencyDialog(SosAlert alert) {
    _sosDialogVisible = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) => _SosAlertDialog(
        alert: alert,
        onViewDetails: () {
          Navigator.of(ctx).pop();
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => EmergencyAlertScreen(alert: alert)),
          );
        },
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    ).then((_) => _sosDialogVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    final unreadAlerts = ref.watch(sosBadgeCountProvider);
    return Scaffold(
      backgroundColor: _DS.surface,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _PremiumNavBar(
        currentIndex: _currentIndex,
        unreadAlerts: unreadAlerts,
        onDestinationSelected: _onTabSelected,
        onLongPress: () {}, // Switcher is in the Appbar now
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium Navigation Bar
// ─────────────────────────────────────────────────────────────────────────────
class _PremiumNavBar extends StatelessWidget {
  final int currentIndex;
  final int unreadAlerts;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onLongPress;

  const _PremiumNavBar({
    required this.currentIndex,
    required this.unreadAlerts,
    required this.onDestinationSelected,
    required this.onLongPress,
  });

  static const _items = [
    _NavItem(icon: Icons.grid_view_rounded, label: 'Home'),
    _NavItem(icon: Icons.people_alt_rounded, label: 'Patients'),
    _NavItem(icon: Icons.photo_library_rounded, label: 'Memories'),
    _NavItem(icon: Icons.assignment_rounded, label: 'Reminders'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _DS.white,
        boxShadow: [
          BoxShadow(
            color: _DS.ink900.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final isSelected = currentIndex == i;
              final item = _items[i];
              final showBadge = i == 0 && unreadAlerts > 0;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onDestinationSelected(i),
                  onLongPress: (i > 0 && i < 4) ? onLongPress : null,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _DS.teal50 : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedScale(
                              scale: isSelected ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                item.icon,
                                size: 22,
                                color: isSelected ? _DS.teal700 : _DS.ink400,
                              ),
                            ),
                            if (showBadge)
                              Positioned(
                                top: -4,
                                right: -6,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: _DS.coral,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$unreadAlerts',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? _DS.teal700 : _DS.ink400,
                            letterSpacing: 0.2,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium SOS Alert Dialog
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: _DS.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _DS.coral.withOpacity(0.25),
              blurRadius: 40,
              spreadRadius: 4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Red header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFFFFEBEE),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _DS.coral,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SOS ALERT',
                        style: TextStyle(
                          color: _DS.coral,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Emergency Triggered',
                        style: TextStyle(
                          color: Color(0xFFB71C1C),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Body ──
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'A patient has triggered an emergency alert. Please respond immediately.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF455A64),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.access_time_rounded,
                    label: 'Triggered',
                    value: _formatTime(alert.triggeredAt),
                  ),
                  if (alert.locationLat != null &&
                      alert.locationLng != null) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.location_on_rounded,
                      label: 'Location',
                      value:
                          '${alert.locationLat!.toStringAsFixed(4)}, ${alert.locationLng!.toStringAsFixed(4)}',
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onDismiss,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _DS.ink400,
                            side: const BorderSide(color: Color(0xFFCFD8DC)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Dismiss',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: onViewDetails,
                          style: FilledButton.styleFrom(
                            backgroundColor: _DS.coral,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.open_in_new_rounded, size: 16),
                              SizedBox(width: 6),
                              Text('View Details',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _DS.ink400),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: _DS.ink400, fontWeight: FontWeight.w500)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  color: _DS.ink900,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
