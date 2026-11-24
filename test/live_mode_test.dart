import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/admin_provider.dart';
import 'package:shifa/core/blood_provider.dart';
import 'package:shifa/core/facility_provider.dart';
import 'package:shifa/core/l10n.dart';
import 'package:shifa/core/providers.dart';
import 'package:shifa/core/pulse_provider.dart';
import 'package:shifa/core/theme.dart';
import 'package:shifa/data/mock_data.dart';
import 'package:shifa/features/blood/blood_screens.dart';
import 'package:shifa/features/care_map/care_map.dart';
import 'package:shifa/features/doctor/doctor_shell.dart';
import 'package:shifa/features/onboarding/onboarding_screens.dart';
import 'package:shifa/features/patient/patient_shell.dart';
import 'package:shifa/features/pulse/pulse_screens.dart';
import 'package:shifa/models/models.dart';

/// Real server: no demo people or content anywhere, and every screen still
/// works with empty lists.
void main() {
  setUp(() => MockData.live = true);
  tearDown(() => MockData.live = false);

  test('no demo data on the real server', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(MockData.doctors, isEmpty);
    expect(c.read(registrationsProvider), isEmpty);
    expect(c.read(facilityProvider).facilities, isEmpty);
    expect(c.read(pulseProvider).posts, isEmpty);
    expect(c.read(bloodProvider).requests, isEmpty);
    expect(c.read(bloodProvider).donors, isEmpty);
    expect(c.read(adminProvider).announcements, isEmpty);
    expect(c.read(adminProvider).donations, isEmpty);
    expect(c.read(carePlacesProvider), isEmpty);
  });

  final screens = <String, Widget Function()>{
    'welcome': () => const WelcomeScreen(),
    'patient': () => const PatientShell(),
    'doctor': () => const DoctorShell(),
    'pulse': () => const PulseHomeScreen(),
    'blood': () => const BloodHomeScreen(),
  };
  for (final e in screens.entries) {
    testWidgets('${e.key} works with no demo data', (t) async {
      t.view.physicalSize = const Size(390, 844) * 2;
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c
          .read(authProvider.notifier)
          .loginAs(
            role: e.key == 'doctor' ? UserRole.doctor : UserRole.patient,
            name: 'تجربة',
          );
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: AppStrings.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: AppTheme.light('ar'),
            home: e.value(),
          ),
        ),
      );
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }
}
