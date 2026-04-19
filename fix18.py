# fix18.py
# Fix 1: main.dart — make Firebase init non-blocking so Supabase
#         initializes immediately without waiting for Firebase.
# Fix 2: auth_gate_screen.dart — wait for Supabase to be ready
#         before accessing Supabase.instance (fast device race condition).

# ── Fix 1: main.dart ────────────────────────────────────────────────────────
with open('lib/main.dart', 'rb') as f:
    raw = f.read()
main = raw.decode('utf-8').replace('\r\n', '\n')

old_firebase = """  try {
    await Firebase.initializeApp();
    await AnalyticsService.initialize();
    debugPrint('Firebase and Analytics initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization skipped or failed: $e');
  }

  try {
    await SupabaseService.initialize();
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }"""

new_firebase = """  // Supabase MUST initialize before runApp — it is the critical path.
  // Firebase is non-blocking: it fires async and resolves in background.
  // This eliminates the race where Firebase blocks Supabase on fast devices,
  // causing "You must initialize the supabase instance" crashes on first frame.
  Firebase.initializeApp().then((_) async {
    try {
      await AnalyticsService.initialize();
      debugPrint('Firebase and Analytics initialized successfully');
    } catch (e) {
      debugPrint('Analytics init failed (non-fatal): $e');
    }
  }).catchError((e) {
    debugPrint('Firebase initialization skipped or failed: $e');
  });

  try {
    await SupabaseService.initialize();
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
    // Do not proceed — AuthGate and all screens require Supabase.
    rethrow;
  }"""

if old_firebase in main:
    main = main.replace(old_firebase, new_firebase, 1)
    print('main.dart: Firebase made non-blocking OK')
else:
    print('main.dart: FAILED - printing Firebase block lines:')
    for i, line in enumerate(main.splitlines()):
        if 'Firebase' in line or 'SupabaseService' in line or 'Analytics' in line:
            print(f'  {i+1}: {repr(line)}')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(main)

# ── Fix 2: auth_gate_screen.dart — wait for Supabase before access ──────────
with open('lib/presentation/auth_gate_screen/auth_gate_screen.dart', 'rb') as f:
    raw2 = f.read()
gate = raw2.decode('utf-8').replace('\r\n', '\n')

old_check = """  Future<void> _checkAuthAndNavigate() async {
    if (!mounted || _navigated) return;

    debugPrint('[AUTH_GATE] _checkAuthAndNavigate started');

    // Guard against deactivated widget — fast devices can trigger navigation
    // callbacks after the widget tree has already been torn down.
    if (!mounted || _navigated) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);"""

new_check = """  Future<void> _checkAuthAndNavigate() async {
    if (!mounted || _navigated) return;

    debugPrint('[AUTH_GATE] _checkAuthAndNavigate started');

    // Guard against deactivated widget — fast devices can trigger navigation
    // callbacks after the widget tree has already been torn down.
    if (!mounted || _navigated) return;

    // Wait for Supabase to finish initializing — on fast devices (Android 15)
    // the warm-up frame fires before SupabaseService.initialize() completes.
    int sbAttempts = 0;
    while (sbAttempts < 50) {
      try {
        Supabase.instance; // throws if not initialized
        break;
      } catch (_) {
        sbAttempts++;
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted || _navigated) return;
      }
    }
    if (sbAttempts >= 50) {
      debugPrint('[AUTH_GATE] Supabase never initialized — aborting navigation');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);"""

if old_check in gate:
    gate = gate.replace(old_check, new_check, 1)
    print('auth_gate_screen.dart: Supabase readiness wait added OK')
else:
    print('auth_gate_screen.dart: FAILED - printing _checkAuthAndNavigate lines:')
    for i, line in enumerate(gate.splitlines()):
        if '_checkAuthAndNavigate' in line or 'authProvider' in line:
            print(f'  {i+1}: {repr(line)}')

with open('lib/presentation/auth_gate_screen/auth_gate_screen.dart', 'w', encoding='utf-8') as f:
    f.write(gate)

print('fix18 done')
