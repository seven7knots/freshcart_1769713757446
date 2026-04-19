# fix21b.py
# 1. Register FavoritesProvider in main.dart
# 2. Fix cart ScaffoldMessenger deactivated widget crash

# ── Fix 1: main.dart ───────────────────────────────────────────────────────
path1 = 'lib/main.dart'
with open(path1, 'rb') as f:
    text = f.read().decode('utf-8').replace('\r\n', '\n')

changed = False

# Add import
if 'favorites_provider' not in text:
    text = text.replace(
        "import './providers/notifications_provider.dart';",
        "import './providers/notifications_provider.dart';\nimport './providers/favorites_provider.dart';",
        1
    )
    print('main.dart: added import OK')
else:
    print('main.dart: import already present')

# Create instance
if 'favoritesProvider' not in text:
    text = text.replace(
        '  final authProvider = AuthProvider();\n  final adminProvider = AdminProvider();',
        '  final authProvider = AuthProvider();\n  final adminProvider = AdminProvider();\n  final favoritesProvider = FavoritesProvider();',
        1
    )
    print('main.dart: created instance OK')
else:
    print('main.dart: instance already present')

# Register in MultiProvider
if 'FavoritesProvider>.value' not in text:
    text = text.replace(
        '          provider.ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),\n        ],',
        '          provider.ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),\n          provider.ChangeNotifierProvider<FavoritesProvider>.value(value: favoritesProvider),\n        ],',
        1
    )
    print('main.dart: registered in MultiProvider OK')
else:
    print('main.dart: already registered')

# Load on startup - find the line after initial admin check
lines = text.splitlines()
for i, line in enumerate(lines):
    if 'app-startup-existing-session' in line and 'checkAdminStatus' in line:
        # Find the debugPrint line right after
        for j in range(i, min(i+5, len(lines))):
            if 'Initial admin status' in lines[j] and 'favoritesProvider.loadFavorites' not in lines[j+1]:
                lines.insert(j+1, '      favoritesProvider.loadFavorites();')
                print('main.dart: added loadFavorites() on startup OK')
                break
        break
text = '\n'.join(lines)

# Load on sign-in
lines = text.splitlines()
for i, line in enumerate(lines):
    if 'supabase-auth-signed-in' in line:
        # Find closing }); of the then block
        for j in range(i, min(i+8, len(lines))):
            if lines[j].strip() == '});' and 'favoritesProvider.loadFavorites' not in lines[j+1]:
                lines.insert(j+1, '        favoritesProvider.loadFavorites();')
                print('main.dart: added loadFavorites() on sign-in OK')
                break
        break
text = '\n'.join(lines)

# Clear on sign-out
lines = text.splitlines()
for i, line in enumerate(lines):
    if 'Admin status will reset to false' in line and 'favoritesProvider.clear' not in lines[i-1]:
        lines.insert(i, '        favoritesProvider.clear();')
        print('main.dart: added clear() on sign-out OK')
        break
text = '\n'.join(lines)

with open(path1, 'w', encoding='utf-8') as f:
    f.write(text)

# ── Fix 2: shopping_cart_screen.dart ───────────────────────────────────────
path2 = 'lib/presentation/shopping_cart_screen/shopping_cart_screen.dart'
with open(path2, 'rb') as f:
    text2 = f.read().decode('utf-8').replace('\r\n', '\n')

if 'final messenger = ScaffoldMessenger.of(context);' in text2:
    print('shopping_cart_screen.dart: already fixed')
else:
    lines2 = text2.splitlines()
    for i, line in enumerate(lines2):
        if 'Navigator.pop(context);' in line:
            # Check if next line or nearby has clearCart
            snippet = '\n'.join(lines2[i:i+10])
            if 'clearCart' in snippet:
                indent = ' ' * (len(line) - len(line.lstrip()))
                lines2.insert(i, indent + 'final messenger = ScaffoldMessenger.of(context);')
                print('shopping_cart_screen.dart: inserted messenger capture OK')
                # Now replace ScaffoldMessenger.of(context) with messenger in next ~10 lines
                text2 = '\n'.join(lines2)
                # Replace the two ScaffoldMessenger.of(context) calls after the pop
                # Do it by finding them after the messenger line
                idx = text2.find('final messenger = ScaffoldMessenger.of(context);')
                after = text2[idx:]
                after = after.replace('ScaffoldMessenger.of(context).showSnackBar', 'messenger.showSnackBar', 2)
                # Remove the if (!mounted) return; guards since messenger is captured
                after = after.replace('                if (!mounted) return;\n                messenger.showSnackBar', '                messenger.showSnackBar', 2)
                text2 = text2[:idx] + after
                print('shopping_cart_screen.dart: replaced ScaffoldMessenger calls OK')
                break

    with open(path2, 'w', encoding='utf-8') as f:
        f.write(text2)

print('fix21b done')
