import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_screens.dart';
import '../features/doctor/doctor_shell.dart';
import '../features/doctor/request_details_screen.dart';
import '../features/onboarding/onboarding_screens.dart';
import '../features/patient/consultation_details_screen.dart';
import '../features/patient/health_profile_screen.dart';
import '../features/patient/new_consultation_screen.dart';
import '../features/patient/patient_shell.dart';
import '../features/shared/shared_screens.dart';
import '../models/models.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/role', builder: (_, _) => const RoleSelectScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/verify', builder: (_, _) => const VerifyPhoneScreen()),

      // Patient
      GoRoute(path: '/patient', builder: (_, _) => const PatientShell()),
      GoRoute(
        path: '/patient/new',
        builder: (_, state) => NewConsultationScreen(
          initialType: state.extra is ConsultationType
              ? state.extra! as ConsultationType
              : null,
        ),
      ),
      GoRoute(
        path: '/patient/consultation/:id',
        builder: (_, state) =>
            ConsultationDetailsScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/patient/health-profile',
        builder: (_, _) => const HealthProfileScreen(),
      ),

      // Doctor
      GoRoute(path: '/doctor', builder: (_, _) => const DoctorShell()),
      GoRoute(
        path: '/doctor/request/:id',
        builder: (_, state) =>
            RequestDetailsScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/doctor/reply/:id',
        builder: (_, state) => ReplyScreen(id: state.pathParameters['id']!),
      ),

      // Shared
      GoRoute(
        path: '/chat/:id',
        builder: (_, state) => ChatScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/disclaimer', builder: (_, _) => const DisclaimerScreen()),
    ],
  );
});
