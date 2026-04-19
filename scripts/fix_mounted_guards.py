#!/usr/bin/env python3
"""
Fix incorrectly placed mounted guards.
The deep_bug_fix.py was too aggressive - it added 'if (!mounted) return;'
before EVERY setState, including:
- Inside build() methods (not async)
- Inside callbacks that are synchronous
- Inside non-void methods where 'return;' is invalid

Strategy: Remove ALL the guards we added, then re-add them ONLY in
async methods that call setState.
"""

import os, re

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJECT, 'lib')

fixed_count = 0

for root, dirs, files in os.walk(LIB):
    dirs[:] = [d for d in dirs if d not in {'l10n', 'generated'}]
    for fname in sorted(files):
        if not fname.endswith('.dart'): continue
        filepath = os.path.join(root, fname)

        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        original = content

        # Remove all lines that are EXACTLY "    if (!mounted) return;"
        # (the ones we added - they have specific indentation patterns)
        # We identify our additions: a line with only "if (!mounted) return;"
        # immediately followed by a line containing "setState("
        lines = content.split('\n')
        new_lines = []
        i = 0
        removed = 0
        while i < len(lines):
            line = lines[i]
            stripped = line.strip()

            # Check if this is our added mounted guard: "if (!mounted) return;"
            # immediately before a setState call
            if stripped == 'if (!mounted) return;' and i + 1 < len(lines):
                next_stripped = lines[i + 1].strip()
                if 'setState(' in next_stripped:
                    # This is one we added - skip it
                    i += 1
                    removed += 1
                    continue

            new_lines.append(line)
            i += 1

        if removed > 0:
            content = '\n'.join(new_lines)
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            rel = os.path.relpath(filepath, PROJECT).replace('\\', '/')
            print(f"  Removed {removed} guards: {rel}")
            fixed_count += 1

print(f"\nFixed {fixed_count} files")
