import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/auth/flutter_login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/caregiver/connections/caregiver_connections_screen.dart';
import '../screens/caregiver/dashboard/caregiver_dashboard_screen.dart';
import '../screens/patient/connections/patient_connections_screen.dart';
import '../screens/patient/home/patient_home_screen.dart';
import '../screens/patient/reminders/reminder_alert_screen.dart';
import '../screens/shared/splash_screen.dart';
import '../widgets/realtime_initializer.dart'; // Added import

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  // Watch profile to trigger redirect when it loads
  ref.watch(userProfileProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
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
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/patient-home',
        builder: (context, state) =>
            const RealtimeInitializer(child: PatientHomeScreen()),
      ),
      GoRoute(
        path: '/caregiver-dashboard',
        builder: (context, state) =>
            const RealtimeInitializer(child: CaregiverDashboardScreen()),
      ),
      GoRoute(
        path: '/admin-panel',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/alert/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ReminderAlertScreen(reminderId: id);
        },
      ),
      GoRoute(
        path: '/patient-connections',
        builder: (context, state) => const PatientConnectionsScreen(),
      ),
      GoRoute(
        path: '/caregiver-connections',
        builder: (context, state) => const CaregiverConnectionsScreen(),
      ),
    ],
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final session = authState.valueOrNull?.session;
      final isAuthenticated = session != null;

      final path = state.uri.toString();
      final isSplash = path == '/';
      final isAuthRoute =
          path == '/login' || path == '/register' || path == '/role-selection';

      // 1. If not authenticated
      if (!isAuthenticated) {
        if (isSplash || isAuthRoute) return null;
        return '/login';
      }

      // 2. If authenticated
      if (isSplash) return null;

      if (isAuthRoute) {
        // We use 'read' safely because this callback runs reactively
        final profileAsync = ref.read(userProfileProvider);

        // If profile is still loading or doesn't exist yet, we can't decide.
        // Ideally, we wait or let them go to a loading/error page.
        // Assuming profile loads quickly or is cached.
        final profile = profileAsync.valueOrNull;

        if (profile != null) {
          if (profile.role == 'caregiver') return '/caregiver-dashboard';
          if (profile.role == 'admin') return '/admin-panel';
          return '/patient-home';
        }

        // Fallback if profile not found yet
        return '/patient-home';
      }

      return null;
    },
  );
});
