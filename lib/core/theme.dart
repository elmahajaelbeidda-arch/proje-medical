import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Visual identity of "شِفاءٌ لِلنّاس".
class AppColors {
  AppColors._();

  // Main palette
  static const primary = Color(0xFF0A5C36); // emerald: titles, buttons, nav
  static const primaryDark = Color(0xFF07432A); // gradients, pressed states
  static const secondary = Color(0xFFE8F5E9); // mint: cards and boxes
  static const emergency = Color(0xFFD9534F); // emergencies & urgent only
  static const background = Color(0xFFF8F9FA); // app background
  static const text = Color(0xFF2C3E50); // body text

  // Aliases used across the screens
  static const ink = primary; // titles, brand name, dark surfaces
  static const teal = primary; // buttons, icons
  static const inkLight = Color(0xFF0E7A48);
  static const green = Color(0xFF1E8449); // tagline, highlights
  static const mint = secondary; // light fill with dark text on it
  static const grey = Color(0xFF5B6168); // secondary text, neutral icons

  // Role colors
  static const patient = Color(0xFF91AFCB); // sky blue  -> patients
  static const doctor = Color(0xFF6E9B87); // medical green -> doctors

  // Darker shades of the role/brand colors, used for text & icons on light
  // backgrounds where the original tone would not be readable enough.
  static const patientDark = Color(0xFF4D6F91);
  static const doctorDark = Color(0xFF4A7362);

  static const accent = Color(0xFFF29E1F); // amber (stars, highlights)
  static const info = Color(0xFF2F6DB5);

  // Status colors. [danger] is the emergency red: only for emergencies and
  // urgent requests.
  static const danger = emergency;
  static const success = Color(0xFF1F8A5B);
  static const warning = Color(0xFFF29E1F);

  // Solid surfaces (no transparency)
  static const border = Color(0xFFD5E8D8);

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
          tertiary: AppColors.doctor,
          onSurface: isLight ? AppColors.text : Colors.white,
          error: AppColors.emergency,
          outlineVariant: isLight ? AppColors.border : const Color(0xFF2A5552),
          surface: isLight ? Colors.white : const Color(0xFF102E2D),
          surfaceContainerLowest: isLight
              ? Colors.white
              : const Color(0xFF143837),
        );
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final fontTheme = languageCode == 'ar'
        ? GoogleFonts.cairoTextTheme(base.textTheme)
        : GoogleFonts.poppinsTextTheme(base.textTheme);
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
          : const Color(0xFF0C2423),
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
        // Mint cards and boxes for comfortable reading.
        color: isLight ? AppColors.secondary : scheme.surfaceContainerLowest,
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
  /// Buttons use the exact brand tone with dark text (good contrast);
  /// text, focus borders and checkboxes use the darker shade.
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
                states.contains(WidgetState.disabled) ? AppColors.border : tone,
          ),
          foregroundColor: const WidgetStatePropertyAll(AppColors.ink),
        ),
      ),
    );
  }
}
