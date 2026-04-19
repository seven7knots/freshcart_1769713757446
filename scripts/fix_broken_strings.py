#!/usr/bin/env python3
"""Fix specific broken string replacements."""

import os

PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

fixes = [
    # login_form_widget.dart line 289 - double quote issue
    {
        'file': 'lib/presentation/authentication_screen/widgets/login_form_widget.dart',
        'old': "Text('Enter your email and we\\'ll send you a reset link''",
        'new': "Text('Enter your email and we\\'ll send you a reset link'",
    },
    # privacy_security_screen.dart - need to check what happened
    # product_grid_widget.dart - need to check what happened
]

for fix in fixes:
    filepath = os.path.join(PROJECT_DIR, fix['file'].replace('/', os.sep))
    if not os.path.exists(filepath):
        print(f"File not found: {fix['file']}")
        continue

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    if fix['old'] in content:
        content = content.replace(fix['old'], fix['new'])
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed: {fix['file']}")
    else:
        print(f"Pattern not found in: {fix['file']}")

print("Done")
