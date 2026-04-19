#!/usr/bin/env python3
"""
Fix 'invalid_constant' errors caused by AppLocalizations calls inside const widgets.
Removes 'const' keyword from widgets/lists that contain AppLocalizations calls.
"""

import os
import re

PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB_DIR = os.path.join(PROJECT_DIR, 'lib')

stats = {'files_modified': 0, 'fixes': 0}

def fix_const_in_file(filepath):
    """Remove const from expressions containing AppLocalizations."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception:
        return False

    if 'AppLocalizations' not in content:
        return False

    original = content
    lines = content.split('\n')
    modified = False

    # Strategy: Find lines containing AppLocalizations and trace back to remove const
    # We need to handle several patterns:
    # 1. const Text(AppLocalizations...) -> Text(AppLocalizations...)
    # 2. const SizedBox(...) containing AppLocalizations in child
    # 3. const [...] lists containing AppLocalizations items

    # Approach: simple regex-based removal of const before known widget types
    # when the same expression contains AppLocalizations

    # Pattern 1: const Text( ... AppLocalizations ... )
    # We need to find "const Text(" and check if there's an AppLocalizations before the matching ")"
    # Simpler: just remove "const " before "Text(AppLocalizations"
    content = content.replace('const Text(AppLocalizations', 'Text(AppLocalizations')

    # Also handle multiline cases where const is on a different line
    # Pattern: const\n    Text(AppLocalizations
    content = re.sub(r'const\s+Text\(AppLocalizations', 'Text(AppLocalizations', content)

    # Pattern 2: Things like const Icon(...) or const SizedBox(...) etc. inside list with AppLocalizations
    # These are trickier. Let's handle the most common case:
    # "const [" followed by items containing AppLocalizations
    # -> remove "const" from the list

    # Actually, the simpler approach: go through each line, find if there's an
    # AppLocalizations call, and look backwards for a "const" that's part of
    # the same expression.

    # Even simpler: Find all "const " that appear before any widget constructor
    # in lines that also contain (or whose enclosing block contains) AppLocalizations

    # Let's do a line-by-line approach
    lines = content.split('\n')
    new_lines = []

    for i, line in enumerate(lines):
        if 'AppLocalizations' in line:
            # Remove const from this line
            line = line.replace('const Text(', 'Text(')
            line = line.replace('const Icon(', 'Icon(')
            line = line.replace('const SizedBox(', 'SizedBox(')
            line = line.replace('const Padding(', 'Padding(')
            line = line.replace('const EdgeInsets', 'EdgeInsets')
            line = line.replace('const TextStyle(', 'TextStyle(')
            line = line.replace('const BoxDecoration(', 'BoxDecoration(')
            line = line.replace('const InputDecoration(', 'InputDecoration(')

        new_lines.append(line)

    content = '\n'.join(new_lines)

    # Now handle the harder case: const on a previous line
    # E.g.:
    #   const Text(
    #     AppLocalizations.of(context)!.xxx,
    #   )
    # The const is on a different line from AppLocalizations

    # Find all positions of AppLocalizations in the content
    # For each one, scan backwards to find if there's a nearby "const " before a widget constructor

    # More robust: process blocks
    # Find "const WidgetName(" and check if the block up to matching ")" contains AppLocalizations

    widget_types = [
        'Text', 'Icon', 'SizedBox', 'Padding', 'Column', 'Row',
        'Container', 'Center', 'Expanded', 'Flexible', 'Wrap',
        'ListTile', 'Card', 'Chip', 'Tab', 'DropdownMenuItem',
        'AlertDialog', 'SimpleDialog', 'BottomSheet',
        'InputDecoration', 'TextStyle', 'BoxDecoration',
        'ElevatedButton', 'TextButton', 'OutlinedButton',
        'IconButton', 'FloatingActionButton',
        'AppBar', 'BottomNavigationBarItem', 'NavigationDestination',
        'SnackBar', 'Tooltip', 'PopupMenuItem',
    ]

    for widget in widget_types:
        pattern = f'const {widget}('
        idx = 0
        while True:
            idx = content.find(pattern, idx)
            if idx == -1:
                break

            # Find the matching closing paren
            paren_start = idx + len(pattern) - 1  # position of '('
            depth = 1
            pos = paren_start + 1
            while pos < len(content) and depth > 0:
                if content[pos] == '(':
                    depth += 1
                elif content[pos] == ')':
                    depth -= 1
                pos += 1

            # Extract the block
            block = content[paren_start:pos]

            if 'AppLocalizations' in block:
                # Remove the 'const ' prefix
                content = content[:idx] + content[idx + 6:]  # skip 'const '
                # Don't advance idx since we shortened the string
            else:
                idx += len(pattern)

    # Handle const lists: const [item1, item2, ...]
    idx = 0
    while True:
        idx = content.find('const [', idx)
        if idx == -1:
            break

        # Find matching ]
        bracket_start = idx + 6  # position of '['
        depth = 1
        pos = bracket_start + 1
        while pos < len(content) and depth > 0:
            if content[pos] == '[':
                depth += 1
            elif content[pos] == ']':
                depth -= 1
            pos += 1

        block = content[bracket_start:pos]

        if 'AppLocalizations' in block:
            content = content[:idx] + content[idx + 6:]  # remove 'const '
        else:
            idx += 7

    # Handle const <Type>[...]
    idx = 0
    while True:
        match = re.search(r'const\s+<\w+>\[', content[idx:])
        if not match:
            break

        abs_idx = idx + match.start()
        bracket_pos = abs_idx + match.end() - match.start() - 1  # position of '['
        depth = 1
        pos = bracket_pos + 1
        while pos < len(content) and depth > 0:
            if content[pos] == '[':
                depth += 1
            elif content[pos] == ']':
                depth -= 1
            pos += 1

        block = content[bracket_pos:pos]

        if 'AppLocalizations' in block:
            content = content[:abs_idx] + content[abs_idx + 6:]  # remove 'const '
            idx = abs_idx
        else:
            idx = abs_idx + match.end() - match.start()

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        stats['files_modified'] += 1
        return True

    return False


def main():
    dart_files = []
    skip_dirs = {'l10n', 'generated'}
    for root, dirs, files in os.walk(LIB_DIR):
        dirs[:] = [d for d in dirs if d not in skip_dirs]
        for fname in sorted(files):
            if fname.endswith('.dart'):
                dart_files.append(os.path.join(root, fname))

    print(f"Fixing const errors in {len(dart_files)} files...")

    for filepath in dart_files:
        rel = os.path.relpath(filepath, PROJECT_DIR).replace('\\', '/')
        if fix_const_in_file(filepath):
            print(f"  Fixed: {rel}")

    print(f"\nDone! Files fixed: {stats['files_modified']}")


if __name__ == '__main__':
    main()
