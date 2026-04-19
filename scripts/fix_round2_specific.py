#!/usr/bin/env python3
"""Fix specific remaining errors - context in initializers, static methods, const maps."""

import os
import re

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJECT, 'lib')


def revert_loc(content, keys_to_revert):
    """Revert specific AppLocalizations calls back to hardcoded strings."""
    import json
    with open(os.path.join(LIB, 'l10n', 'app_en.arb'), 'r', encoding='utf-8') as f:
        en = json.load(f)
    k2s = {k: v for k, v in en.items() if not k.startswith('@@')}

    for key in keys_to_revert:
        if key in k2s:
            old = f"AppLocalizations.of(context)!.{key}"
            new = f"'{k2s[key]}'"
            content = content.replace(old, new)
    return content


def fix_driver_application():
    """Fix field initializer using context."""
    path = os.path.join(LIB, 'presentation', 'driver_application_screen', 'driver_application_screen.dart')
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Revert the field initializer list back to plain strings
    content = revert_loc(content, ['motorcycle', 'car', 'bicycle', 'van'])
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("  Fixed: driver_application_screen.dart (field initializers)")


def fix_merchant_application():
    """Fix field initializer using context."""
    path = os.path.join(LIB, 'presentation', 'merchant_application_screen', 'merchant_application_screen.dart')
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    content = revert_loc(content, ['pharmacy', 'services'])
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("  Fixed: merchant_application_screen.dart (field initializers)")


def fix_recent_orders_widget():
    """Fix _getStatusLabel which is a helper without BuildContext param."""
    path = os.path.join(LIB, 'presentation', 'home_screen', 'widgets', 'recent_orders_widget.dart')
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    content = revert_loc(content, [
        'delivered', 'cancelled', 'pending', 'confirmed',
        'preparing', 'ready', 'pickedUp', 'inTransit',
    ])
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("  Fixed: recent_orders_widget.dart (helper method)")


def fix_admin_editable_item_wrapper():
    """Fix _label getter - it's a StatelessWidget getter, no context available."""
    path = os.path.join(LIB, 'widgets', 'admin_editable_item_wrapper.dart')
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    content = revert_loc(content, [
        'banner', 'product2', 'category2', 'store2', 'listing', 'item',
    ])
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("  Fixed: admin_editable_item_wrapper.dart (getter without context)")


def fix_notifications_screen():
    """Fix _formatTime helper method."""
    path = os.path.join(LIB, 'presentation', 'notifications_screen', 'notifications_screen.dart')
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    content = revert_loc(content, ['justNow'])
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("  Fixed: notifications_screen.dart (helper method)")


def fix_content_edit_modal():
    """Fix const map with AppLocalizations values."""
    path = os.path.join(LIB, 'presentation', 'admin_edit_overlay_system_screen', 'widgets', 'content_edit_modal_widget.dart')
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Revert in the const map
    content = revert_loc(content, ['pharmacy', 'retail', 'services'])

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("  Fixed: content_edit_modal_widget.dart (const map)")


def main():
    print("Fixing specific remaining errors...")
    fix_driver_application()
    fix_merchant_application()
    fix_recent_orders_widget()
    fix_admin_editable_item_wrapper()
    fix_notifications_screen()
    fix_content_edit_modal()
    print("\nDone!")


if __name__ == '__main__':
    main()
