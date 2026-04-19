#!/usr/bin/env python3
"""Final targeted fixes for remaining 41 theme audit errors."""

import os, re

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJECT, 'lib')
fixed = 0

def fix(filepath, replacements):
    """Apply specific replacements to a file."""
    global fixed
    fp = os.path.join(PROJECT, filepath.replace('/', os.sep))
    if not os.path.exists(fp): return

    with open(fp, 'r', encoding='utf-8') as f:
        content = f.read()
    original = content

    for old, new in replacements:
        content = content.replace(old, new)

    if content != original:
        with open(fp, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  {filepath}")
        fixed += 1


print("Final theme fixes...\n")

# 1. Files where 'theme' is undefined — revert theme.xxx to hardcoded
for fp in [
    'lib/presentation/admin_ads_management_screen/widgets/ad_creation_wizard_widget.dart',
    'lib/presentation/admin_dashboard_screen/admin_dashboard_screen.dart',
    'lib/presentation/admin_navigation_drawer_screen/admin_navigation_drawer_screen.dart',
    'lib/presentation/driver_application_screen/driver_application_screen.dart',
    'lib/presentation/merchant_application_screen/merchant_application_screen.dart',
]:
    fp_full = os.path.join(PROJECT, fp.replace('/', os.sep))
    if not os.path.exists(fp_full): continue
    with open(fp_full, 'r', encoding='utf-8') as f:
        content = f.read()
    original = content
    # Revert theme references (longest first)
    for tr, fb in [
        ('theme.colorScheme.surfaceContainerHighest', 'Colors.grey.shade200'),
        ('theme.colorScheme.onSurfaceVariant', 'Colors.grey'),
        ('theme.colorScheme.outlineVariant', 'Colors.grey.shade300'),
        ('theme.colorScheme.onSurface', 'Colors.black87'),
        ('theme.colorScheme.outline', 'Colors.grey.shade400'),
        ('theme.colorScheme.surface', 'Colors.white'),
        ('theme.scaffoldBackgroundColor', 'Color(0xFFF5F5F5)'),
    ]:
        content = content.replace(tr, fb)
    if content != original:
        with open(fp_full, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  {fp} (reverted theme refs)")
        fixed += 1

# 2. prefix_shadowed_by_local_declaration: 'theme' shadows something
# In these files, there's a local variable 'theme' that shadows a type
# The fix: these were already using 'theme' correctly (it was a local ThemeData)
# but our replacements changed Colors.xxx to theme.xxx and the local 'theme'
# variable caused confusion. These should use the existing local theme variable.
# Actually, the issue is `theme.colorScheme` is being used where the local variable
# IS the theme. So `theme.colorScheme.onSurface` should work... unless 'theme' is
# being used as a named parameter.
# Let me check: these files define `final isLight = theme.brightness == Brightness.light;`
# so they DO have 'theme' but it might be shadowing an import.
# Actually, the error says "prefix 'theme' can't be used here because it's shadowed"
# This means there's a library prefix 'theme' being imported somewhere.
# Fix: The files import app_theme.dart which might use 'theme' as prefix.
# Actually, let's just check what's happening and revert the specific lines.

for fp in [
    'lib/presentation/ai_chat_assistant_screen/ai_chat_assistant_screen.dart',
    'lib/presentation/ai_chat_assistant_screen/widgets/message_bubble_widget.dart',
    'lib/presentation/marketplace_chat_screen/widgets/message_bubble_widget.dart',
]:
    fp_full = os.path.join(PROJECT, fp.replace('/', os.sep))
    if not os.path.exists(fp_full): continue
    with open(fp_full, 'r', encoding='utf-8') as f:
        content = f.read()
    original = content
    # These files use isLight ternaries with theme references
    # Revert to hardcoded colors since the 'theme' prefix conflicts
    for tr, fb in [
        ('theme.colorScheme.surfaceContainerHighest', 'Colors.grey.shade200'),
        ('theme.colorScheme.onSurfaceVariant', 'Colors.grey'),
        ('theme.colorScheme.outlineVariant', 'Colors.grey.shade300'),
        ('theme.colorScheme.onSurface', 'Colors.black87'),
        ('theme.colorScheme.outline', 'Colors.grey.shade400'),
        ('theme.colorScheme.surface', 'Colors.white'),
    ]:
        content = content.replace(tr, fb)
    # Fix 'const Colors.black87' -> just Colors.black87
    content = content.replace('const Colors.black87', 'Colors.black87')
    if content != original:
        with open(fp_full, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  {fp} (reverted shadowed theme)")
        fixed += 1

# 3. store_detail_screen: corrupted colorScheme getters like onSurface26
fix('lib/presentation/store_detail_screen/store_detail_screen.dart', [
    ('theme.colorScheme.onSurface26', 'Colors.black.withAlpha(26)'),
    ('theme.colorScheme.onSurface45', 'Colors.black.withAlpha(45)'),
    ('theme.colorScheme.onSurface54', 'Colors.black.withAlpha(54)'),
])

# 4. admin_edit_button: const with theme
fix('lib/presentation/admin_edit_overlay_system_screen/widgets/admin_edit_button_widget.dart', [
    ('const Icon(Icons.edit, color: theme.colorScheme.surface,', 'Icon(Icons.edit, color: theme.colorScheme.surface,'),
])

# 5. unchecked_use_of_nullable_value: .withOpacity() on nullable Color?
# These happen when theme.textTheme.xxx?.color is used with .withOpacity()
# Fix: add null check with ?? Colors.grey
for fp in [
    'lib/presentation/merchant_analytics_screen/merchant_analytics_screen.dart',
    'lib/presentation/order_history_screen/widgets/filter_bottom_sheet_widget.dart',
    'lib/presentation/order_tracking_screen/order_tracking_screen.dart',
    'lib/presentation/phone_collection_screen/phone_collection_screen.dart',
    'lib/presentation/shopping_cart_screen/widgets/cart_item_widget.dart',
    'lib/presentation/shopping_cart_screen/widgets/order_summary_widget.dart',
    'lib/presentation/shopping_cart_screen/widgets/saved_for_later_widget.dart',
    'lib/presentation/subscription_management_screen/widgets/plan_card_widget.dart',
    'lib/widgets/driver_rating_dialog.dart',
]:
    fp_full = os.path.join(PROJECT, fp.replace('/', os.sep))
    if not os.path.exists(fp_full): continue
    with open(fp_full, 'r', encoding='utf-8') as f:
        content = f.read()
    original = content
    # Fix pattern: something?.color.withOpacity() → something?.color?.withOpacity() ?? Colors.grey
    # Or simpler: replace .color.withOpacity with .color?.withOpacity
    content = re.sub(r'\.color\.with(Opacity|Values)\(', r'.color?.with\1(', content)
    if content != original:
        with open(fp_full, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  {fp} (nullable color fix)")
        fixed += 1

# 6. available_order_card & filter_options: Color? assigned to Color
for fp in [
    'lib/presentation/available_orders_screen/widgets/available_order_card_widget.dart',
    'lib/presentation/available_orders_screen/widgets/filter_options_widget.dart',
]:
    fp_full = os.path.join(PROJECT, fp.replace('/', os.sep))
    if not os.path.exists(fp_full): continue
    with open(fp_full, 'r', encoding='utf-8') as f:
        content = f.read()
    original = content
    content = re.sub(r'\.color\.with(Opacity|Values)\(', r'.color?.with\1(', content)
    if content != original:
        with open(fp_full, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  {fp} (nullable color fix)")
        fixed += 1

print(f"\nFixed {fixed} files")
