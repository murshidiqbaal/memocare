import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memocare/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:memocare/features/auth/presentation/screens/biometric_login_screen.dart';
import 'package:memocare/features/auth/presentation/screens/flutter_login_screen.dart';
import 'package:memocare/features/auth/presentation/screens/register_screen.dart';
import 'package:memocare/features/auth/providers/auth_provider.dart';
import 'package:memocare/features/caregiver/presentation/screens/connections/caregiver_connections_screen.dart';
import 'package:memocare/features/caregiver/presentation/screens/dashboard/caregiver_dashboard_screen.dart';
import 'package:memocare/features/location/presentation/screens/caregiver_location_requests_screen.dart';
import 'package:memocare/features/location/presentation/screens/caregiver_patient_map_screen.dart';
import 'package:memocare/features/location/presentation/screens/patient_home_location_screen.dart';
import 'package:memocare/features/patient/presentation/screens/connections/patient_connections_screen.dart';
import 'package:memocare/features/patient/presentation/screens/games/games_screen.dart';
import 'package:memocare/features/patient/presentation/screens/games/mini_games/memory_match_game_screen.dart';
import 'package:memocare/features/patient/presentation/screens/games/mini_games/reaction_tap_game_screen.dart';
import 'package:memocare/features/patient/presentation/screens/patient_main_screen.dart';
import 'package:memocare/features/patient/presentation/screens/reminders/alarm_screen.dart';
import 'package:memocare/features/shared/presentation/screens/splash_screen.dart';
import 'package:memocare/widgets/realtime_initializer.dart';

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
          path: '/login',
          builder: (context, state) => const FlutterLoginScreen(),
        ),

        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),

        // ================= BIOMETRIC =================
        GoRoute(
          path: '/biometric-login',
          builder: (context, state) => const BiometricLoginScreen(),
        ),

        // ================= PATIENT =================
        GoRoute(
          path: '/patientDashboard',
          builder: (context, state) =>
              const RealtimeInitializer(child: PatientMainScreen()),
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
          path: '/caregiverDashboard',
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
          path: '/adminDashboard',
          builder: (context, state) => const AdminDashboardScreen(),
        ),

        // ================= DEV =================
        // GoRoute(
        //   path: '/notification-test',
        //   builder: (context, state) => const NotificationTestScreen(),
        // ),
        // ================= LOCATION / SAFE ZONE =================
        GoRoute(
          path: '/patient-home-location/:patientId',
          builder: (context, state) {
            final patientId = state.pathParameters['patientId'] ?? '';
            return PatientHomeLocationScreen(patientId: patientId);
          },
        ),

        GoRoute(
          path: '/caregiver-location-requests',
          builder: (context, state) => const CaregiverLocationRequestsScreen(),
        ),

        GoRoute(
          path: '/caregiver-patient-map/:patientId',
          builder: (context, state) {
            final patientId = state.pathParameters['patientId'] ?? '';
            final patientName = state.uri.queryParameters['name'] ?? 'Patient';
            return CaregiverPatientMapScreen(
              patientId: patientId,
              patientName: patientName,
            );
          },
        ),
        // 🚨 ================= REMINDER ALERTS =================
        GoRoute(
          path: '/alert/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            // For now, always use AlarmScreen for alerts as requested
            return AlarmScreen(reminderId: id);
          },
        ),
      ],

      // ================= REDIRECT LOGIC =================
      redirect: (context, state) {
        final path = state.uri.toString();
        final isSplash = path == '/';

        // 1. Wait for Auth State
        if (authState.isLoading) {
          return isSplash ? null : '/';
        }

        final session = authState.valueOrNull?.session;
        final isAuthenticated = session != null;

        final isBiometricRoute = path == '/biometric-login';
        final isAuthRoute =
            path == '/login' || path == '/register' || isBiometricRoute;

        // � NOT AUTHENTICATED
        if (!isAuthenticated) {
          if (isAuthRoute) return null;
          return '/login';
        }

        // 2. Wait for Profile Data
        // If we are authenticated but the profile is still loading, stay on Splash
        if (profileAsync.isLoading) {
          return isSplash ? null : '/';
        }

        final profile = profileAsync.valueOrNull;

        // 3. Handle Authenticated but No Profile found
        if (profile == null) {
          // If no profile found in any table AFTER loading, we might be in a (temporary) weird state.
          // Don't loop back to login if we just signed up and provider is still fetching.
          if (profileAsync.isLoading || profileAsync.isRefreshing) {
            return isSplash ? null : '/';
          }

          // If it's truly null after a clean fetch, redirect to login to try again.
          if (!isAuthRoute) return '/login';
          return null;
        }

        // 4. Role-based Redirection
        if (isSplash || isAuthRoute) {
          debugPrint(
              '[Router] Redirecting authenticated user with role: ${profile.role}');
          if (profile.role == 'caregiver') return '/caregiverDashboard';
          if (profile.role == 'admin') return '/adminDashboard';
          if (profile.role == 'patient') return '/patientDashboard';

          // Fallback if role is somehow missing or different
          return '/login';
        }

        // 5. Protected Route Guard (example: Games only for patients)
        if (path.startsWith('/games')) {
          if (profile.role != 'patient') {
            return profile.role == 'caregiver'
                ? '/caregiverDashboard'
                : '/adminDashboard';
          }
        }

        return null;
      });
});
