import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Visual identity of "جمعية عون وسند الخيرية".
class AppColors {
  AppColors._();

  // Brand colors (from the association logo)
  static const navy = Color(0xFF282447);
  static const peach = Color(0xFFF3A995);

  // Role colors
  static const patient = Color(0xFF91AFCB); // sky blue  -> patients
  static const doctor = Color(0xFF6E9B87); // medical green -> doctors

  // Darker shades of the role/brand colors, used for text & icons on light
  // backgrounds where the original tone would not be readable enough.
  static const patientDark = Color(0xFF4D6F91);
  static const doctorDark = Color(0xFF4A7362);
  static const peachDark = Color(0xFFC4705A);
  static const navyLight = Color(0xFF433D72);

  static const primary = navy;
  static const secondary = peach;
  static const accent = Color(
    0xFFE0663F,
  ); // saturated coral (stars, highlights)
  static const info = Color(0xFF2F6DB5);

  // Strong, saturated status colors
  static const danger = Color(0xFFD7263D);
  static const success = Color(0xFF1F8A5B);
  static const warning = Color(0xFFF29E1F);

  // Solid surfaces (no transparency)
  static const background = Color(0xFFF4F3F9);
  static const border = Color(0xFFDCD9EA);

  /// Picks navy or white text, whichever contrasts more with [background].
  static Color on(Color background) {
    double contrast(Color a, Color b) {
      final la = a.computeLuminance(), lb = b.computeLuminance();
      return (la > lb ? la + .05 : lb + .05) / (la > lb ? lb + .05 : la + .05);
    }

    return contrast(background, Colors.white) >= contrast(background, navy)
        ? Colors.white
        : navy;
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
          seedColor: AppColors.navy,
          brightness: brightness,
        ).copyWith(
          primary: isLight ? AppColors.navy : AppColors.peach,
          onPrimary: isLight ? Colors.white : AppColors.navy,
          primaryContainer: isLight
              ? const Color(0xFFE6E4F2)
              : AppColors.navyLight,
          onPrimaryContainer: isLight ? AppColors.navy : Colors.white,
          secondary: AppColors.peach,
          onSecondary: AppColors.navy,
          secondaryContainer: isLight
              ? const Color(0xFFFCE6DF)
              : const Color(0xFF5A3E3B),
          onSecondaryContainer: isLight ? AppColors.navy : AppColors.peach,
          tertiary: AppColors.doctor,
          surface: isLight ? Colors.white : const Color(0xFF1D1A33),
          surfaceContainerLowest: isLight
              ? Colors.white
              : const Color(0xFF232040),
        );
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final textTheme = languageCode == 'ar'
        ? GoogleFonts.cairoTextTheme(base.textTheme)
        : GoogleFonts.poppinsTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: isLight
          ? const Color(0xFFF7F6FA)
          : const Color(0xFF16142A),
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
        indicatorColor: AppColors.peach,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// Theme used on the patient / doctor sign-in & sign-up screens:
  /// sky blue for patients, medical green for volunteer doctors.
  /// Buttons use the exact brand tone with navy text (good contrast);
  /// text, focus borders and checkboxes use the darker shade.
  static ThemeData forRole(ThemeData base, {required bool isDoctor}) {
    final isLight = base.brightness == Brightness.light;
    final tone = AppColors.role(isDoctor);
    final dark = AppColors.roleDark(isDoctor);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: isLight ? dark : tone,
        onPrimary: isLight ? Colors.white : AppColors.navy,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: base.filledButtonTheme.style?.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.disabled) ? AppColors.border : tone,
          ),
          foregroundColor: const WidgetStatePropertyAll(AppColors.navy),
        ),
      ),
    );
  }
}
