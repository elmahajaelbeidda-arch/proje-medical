import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n.dart';
import 'core/providers.dart';
import 'core/router.dart';
import 'core/theme.dart';

void main() {
  runApp(const ProviderScope(child: ShifaApp()));
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
    );
  }
}
