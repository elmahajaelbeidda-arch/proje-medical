import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/admin_provider.dart';
import 'core/admin_router.dart';
import 'core/l10n.dart';
import 'core/providers.dart';
import 'core/theme.dart';
import 'features/admin/demo_admins.dart';
import 'features/aid/aid_repository.dart';

/// «فريق المتابعة والإدارة»: the association's dashboard, a separate app
/// from the users' app (lib/main.dart). Published under /admin/.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseConfigured) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  }
  runApp(
    ProviderScope(
      overrides: [adminSeedAccountsProvider.overrideWithValue(demoAdmins())],
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
    );
  }
}
