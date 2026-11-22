import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/admin_provider.dart';
import 'package:shifa/core/l10n.dart';
import 'package:shifa/core/l10n_en.dart';
import 'package:shifa/core/providers.dart';
import 'package:shifa/features/admin/demo_admins.dart';
import 'package:shifa/models/admin.dart';

List<String> placeholders(String s) =>
    RegExp(r'\{\w+\}').allMatches(s).map((m) => m.group(0)!).toList()..sort();

void main() {
  test('every text has an English translation with the same placeholders', () {
    final missing = <String>[];
    final mismatched = <String>[];
    for (final k in AppStrings.keys) {
      final en = enStrings[k];
      if (en == null || en.trim().isEmpty) {
        missing.add(k);
        continue;
      }
      final fr = AppStrings.of('fr', k);
      if (placeholders(fr).join() != placeholders(en).join()) mismatched.add(k);
      // No Arabic letters left in English texts.
      if (RegExp(r'[؀-ۿ]').hasMatch(en)) mismatched.add(k);
    }
    expect(missing, isEmpty, reason: 'keys without English');
    expect(mismatched, isEmpty, reason: 'placeholders or script differ');
    expect(enStrings.keys.where((k) => !AppStrings.keys.contains(k)), isEmpty);
  });

  test('the three languages are offered and read correctly', () {
    expect(AppStrings.supportedLocales.map((l) => l.languageCode), [
      'ar',
      'fr',
      'en',
    ]);
    expect(AppStrings.of('en', 'nav_home'), 'Home');
    expect(AppStrings.of('fr', 'nav_home'), 'Accueil');
    expect(AppStrings.of('ar', 'nav_home'), isNot('Home'));
  });

  test('the dashboard can switch English off; Arabic is then used', () {
    final c = ProviderContainer(
      overrides: [adminSeedAccountsProvider.overrideWithValue(demoAdmins())],
    );
    addTearDown(c.dispose);
    expect(const AppSettings().languages, ['ar', 'fr', 'en']);
    final admin = c.read(adminProvider.notifier);
    expect(admin.login('admin@shifa.mr', 'Admin@2026'), LoginResult.success);
    admin.setLanguages(defaultLanguage: 'en', french: true, english: true);
    expect(c.read(localeProvider), const Locale('en'));
    admin.setLanguages(defaultLanguage: 'en', french: true, english: false);
    expect(c.read(appSettingsProvider).languages, ['ar', 'fr']);
    expect(c.read(localeProvider), const Locale('ar'));
    final restored = AppSettings.fromJson(c.read(appSettingsProvider).toJson());
    expect(restored.englishEnabled, isFalse);
  });
}
