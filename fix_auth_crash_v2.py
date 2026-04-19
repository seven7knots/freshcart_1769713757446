import sys

file_path = r"C:\dev\kj_delivery_fresh\lib\main.dart"

with open(file_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

# ---- FIX 1: Add firebase_crashlytics import if missing ----
has_crashlytics_import = any("firebase_crashlytics" in line for line in lines)
if not has_crashlytics_import:
    for i, line in enumerate(lines):
        if "firebase_core/firebase_core.dart" in line:
            lines.insert(i + 1, "import 'package:firebase_crashlytics/firebase_crashlytics.dart';\n")
            print("  Added firebase_crashlytics import")
            break

# ---- FIX 2: Insert error handlers before runApp() ----
# Find the line that starts with "  runApp(" (first occurrence)
runapp_idx = None
for i, line in enumerate(lines):
    if line.strip().startswith("runApp("):
        runapp_idx = i
        break

assert runapp_idx is not None, "ERROR: Could not find runApp( line"

# Check if we already patched (avoid double-patching)
already_patched = any("SESSION 44: Global Flutter error handler" in line for line in lines)
if already_patched:
    print("ALREADY PATCHED — skipping")
    sys.exit(0)

error_handler_block = r"""  // SESSION 44: Global Flutter error handler — sends to Crashlytics
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
      debugPrint('[AUTH] Network error (non-fatal): $msg');
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
      return true; // handled, don't crash
    }
    // Everything else — fatal
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

"""

lines.insert(runapp_idx, error_handler_block)

with open(file_path, "w", encoding="utf-8") as f:
    f.writelines(lines)

print("DONE — main.dart patched (auth network crashes now non-fatal)")
