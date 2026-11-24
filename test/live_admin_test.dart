import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/admin_provider.dart';
import 'package:shifa/core/l10n.dart';
import 'package:shifa/core/theme.dart';
import 'package:shifa/data/mock_data.dart';
import 'package:shifa/features/admin/admin_shell.dart';
import 'package:shifa/features/admin/demo_admins.dart';

/// Real server: every dashboard section opens with empty data.
void main() {
  setUp(() => MockData.live = true);
  tearDown(() => MockData.live = false);

  for (final section in AdminSection.values) {
    testWidgets('dashboard «${section.name}» with no demo data', (t) async {
      t.view.physicalSize = const Size(1280, 900) * 2;
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      final c = ProviderContainer(
        overrides: [adminSeedAccountsProvider.overrideWithValue(demoAdmins())],
      );
      addTearDown(c.dispose);
      c.read(adminProvider.notifier).login('admin@shifa.mr', 'Admin@2026');
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: AppStrings.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: AppTheme.light('ar'),
            home: AdminShell(section: section),
          ),
        ),
      );
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }
}
