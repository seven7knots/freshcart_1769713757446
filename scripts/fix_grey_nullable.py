#!/usr/bin/env python3
"""Fix Colors.grey[N] nullable issues - replace with Colors.grey.shadeN which is non-nullable."""

import os, re

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJECT, 'lib')

fixed = 0
for root, dirs, files in os.walk(LIB):
    dirs[:] = [d for d in dirs if d not in {'l10n', 'generated'}]
    for fname in sorted(files):
        if not fname.endswith('.dart'): continue
        fp = os.path.join(root, fname)

        with open(fp, 'r', encoding='utf-8') as f:
            content = f.read()
        original = content

        # Replace Colors.grey[N] with Colors.grey.shadeN (non-nullable)
        # Only where followed by .withOpacity or .withValues or as a Color parameter
        content = re.sub(r'Colors\.grey\[(\d+)\]', r'Colors.grey.shade\1', content)

        # Also fix const with theme
        content = content.replace(
            'const Icon(Icons.edit, color: theme.colorScheme.surface,',
            'Icon(Icons.edit, color: theme.colorScheme.surface,'
        )

        if content != original:
            with open(fp, 'w', encoding='utf-8') as f:
                f.write(content)
            rel = os.path.relpath(fp, PROJECT).replace('\\', '/')
            print(f"  {rel}")
            fixed += 1

print(f"\nFixed {fixed} files")
