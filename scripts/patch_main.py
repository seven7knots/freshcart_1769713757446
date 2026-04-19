#!/usr/bin/env python3
"""Patch main.dart to add locale support."""

import os

MAIN_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'lib', 'main.dart')

with open(MAIN_PATH, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add imports
old_imports_end = "import './widgets/custom_error_widget.dart';\nimport './utils/route_guard.dart';"
new_imports = """import './widgets/custom_error_widget.dart';
import './utils/route_guard.dart';
import './providers/locale_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import './l10n/generated/app_localizations.dart';"""

content = content.replace(old_imports_end, new_imports)

# 2. Add localeProvider initialization before runApp
old_theme_init = """  final themeProvider = ThemeProvider();
  await themeProvider.init();"""
new_theme_init = """  final themeProvider = ThemeProvider();
  await themeProvider.init();

  final localeProvider = LocaleProvider();
  await localeProvider.init();"""

content = content.replace(old_theme_init, new_theme_init)

# 3. Add LocaleProvider to MultiProvider
old_providers = """          provider.ChangeNotifierProvider<FavoritesProvider>.value(value: favoritesProvider),"""
new_providers = """          provider.ChangeNotifierProvider<FavoritesProvider>.value(value: favoritesProvider),
          provider.ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),"""

content = content.replace(old_providers, new_providers)

# 4. Update MaterialApp to add locale support
# Replace the entire build method of MyApp
old_build = """  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return provider.Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKey,
              title: 'FreshCart',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              initialRoute: AppRoutes.initial,
              onGenerateRoute: _guardedRoute,
              routes: AppRoutes.routes,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.0),
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
            );
          },
        );
      },
    );
  }"""

new_build = """  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return provider.Consumer2<ThemeProvider, LocaleProvider>(
          builder: (context, themeProvider, localeProvider, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKey,
              title: 'KJ Delivery',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              locale: localeProvider.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              initialRoute: AppRoutes.initial,
              onGenerateRoute: _guardedRoute,
              routes: AppRoutes.routes,
              builder: (context, child) {
                return Directionality(
                  textDirection: localeProvider.isArabic ? TextDirection.rtl : TextDirection.ltr,
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: const TextScaler.linear(1.0),
                    ),
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }"""

content = content.replace(old_build, new_build)

with open(MAIN_PATH, 'w', encoding='utf-8') as f:
    f.write(content)

print("main.dart patched successfully")
