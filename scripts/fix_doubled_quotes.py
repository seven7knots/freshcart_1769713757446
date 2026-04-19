#!/usr/bin/env python3
"""Fix doubled single quotes from broken string replacements."""

import os
import re

PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB_DIR = os.path.join(PROJECT_DIR, 'lib')

fixed = 0
for root, dirs, files in os.walk(LIB_DIR):
    dirs[:] = [d for d in dirs if d not in {'l10n', 'generated'}]
    for fname in files:
        if not fname.endswith('.dart'):
            continue

        filepath = os.path.join(root, fname)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        original = content

        # Fix pattern: 'text with escaped quote\'' followed by extra '
        # The pattern is: escaped-quote-at-end '' -> just '
        # Specifically: \'' at end of a string should be \'
        # Look for: sometext\'' followed by , or ) which indicates end of string arg
        content = re.sub(r"(\\')('[\s,)\n])", r"\1", content)

        # Also fix remaining invalid_constant by running const removal again
        # Find all lines with "const" and check if following expression has AppLocalizations

        if content != original:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            rel = os.path.relpath(filepath, PROJECT_DIR).replace('\\', '/')
            print(f"Fixed: {rel}")
            fixed += 1

print(f"\nFixed {fixed} files")
