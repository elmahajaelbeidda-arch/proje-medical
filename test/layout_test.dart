import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/l10n.dart';
import 'package:shifa/core/theme.dart';
import 'package:shifa/features/patient/patient_shell.dart';
import 'package:shifa/features/pulse/pulse_screens.dart';
import 'package:shifa/features/patient/doctor_profile_screen.dart';
import 'package:shifa/features/about/about_app_screen.dart';
import 'package:shifa/features/blood/blood_screens.dart';
import 'package:shifa/features/cards/member_card_screens.dart';
import 'package:shifa/features/doctor/doctor_shell.dart';
import 'package:shifa/features/auth/auth_screens.dart';
import 'package:shifa/features/onboarding/onboarding_screens.dart';
import 'package:shifa/features/patient/consultation_details_screen.dart';
import 'package:shifa/features/patient/new_consultation_screen.dart';
import 'package:shifa/features/shared/shared_screens.dart';

/// The main screens must lay out without overflow on small and large
/// phones, in the three languages, in light and dark mode.
void main() {
  const sizes = {'small': Size(320, 568), 'large': Size(430, 932)};
  final screens = <String, Widget Function()>{
    'patient home': () => const PatientShell(),
    'pulse': () => const PulseHomeScreen(),
    'doctor page': () => const DoctorProfileScreen(id: 'd1'),
    'doctor space': () => const DoctorShell(),
    'welcome': () => const WelcomeScreen(),
    'role': () => const RoleSelectScreen(),
    'login': () => const LoginScreen(),
    'blood': () => const BloodHomeScreen(),
    'new consultation': () => const NewConsultationScreen(),
    'consultation': () => const ConsultationDetailsScreen(id: 'c1'),
    'settings': () => const SettingsScreen(),
    'verify card': () => const VerifyCardScreen(),
    'about app': () => const AboutAppScreen(),
  };

  for (final lang in ['ar', 'fr', 'en']) {
    for (final b in Brightness.values) {
      for (final size in sizes.entries) {
        for (final screen in screens.entries) {
          testWidgets('${screen.key} · $lang · ${b.name} · ${size.key}', (
            t,
          ) async {
            t.view.physicalSize = size.value * 2;
            t.view.devicePixelRatio = 2;
            addTearDown(t.view.reset);
            AppColors.use(b);
            addTearDown(() => AppColors.use(Brightness.light));
            await t.pumpWidget(
              ProviderScope(
                child: MaterialApp(
                  locale: Locale(lang),
                  supportedLocales: AppStrings.supportedLocales,
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  theme: b == Brightness.dark
                      ? AppTheme.dark(lang)
                      : AppTheme.light(lang),
                  home: screen.value(),
                ),
              ),
            );
            await t.pump(const Duration(seconds: 1));
            expect(t.takeException(), isNull);
            await t.pumpWidget(const SizedBox());
          });
        }
      }
    }
  }
}
