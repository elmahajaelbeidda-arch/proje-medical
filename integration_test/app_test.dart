import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shifa/core/l10n.dart';
import 'package:shifa/core/providers.dart';
import 'package:shifa/core/router.dart';
import 'package:shifa/core/summons_provider.dart';
import 'package:shifa/features/blood/blood_screens.dart';
import 'package:shifa/features/cards/member_card_screens.dart';
import 'package:shifa/features/doctor/doctor_shell.dart';
import 'package:shifa/features/facility/facility_screens.dart';
import 'package:shifa/features/onboarding/onboarding_screens.dart';
import 'package:shifa/features/patient/consultation_details_screen.dart';
import 'package:shifa/features/patient/new_consultation_screen.dart';
import 'package:shifa/features/patient/patient_shell.dart';
import 'package:shifa/features/psych/psych_screens.dart';
import 'package:shifa/features/summons/summons_pdf.dart';
import 'package:shifa/features/summons/summons_screens.dart';
import 'package:shifa/main.dart';
import 'package:shifa/models/models.dart';

/// End-to-end check of the users' app on a real device or simulator
/// (Android and iOS): every main section opens without errors, and PDF
/// cards can be generated with the bundled fonts.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('main sections open on the device', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ShifaApp()),
    );
    // Splash, then onboarding.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);

    final router = container.read(routerProvider);
    Future<void> open(String location, Type screen) async {
      router.go(location);
      await tester.pumpAndSettle();
      expect(find.byType(screen), findsOneWidget, reason: location);
      expect(tester.takeException(), isNull, reason: location);
    }

    await open('/role', RoleSelectScreen);
    expect(find.text(AppStrings.of('ar', 'role_patient')), findsOneWidget);

    // Patient
    final auth = container.read(authProvider.notifier);
    auth.selectRole(UserRole.patient);
    auth.login();
    await open('/patient', PatientShell);
    await open('/patient/new', NewConsultationScreen);
    await open('/patient/consultation/c1', ConsultationDetailsScreen);
    await open('/patient/psych', PsychHomeScreen);
    await open('/patient/psych/new', PsychBookingScreen);
    await open('/blood', BloodHomeScreen);
    await open('/patient/blood/new', NewBloodRequestScreen);
    await open('/summons/cv1001', SummonsScreen);
    await open('/my-card', MyMemberCardScreen);
    expect(find.byType(MemberCardView), findsOneWidget);

    // PDF generation on the device (fonts and logo from the app bundle).
    final summons = container.read(summonsProvider).first;
    final bytes = await buildSummonsPdf(
      summons,
      await loadPdfAssets(),
      tr: (k) => AppStrings.of('ar', k),
      rtl: true,
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');

    // Volunteer doctor
    auth.selectRole(UserRole.doctor);
    auth.login();
    await open('/doctor', DoctorShell);

    // Medical facility
    await open('/facility', FacilityEntryScreen);
    await open('/facility/register', FacilityRegisterScreen);

    // French interface
    container.read(localeProvider.notifier).set(const Locale('fr'));
    await open('/role', RoleSelectScreen);
    expect(find.text(AppStrings.of('fr', 'role_patient')), findsOneWidget);
  });
}
