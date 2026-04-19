# fix21.py
# 1. Register FavoritesProvider in main.dart MultiProvider
# 2. Call loadFavorites() on sign-in and app startup
# 3. Call clear() on sign-out
# 4. Fix cart ScaffoldMessenger deactivated widget crash

# ── Fix 1 & 2 & 3: main.dart ───────────────────────────────────────────────
path1 = 'lib/main.dart'
with open(path1, 'rb') as f:
    text = f.read().decode('utf-8').replace('\r\n', '\n')

# Add import after notifications_provider import
old_import = "import './providers/notifications_provider.dart';"
new_import = """import './providers/notifications_provider.dart';
import './providers/favorites_provider.dart';"""
if old_import in text and 'favorites_provider' not in text:
    text = text.replace(old_import, new_import, 1)
    print('main.dart: added FavoritesProvider import OK')
else:
    print('main.dart: import already exists or not found')

# Create favoritesProvider instance alongside authProvider/adminProvider
old_create = "  final authProvider = AuthProvider();\n  final adminProvider = AdminProvider();"
new_create = """  final authProvider = AuthProvider();
  final adminProvider = AdminProvider();
  final favoritesProvider = FavoritesProvider();"""
if old_create in text:
    text = text.replace(old_create, new_create, 1)
    print('main.dart: created favoritesProvider instance OK')
else:
    print('main.dart: WARNING - could not find authProvider/adminProvider creation')

# Add to MultiProvider
old_providers = "          provider.ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),\n        ],"
new_providers = """          provider.ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          provider.ChangeNotifierProvider<FavoritesProvider>.value(value: favoritesProvider),
        ],"""
if old_providers in text:
    text = text.replace(old_providers, new_providers, 1)
    print('main.dart: registered FavoritesProvider in MultiProvider OK')
else:
    print('main.dart: WARNING - could not find MultiProvider providers list')

# Load favorites on startup if user already logged in
old_startup = "      await adminProvider.checkAdminStatus(reason: 'app-startup-existing-session');\n      debugPrint('[MAIN] Initial admin status: \${adminProvider.isAdmin}');"
new_startup = """      await adminProvider.checkAdminStatus(reason: 'app-startup-existing-session');
      debugPrint('[MAIN] Initial admin status: \${adminProvider.isAdmin}');
      favoritesProvider.loadFavorites();"""
if old_startup in text:
    text = text.replace(old_startup, new_startup, 1)
    print('main.dart: added loadFavorites() on startup OK')
else:
    print('main.dart: WARNING - could not find startup admin check')

# Load favorites on sign-in
old_signin = "        adminProvider.checkAdminStatus(reason: 'supabase-auth-signed-in').then((_) {\n          debugPrint('[MAIN] Admin check complete: isAdmin=\${adminProvider.isAdmin}');\n        });"
new_signin = """        adminProvider.checkAdminStatus(reason: 'supabase-auth-signed-in').then((_) {
          debugPrint('[MAIN] Admin check complete: isAdmin=\${adminProvider.isAdmin}');
        });
        favoritesProvider.loadFavorites();"""
if old_signin in text:
    text = text.replace(old_signin, new_signin, 1)
    print('main.dart: added loadFavorites() on sign-in OK')
else:
    print('main.dart: WARNING - could not find sign-in block')

# Clear favorites on sign-out
old_signout = "        debugPrint('[MAIN] \u{1F6AA} User signed out');\n        // Admin status will reset to false on next check (no user)"
new_signout = """        debugPrint('[MAIN] \u{1F6AA} User signed out');
        favoritesProvider.clear();
        // Admin status will reset to false on next check (no user)"""
if old_signout in text:
    text = text.replace(old_signout, new_signout, 1)
    print('main.dart: added clear() on sign-out OK')
else:
    # Try simpler match
    old_signout2 = "        // Admin status will reset to false on next check (no user)"
    new_signout2 = """        favoritesProvider.clear();
        // Admin status will reset to false on next check (no user)"""
    if old_signout2 in text:
        text = text.replace(old_signout2, new_signout2, 1)
        print('main.dart: added clear() on sign-out OK (fallback match)')
    else:
        print('main.dart: WARNING - could not find sign-out block')

with open(path1, 'w', encoding='utf-8') as f:
    f.write(text)

# ── Fix 4: shopping_cart_screen.dart ───────────────────────────────────────
path2 = 'lib/presentation/shopping_cart_screen/shopping_cart_screen.dart'
with open(path2, 'rb') as f:
    text2 = f.read().decode('utf-8').replace('\r\n', '\n')

# Capture messenger before pop to avoid deactivated widget crash
old_cart = """              Navigator.pop(context);
              try {
                await ref.read(cartNotifierProvider.notifier).clearCart();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cart cleared')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to clear cart: $e')),
                );
              }"""
new_cart = """              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await ref.read(cartNotifierProvider.notifier).clearCart();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Cart cleared')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to clear cart: $e')),
                );
              }"""

if old_cart in text2:
    text2 = text2.replace(old_cart, new_cart, 1)
    print('shopping_cart_screen.dart: ScaffoldMessenger fix OK')
else:
    print('shopping_cart_screen.dart: WARNING - could not find clearCart block, printing nearby lines:')
    for i, line in enumerate(text2.splitlines()):
        if 'clearCart' in line or 'Navigator.pop' in line:
            print(f'  {i+1}: {repr(line)}')

with open(path2, 'w', encoding='utf-8') as f:
    f.write(text2)

print('fix21 done')
