#!/usr/bin/env python3
"""Fix all errors from round 2 patching."""

import os
import re
import json

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJECT, 'lib')

# Load current EN arb for key lookup
with open(os.path.join(LIB, 'l10n', 'app_en.arb'), 'r', encoding='utf-8') as f:
    en_arb = json.load(f)

# Build reverse: string -> key
s2k = {}
for k, v in en_arb.items():
    if not k.startswith('@@'):
        s2k[v] = k

stats = {'files': 0, 'fixes': 0}


def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    # ── Fix 1: Renamed ARB keys (7Days->n7Days etc.) ──
    content = content.replace('AppLocalizations.of(context)!.247Support', 'AppLocalizations.of(context)!.n247Support')
    content = content.replace('AppLocalizations.of(context)!.7Days', 'AppLocalizations.of(context)!.n7Days')
    content = content.replace('AppLocalizations.of(context)!.30Days', 'AppLocalizations.of(context)!.n30Days')
    content = content.replace('AppLocalizations.of(context)!.90Days', 'AppLocalizations.of(context)!.n90Days')

    # ── Fix 2: Revert AppLocalizations in return statements inside methods
    # that don't have BuildContext ──
    # These are typically in:
    #   - model files (return statements mapping enum->string)
    #   - static methods
    #   - service files
    # We detect this by: if 'return AppLocalizations' appears in a file that
    # doesn't have a build(BuildContext context) method nearby, or
    # the return is inside a static method

    # For models and services: revert ALL AppLocalizations in return statements
    rel_path = os.path.relpath(filepath, LIB).replace('\\', '/')
    is_model = rel_path.startswith('models/')
    is_service = rel_path.startswith('services/')
    is_theme = rel_path.startswith('theme/')
    is_route = rel_path.startswith('routes/')
    is_provider = rel_path.startswith('providers/')

    if is_model or is_service or is_theme or is_provider:
        # Revert all AppLocalizations calls back to original strings
        pattern = r"AppLocalizations\.of\(context\)!\.(\w+)"
        def revert(m):
            key = m.group(1)
            for s, k in s2k.items():
                if k == key:
                    return f"'{s}'"
            return m.group(0)  # keep if not found
        content = re.sub(pattern, revert, content)
        # Remove import if no more AppLocalizations
        if 'AppLocalizations' not in content.split('import')[-1] if 'import' in content else True:
            content = re.sub(r"import '[^']*app_localizations\.dart';\n?", '', content)

    # ── Fix 3: Revert AppLocalizations in return statements inside
    # non-build static/helper methods in widget files ──
    # Look for patterns like:
    #   return AppLocalizations.of(context)!.xxx;
    # inside methods that are clearly NOT build methods
    # (i.e., the method doesn't take BuildContext as parameter)

    # For certain known files with static helper methods:
    # These files have return statements in static/helper methods without context
    known_revert_files = {
        'admin_edit_button_widget.dart',
        'category_tabs_widget.dart',
        'message_bubble_widget.dart',  # ai_chat
        'conversation_card_widget.dart',
        'order_queue_panel_widget.dart',
        'category_listings_screen.dart',
        'marketplace_listings_feed_widget.dart',
    }

    fname = os.path.basename(filepath)

    # For these specific files, we need a more targeted approach:
    # Find return statements with AppLocalizations that are inside methods
    # without BuildContext parameter

    # Actually, let's look at each function/method to see if it has context
    # Simpler: just find lines with "return AppLocalizations" and check if
    # the enclosing function has a BuildContext parameter

    if fname in known_revert_files:
        lines = content.split('\n')
        new_lines = []
        in_method_without_context = False
        brace_depth = 0
        method_start_depth = 0

        for i, line in enumerate(lines):
            stripped = line.strip()

            # Track method definitions
            # A method def looks like: Type methodName(params) {
            method_match = re.match(r'\s*(?:static\s+)?(?:Future<[^>]+>|String|int|double|bool|void|Widget|dynamic)\s+\w+\s*\(([^)]*)\)', line)
            if method_match and '{' in line:
                params = method_match.group(1)
                if 'BuildContext' not in params and 'context' not in params:
                    in_method_without_context = True
                    method_start_depth = brace_depth
                else:
                    in_method_without_context = False

            # Track braces
            brace_depth += line.count('{') - line.count('}')

            # If we've exited the method
            if in_method_without_context and brace_depth <= method_start_depth:
                in_method_without_context = False

            # Revert AppLocalizations in this line if in method without context
            if in_method_without_context and 'AppLocalizations.of(context)!' in stripped:
                pattern = r"AppLocalizations\.of\(context\)!\.(\w+)"
                def revert_line(m):
                    key = m.group(1)
                    for s, k in s2k.items():
                        if k == key:
                            return f"'{s}'"
                    return m.group(0)
                line = re.sub(pattern, revert_line, line)

            new_lines.append(line)

        content = '\n'.join(new_lines)

    # ── Fix 4: Remove const from expressions with AppLocalizations ──
    # Handle const maps
    idx = 0
    while True:
        m = re.search(r'\bconst\s+\{', content[idx:])
        if not m:
            break
        abs_idx = idx + m.start()
        brace_start = abs_idx + m.end() - m.start() - 1
        depth = 1
        pos = brace_start + 1
        while pos < len(content) and depth > 0:
            if content[pos] == '{': depth += 1
            elif content[pos] == '}': depth -= 1
            pos += 1
        block = content[brace_start:pos]
        if 'AppLocalizations' in block:
            content = content[:abs_idx] + content[abs_idx + 6:]  # remove "const "
        else:
            idx = abs_idx + m.end() - m.start()

    # Handle const <Type>{...}
    idx = 0
    while True:
        m = re.search(r'\bconst\s+<[^>]+>\{', content[idx:])
        if not m:
            break
        abs_idx = idx + m.start()
        brace_pos = content.index('{', abs_idx + 6)
        depth = 1
        pos = brace_pos + 1
        while pos < len(content) and depth > 0:
            if content[pos] == '{': depth += 1
            elif content[pos] == '}': depth -= 1
            pos += 1
        block = content[brace_pos:pos]
        if 'AppLocalizations' in block:
            content = content[:abs_idx] + content[abs_idx + 6:]
        else:
            idx = abs_idx + m.end() - m.start()

    # Handle remaining const Widget/Text/etc with AppLocalizations
    widget_types = [
        'Text', 'Icon', 'SizedBox', 'Padding', 'Column', 'Row',
        'Container', 'Center', 'Scaffold', 'AlertDialog',
        'DropdownMenuItem', 'TextSpan', 'InfoWindow',
        'PopupMenuItem', 'ListTile', 'SnackBar',
    ]
    for w in widget_types:
        pat = f'const {w}('
        idx = 0
        while True:
            idx = content.find(pat, idx)
            if idx == -1: break
            pstart = idx + len(pat) - 1
            depth = 1
            pos = pstart + 1
            while pos < len(content) and depth > 0:
                c = content[pos]
                if c == '(': depth += 1
                elif c == ')': depth -= 1
                elif c in ("'", '"'):
                    q = c
                    pos += 1
                    while pos < len(content) and content[pos] != q:
                        if content[pos] == '\\': pos += 1
                        pos += 1
                pos += 1
            block = content[pstart:pos]
            if 'AppLocalizations' in block:
                content = content[:idx] + content[idx + 6:]
            else:
                idx += len(pat)

    # Handle const [...] with AppLocalizations
    idx = 0
    while True:
        idx = content.find('const [', idx)
        if idx == -1: break
        bstart = idx + 6
        depth = 1
        pos = bstart + 1
        while pos < len(content) and depth > 0:
            if content[pos] == '[': depth += 1
            elif content[pos] == ']': depth -= 1
            pos += 1
        block = content[bstart:pos]
        if 'AppLocalizations' in block:
            content = content[:idx] + content[idx + 6:]
        else:
            idx += 7

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        rel = os.path.relpath(filepath, PROJECT).replace('\\', '/')
        print(f"  Fixed: {rel}")
        stats['files'] += 1
        return True
    return False


def main():
    print("Fixing round 2 errors...")
    for root, dirs, files in os.walk(LIB):
        dirs[:] = [d for d in dirs if d not in {'l10n', 'generated'}]
        for fname in sorted(files):
            if not fname.endswith('.dart'):
                continue
            fix_file(os.path.join(root, fname))
    print(f"\nFixed {stats['files']} files")


if __name__ == '__main__':
    main()
