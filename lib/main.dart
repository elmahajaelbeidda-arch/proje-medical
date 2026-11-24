import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/admin_provider.dart';
import 'core/admin_remote.dart';
import 'core/l10n.dart';
import 'data/mock_data.dart';
import 'core/providers.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'features/aid/aid_repository.dart';
import 'features/calls/incoming_call.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Patient map backend (see supabase/migrations). Without the keys the
  // feature runs on demo data.
  // Real server: only real people and content, no demo data.
  MockData.live = supabaseConfigured;
  if (supabaseConfigured) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  }
  final container = ProviderContainer();
  runApp(
    UncontrolledProviderScope(container: container, child: const ShifaApp()),
  );
  // Sections on/off, association information and announcements set by the
  // dashboard (server), applied as soon as they arrive.
  final public = await AdminRemote.loadPublic();
  if (public != null) {
    container.read(adminProvider.notifier).applyPublic(public);
  }
}

class ShifaApp extends ConsumerWidget {
  const ShifaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.tr('app_name'),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: themeMode,
      theme: AppTheme.light(locale.languageCode),
      darkTheme: AppTheme.dark(locale.languageCode),
      // Colours follow the light / dark mode (the phone's setting by
      // default). Changing it rebuilds the screens with the new palette.
      builder: (context, child) {
        final b = Theme.of(context).brightness;
        AppColors.use(b);
        return KeyedSubtree(
          key: ValueKey(b),
          child: IncomingCallWatcher(child: child ?? const SizedBox()),
        );
      },
    );
  }
}
