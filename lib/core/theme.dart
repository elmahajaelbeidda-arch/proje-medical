import 'package:flutter/material.dart';

/// Visual identity of "شِفاءٌ لِلنّاس".
///
/// Six colours only. Every other shade below is a mix of these six (and
/// white), noted next to it, so the whole app stays within the palette.
class AppColors {
  AppColors._();

  // ---- The palette --------------------------------------------------------
  static const primary = Color(
    0xFF126B50,
  ); // emerald: brand, titles, main buttons
  static const turquoise = Color(
    0xFF258C91,
  ); // turquoise: icons, highlights, life
  static const secondary = Color(0xFFE4F1EB); // mint: cards and light areas
  static const gold = Color(0xFFD9A441); // calm gold: a few touches only
  static const background = Color(0xFFF7F9F8); // white-grey: app background
  static const text = Color(0xFF263B36); // dark grey: text and secondary titles
  static const surface = Color(0xFFFFFFFF); // white cards

  // ---- Derived shades (mixes of the palette) ------------------------------
  static const primaryDark = Color(0xFF195A47); // emerald 65% + dark grey
  static const turquoiseText = Color(
    0xFF25787A,
  ); // turquoise 75% + dark grey (small text)
  static const grey = Color(
    0xFF61706C,
  ); // dark grey 73% on white: secondary text
  static const border = Color(0xFFD5E2DD); // mint 92% + dark grey
  static const fieldFill = Color(0xFFEEF5F2); // white-grey 55% + mint
  static const turquoiseSoft = Color(0xFFE5F1F2); // turquoise 12% on white
  static const goldSoft = Color(0xFFF9F1E2); // gold 15% on white
  static const goldDeep = Color(0xFF9A7F3D); // gold 65% + dark grey
  static const emeraldTeal = Color(0xFF1C7C70); // emerald 50% + turquoise
  static const offline = Color(0xFFABBAB5); // mint 70% + dark grey

  // Dark mode (deep shades of the dark grey and emerald)
  static const darkBackground = Color(0xFF172B26);
  static const darkSurface = Color(0xFF1A3930);
  static const darkSurfaceHigh = Color(0xFF21473C);
  static const darkOutline = Color(0xFF4C5F5A);

  /// Soft gradient for the few large coloured areas: emerald to turquoise.
  static const heroGradient = [primary, turquoise];

  /// Urgent cases: turquoise (no red), always with an icon.
  static const emergency = turquoise;

  // ---- Aliases used across the screens -----------------------------------
  static const vivid = turquoise; // lively highlights (numbers, likes, ticks)
  static const ink = primary;
  static const teal = turquoise;
  static const calm = turquoise;
  static const inkLight = emeraldTeal;
  static const green = primary;
  static const mint = secondary;

  // Role tints (patients: turquoise, doctors: emerald)
  static const patient = Color(0xFFD8EAEB); // turquoise 18% on white
  static const doctor = Color(0xFFD9E7E3); // emerald 16% on white
  static const patientDark = turquoise;
  static const doctorDark = primary;

  static const accent = gold; // stars
  static const info = turquoise;

  // Status (no red anywhere)
  static const danger = emergency;
  static const success = primary;
  static const warning = gold; // pending
  static const error = Color(0xFF256868); // turquoise 55% + dark grey

  /// Soft shadow in the brand colour.
  static const shadow = [
    BoxShadow(color: Color(0x14126B50), blurRadius: 18, offset: Offset(0, 6)),
  ];

  /// Picks dark grey or white text, whichever contrasts more.
  static Color on(Color background) {
    double contrast(Color a, Color b) {
      final la = a.computeLuminance(), lb = b.computeLuminance();
      return (la > lb ? la + .05 : lb + .05) / (la > lb ? lb + .05 : la + .05);
    }

    return contrast(background, Colors.white) >= contrast(background, text)
        ? Colors.white
        : text;
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
    final isLight = brightness == Brightness.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
        ).copyWith(
          // Main buttons, switches, selections: emerald with white text.
          primary: isLight ? AppColors.primary : AppColors.secondary,
          onPrimary: isLight ? Colors.white : AppColors.primary,
          primaryContainer: AppColors.mint,
          onPrimaryContainer: AppColors.primary,
          // Secondary actions and icons: turquoise.
          secondary: AppColors.turquoise,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.turquoiseSoft,
          onSecondaryContainer: AppColors.turquoiseText,
          tertiary: AppColors.gold,
          onTertiary: AppColors.text,
          onSurface: isLight ? AppColors.text : Colors.white,
          onSurfaceVariant: isLight ? AppColors.grey : AppColors.offline,
          error: AppColors.error,
          outline: isLight ? AppColors.border : AppColors.darkOutline,
          outlineVariant: isLight ? AppColors.border : AppColors.darkOutline,
          surface: isLight ? AppColors.surface : AppColors.darkSurface,
          surfaceContainerLowest: isLight
              ? AppColors.surface
              : AppColors.darkSurface,
          surfaceContainerHighest: isLight
              ? AppColors.mint
              : AppColors.darkSurfaceHigh,
        );
    // El Messiri for the whole app (Arabic, French and English), bundled in
    // assets/fonts with its four weights, so it works offline.
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: 'ElMessiri',
    );
    final fontTheme = base.textTheme;
    final ink = isLight ? AppColors.text : Colors.white;
    final brand = isLight ? AppColors.primary : Colors.white;
    // Body text in dark grey; main titles in emerald.
    final textTheme = fontTheme
        .apply(bodyColor: ink, displayColor: ink)
        .copyWith(
          titleLarge: fontTheme.titleLarge?.copyWith(color: brand),
          headlineSmall: fontTheme.headlineSmall?.copyWith(color: brand),
          headlineMedium: fontTheme.headlineMedium?.copyWith(color: brand),
        );
    final radius16 = BorderRadius.circular(16);

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: isLight
          ? AppColors.background
          : AppColors.darkBackground,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: brand,
        iconTheme: IconThemeData(color: brand),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: brand,
        ),
      ),
      cardTheme: CardThemeData(
        // White cards, a fine mint border and a soft emerald shadow.
        elevation: isLight ? 2 : 0,
        shadowColor: const Color(0x1F126B50),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        color: isLight ? AppColors.surface : AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .7)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: isLight ? AppColors.turquoise : AppColors.secondary,
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      iconTheme: IconThemeData(
        color: isLight ? AppColors.turquoise : AppColors.secondary,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 24,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? AppColors.surface : AppColors.darkSurfaceHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        floatingLabelStyle: TextStyle(
          color: brand,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        prefixIconColor: isLight ? AppColors.turquoise : AppColors.secondary,
        border: OutlineInputBorder(
          borderRadius: radius16,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius16,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius16,
          borderSide: BorderSide(color: scheme.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius16,
          borderSide: const BorderSide(color: AppColors.error, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: isLight
              ? AppColors.border
              : AppColors.darkOutline,
          disabledForegroundColor: scheme.onSurfaceVariant,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: radius16),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          foregroundColor: brand,
          side: BorderSide(
            color: isLight ? AppColors.turquoise : AppColors.secondary,
            width: 1.4,
          ),
          shape: RoundedRectangleBorder(borderRadius: radius16),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isLight
              ? AppColors.turquoiseText
              : AppColors.secondary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: isLight ? AppColors.surface : AppColors.darkSurface,
        selectedColor: isLight ? AppColors.mint : AppColors.darkSurfaceHigh,
        checkmarkColor: brand,
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: textTheme.labelLarge?.copyWith(color: ink),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: brand,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? (isLight ? AppColors.mint : AppColors.darkSurfaceHigh)
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? brand : ink,
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : null,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : null,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.turquoise,
        linearTrackColor: AppColors.mint,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.text,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'ElMessiri',
        ),
        actionTextColor: AppColors.gold,
        shape: RoundedRectangleBorder(borderRadius: radius16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? AppColors.surface : AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: brand,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isLight ? AppColors.surface : AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: brand,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: isLight ? AppColors.turquoise : AppColors.secondary,
        dividerColor: scheme.outlineVariant,
      ),
      // Light bottom bar: white, the selected tab on a mint pill.
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        elevation: 3,
        shadowColor: const Color(0x22126B50),
        surfaceTintColor: Colors.transparent,
        backgroundColor: isLight ? AppColors.surface : AppColors.darkSurface,
        indicatorColor: isLight ? AppColors.mint : AppColors.darkSurfaceHigh,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? brand
                : (isLight ? AppColors.grey : AppColors.offline),
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? brand
                : (isLight ? AppColors.grey : AppColors.offline),
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isLight ? AppColors.surface : AppColors.darkSurface,
        indicatorColor: isLight ? AppColors.mint : AppColors.darkSurfaceHigh,
        selectedIconTheme: IconThemeData(color: brand),
        unselectedIconTheme: IconThemeData(
          color: isLight ? AppColors.grey : AppColors.offline,
        ),
        selectedLabelTextStyle: TextStyle(
          color: brand,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: isLight ? AppColors.grey : AppColors.offline,
        ),
      ),
    );
  }

  /// Theme used on the patient / doctor sign-in & sign-up screens:
  /// sky blue for patients, medical green for volunteer doctors.
  /// Buttons, text, focus borders and checkboxes use the darker shade of
  /// the role tone (white text on buttons for good contrast).
  static ThemeData forRole(ThemeData base, {required bool isDoctor}) {
    final isLight = base.brightness == Brightness.light;
    final tone = AppColors.role(isDoctor);
    final dark = AppColors.roleDark(isDoctor);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: isLight ? dark : tone,
        onPrimary: isLight ? Colors.white : AppColors.ink,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: base.filledButtonTheme.style?.copyWith(
          // Main buttons stay emerald for every role.
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? AppColors.border
                : AppColors.primary,
          ),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
        ),
      ),
    );
  }
}
