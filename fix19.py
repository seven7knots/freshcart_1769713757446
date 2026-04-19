# fix19.py
# Fix 1: custom_image_widget.dart — guard against infinite/NaN width/height
#         before multiplying by devicePixelRatio.
# Fix 2: shopping_cart_screen.dart — add mounted check before ScaffoldMessenger.of

# ── Fix 1: custom_image_widget.dart ─────────────────────────────────────────
with open('lib/widgets/custom_image_widget.dart', 'rb') as f:
    raw = f.read()
text = raw.decode('utf-8').replace('\r\n', '\n')

old_cache = """        final cacheW = memCacheWidth ??
            (width != null ? (width! * dpr).ceil().clamp(1, 1200) : 800);
        final cacheH = memCacheHeight ??
            (height != null ? (height! * dpr).ceil().clamp(1, 1200) : null);"""

new_cache = """        // Guard against infinite/NaN layout dimensions (e.g. when widget is
        // inside an unbounded Column or ListView without explicit size).
        // Multiplying double.infinity by dpr produces infinity, causing
        // "Unsupported operation: Infinity or NaN toInt" on .ceil().
        final safeWidth = (width != null && width!.isFinite) ? width! : null;
        final safeHeight = (height != null && height!.isFinite) ? height! : null;
        final cacheW = memCacheWidth ??
            (safeWidth != null ? (safeWidth * dpr).ceil().clamp(1, 1200) : 800);
        final cacheH = memCacheHeight ??
            (safeHeight != null ? (safeHeight * dpr).ceil().clamp(1, 1200) : null);"""

if old_cache in text:
    text = text.replace(old_cache, new_cache, 1)
    print('custom_image_widget.dart: infinite dimension guard added OK')
else:
    print('custom_image_widget.dart: FAILED - printing cache lines:')
    for i, line in enumerate(text.splitlines()):
        if 'cacheW' in line or 'cacheH' in line or 'dpr' in line:
            print(f'  {i+1}: {repr(line)}')

with open('lib/widgets/custom_image_widget.dart', 'w', encoding='utf-8') as f:
    f.write(text)

# ── Fix 2: shopping_cart_screen.dart — mounted guard ────────────────────────
with open('lib/presentation/shopping_cart_screen/shopping_cart_screen.dart', 'rb') as f:
    raw2 = f.read()
cart = raw2.decode('utf-8').replace('\r\n', '\n')

# Find the _clearCart method and add mounted checks
# The error is at line 133: ScaffoldMessenger.of(context) after async gap
# Pattern: after await clearCart(), check mounted before using context
old_snack = "ScaffoldMessenger.of(context).showSnackBar("
lines = cart.splitlines()

fixed_lines = []
i = 0
changes = 0
while i < len(lines):
    line = lines[i]
    # Check if this is a ScaffoldMessenger.of(context) call after an async operation
    # We wrap it with a mounted check if not already wrapped
    stripped = line.strip()
    if 'ScaffoldMessenger.of(context)' in stripped:
        # Check if there's already a mounted check on the previous non-empty line
        prev_lines = [l.strip() for l in fixed_lines[-3:] if l.strip()]
        already_guarded = any('mounted' in l or 'if (!mounted)' in l for l in prev_lines)
        if not already_guarded:
            indent = len(line) - len(line.lstrip())
            indent_str = ' ' * indent
            fixed_lines.append(f'{indent_str}if (!mounted) return;')
            changes += 1
    fixed_lines.append(line)
    i += 1

if changes > 0:
    with open('lib/presentation/shopping_cart_screen/shopping_cart_screen.dart', 'w', encoding='utf-8') as f:
        f.write('\n'.join(fixed_lines) + '\n')
    print(f'shopping_cart_screen.dart: added {changes} mounted guard(s) OK')
else:
    print('shopping_cart_screen.dart: no unguarded ScaffoldMessenger calls found (already clean)')

print('fix19 done')
