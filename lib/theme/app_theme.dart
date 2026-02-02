// BUILD_CHECK_12345
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTheme
/// Material 3 light/dark themes with consistent ColorScheme + theme-aware components.
/// Fixes mixed dark UI by removing hardcoded styling and deriving component colors
/// from the active ColorScheme.
class AppTheme {
  AppTheme._();

  // Static color properties for backward compatibility
  static const Color accentLight = Color(0xFF4CAF50);
  static const Color textOnLight = Color(0xFF212121);

  // Brand
  static const Color kjRed = Color(0xFFE50914);

  // Light palette
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color errorLight = Color(0xFFDC3545);

  // Dark palette
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color borderDark = Color(0xFF2D3748);
  static const Color errorDark = Color(0xFFEF5350);

  static const Color primaryLight = kjRed;
  static const Color primaryDark = Color(0xFFFF3B30);

  // Optional gradient reserved for primary CTA
  static const LinearGradient gradientAccent = LinearGradient(
    colors: [Color(0xFFE10600), Color(0xFFFF3B30)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Theme-aware helpers (safe for UI decisions)
  static Color textPrimaryOf(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color textSecondaryOf(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.70);

  static Color surfaceOf(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color backgroundOf(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static String themeLabelOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? 'Dark mode' : 'Light mode';

  /// Returns the correct switch value even if ThemeMode.system is used.
  static bool resolvedIsDark({
    required BuildContext context,
    required ThemeMode themeMode,
  }) {
    if (themeMode == ThemeMode.dark) return true;
    if (themeMode == ThemeMode.light) return false;
    return Theme.of(context).brightness == Brightness.dark;
  }

  // --------- ColorSchemes (single source of truth) ---------

  static const ColorScheme _schemeLight = ColorScheme(
    brightness: Brightness.light,
    primary: primaryLight,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFFFDAD6),
    onPrimaryContainer: Color(0xFF410002),
    secondary: Color(0xFFF5F5F5),
    onSecondary: Color(0xFF111111),
    secondaryContainer: Color(0xFFECECEC),
    onSecondaryContainer: Color(0xFF111111),
    tertiary: Color(0xFFFF3B47),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFFDAD9),
    onTertiaryContainer: Color(0xFF3F0010),
    error: errorLight,
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: surfaceLight,
    onSurface: Color(0xFF111111),
    surfaceContainerHighest: Color(0xFFF3F3F3),
    onSurfaceVariant: Color(0xFF444444),
    outline: borderLight,
    outlineVariant: Color(0xFFCCCCCC),
    shadow: Color(0x14000000),
    scrim: Color(0x66000000),
    inverseSurface: Color(0xFF1C1C1C),
    onInverseSurface: Color(0xFFF5F5F5),
    inversePrimary: Color(0xFFFFB4AB),
  );

  static const ColorScheme _schemeDark = ColorScheme(
    brightness: Brightness.dark,
    primary: primaryDark,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF930000),
    onPrimaryContainer: Color(0xFFFFDAD6),
    secondary: Color(0xFF1A202C),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF2A3142),
    onSecondaryContainer: Colors.white,
    tertiary: Color(0xFFFF3B30),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFF7A0000),
    onTertiaryContainer: Color(0xFFFFDAD6),
    error: errorDark,
    onError: Colors.white,
    errorContainer: Color(0xFF930000),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: surfaceDark,
    onSurface: Colors.white,
    surfaceContainerHighest: Color(0xFF242424),
    onSurfaceVariant: Color(0xFFBEBEBE),
    outline: borderDark,
    outlineVariant: Color(0xFF3A475C),
    shadow: Color(0x1FFFFFFF),
    scrim: Color(0x99000000),
    inverseSurface: Color(0xFFEAEAEA),
    onInverseSurface: Color(0xFF1C1C1C),
    inversePrimary: Color(0xFFE50914),
  );

  // --------- Component themes derived from ColorScheme ---------

  static InputDecorationThemeData _inputThemeFrom(
    ColorScheme cs, {
    double radius = 12,
  }) {
    final Color fill = cs.surfaceContainerHighest.withOpacity(
      cs.brightness == Brightness.dark ? 0.55 : 1.0,
    );

    return InputDecorationThemeData(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.60)),
      labelStyle: TextStyle(color: cs.onSurface.withOpacity(0.80)),
      floatingLabelStyle: TextStyle(color: cs.primary),
      errorStyle: TextStyle(color: cs.error),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: cs.outline.withOpacity(0.70)),
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: cs.primary, width: 1.6),
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: cs.error, width: 1.2),
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: cs.error, width: 1.6),
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      ),
    );
  }

  static AppBarThemeData _appBarThemeFrom(ColorScheme cs) {
    return AppBarThemeData(
      backgroundColor: cs.surface,
      foregroundColor: cs.onSurface,
      surfaceTintColor: Colors.transparent, // avoids "washed" surfaces in M3
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
      iconTheme: IconThemeData(color: cs.onSurface),
    );
  }

  static CardThemeData _cardThemeFrom(ColorScheme cs) {
    return CardThemeData(
      color: cs.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonThemeFrom(ColorScheme cs) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  static TextButtonThemeData _textButtonThemeFrom(ColorScheme cs) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: cs.primary,
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  static DividerThemeData _dividerThemeFrom(ColorScheme cs) {
    return DividerThemeData(
      color: cs.outlineVariant.withOpacity(0.90),
      thickness: 1,
      space: 1,
    );
  }

  static BottomNavigationBarThemeData _bottomNavThemeFrom(ColorScheme cs) {
    return BottomNavigationBarThemeData(
      backgroundColor: cs.surface,
      selectedItemColor: cs.primary,
      unselectedItemColor: cs.onSurface.withOpacity(0.60),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    );
  }

  static IconThemeData _iconThemeFrom(ColorScheme cs) {
    return IconThemeData(color: cs.onSurface, size: 24);
  }

  // --------- Public themes ---------

  static final ThemeData lightTheme = _buildTheme(_schemeLight);
  static final ThemeData darkTheme = _buildTheme(_schemeDark);

  static ThemeData _buildTheme(ColorScheme cs) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: cs.brightness,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      fontFamily: GoogleFonts.inter().fontFamily,
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: cs.onSurface,
      displayColor: cs.onSurface,
    );

    return base.copyWith(
      textTheme: textTheme,

      // Selection
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: cs.primary,
        selectionColor: cs.primary.withOpacity(0.20),
        selectionHandleColor: cs.primary,
      ),

      // Inputs
      inputDecorationTheme: _inputThemeFrom(cs, radius: 12),

      // AppBar / Cards
      appBarTheme: _appBarThemeFrom(cs),
      cardTheme: _cardThemeFrom(cs),

      // Buttons
      elevatedButtonTheme: _elevatedButtonThemeFrom(cs),
      textButtonTheme: _textButtonThemeFrom(cs),

      // Icons / Dividers / Bottom nav
      iconTheme: _iconThemeFrom(cs),
      dividerTheme: _dividerThemeFrom(cs),
      bottomNavigationBarTheme: _bottomNavThemeFrom(cs),
    );
  }

  // Kept for compatibility if older parts of your code call it.
  static TextTheme buildTextTheme({required bool isLight}) {
    final cs = isLight ? _schemeLight : _schemeDark;
    return GoogleFonts.interTextTheme().apply(
      bodyColor: cs.onSurface,
      displayColor: cs.onSurface,
    );
  }
}
