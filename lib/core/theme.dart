import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// One set of colours (light or dark). Values come from the design brief;
/// the deeper / lighter tones noted are there for WCAG AA contrast.
class Palette {
  const Palette({
    required this.primary,
    required this.onPrimary,
    required this.primaryDark,
    required this.turquoise,
    required this.turquoiseText,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.text,
    required this.grey,
    required this.border,
    required this.navInactive,
    required this.emergency,
    required this.emergencySoft,
    required this.emergencyText,
    required this.answered,
    required this.answeredSoft,
    required this.answeredText,
    required this.reviewing,
    required this.reviewingSoft,
    required this.reviewingText,
  });
  final Color primary,
      onPrimary,
      primaryDark,
      turquoise,
      turquoiseText,
      secondary,
      background,
      surface,
      text,
      grey,
      border,
      navInactive,
      emergency,
      emergencySoft,
      emergencyText,
      answered,
      answeredSoft,
      answeredText,
      reviewing,
      reviewingSoft,
      reviewingText;

  static const light = Palette(
    primary: Color(0xFF2F6B55),
    onPrimary: Color(0xFFFFFFFF),
    primaryDark: Color(0xFF234F40),
    turquoise: Color(0xFF4A8A90),
    turquoiseText: Color(0xFF447C80), // deeper, for small text
    secondary: Color(0xFFE6F0EB),
    background: Color(0xFFF6F8F7),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF1F2A26),
    grey: Color(0xFF6B7A74),
    border: Color(0xFFE3E8E6),
    navInactive: Color(0xFF9AA6A1),
    emergency: Color(0xFFD9534F),
    emergencySoft: Color(0xFFFCEBEA),
    emergencyText: Color(0xFFB44B47),
    answered: Color(0xFF3BA776),
    answeredSoft: Color(0xFFE2F2EA),
    answeredText: Color(0xFF2E6F52),
    reviewing: Color(0xFFE0A030),
    reviewingSoft: Color(0xFFFAF1E0),
    reviewingText: Color(0xFF896B2C),
  );

  /// Dark mode of the brief: background #121816, cards #1C2421, green
  /// #4FA383 (with dark text on it: white would be too faint).
  static const dark = Palette(
    primary: Color(0xFF4FA383),
    onPrimary: Color(0xFF0E1A15),
    primaryDark: Color(0xFF7CC2A6),
    turquoise: Color(0xFF6AAEB4),
    turquoiseText: Color(0xFF7FBFC4),
    secondary: Color(0xFF213029),
    background: Color(0xFF121816),
    surface: Color(0xFF1C2421),
    text: Color(0xFFE6EDEA),
    grey: Color(0xFF9BA9A3),
    border: Color(0xFF2A3430),
    navInactive: Color(0xFF8C9A94),
    emergency: Color(0xFFE0605C),
    emergencySoft: Color(0xFF3A2220),
    emergencyText: Color(0xFFF2A3A0),
    answered: Color(0xFF4CC08A),
    answeredSoft: Color(0xFF1E3329),
    answeredText: Color(0xFF7AD3A8),
    reviewing: Color(0xFFE8B04A),
    reviewingSoft: Color(0xFF382E1A),
    reviewingText: Color(0xFFEDC27A),
  );
}

/// Colours of the app. They follow the current palette, which the app
/// switches with the phone's light / dark setting (see AppColors.use).
class AppColors {
  AppColors._();

  static Palette _p = Palette.light;
  static bool get isDark => identical(_p, Palette.dark);

  /// Called by the app root whenever the brightness changes.
  static void use(Brightness b) =>
      _p = b == Brightness.dark ? Palette.dark : Palette.light;

  // ---- The palette --------------------------------------------------------
  static Color get primary => _p.primary;
  static Color get onPrimary => _p.onPrimary;
  static Color get primaryDark => _p.primaryDark;
  static Color get turquoise => _p.turquoise;
  static Color get secondary => _p.secondary;
  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get text => _p.text;
  static Color get grey => _p.grey;
  static Color get border => _p.border;
  static Color get emergency => _p.emergency;
  static Color get emergencySoft => _p.emergencySoft;
  static Color get answered => _p.answered;
  static Color get reviewing => _p.reviewing;
  static Color get navInactive => _p.navInactive;
  static Color get turquoiseText => _p.turquoiseText;
  static Color get emergencyText => _p.emergencyText;
  static Color get answeredText => _p.answeredText;
  static Color get reviewingText => _p.reviewingText;
  static Color get answeredSoft => _p.answeredSoft;
  static Color get reviewingSoft => _p.reviewingSoft;

  // Older names kept for the other screens.
  static Color get fieldFill => background;
  static Color get turquoiseSoft => secondary;
  static Color get emeraldTeal => turquoise;
  static Color get offline => navInactive;
  static Color get darkBackground => Palette.dark.background;
  static Color get darkSurface => Palette.dark.surface;
  static Color get darkSurfaceHigh => Palette.dark.secondary;
  static Color get darkOutline => Palette.dark.border;
  static List<Color> get heroGradient => [primary, primary];
  static Color get vivid => turquoise;
  static Color get ink => primary;
  static Color get teal => turquoise;
  static Color get calm => turquoise;
  static Color get inkLight => turquoise;
  static Color get green => primary;
  static Color get mint => secondary;
  static Color get patient => secondary;
  static Color get doctor => secondary;
  static Color get patientDark => turquoise;
  static Color get doctorDark => primary;
  static Color get accent => reviewing;
  static Color get info => turquoise;
  static Color get danger => emergency;
  static Color get success => answered;
  static Color get warning => reviewing;
  static Color get error => emergencyText;

  /// Very light shadow: 0 2 8, 6 % (none in dark mode).
  static List<BoxShadow> get shadow => isDark
      ? const []
      : const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ];

  /// Picks the main text colour or white, whichever contrasts more.
  static Color on(Color background) {
    double contrast(Color a, Color b) {
      final la = a.computeLuminance(), lb = b.computeLuminance();
      return (la > lb ? la + .05 : lb + .05) / (la > lb ? lb + .05 : la + .05);
    }

    final dark = Color(0xFF1F2A26);
    return contrast(background, Colors.white) >= contrast(background, dark)
        ? Colors.white
        : dark;
  }

  static Color role(bool isDoctor) => isDoctor ? doctor : patient;
  static Color roleDark(bool isDoctor) => isDoctor ? doctorDark : patientDark;
}

class AppTheme {
  AppTheme._();

  static ThemeData light(String languageCode) =>
      _build(Brightness.light, languageCode);
  static ThemeData dark(String languageCode) =>
      _build(Brightness.dark, languageCode);

  static ThemeData _build(Brightness brightness, String languageCode) {
    final p = brightness == Brightness.dark ? Palette.dark : Palette.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: p.primary,
          brightness: brightness,
        ).copyWith(
          primary: p.primary,
          onPrimary: p.onPrimary,
          primaryContainer: p.secondary,
          onPrimaryContainer: p.primary,
          secondary: p.turquoise,
          onSecondary: p.onPrimary,
          secondaryContainer: p.secondary,
          onSecondaryContainer: p.turquoiseText,
          tertiary: p.turquoise,
          onTertiary: p.onPrimary,
          surface: p.surface,
          onSurface: p.text,
          onSurfaceVariant: p.grey,
          surfaceContainerLowest: p.surface,
          surfaceContainerLow: p.surface,
          surfaceContainer: p.surface,
          surfaceContainerHigh: p.secondary,
          surfaceContainerHighest: p.secondary,
          outline: p.border,
          outlineVariant: p.border,
          error: p.emergencyText,
        );
    // El Messiri for the whole app (Arabic, French and English), bundled in
    // assets/fonts with its four weights, so it works offline.
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: 'ElMessiri',
    );
    final f = base.textTheme;
    // Type scale of the brief: 22 large title, 18 card title, 15 body,
    // 13 small (secondary colour), 11 tab labels; line height 1.6.
    final textTheme = f
        .apply(bodyColor: p.text, displayColor: p.text)
        .copyWith(
          headlineMedium: f.headlineMedium?.copyWith(color: p.primary),
          headlineSmall: f.headlineSmall?.copyWith(
            color: p.primary,
            fontSize: TextSize.large,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: f.titleLarge?.copyWith(
            color: p.primary,
            fontSize: TextSize.large,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: f.titleMedium?.copyWith(
            fontSize: TextSize.title,
            fontWeight: FontWeight.w700,
            color: p.text,
          ),
          titleSmall: f.titleSmall?.copyWith(
            fontSize: TextSize.section,
            fontWeight: FontWeight.w700,
            color: p.text,
          ),
          bodyLarge: f.bodyLarge?.copyWith(
            fontSize: TextSize.body,
            height: TextSize.lineHeight,
            color: p.text,
          ),
          bodyMedium: f.bodyMedium?.copyWith(
            fontSize: TextSize.body,
            height: TextSize.lineHeight,
            color: p.text,
          ),
          bodySmall: f.bodySmall?.copyWith(
            fontSize: TextSize.small,
            height: TextSize.lineHeight,
            color: p.grey,
          ),
          labelSmall: f.labelSmall?.copyWith(fontSize: TextSize.tab),
        );
    final card = BorderRadius.circular(Radii.card);
    final button = BorderRadius.circular(Radii.button);

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: p.background,
      // Smooth transitions between screens (fade + slight slide).
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: p.primary,
        iconTheme: IconThemeData(color: p.text, size: 24),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: TextSize.title,
          fontWeight: FontWeight.w700,
          color: p.text,
        ),
      ),
      cardTheme: CardThemeData(
        // White cards, 16 corners, a very light shadow and no border.
        elevation: brightness == Brightness.dark ? 0 : 1,
        shadowColor: const Color(0x0F000000),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        color: p.surface,
        shape: RoundedRectangleBorder(borderRadius: card),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.turquoise,
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: textTheme.bodySmall,
      ),
      iconTheme: IconThemeData(color: p.turquoise, size: 24),
      dividerTheme: DividerThemeData(
        color: p.border,
        thickness: 1,
        space: Space.l,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.m,
          vertical: Space.m,
        ),
        labelStyle: TextStyle(color: p.grey),
        floatingLabelStyle: TextStyle(
          color: p.primary,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(color: p.grey),
        prefixIconColor: p.turquoise,
        border: OutlineInputBorder(
          borderRadius: button,
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: button,
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: button,
          borderSide: BorderSide(color: p.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: button,
          borderSide: BorderSide(color: p.emergencyText, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: p.primary,
              foregroundColor: p.onPrimary,
              disabledBackgroundColor: p.border,
              disabledForegroundColor: p.grey,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: button),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'ElMessiri',
              ),
            ).copyWith(
              overlayColor: WidgetStatePropertyAll(
                p.onPrimary.withValues(alpha: .08),
              ),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: p.primary,
          side: BorderSide(color: p.border, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: button),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'ElMessiri',
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.turquoiseText,
          minimumSize: const Size(44, 44),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontFamily: 'ElMessiri',
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: p.surface,
        selectedColor: p.secondary,
        checkmarkColor: p.primary,
        side: BorderSide(color: p.border),
        labelStyle: TextStyle(
          color: p.text,
          fontFamily: 'ElMessiri',
          fontSize: 14,
        ),
        secondaryLabelStyle: TextStyle(
          color: p.primary,
          fontWeight: FontWeight.w700,
          fontFamily: 'ElMessiri',
        ),
        shape: RoundedRectangleBorder(borderRadius: button),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? p.secondary
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.primary : p.text,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: p.border)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.onPrimary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primary : null,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primary : null,
        ),
        checkColor: WidgetStatePropertyAll(p.onPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Space.xs + 1),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.secondary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.text,
        contentTextStyle: TextStyle(
          color: p.background,
          fontFamily: 'ElMessiri',
          fontSize: 15,
        ),
        actionTextColor: p.secondary,
        shape: RoundedRectangleBorder(borderRadius: button),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sheet),
        ),
        titleTextStyle: textTheme.titleMedium?.copyWith(color: p.text),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Radii.sheet),
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.primary,
        unselectedLabelColor: p.grey,
        indicatorColor: p.primary,
        dividerColor: p.border,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: p.surface,
        indicatorColor: p.secondary,
        iconTheme: WidgetStateProperty.resolveWith(
          (st) => IconThemeData(
            color: st.contains(WidgetState.selected) ? p.primary : p.grey,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (st) => TextStyle(
            fontSize: TextSize.tab,
            fontFamily: 'ElMessiri',
            color: st.contains(WidgetState.selected) ? p.primary : p.grey,
            fontWeight: st.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.secondary,
        selectedIconTheme: IconThemeData(color: p.primary),
        unselectedIconTheme: IconThemeData(color: p.grey),
        selectedLabelTextStyle: TextStyle(
          color: p.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: TextStyle(color: p.grey),
      ),
    );
  }

  /// Sign-in & sign-up screens: same look for every role.
  static ThemeData forRole(ThemeData base, {required bool isDoctor}) => base;
}

// ---------------------------------------------------------------------------
// Design tokens: spacing, radii, type and motion, used by every screen.
// ---------------------------------------------------------------------------

/// Spacing on a 4 / 8 grid.
abstract final class Space {
  static const double xxs = 4;
  static const double xs = 8;
  static const double s = 12;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;

  /// Page side margin and gap between sections.
  static const double page = 16;
  static const double section = 24;
}

abstract final class Radii {
  static const double button = 12;
  static const double card = 16;
  static const double hero = 20;
  static const double sheet = 24;
}

/// Font sizes of the brief (El Messiri) and the line height.
abstract final class TextSize {
  static const double large = 22;
  static const double title = 18;
  static const double section = 16;
  static const double body = 15;
  static const double small = 13;
  static const double tab = 11;
  static const double lineHeight = 1.6;
}

/// Motion: short and soft.
abstract final class Motion {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 300);
  static const stagger = Duration(milliseconds: 60);
  static const curve = Curves.easeOutCubic;
  static const pressScale = 0.97;
}
