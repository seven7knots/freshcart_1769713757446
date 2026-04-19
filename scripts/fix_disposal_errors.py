#!/usr/bin/env python3
"""Fix errors from incorrect controller disposal additions."""

import os, re

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJECT, 'lib')

fixes = 0

def remove_bad_dispose(filepath, controller_names):
    """Remove dispose() lines for controllers that are NOT class fields."""
    global fixes
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    original = content

    for name in controller_names:
        # Check if this controller is a class field (declared outside methods)
        # A class field looks like: final _name = TextEditingController();
        # at class level (no leading method context)
        # If the controller is only declared inside a method, remove the dispose
        field_pattern = rf'^\s+(?:final\s+|late\s+)?{re.escape(name)}\s*=\s*TextEditingController'
        lines = content.split('\n')

        is_field = False
        in_method = False
        brace_depth = 0

        for line in lines:
            # Track if we're inside a method
            if re.match(r'\s+(?:Future|void|Widget|String|static|@override)', line) and '(' in line and '{' in line:
                in_method = True

            if not in_method and re.search(field_pattern, line):
                is_field = True
                break

            brace_depth += line.count('{') - line.count('}')

        if not is_field:
            # Remove the dispose line for this controller
            content = re.sub(rf'\n?\s*{re.escape(name)}\.dispose\(\);', '', content)

    # If we removed ALL dispose lines from a dispose method, remove the whole method
    # Check if dispose method now has empty body
    dispose_empty = re.search(r'@override\s*\n\s*void dispose\(\)\s*\{\s*\n\s*super\.dispose\(\);\s*\n\s*\}', content)
    if dispose_empty:
        content = content.replace(dispose_empty.group(0), '')
        # Clean up extra blank lines
        content = re.sub(r'\n{3,}', '\n\n', content)

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        fixes += 1
        rel = os.path.relpath(filepath, PROJECT).replace('\\', '/')
        print(f"  Fixed: {rel}")

# Fix specific files from the error list
files_to_fix = {
    'lib/presentation/admin_dashboard_screen/admin_dashboard_screen.dart': ['controller'],
    'lib/presentation/admin_role_upgrade_management_screen/admin_role_upgrade_management_screen.dart': ['reasonController'],
    'lib/presentation/marketplace_listing_detail_screen/marketplace_listing_detail_screen.dart': ['messageController'],
    'lib/presentation/merchant_dashboard_screen/merchant_dashboard_screen.dart': ['nameController', 'descriptionController', 'addressController'],
    'lib/presentation/merchant_store_screen/merchant_store_screen.dart': ['nameController', 'priceController', 'descriptionController', 'categoryController'],
    'lib/presentation/privacy_security_screen/privacy_security_screen.dart': ['newPwController', 'confirmPwController', 'confirmController'],
}

print("Fixing bad controller disposals...")
for relpath, controllers in files_to_fix.items():
    fp = os.path.join(PROJECT, relpath.replace('/', os.sep))
    if os.path.exists(fp):
        remove_bad_dispose(fp, controllers)

# Fix missing debugPrint import
for relpath in ['lib/providers/product_provider.dart', 'lib/services/marketplace_service.dart']:
    fp = os.path.join(PROJECT, relpath.replace('/', os.sep))
    if not os.path.exists(fp): continue

    with open(fp, 'r', encoding='utf-8') as f:
        content = f.read()

    if 'debugPrint' in content and "import 'package:flutter/foundation.dart'" not in content:
        # Replace debugPrint with print (simpler, no import needed)
        content = content.replace(
            "debugPrint('[PRODUCT_PROVIDER] Silent error: $e')",
            "// ignore: avoid_print\n      print('[PRODUCT_PROVIDER] Silent error: \$e')"
        )
        content = content.replace(
            "debugPrint('[MARKETPLACE_SERVICE] Silent error: $e')",
            "// ignore: avoid_print\n      print('[MARKETPLACE_SERVICE] Silent error: \$e')"
        )

        # Actually, just add the import
        if "import 'package:flutter/foundation.dart'" not in content:
            # Find first import and add before it
            content = "import 'package:flutter/foundation.dart';\n" + content

        with open(fp, 'w', encoding='utf-8') as f:
            f.write(content)
        rel = os.path.relpath(fp, PROJECT).replace('\\', '/')
        print(f"  Fixed import: {rel}")
        fixes += 1

print(f"\nFixed {fixes} files")
