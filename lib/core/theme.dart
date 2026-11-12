import 'package:flutter/material.dart';

/// Visual identity of "شِفاءٌ لِلنّاس".
class AppColors {
  AppColors._();

  // Main palette: emerald for the brand and titles, vivid green for actions,
  // rich turquoise for icons and highlights, white cards, gold sparingly.
  static const primary = Color(0xFF126B50); // emerald: titles, brand
  static const primaryDark = Color(0xFF0D5640); // pressed states
  static const vivid = Color(0xFF269B72); // vivid green: buttons, actions
  static const turquoise = Color(
    0xFF258C91,
  ); // rich turquoise: icons, highlights
  static const secondary = Color(0xFFE4F1EB); // snow green: soft fills
  static const background = Color(0xFFF7F9F8); // white-grey app background
  static const surface = Color(0xFFFFFFFF); // cards and inner spaces
  static const text = Color(0xFF263B36); // body text
  static const gold = Color(0xFFD9A441); // calm gold: used sparingly

  /// Lively gradient for the few large colored boxes (intro, main action).
  static const heroGradient = [turquoise, vivid];

  /// Urgent cases: rich turquoise (no red), always with an icon
  /// (priority / emergency) so they stay easy to spot.
  static const emergency = turquoise;

  // Aliases used across the screens
  static const ink = primary; // titles, brand name
  static const teal = turquoise; // icon bubbles, highlighted buttons
  static const calm = vivid;
  static const inkLight = Color(0xFF1C8562);
  static const green = vivid; // tagline, highlights
  static const mint = secondary; // light fill with dark text on it
  static const grey = Color(0xFF5E706B); // secondary text, neutral icons

  // Role colors (soft tints of the palette)
  static const patient = Color(0xFFCDE8EA); // turquoise tint -> patients
  static const doctor = Color(0xFFCFEBDD); // green tint -> doctors

  // Darker shades of the role colors, for text, icons, borders and buttons.
  static const patientDark = turquoise;
  static const doctorDark = vivid;

  static const accent = gold; // stars
  static const info = Color(0xFF3F7DA6); // calm blue: information

  // Status colors (no red anywhere in the app).
  static const danger = emergency;
  static const success = vivid;
  static const warning = gold; // pending
  static const error = Color(0xFF1E7478); // deep turquoise: form errors

  // Solid surfaces (no transparency)
  static const border = Color(0xFFDCE8E2);

  /// Picks ink or white text, whichever contrasts more with [background].
  static Color on(Color background) {
    double contrast(Color a, Color b) {
      final la = a.computeLuminance(), lb = b.computeLuminance();
      return (la > lb ? la + .05 : lb + .05) / (la > lb ? lb + .05 : la + .05);
    }

    return contrast(background, Colors.white) >= contrast(background, ink)
        ? Colors.white
        : ink;
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
          // Buttons, switches, selections: vivid green.
          primary: isLight ? AppColors.vivid : AppColors.secondary,
          onPrimary: isLight ? Colors.white : AppColors.primary,
          primaryContainer: AppColors.mint,
          onPrimaryContainer: AppColors.ink,
          secondary: AppColors.turquoise,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.mint,
          onSecondaryContainer: AppColors.ink,
          tertiary: AppColors.turquoise,
          onTertiary: Colors.white,
          onSurface: isLight ? AppColors.text : Colors.white,
          error: AppColors.error,
          outlineVariant: isLight ? AppColors.border : const Color(0xFF2E5248),
          surface: isLight ? AppColors.surface : const Color(0xFF10291F),
          surfaceContainerLowest: isLight
              ? AppColors.surface
              : const Color(0xFF15342A),
        );
    // El Messiri for the whole app (Arabic and French), bundled in
    // assets/fonts with its four weights, so it works offline.
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: 'ElMessiri',
    );
    final fontTheme = base.textTheme;
    // Body text in dark grey; titles in the primary green.
    final textTheme = fontTheme
        .apply(
          bodyColor: isLight ? AppColors.text : Colors.white,
          displayColor: isLight ? AppColors.text : Colors.white,
        )
        .copyWith(
          titleLarge: fontTheme.titleLarge?.copyWith(
            color: isLight ? AppColors.primary : Colors.white,
          ),
          headlineSmall: fontTheme.headlineSmall?.copyWith(
            color: isLight ? AppColors.primary : Colors.white,
          ),
        );

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: isLight
          ? AppColors.background
          : const Color(0xFF0B201A),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isLight ? AppColors.primary : Colors.white,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: isLight ? AppColors.primary : Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        // White cards with a soft shadow on the white-grey background.
        elevation: isLight ? 1.5 : 0,
        shadowColor: const Color(0x1A126B50),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        color: isLight ? AppColors.surface : scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      // Light bottom bar: white, the selected tab on a snow-green pill.
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        elevation: 3,
        shadowColor: const Color(0x22126B50),
        surfaceTintColor: Colors.transparent,
        backgroundColor: isLight ? AppColors.surface : const Color(0xFF15342A),
        indicatorColor: isLight ? AppColors.secondary : AppColors.vivid,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? (isLight ? AppColors.vivid : Colors.white)
                : (isLight ? AppColors.grey : Colors.white70),
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? (isLight ? AppColors.primary : Colors.white)
                : (isLight ? AppColors.grey : Colors.white70),
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w500,
          ),
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
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.disabled) ? AppColors.border : dark,
          ),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
        ),
      ),
    );
  }
}
