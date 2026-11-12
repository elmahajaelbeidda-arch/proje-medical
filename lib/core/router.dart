import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/about/about_screen.dart';
import '../features/aid/aid_screens.dart';
import '../features/auth/auth_screens.dart';
import '../features/cards/member_card_screens.dart';
import '../features/blood/blood_screens.dart';
import '../features/doctor/doctor_shell.dart';
import '../features/facility/facility_screens.dart';
import '../features/doctor/request_details_screen.dart';
import '../features/onboarding/onboarding_screens.dart';
import '../features/patient/consultation_details_screen.dart';
import '../features/patient/health_profile_screen.dart';
import '../features/patient/new_consultation_screen.dart';
import '../features/patient/patient_shell.dart';
import '../features/psych/psych_screens.dart';
import '../features/shared/shared_screens.dart';
import '../features/summons/summons_screens.dart';
import '../models/models.dart';
import '../models/admin.dart';
import 'admin_provider.dart';
import 'providers.dart';

/// Routes of the users' app (patients, doctors, facilities, donors).
/// The follow-up & management dashboard is a separate app: see
/// admin_router.dart and main_admin.dart.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    // Unknown links (e.g. dashboard pages, which are not part of this app)
    // lead to the start screen.
    onException: (_, _, router) => router.go('/role'),
    redirect: (context, state) {
      // Sections switched off by the administration.
      final loc = state.matchedLocation;
      final settings = ref.read(appSettingsProvider);
      const gates = {
        '/patient/psych': AppSection.psych,
        '/psych/': AppSection.psych,
        '/blood': AppSection.blood,
        '/patient/blood': AppSection.blood,
        '/aid': AppSection.aid,
        '/facility/register': AppSection.facilities,
        '/patient/new': AppSection.consultations,
      };
      for (final g in gates.entries) {
        if (loc.startsWith(g.key) && !settings.enabled(g.value)) {
          return '/section-off';
        }
      }
      // Psychiatrist workspace: volunteer psychiatrists only.
      final psychDoctorPage = state.matchedLocation.startsWith('/psych/doctor');
      if (psychDoctorPage && !ref.read(authProvider).isPsychDoctor) {
        return '/role';
      }
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

      // Psychological consultations
      GoRoute(
        path: '/patient/psych',
        builder: (_, _) => const PsychHomeScreen(),
      ),
      GoRoute(
        path: '/patient/psych/new',
        builder: (_, state) =>
            PsychBookingScreen(doctorId: state.extra as String?),
      ),
      GoRoute(
        path: '/patient/psych/:id',
        builder: (_, state) => PsychSessionScreen(
          id: state.pathParameters['id']!,
          asDoctor: false,
        ),
      ),
      GoRoute(
        path: '/psych/doctor',
        builder: (_, _) => const PsychDoctorShell(),
      ),
      GoRoute(
        path: '/psych/doctor/session/:id',
        builder: (_, state) =>
            PsychSessionScreen(id: state.pathParameters['id']!, asDoctor: true),
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

      GoRoute(
        path: '/section-off',
        builder: (_, _) => const SectionOffScreen(),
      ),

      // Registration cards
      GoRoute(path: '/my-card', builder: (_, _) => const MyMemberCardScreen()),
      GoRoute(
        path: '/verify-card',
        builder: (_, state) => VerifyCardScreen(
          number: state.uri.queryParameters['n'],
          code: state.uri.queryParameters['c'],
        ),
      ),
      // Medical summons cards
      GoRoute(
        path: '/patient/summons',
        builder: (_, _) => const SummonsListScreen(),
      ),
      GoRoute(
        path: '/summons/:id',
        builder: (_, state) => SummonsScreen(id: state.pathParameters['id']!),
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
