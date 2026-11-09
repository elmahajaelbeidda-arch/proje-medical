import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Visual identity of "شِفاءٌ لِلنّاس" (heart + cross logo).
class AppColors {
  AppColors._();

  // Brand colors (from the app logo)
  static const ink = Color(0xFF0B4747); // dark teal: titles, dark surfaces
  static const teal = Color(0xFF0E7C7B); // heart (left) + cross
  static const green = Color(0xFF2E9E5A); // heart (right)
  static const mint = Color(0xFF8ED1A8); // light green fill (dark text on it)
  static const inkLight = Color(0xFF136262);
  static const grey = Color(0xFF5B6168); // association line in the logo

  // Role colors
  static const patient = Color(0xFF91AFCB); // sky blue  -> patients
  static const doctor = Color(0xFF6E9B87); // medical green -> doctors

  // Darker shades of the role/brand colors, used for text & icons on light
  // backgrounds where the original tone would not be readable enough.
  static const patientDark = Color(0xFF4D6F91);
  static const doctorDark = Color(0xFF4A7362);

  static const primary = teal;
  static const secondary = green;
  static const accent = Color(0xFFF29E1F); // amber (stars, highlights)
  static const info = Color(0xFF2F6DB5);

  // Strong, saturated status colors
  static const danger = Color(0xFFD7263D);
  static const success = Color(0xFF1F8A5B);
  static const warning = Color(0xFFF29E1F);

  // Solid surfaces (no transparency)
  static const background = Color(0xFFF2F7F6);
  static const border = Color(0xFFD3E3E0);

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
          seedColor: AppColors.teal,
          brightness: brightness,
        ).copyWith(
          primary: isLight ? AppColors.teal : AppColors.mint,
          onPrimary: isLight ? Colors.white : AppColors.ink,
          primaryContainer: AppColors.mint,
          onPrimaryContainer: AppColors.ink,
          secondary: AppColors.green,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.mint,
          onSecondaryContainer: AppColors.ink,
          tertiary: AppColors.doctor,
          outlineVariant: isLight ? AppColors.border : const Color(0xFF2A5552),
          surface: isLight ? Colors.white : const Color(0xFF102E2D),
          surfaceContainerLowest: isLight
              ? Colors.white
              : const Color(0xFF143837),
        );
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final textTheme = languageCode == 'ar'
        ? GoogleFonts.cairoTextTheme(base.textTheme)
        : GoogleFonts.poppinsTextTheme(base.textTheme);

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
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLowest,
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
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: AppColors.mint,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
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
