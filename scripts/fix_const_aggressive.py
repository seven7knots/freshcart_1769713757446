#!/usr/bin/env python3
"""Aggressively fix remaining const issues near AppLocalizations calls."""

import os
import re

PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB_DIR = os.path.join(PROJECT_DIR, 'lib')

fixed_count = 0

for root, dirs, files in os.walk(LIB_DIR):
    dirs[:] = [d for d in dirs if d not in {'l10n', 'generated'}]
    for fname in files:
        if not fname.endswith('.dart'):
            continue

        filepath = os.path.join(root, fname)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        if 'AppLocalizations' not in content:
            continue

        original = content

        # Strategy: find each "const " and check if the expression it
        # starts contains AppLocalizations. If so, remove "const ".
        # We do multiple passes until no more changes.
        changed = True
        while changed:
            changed = False
            idx = 0
            while idx < len(content):
                # Find next "const " (word boundary)
                match = re.search(r'\bconst\s+', content[idx:])
                if not match:
                    break

                const_pos = idx + match.start()
                const_end = idx + match.end()

                # Check what follows
                rest = content[const_end:]

                # Skip if this is "const " inside a string
                # Simple heuristic: count quotes before this position
                before = content[:const_pos]
                # If we're inside a string, skip
                single_quotes = before.count("'") - before.count("\\'")
                double_quotes = before.count('"') - before.count('\\"')
                if single_quotes % 2 == 1 or double_quotes % 2 == 1:
                    idx = const_end
                    continue

                # Skip type annotations: const <Type>
                type_skip = 0
                if rest.startswith('<'):
                    angle_depth = 1
                    p = 1
                    while p < len(rest) and angle_depth > 0:
                        if rest[p] == '<': angle_depth += 1
                        elif rest[p] == '>': angle_depth -= 1
                        p += 1
                    type_skip = p
                    # Skip whitespace after >
                    while type_skip < len(rest) and rest[type_skip] in ' \t\n':
                        type_skip += 1
                    rest = rest[type_skip:]

                # Find the bracket
                if not rest or rest[0] not in '([{':
                    # Could be "const WidgetName(" — skip the identifier
                    id_match = re.match(r'[A-Za-z_]\w*\s*', rest)
                    if id_match:
                        rest = rest[id_match.end():]
                        type_skip += id_match.end()

                if not rest or rest[0] not in '([{':
                    idx = const_end
                    continue

                open_b = rest[0]
                close_b = {'(': ')', '[': ']', '{': '}'}[open_b]
                depth = 1
                p = 1
                while p < len(rest) and depth > 0:
                    c = rest[p]
                    if c == open_b: depth += 1
                    elif c == close_b: depth -= 1
                    # Skip strings
                    elif c in ("'", '"'):
                        q = c
                        p += 1
                        while p < len(rest) and rest[p] != q:
                            if rest[p] == '\\': p += 1
                            p += 1
                    p += 1

                expr = rest[:p]
                if 'AppLocalizations' in expr:
                    # Remove "const "
                    content = content[:const_pos] + content[const_end:]
                    changed = True
                    break  # restart the while loop
                else:
                    idx = const_end

        if content != original:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            rel = os.path.relpath(filepath, PROJECT_DIR).replace('\\', '/')
            print(f"  Fixed: {rel}")
            fixed_count += 1

print(f"\nFixed {fixed_count} files")
