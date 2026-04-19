import sys

file_path = r"C:\dev\kj_delivery_fresh\lib\main.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# ---- FIX 1: Add firebase_crashlytics import if missing ----
if "firebase_crashlytics" not in content:
    old_import = "import 'package:firebase_core/firebase_core.dart';"
    new_import = """import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';"""
    assert old_import in content, "ERROR: Could not find firebase_core import"
    content = content.replace(old_import, new_import, 1)

# ---- FIX 2: Add supabase_flutter import if missing (for AuthRetryableFetchException) ----
# Already imported — just verify
assert "supabase_flutter" in content, "ERROR: supabase_flutter import missing"

# ---- FIX 3: Wrap runApp in runZonedGuarded with Crashlytics error handling ----
# Replace the simple runApp block with zone-guarded version that catches auth errors

old_runapp = """  runApp(
    ProviderScope(
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
          ),
          provider.ChangeNotifierProvider<AdminProvider>.value(
            value: adminProvider,
          ),
          provider.ChangeNotifierProvider(create: (_) => MerchantProvider()),
          provider.ChangeNotifierProvider(create: (_) => NotificationsProvider()),
          provider.ChangeNotifierProvider<ThemeProvider>.value(
            value: themeProvider,
          ),
          provider.ChangeNotifierProvider<FavoritesProvider>.value(
            value: favoritesProvider,
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );"""

new_runapp = """  // SESSION 44: Global Flutter error handler — sends to Crashlytics
  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  // SESSION 44: Global async error handler — catches auth network errors as non-fatal
  PlatformDispatcher.instance.onError = (error, stack) {
    // Auth token refresh failures on bad network — non-fatal, expected
    final msg = error.toString();
    if (msg.contains('AuthRetryableFetchException') ||
        msg.contains('ClientException') ||
        msg.contains('SocketException') ||
        msg.contains('connection abort')) {
      debugPrint('[AUTH] Network error (non-fatal): \$msg');
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
      return true; // handled, don't crash
    }
    // Everything else — fatal
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(
    ProviderScope(
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
          ),
          provider.ChangeNotifierProvider<AdminProvider>.value(
            value: adminProvider,
          ),
          provider.ChangeNotifierProvider(create: (_) => MerchantProvider()),
          provider.ChangeNotifierProvider(create: (_) => NotificationsProvider()),
          provider.ChangeNotifierProvider<ThemeProvider>.value(
            value: themeProvider,
          ),
          provider.ChangeNotifierProvider<FavoritesProvider>.value(
            value: favoritesProvider,
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );"""

assert old_runapp in content, "ERROR: Could not find runApp block"
content = content.replace(old_runapp, new_runapp, 1)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("DONE — main.dart patched (auth network crashes now non-fatal)")
