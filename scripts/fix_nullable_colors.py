#!/usr/bin/env python3
"""Fix nullable color method calls (.color.withOpacity / .color.withValues)."""

import os, re

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

files = [
    'lib/presentation/admin_edit_overlay_system_screen/widgets/admin_edit_button_widget.dart',
    'lib/presentation/available_orders_screen/widgets/available_order_card_widget.dart',
    'lib/presentation/available_orders_screen/widgets/filter_options_widget.dart',
    'lib/presentation/merchant_analytics_screen/merchant_analytics_screen.dart',
    'lib/presentation/order_history_screen/widgets/filter_bottom_sheet_widget.dart',
    'lib/presentation/order_tracking_screen/order_tracking_screen.dart',
    'lib/presentation/phone_collection_screen/phone_collection_screen.dart',
    'lib/presentation/shopping_cart_screen/widgets/cart_item_widget.dart',
    'lib/presentation/shopping_cart_screen/widgets/order_summary_widget.dart',
    'lib/presentation/shopping_cart_screen/widgets/saved_for_later_widget.dart',
    'lib/presentation/subscription_management_screen/widgets/plan_card_widget.dart',
    'lib/widgets/driver_rating_dialog.dart',
]

fixed = 0
for relpath in files:
    fp = os.path.join(PROJECT, relpath.replace('/', os.sep))
    if not os.path.exists(fp): continue

    with open(fp, 'r', encoding='utf-8') as f:
        content = f.read()
    original = content

    # Fix .color.withOpacity( → .color?.withOpacity(
    content = re.sub(r'\.color\.withOpacity\(', '.color?.withOpacity(', content)
    # Fix .color.withValues( → .color?.withValues(
    content = re.sub(r'\.color\.withValues\(', '.color?.withValues(', content)

    # Fix Color? assigned to Color parameter
    # Pattern: color: theme.textTheme.xxx?.color?.withOpacity(...)
    # This returns Color? but some params need Color
    # Add ?? Colors.grey fallback
    # Actually, better to handle case by case with ! since we know the theme text styles have colors

    # Fix const with theme.colorScheme
    content = content.replace(
        'const Icon(Icons.edit, color: theme.colorScheme.surface,',
        'Icon(Icons.edit, color: theme.colorScheme.surface,'
    )

    if content != original:
        with open(fp, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  {relpath}")
        fixed += 1

print(f"\nFixed {fixed} files")
