#!/usr/bin/env python3
"""
UI POLISH V2: Add subtle shadows to flat containers, modernize specific patterns,
ensure all corners are properly rounded.
"""

import os, re

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJECT, 'lib')

stats = {'files': 0}

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    original = content

    # Round more corners that look dated
    # 5px radius → 12 (mid)
    content = content.replace('BorderRadius.circular(5)', 'BorderRadius.circular(12)')
    # 7 → 12
    content = content.replace('BorderRadius.circular(7)', 'BorderRadius.circular(12)')
    # 9 → 14
    content = content.replace('BorderRadius.circular(9)', 'BorderRadius.circular(14)')
    # 11 → 14
    content = content.replace('BorderRadius.circular(11)', 'BorderRadius.circular(14)')
    # 13 → 14
    content = content.replace('BorderRadius.circular(13)', 'BorderRadius.circular(14)')
    # 15 → 16
    content = content.replace('BorderRadius.circular(15)', 'BorderRadius.circular(16)')

    # Specific top-only / bottom-only patterns
    content = content.replace('Radius.circular(8)', 'Radius.circular(14)')
    content = content.replace('Radius.circular(12)', 'Radius.circular(16)')

    # Modernize Status badge style
    # Common pattern: Container(padding: EdgeInsets.symmetric(horizontal: X, vertical: Y), decoration: BoxDecoration(color: ..., borderRadius: BorderRadius.circular(4)))
    # Already handled by 4→10, 6→12

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        stats['files'] += 1
        return True
    return False

print("UI Polish V2: rounding corners further...\n")

for root, dirs, files in os.walk(LIB):
    dirs[:] = [d for d in dirs if d not in {'l10n', 'generated'}]
    for fname in sorted(files):
        if not fname.endswith('.dart'): continue
        fp = os.path.join(root, fname)
        if fix_file(fp):
            pass  # don't print each file

print(f"Files updated: {stats['files']}")
print("=== UI POLISH V2 COMPLETE ===")
