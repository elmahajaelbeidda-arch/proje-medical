import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/admin_provider.dart';
import 'core/admin_router.dart';
import 'core/l10n.dart';
import 'data/mock_data.dart';
import 'core/providers.dart';
import 'core/theme.dart';
import 'features/admin/admin_sync.dart';
import 'features/admin/demo_admins.dart';
import 'features/aid/aid_repository.dart';

/// «فريق المتابعة والإدارة»: the association's dashboard, a separate app
/// from the users' app (lib/main.dart). Published under /admin/.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Real server: only real people and content, no demo data.
  MockData.live = supabaseConfigured;
  if (supabaseConfigured) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  }
  runApp(
    ProviderScope(
      // Demo accounts only without a server; with one, the team signs in
      // with its real accounts (Supabase).
      overrides: [
        if (!supabaseConfigured)
          adminSeedAccountsProvider.overrideWithValue(demoAdmins()),
      ],
      child: const ShifaAdminApp(),
    ),
  );
}

class ShifaAdminApp extends ConsumerWidget {
  const ShifaAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) =>
          '${context.tr('ad_title')} — ${context.tr('app_name')}',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(adminRouterProvider),
      locale: locale,
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: ref.watch(themeModeProvider),
      theme: AppTheme.light(locale.languageCode),
      darkTheme: AppTheme.dark(locale.languageCode),
      // Colours follow the light / dark mode (the phone's setting by
      // default). Changing it rebuilds the screens with the new palette.
      builder: (context, child) {
        final b = Theme.of(context).brightness;
        AppColors.use(b);
        return KeyedSubtree(
          key: ValueKey(b),
          child: AdminSync(child: child ?? const SizedBox()),
        );
      },
    );
  }
}
