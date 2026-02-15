// ============================================================
// FILE: lib/theme/app_theme.dart
// ============================================================
// Light mode: Red AppBar + Red BottomNav (white icons/text)
// Dark mode:  Dark surface AppBar + Dark BottomNav (NO red bars)
// Flutter 3.29+ compatible (*ThemeData naming)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color accentLight = Color(0xFF4CAF50);
  static const Color textOnLight = Color(0xFF212121);

  // Brand
  static const Color kjRed = Color(0xFFE50914);
  static const Color kjRedDark = Color(0xFFFF3B30);

  // Light palette
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color errorLight = Color(0xFFDC3545);

  // Dark palette
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color borderDark = Color(0xFF2D3748);
  static const Color errorDark = Color(0xFFEF5350);

  static const Color primaryLight = kjRed;
  static const Color primaryDark = kjRedDark;

  static const LinearGradient gradientAccent = LinearGradient(
    colors: [Color(0xFFE10600), Color(0xFFFF3B30)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color textPrimaryOf(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  static Color textSecondaryOf(BuildContext context) => Theme.of(context).colorScheme.onSurface.withOpacity(0.70);
  static Color surfaceOf(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color backgroundOf(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static String themeLabelOf(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? 'Dark mode' : 'Light mode';

  static bool resolvedIsDark({required BuildContext context, required ThemeMode themeMode}) {
    if (themeMode == ThemeMode.dark) return true;
    if (themeMode == ThemeMode.light) return false;
    return Theme.of(context).brightness == Brightness.dark;
  }

  // --------- ColorSchemes ---------

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
    onSurface: Color(0xFFEAEAEA),
    surfaceContainerHighest: Color(0xFF2A2A2A),
    onSurfaceVariant: Color(0xFFBEBEBE),
    outline: borderDark,
    outlineVariant: Color(0xFF3A475C),
    shadow: Color(0x1FFFFFFF),
    scrim: Color(0x99000000),
    inverseSurface: Color(0xFFEAEAEA),
    onInverseSurface: Color(0xFF1C1C1C),
    inversePrimary: Color(0xFFE50914),
  );

  // --------- Public themes ---------

  static final ThemeData lightTheme = _buildTheme(_schemeLight);
  static final ThemeData darkTheme = _buildTheme(_schemeDark);

  static ThemeData _buildTheme(ColorScheme cs) {
    final bool isLight = cs.brightness == Brightness.light;

    final base = ThemeData(
      useMaterial3: true,
      brightness: cs.brightness,
      colorScheme: cs,
      scaffoldBackgroundColor: isLight ? backgroundLight : backgroundDark,
      fontFamily: GoogleFonts.inter().fontFamily,
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: cs.onSurface,
      displayColor: cs.onSurface,
    );

    return base.copyWith(
      textTheme: textTheme,

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: cs.primary,
        selectionColor: cs.primary.withOpacity(0.20),
        selectionHandleColor: cs.primary,
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: cs.surfaceContainerHighest.withOpacity(isLight ? 1.0 : 0.55),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.60)),
        labelStyle: TextStyle(color: cs.onSurface.withOpacity(0.80)),
        floatingLabelStyle: TextStyle(color: cs.primary),
        errorStyle: TextStyle(color: cs.error),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: cs.outline.withOpacity(0.70)), borderRadius: const BorderRadius.all(Radius.circular(12))),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: cs.primary, width: 1.6), borderRadius: const BorderRadius.all(Radius.circular(12))),
        errorBorder: OutlineInputBorder(borderSide: BorderSide(color: cs.error, width: 1.2), borderRadius: const BorderRadius.all(Radius.circular(12))),
        focusedErrorBorder: OutlineInputBorder(borderSide: BorderSide(color: cs.error, width: 1.6), borderRadius: const BorderRadius.all(Radius.circular(12))),
      ),

      // AppBar: RED in light, dark surface in dark
      appBarTheme: AppBarThemeData(
        backgroundColor: isLight ? kjRed : surfaceDark,
        foregroundColor: isLight ? Colors.white : cs.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: isLight ? Colors.white : cs.onSurface),
        iconTheme: IconThemeData(color: isLight ? Colors.white : cs.onSurface),
        actionsIconTheme: IconThemeData(color: isLight ? Colors.white : cs.onSurface),
      ),

      // Card
      cardTheme: CardThemeData(
        color: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Icons
      iconTheme: IconThemeData(color: cs.onSurface, size: 24),

      // Divider
      dividerTheme: DividerThemeData(color: cs.outlineVariant.withOpacity(0.90), thickness: 1, space: 1),

      // BottomNavigationBar: RED in light, dark surface in dark
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isLight ? kjRed : surfaceDark,
        selectedItemColor: isLight ? Colors.white : cs.primary,
        unselectedItemColor: isLight ? Colors.white.withOpacity(0.60) : cs.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: cs.onSurface),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: cs.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // BottomSheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      ),

      // PopupMenu
      popupMenuTheme: PopupMenuThemeData(
        color: cs.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: GoogleFonts.inter(fontSize: 14, color: cs.onSurface),
      ),

      // ListTile
      listTileTheme: ListTileThemeData(
        textColor: cs.onSurface,
        iconColor: cs.onSurface,
        subtitleTextStyle: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainerHighest,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: cs.onSurface),
        side: BorderSide(color: cs.outline.withOpacity(0.5)),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary;
          return cs.onSurface.withOpacity(0.4);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary.withOpacity(0.3);
          return cs.onSurface.withOpacity(0.1);
        }),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cs.inverseSurface,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: cs.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      // TabBar
      tabBarTheme: TabBarThemeData(
        labelColor: cs.onSurface,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicatorColor: cs.primary,
      ),

      // NavigationBar (M3): RED in light, dark in dark
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isLight ? kjRed : surfaceDark,
        indicatorColor: isLight ? Colors.white.withOpacity(0.2) : cs.primary.withOpacity(0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return IconThemeData(color: isLight ? Colors.white : cs.primary);
          return IconThemeData(color: isLight ? Colors.white.withOpacity(0.6) : cs.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: isLight ? Colors.white : cs.primary);
          return GoogleFonts.inter(fontSize: 11, color: isLight ? Colors.white.withOpacity(0.6) : cs.onSurfaceVariant);
        }),
      ),

      // Drawer
      drawerTheme: DrawerThemeData(backgroundColor: cs.surface, surfaceTintColor: Colors.transparent),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
    );
  }

  static TextTheme buildTextTheme({required bool isLight}) {
    final cs = isLight ? _schemeLight : _schemeDark;
    return GoogleFonts.interTextTheme().apply(bodyColor: cs.onSurface, displayColor: cs.onSurface);
  }
}