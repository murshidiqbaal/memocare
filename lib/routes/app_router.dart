import 'package:dementia_care_app/screens/patient/games/games_screen.dart';
import 'package:dementia_care_app/screens/patient/games/mini_games/memory_match_game_screen.dart';
import 'package:dementia_care_app/screens/patient/games/mini_games/reaction_tap_game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/auth/biometric_login_screen.dart';
import '../screens/auth/flutter_login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/caregiver/connections/caregiver_connections_screen.dart';
import '../screens/caregiver/dashboard/caregiver_dashboard_screen.dart';
import '../screens/patient/connections/patient_connections_screen.dart';
import '../screens/patient/home/patient_home_screen.dart';
import '../screens/patient/reminders/reminder_alert_screen.dart';
import '../screens/shared/notification_test_screen.dart';
import '../screens/shared/splash_screen.dart';
import '../widgets/realtime_initializer.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  // watch profile reactively
  final profileAsync = ref.watch(userProfileProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',

    // ================= ROUTES =================
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),

      GoRoute(
        path: '/login',
        builder: (context, state) => const FlutterLoginScreen(),
      ),

      GoRoute(
        path: '/biometric-login',
        builder: (context, state) => const BiometricLoginScreen(),
      ),

      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ================= PATIENT =================
      GoRoute(
        path: '/patient-home',
        builder: (context, state) =>
            const RealtimeInitializer(child: PatientHomeScreen()),
      ),

      // ✅ ================= GAMES =================
      GoRoute(
        path: '/games',
        builder: (context, state) =>
            const RealtimeInitializer(child: GamesScreen()),
      ),

      // 🃏 Memory Match
      GoRoute(
        path: '/games/memory-match',
        builder: (context, state) =>
            const RealtimeInitializer(child: MemoryMatchGameScreen()),
      ),

      // ⚡ Reaction Tap
      GoRoute(
        path: '/games/reaction-tap',
        builder: (context, state) =>
            const RealtimeInitializer(child: ReactionTapGameScreen()),
      ),

      // ================= CAREGIVER =================
      GoRoute(
        path: '/caregiver-dashboard',
        builder: (context, state) =>
            const RealtimeInitializer(child: CaregiverDashboardScreen()),
      ),

      GoRoute(
        path: '/patient-connections',
        builder: (context, state) => const PatientConnectionsScreen(),
      ),

      GoRoute(
        path: '/caregiver-connections',
        builder: (context, state) => const CaregiverConnectionsScreen(),
      ),

      // ================= ADMIN =================
      GoRoute(
        path: '/admin-panel',
        builder: (context, state) => const AdminDashboardScreen(),
      ),

      // ================= ALERT =================
      GoRoute(
        path: '/alert/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ReminderAlertScreen(reminderId: id);
        },
      ),

      // ================= DEV =================
      GoRoute(
        path: '/notification-test',
        builder: (context, state) => const NotificationTestScreen(),
      ),
    ],

    // ================= REDIRECT LOGIC =================
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final session = authState.valueOrNull?.session;
      final isAuthenticated = session != null;

      final path = state.uri.toString();

      final isSplash = path == '/';
      final isAuthRoute =
          path == '/login' || path == '/register' || path == '/role-selection';

      // 🔴 NOT AUTHENTICATED
      if (!isAuthenticated) {
        // Check if patient has biometric enabled on this device
        // We only navigate to biometric login from splash, not from auth routes
        if (isSplash) return null; // SplashScreen handles biometric check
        if (isAuthRoute) return null;
        return '/login';
      }

      // 🟢 AUTHENTICATED
      final profile = profileAsync.valueOrNull;

      // wait until profile loads
      if (profileAsync.isLoading) return null;

      // 🚫 prevent auth pages after login
      if (isAuthRoute) {
        if (profile?.role == 'caregiver') return '/caregiver-dashboard';
        if (profile?.role == 'admin') return '/admin-panel';
        return '/patient-home';
      }

      // 🎮 ROLE GUARD — only patients can access any game route
      if (path == '/games' ||
          path == '/games/memory-match' ||
          path == '/games/reaction-tap') {
        final role = profile?.role;
        if (role == 'admin') return '/admin-panel';
        if (role != 'patient') return '/caregiver-dashboard';
      }

      return null;
    },
  );
});
