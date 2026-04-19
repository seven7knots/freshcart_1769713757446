# fix17.py
# Fix 1: Guard Supabase.instance access in initState — move auth listener
#         setup into postFrameCallback so Supabase is guaranteed initialized.
# Fix 2: Add mounted guard before Provider.of in _checkAuthAndNavigate.

with open('lib/presentation/auth_gate_screen/auth_gate_screen.dart', 'rb') as f:
    raw = f.read()

text = raw.decode('utf-8').replace('\r\n', '\n')

# ── Fix 1: Move _authSub setup into postFrameCallback ──────────────────────
old_init = """    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {"""

new_init = """    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
      // Set up auth listener here so Supabase is guaranteed initialized.
      // On fast devices initState runs before SupabaseService.initialize()
      // completes, causing "You must initialize the supabase instance" crash.
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {"""

# We also need to close the listen block properly - find the closing }) of the listen
# The old code has the listen block closed later, so we just replace the opening
if old_init in text:
    text = text.replace(old_init, new_init, 1)
    print('Fix 1: auth listener moved into postFrameCallback OK')
else:
    print('Fix 1: FAILED - could not find initState block')
    for i, line in enumerate(text.splitlines()):
        if 'addPostFrameCallback' in line or 'onAuthStateChange' in line:
            print(f'  {i+1}: {repr(line)}')

# ── Fix 2: Add mounted guard before Provider.of ────────────────────────────
old_provider = """    debugPrint('[AUTH_GATE] _checkAuthAndNavigate started');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);"""

new_provider = """    debugPrint('[AUTH_GATE] _checkAuthAndNavigate started');

    // Guard against deactivated widget — fast devices can trigger navigation
    // callbacks after the widget tree has already been torn down.
    if (!mounted || _navigated) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);"""

if old_provider in text:
    text = text.replace(old_provider, new_provider, 1)
    print('Fix 2: mounted guard added before Provider.of OK')
else:
    print('Fix 2: FAILED - could not find Provider.of block')

# ── Fix 3: Close the listen block properly after moving it ─────────────────
# The listen block's closing }); needs to move inside the postFrameCallback
# Find the pattern: the _authSub listen block closes with    });  then  }
# We need to also close the postFrameCallback after the listen block.

old_close = """      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();"""

new_close = """      }
      });
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();"""

if old_close in text:
    text = text.replace(old_close, new_close, 1)
    print('Fix 3: listen block closure fixed OK')
else:
    print('Fix 3: FAILED - could not find closing block')
    # Print surrounding lines for debug
    for i, line in enumerate(text.splitlines()):
        if 'dispose' in line or '_authSub?.cancel' in line:
            start = max(0, i-5)
            end = min(len(text.splitlines()), i+3)
            for j, l in enumerate(text.splitlines()[start:end], start=start+1):
                print(f'  {j}: {repr(l)}')
            break

with open('lib/presentation/auth_gate_screen/auth_gate_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print('fix17 done')
