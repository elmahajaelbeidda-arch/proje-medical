import 'package:flutter/material.dart';

/// Visual identity of "شِفاءٌ لِلنّاس".
class AppColors {
  AppColors._();

  // Main palette (medical, calm and soft on the eyes)
  static const primary = Color(
    0xFF176B55,
  ); // dark medical green: titles, main buttons
  static const primaryDark = Color(0xFF0F5242); // gradients, pressed states
  static const calm = Color(
    0xFF55A879,
  ); // calm green: icons, secondary elements
  static const turquoise = Color(0xFF398B89); // medical turquoise: highlights
  static const secondary = Color(
    0xFFDCEFE5,
  ); // light green: secondary backgrounds
  static const background = Color(0xFFF3F7F5); // app background
  static const surface = Color(0xFFFFFFFF); // cards and inner spaces
  static const text = Color(0xFF263B36); // body text

  /// Urgent cases: medical turquoise (no red), always shown with an icon
  /// (priority / emergency) so they stay easy to spot.
  static const emergency = turquoise;

  // Aliases used across the screens
  static const ink = primary; // titles, brand name, dark surfaces
  static const teal = turquoise; // highlighted buttons and cards
  static const inkLight = Color(0xFF1F8A6E);
  static const green = calm; // tagline, highlights
  static const mint = secondary; // light fill with dark text on it
  static const grey = Color(0xFF5F716C); // secondary text, neutral icons

  // Role colors (soft tints of the palette)
  static const patient = Color(0xFFA9D6D4); // light turquoise -> patients
  static const doctor = Color(0xFFA8D8BC); // light calm green -> doctors

  // Darker shades of the role colors, for text, icons and borders.
  static const patientDark = turquoise;
  static const doctorDark = Color(0xFF3F8A60);

  static const accent = Color(0xFFD9A441); // soft gold (stars)
  static const info = Color(0xFF4F7F9E); // muted slate blue

  // Status colors (no red anywhere in the app).
  static const danger = emergency;
  static const success = calm;
  static const warning = Color(0xFFD9A441); // soft gold: pending
  static const error = Color(0xFF2C6F6D); // deep turquoise: form errors

  // Solid surfaces (no transparency)
  static const border = Color(0xFFCFE5D9);

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
          primary: isLight ? AppColors.primary : AppColors.secondary,
          onPrimary: isLight ? Colors.white : AppColors.primary,
          primaryContainer: AppColors.mint,
          onPrimaryContainer: AppColors.ink,
          secondary: AppColors.green,
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
        elevation: 0,
        margin: EdgeInsets.zero,
        // White cards on the soft green background.
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
      // Bottom bar in the primary green.
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: AppColors.primary,
        indicatorColor: AppColors.secondary,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : Colors.white,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: Colors.white,
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
