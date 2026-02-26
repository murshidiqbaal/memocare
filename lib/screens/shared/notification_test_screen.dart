import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/service_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NotificationTestScreen
//
// Accessible via the route: /notification-test
// Open it from the caregiver or patient dashboard while testing.
//
// Tests covered:
//   1. Show immediate local notification (no FCM)
//   2. Schedule local alarm 10 seconds out
//   3. Show your FCM token (copy to clipboard)
//   4. Check notification permission status
//   5. Call the Edge Function with a dummy payload
//   6. Tap-to-navigate deep-link to /alert/:id
// ─────────────────────────────────────────────────────────────────────────────
class NotificationTestScreen extends ConsumerStatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  ConsumerState<NotificationTestScreen> createState() =>
      _NotificationTestScreenState();
}

class _NotificationTestScreenState
    extends ConsumerState<NotificationTestScreen> {
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  String _fcmToken = 'Fetching…';
  String _permStatus = 'Checking…';
  final List<_TestResult> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initLocalPlugin();
    _loadFcmToken();
    _checkPermission();
  }

  Future<void> _initLocalPlugin() async {
    await _localNotif.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  Future<void> _loadFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken() ?? 'null';
      if (mounted) setState(() => _fcmToken = token);
    } catch (e) {
      if (mounted) setState(() => _fcmToken = 'Error: $e');
    }
  }

  Future<void> _checkPermission() async {
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      if (mounted) {
        setState(() => _permStatus = settings.authorizationStatus.name);
      }
    } catch (e) {
      if (mounted) setState(() => _permStatus = 'Error: $e');
    }
  }

  void _addResult(String label, bool success, String detail) {
    setState(() {
      _results.insert(
          0,
          _TestResult(
            label: label,
            success: success,
            detail: detail,
            time: TimeOfDay.now(),
          ));
    });
  }

  // ── Test 1: Instant local notification ────────────────────────────────────
  Future<void> _testLocalImmediate() async {
    setState(() => _loading = true);
    try {
      await _localNotif.show(
        id: 1001,
        title: '🔔 Test: Local Notification',
        body: 'If you see this — local notifications work!',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Reminders',
            channelDescription: 'Test notification',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: 'reminder|test-id-001',
      );
      _addResult(
          'Immediate local notification', true, 'Check your status bar ↑');
    } catch (e) {
      _addResult('Immediate local notification', false, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Test 2: Scheduled local alarm (10 s) ──────────────────────────────────
  Future<void> _testLocalScheduled() async {
    setState(() => _loading = true);
    try {
      // Use the already-wired ReminderNotificationService which handles all the TZ setup
      final svc = ref.read(reminderNotificationServiceProvider);

      // Create a fake reminder due in 10 seconds
      final now = DateTime.now();
      final due = now.add(const Duration(seconds: 10));

      // We call showEmergencyNotification as a quick local test
      // (In production, scheduleReminder() is used for future times)
      await Future.delayed(const Duration(seconds: 10), () async {
        if (mounted) {
          await svc.showEmergencyNotification(
            title: '⏰ Test: Scheduled Alarm',
            body: 'This fired 10 seconds after you tapped Schedule!',
          );
        }
      });

      _addResult(
        'Scheduled local (10 s)',
        true,
        'Notification will appear at ${due.hour}:${due.minute.toString().padLeft(2, '0')}:${due.second.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      _addResult('Scheduled local (10 s)', false, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Test 3: Edge Function (full pipeline) ─────────────────────────────────
  Future<void> _testEdgeFunction() async {
    setState(() => _loading = true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      final userId = supabase.auth.currentUser?.id;

      // Find my patient_id to use in the test
      String? patientId;

      // Try to find a linked patient for this user
      final caregiverRow = await supabase
          .from('caregiver_profiles')
          .select('id')
          .eq('user_id', userId ?? '')
          .maybeSingle();

      if (caregiverRow != null) {
        final link = await supabase
            .from('caregiver_patient_links')
            .select('patient_id')
            .eq('caregiver_id', caregiverRow['id'])
            .limit(1)
            .maybeSingle();
        patientId = link?['patient_id'] as String?;
      }

      // Fallback: use own patient record
      if (patientId == null) {
        final patientRow = await supabase
            .from('patients')
            .select('id')
            .eq('user_id', userId ?? '')
            .maybeSingle();
        patientId = patientRow?['id'] as String?;
      }

      if (patientId == null) {
        _addResult('Edge Function', false,
            'No patient_id found. Make sure a patient is linked.');
        return;
      }

      // Call the service
      final trigger = ref.read(notificationTriggerProvider);
      await trigger.sendReminderCreated(
        patientId: patientId,
        reminderId: 'test-reminder-${DateTime.now().millisecondsSinceEpoch}',
        reminderTitle: '🧪 Test Reminder',
        reminderDescription: 'Sent from NotificationTestScreen',
      );

      _addResult(
        'Edge Function invoked',
        true,
        'patient_id: ${patientId.substring(0, 8)}… — Check device for push!',
      );
    } catch (e) {
      _addResult('Edge Function', false, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Test 4: Navigate to /alert/:id ────────────────────────────────────────
  void _testDeepLink() {
    context.push('/alert/test-reminder-id-123');
  }

  // ── Test 5: Request permission ────────────────────────────────────────────
  Future<void> _requestPermission() async {
    setState(() => _loading = true);
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      _addResult(
        'Permission request',
        settings.authorizationStatus == AuthorizationStatus.authorized,
        'Status: ${settings.authorizationStatus.name}',
      );
      if (mounted) {
        setState(() => _permStatus = settings.authorizationStatus.name);
      }
    } catch (e) {
      _addResult('Permission request', false, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Test 6: Verify token saved to Supabase ────────────────────────────────
  Future<void> _testTokenSave() async {
    setState(() => _loading = true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        _addResult('Token in Supabase', false, 'Not logged in');
        return;
      }

      // Check caregiver_profiles
      final caregiverRow = await supabase
          .from('caregiver_profiles')
          .select('fcm_token')
          .eq('user_id', userId)
          .maybeSingle();

      if (caregiverRow != null) {
        final savedToken = caregiverRow['fcm_token'] as String?;
        final match = savedToken == _fcmToken && savedToken != null;
        _addResult(
          'Token in caregiver_profiles',
          match,
          match
              ? 'Token matches ✅'
              : savedToken == null
                  ? '❌ Token is NULL — FCMService.initialize() may not have run'
                  : '❌ Token mismatch — stale data?',
        );
        return;
      }

      // Check patients table
      final patientRow = await supabase
          .from('patients')
          .select('fcm_token')
          .eq('user_id', userId)
          .maybeSingle();

      if (patientRow != null) {
        final savedToken = patientRow['fcm_token'] as String?;
        final match = savedToken == _fcmToken && savedToken != null;
        _addResult(
          'Token in patients',
          match,
          match
              ? 'Token matches ✅'
              : savedToken == null
                  ? '❌ Token is NULL — run FCMService.initialize()'
                  : '❌ Token mismatch',
        );
        return;
      }

      _addResult('Token in Supabase', false,
          'No caregiver_profiles or patients row found for user $userId');
    } catch (e) {
      _addResult('Token in Supabase', false, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.science_outlined, color: Color(0xFF38BDF8)),
            SizedBox(width: 8),
            Text(
              'Notification Test Lab',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Status Bar ────────────────────────────────────────────────
          _buildStatusBar(),

          // ── Test Buttons ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionHeader('📱 Local Notification Tests'),
                  _testButton(
                    icon: Icons.notifications_active,
                    label: 'Show Immediate Notification',
                    subtitle: 'Appears in status bar right now',
                    color: const Color(0xFF10B981),
                    onTap: _testLocalImmediate,
                  ),
                  _testButton(
                    icon: Icons.alarm,
                    label: 'Schedule Alarm (+10 seconds)',
                    subtitle:
                        'Fires 10 seconds from now (simulates due reminder)',
                    color: const Color(0xFF3B82F6),
                    onTap: _testLocalScheduled,
                  ),

                  const SizedBox(height: 12),
                  _sectionHeader('☁️ FCM Push Tests'),
                  _testButton(
                    icon: Icons.send,
                    label: 'Invoke Edge Function',
                    subtitle: 'Sends real FCM push via Supabase → Firebase',
                    color: const Color(0xFF8B5CF6),
                    onTap: _testEdgeFunction,
                  ),
                  _testButton(
                    icon: Icons.verified_user_outlined,
                    label: 'Verify Token in Supabase',
                    subtitle: 'Checks that FCM token was saved correctly',
                    color: const Color(0xFFF59E0B),
                    onTap: _testTokenSave,
                  ),
                  _testButton(
                    icon: Icons.lock_open_outlined,
                    label: 'Request Permission',
                    subtitle: 'Re-requests notification permission',
                    color: const Color(0xFFEC4899),
                    onTap: _requestPermission,
                  ),

                  const SizedBox(height: 12),
                  _sectionHeader('🔗 Navigation Tests'),
                  _testButton(
                    icon: Icons.open_in_new,
                    label: 'Test Deep-Link (/alert/:id)',
                    subtitle: 'Simulates tapping a notification → Alert screen',
                    color: const Color(0xFFEF4444),
                    onTap: _testDeepLink,
                  ),

                  // ── Results log ─────────────────────────────────────────
                  if (_results.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _sectionHeader('📋 Results Log'),
                    ..._results.map(_buildResultCard),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _results.clear()),
        label: const Text('Clear Log'),
        icon: const Icon(Icons.delete_sweep_outlined),
        backgroundColor: const Color(0xFF334155),
        foregroundColor: Colors.white,
      ),
    );
  }

  // ── Widgets ─────────────────────────────────────────────────────────────────

  Widget _buildStatusBar() {
    final permColor = _permStatus == 'authorized'
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Permission badge
          Row(
            children: [
              Icon(
                _permStatus == 'authorized'
                    ? Icons.check_circle
                    : Icons.warning_amber_rounded,
                color: permColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Permission: $_permStatus',
                style: TextStyle(
                    color: permColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
              const Spacer(),
              if (_loading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF38BDF8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // FCM token row
          Row(
            children: [
              const Icon(Icons.key_outlined,
                  color: Color(0xFF94A3B8), size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _fcmToken == 'Fetching…'
                      ? 'FCM Token: fetching…'
                      : 'FCM: ${_fcmToken.length > 30 ? '${_fcmToken.substring(0, 30)}…' : _fcmToken}',
                  style:
                      const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_fcmToken.length > 10)
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _fcmToken));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('FCM token copied to clipboard'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Color(0xFF1E293B),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.copy_outlined,
                        color: Color(0xFF38BDF8), size: 16),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _testButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _loading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: color.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(_TestResult result) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: result.success
              ? const Color(0xFF064E3B).withOpacity(0.5)
              : const Color(0xFF450A0A).withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: result.success
                ? const Color(0xFF10B981).withOpacity(0.4)
                : const Color(0xFFEF4444).withOpacity(0.4),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              result.success ? Icons.check_circle : Icons.error_outline,
              color: result.success
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.label,
                    style: TextStyle(
                      color: result.success
                          ? const Color(0xFF6EE7B7)
                          : const Color(0xFFFCA5A5),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    result.detail,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${result.time.hour}:${result.time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestResult {
  final String label;
  final bool success;
  final String detail;
  final TimeOfDay time;

  _TestResult({
    required this.label,
    required this.success,
    required this.detail,
    required this.time,
  });
}
