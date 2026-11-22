import 'package:flutter/material.dart';

/// Visual identity of "شِفاءٌ لِلنّاس" (clean, iOS / Material 3 style).
///
/// Palette of the design brief. The few extra shades are noted: they are
/// deeper tones of the same colours, used only where small text needs
/// more contrast (WCAG AA, for older readers).
class AppColors {
  AppColors._();

  // ---- The palette --------------------------------------------------------
  static const primary = Color(0xFF2F6B55); // green: brand, main actions
  static const primaryDark = Color(0xFF234F40); // pressed states, headings
  static const turquoise = Color(0xFF4A8A90); // blue-green: secondary, icons
  static const secondary = Color(0xFFE6F0EB); // light mint: secondary fills
  static const background = Color(0xFFF6F8F7); // page background
  static const surface = Color(0xFFFFFFFF); // cards
  static const text = Color(0xFF1F2A26); // main text
  static const grey = Color(0xFF6B7A74); // secondary text
  static const border = Color(0xFFE3E8E6); // borders and dividers
  static const emergency = Color(0xFFD9534F); // emergency only
  static const emergencySoft = Color(0xFFFCEBEA); // emergency background
  static const answered = Color(0xFF3BA776); // status "answered"
  static const reviewing = Color(0xFFE0A030); // status "under review"
  static const navInactive = Color(0xFF9AA6A1); // inactive tab icons

  // ---- Deeper tones for small text (contrast AA) ---------------------------
  static const turquoiseText = Color(0xFF447C80); // links, verse
  static const emergencyText = Color(0xFFB44B47); // emergency text on its tint
  static const answeredText = Color(0xFF2E6F52); // on answeredSoft
  static const reviewingText = Color(0xFF896B2C); // on reviewingSoft
  static const answeredSoft = Color(0xFFE2F2EA); // answered 15% on white
  static const reviewingSoft = Color(0xFFFAF1E0); // reviewing 15% on white

  // Older names kept for the other screens.
  static const fieldFill = background;
  static const turquoiseSoft = secondary;
  static const emeraldTeal = turquoise;
  static const offline = navInactive;

  // Dark mode
  static const darkBackground = Color(0xFF16201D);
  static const darkSurface = Color(0xFF1F2A26);
  static const darkSurfaceHigh = Color(0xFF283631);
  static const darkOutline = Color(0xFF3A4A44);

  /// Flat colour for the large coloured areas (no gradients).
  static const heroGradient = [primary, primary];

  // ---- Aliases used across the screens -----------------------------------
  static const vivid = turquoise; // lively highlights (numbers, likes, ticks)
  static const ink = primary;
  static const teal = turquoise;
  static const calm = turquoise;
  static const inkLight = emeraldTeal;
  static const green = primary;
  static const mint = secondary;

  // Role tints (patients: turquoise, doctors: emerald)
  static const patient = secondary;
  static const doctor = secondary;
  static const patientDark = turquoise;
  static const doctorDark = primary;

  static const accent = reviewing; // stars
  static const info = turquoise;

  // Status
  static const danger = emergency;
  static const success = answered;
  static const warning = reviewing;
  static const error = emergencyText;

  /// Very light shadow: 0 2 8, 6 %.
  static const shadow = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
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
          tertiary: AppColors.turquoise,
          onTertiary: Colors.white,
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
    // Type scale of the brief: 22 large title, 18 card title, 15 body,
    // 13 small (secondary colour), 11 tab labels; line height 1.6.
    final muted = isLight ? AppColors.grey : AppColors.navInactive;
    final textTheme = fontTheme
        .apply(bodyColor: ink, displayColor: ink)
        .copyWith(
          headlineMedium: fontTheme.headlineMedium?.copyWith(color: brand),
          headlineSmall: fontTheme.headlineSmall?.copyWith(
            color: brand,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: fontTheme.titleLarge?.copyWith(
            color: brand,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: fontTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          titleSmall: fontTheme.titleSmall?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: fontTheme.bodyLarge?.copyWith(fontSize: 15, height: 1.6),
          bodyMedium: fontTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.6),
          bodySmall: fontTheme.bodySmall?.copyWith(
            fontSize: 13,
            height: 1.6,
            color: muted,
          ),
          labelSmall: fontTheme.labelSmall?.copyWith(fontSize: 11),
        );
    final radius16 = BorderRadius.circular(16);
    final radius12 = BorderRadius.circular(12);

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
        // White cards, 16 corners, a very light shadow and no border.
        elevation: isLight ? 1 : 0,
        shadowColor: const Color(0x0F000000),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        color: isLight ? AppColors.surface : AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: radius16),
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
        shape: RoundedRectangleBorder(borderRadius: radius12),
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
        actionTextColor: AppColors.secondary,
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
