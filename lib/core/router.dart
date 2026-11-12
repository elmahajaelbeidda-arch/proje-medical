import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/about/about_screen.dart';
import '../features/aid/aid_screens.dart';
import '../features/auth/auth_screens.dart';
import '../features/blood/blood_screens.dart';
import '../features/blood/committee_screens.dart';
import '../features/doctor/doctor_shell.dart';
import '../features/facility/facility_screens.dart';
import '../features/doctor/request_details_screen.dart';
import '../features/onboarding/onboarding_screens.dart';
import '../features/patient/consultation_details_screen.dart';
import '../features/patient/health_profile_screen.dart';
import '../features/patient/new_consultation_screen.dart';
import '../features/patient/patient_shell.dart';
import '../features/shared/shared_screens.dart';
import '../models/models.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    // Committee pages hold personal data: committee members only.
    redirect: (context, state) {
      final committeePage = state.matchedLocation.startsWith('/committee');
      if (committeePage && !ref.read(authProvider).isCommittee) return '/role';
      return null;
    },
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

      // Blood donation: donor registration only
      GoRoute(path: '/blood', builder: (_, _) => const BloodHomeScreen()),
      GoRoute(
        path: '/blood/donor',
        builder: (_, _) => const DonorRegisterScreen(),
      ),

      // Blood requests: only from the patient's profile
      GoRoute(
        path: '/patient/blood',
        builder: (_, _) => const MyBloodRequestsScreen(),
      ),
      GoRoute(
        path: '/patient/blood/new',
        builder: (_, _) => const NewBloodRequestScreen(),
      ),
      GoRoute(
        path: '/patient/blood/:id',
        builder: (_, state) =>
            BloodRequestDetailsScreen(id: state.pathParameters['id']!),
      ),

      // Blood donation committee
      GoRoute(
        path: '/committee',
        builder: (_, _) => const CommitteeHomeScreen(),
      ),
      GoRoute(
        path: '/committee/request/:id',
        builder: (_, state) =>
            CommitteeRequestScreen(id: state.pathParameters['id']!),
      ),

      GoRoute(
        path: '/committee/facility/:id',
        builder: (_, state) =>
            CommitteeFacilityScreen(id: state.pathParameters['id']!),
      ),

      // Medical facilities (hospitals, clinics, labs, pharmacies, radiology)
      GoRoute(
        path: '/facility',
        builder: (_, _) => const FacilityEntryScreen(),
      ),
      GoRoute(
        path: '/facility/register',
        builder: (_, _) => const FacilityRegisterScreen(),
      ),
      GoRoute(
        path: '/facility/login',
        builder: (_, _) => const FacilityLoginScreen(),
      ),
      GoRoute(
        path: '/facility/home',
        builder: (_, _) => const FacilityHomeScreen(),
      ),
      GoRoute(
        path: '/facility/referral/:id',
        builder: (_, state) =>
            FacilityReferralScreen(id: state.pathParameters['id']!),
      ),

      // Patient map (medical aid committee)
      GoRoute(path: '/aid', builder: (_, _) => const MyAidRequestsScreen()),
      GoRoute(
        path: '/aid/new',
        builder: (_, _) => const AidRequestFormScreen(),
      ),
      GoRoute(path: '/aid/map', builder: (_, _) => const AidMapScreen()),
      GoRoute(
        path: '/aid/members',
        builder: (_, _) => const AidMembersScreen(),
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
      GoRoute(
        path: '/about',
        builder: (_, _) => const AboutAssociationScreen(),
      ),
      GoRoute(path: '/disclaimer', builder: (_, _) => const DisclaimerScreen()),
    ],
  );
});
