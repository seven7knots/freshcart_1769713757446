#!/usr/bin/env python3
"""
Fix all errors from mega patch:
1. Revert AppLocalizations in field initializers (no context available)
2. Remove const from collections containing AppLocalizations
3. Revert AppLocalizations in methods without BuildContext
"""

import os, re, json

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJECT, 'lib')

# Load EN ARB for reverse lookups
with open(os.path.join(LIB, 'l10n', 'app_en.arb'), 'r', encoding='utf-8') as f:
    en_arb = json.load(f)

k2s = {k: v for k, v in en_arb.items() if not k.startswith('@@')}

def revert_pattern(content, pattern_str):
    """Revert AppLocalizations.of(context)!.key back to 'original string'."""
    def replacer(m):
        key = m.group(1)
        if key in k2s:
            val = k2s[key]
            return f"'{val}'"
        return m.group(0)
    return re.sub(pattern_str, replacer, content)


def fix_const(content):
    """Remove const from all collections/widgets containing AppLocalizations."""
    # const [...] with AppLocalizations
    idx = 0
    while True:
        idx = content.find('const [', idx)
        if idx == -1: break
        d = 1; p = idx + 7
        while p < len(content) and d > 0:
            if content[p] == '[': d += 1
            elif content[p] == ']': d -= 1
            p += 1
        if 'AppLocalizations' in content[idx+7:p]:
            content = content[:idx] + content[idx+6:]
        else:
            idx += 7

    # const {...} with AppLocalizations
    idx = 0
    while True:
        m = re.search(r'\bconst\s+\{', content[idx:])
        if not m: break
        ai = idx + m.start()
        bs = content.index('{', ai)
        d = 1; p = bs + 1
        while p < len(content) and d > 0:
            if content[p] == '{': d += 1
            elif content[p] == '}': d -= 1
            p += 1
        if 'AppLocalizations' in content[bs:p]:
            content = content[:ai] + content[ai+6:]
        else:
            idx = ai + m.end() - m.start()

    # const <Type>[...] with AppLocalizations
    idx = 0
    while True:
        m = re.search(r'\bconst\s+<[^>]+>\s*\[', content[idx:])
        if not m: break
        ai = idx + m.start()
        bs = content.index('[', ai)
        d = 1; p = bs + 1
        while p < len(content) and d > 0:
            if content[p] == '[': d += 1
            elif content[p] == ']': d -= 1
            p += 1
        if 'AppLocalizations' in content[bs:p]:
            content = content[:ai] + content[ai+6:]
        else:
            idx = ai + m.end() - m.start()

    # const <Type>{...} with AppLocalizations
    idx = 0
    while True:
        m = re.search(r'\bconst\s+<[^>]+>\s*\{', content[idx:])
        if not m: break
        ai = idx + m.start()
        bs = content.index('{', ai)
        d = 1; p = bs + 1
        while p < len(content) and d > 0:
            if content[p] == '{': d += 1
            elif content[p] == '}': d -= 1
            p += 1
        if 'AppLocalizations' in content[bs:p]:
            content = content[:ai] + content[ai+6:]
        else:
            idx = ai + m.end() - m.start()

    # const Widget(...) with AppLocalizations
    widgets = ['Text','Icon','SizedBox','Padding','Column','Row','Container','Center',
               'Scaffold','AlertDialog','DropdownMenuItem','TextSpan','InfoWindow',
               'PopupMenuItem','ListTile','SnackBar','Chip','Card','Tab',
               'SwitchListTile','CheckboxListTile','RadioListTile','Tooltip',
               'ElevatedButton','TextButton','OutlinedButton','BottomNavigationBarItem',
               'NavigationDestination','InputDecoration','BoxDecoration','TextStyle',
               'Expanded','Flexible','Wrap','SimpleDialog','BottomSheet','IconButton',
               'FloatingActionButton']
    for w in widgets:
        pat = f'const {w}('
        idx = 0
        while True:
            idx = content.find(pat, idx)
            if idx == -1: break
            ps = idx + len(pat) - 1
            d = 1; p = ps + 1
            while p < len(content) and d > 0:
                c = content[p]
                if c == '(': d += 1
                elif c == ')': d -= 1
                elif c in ("'",'"'):
                    q = c; p += 1
                    while p < len(content) and content[p] != q:
                        if content[p] == '\\': p += 1
                        p += 1
                p += 1
            if 'AppLocalizations' in content[ps:p]:
                content = content[:idx] + content[idx+6:]
            else:
                idx += len(pat)

    return content


def fix_field_initializers(content):
    """Revert AppLocalizations calls in field initializers.
    Field initializers are: final/var/late declarations at class level
    that use = [...] or = {...} or = AppLocalizations..."""

    lines = content.split('\n')
    new_lines = []
    in_class = False
    in_method = False
    brace_depth = 0
    method_depth = 0

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Track class bodies vs methods
        # If we see a method signature, mark as in_method
        if re.match(r'\s*(static\s+)?(?:Future|Stream|void|Widget|String|int|double|bool|Map|List|dynamic|State|@override)\s', line) and '{' in line and '(' in line:
            in_method = True
            method_depth = brace_depth

        brace_depth += line.count('{') - line.count('}')

        if in_method and brace_depth <= method_depth:
            in_method = False

        # If NOT in a method body and line has AppLocalizations, it's likely a field initializer
        if not in_method and 'AppLocalizations.of(context)!' in line:
            # Check if this is a field declaration (final, var, late, or list/map literal inside one)
            is_field = bool(re.match(r'\s*(final|var|late|static)\s', line))
            # Or if it's inside a list/map that's a field (continuation of previous line)
            is_field = is_field or (stripped.startswith('{') or stripped.startswith("'") or
                                   stripped.startswith('"') or stripped.startswith('['))

            if is_field:
                line = revert_pattern(line, r"AppLocalizations\.of\(context\)!\.(\w+)")

        new_lines.append(line)

    return '\n'.join(new_lines)


def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    if 'AppLocalizations' not in content:
        return False

    original = content

    # Fix 1: Remove const from collections/widgets with AppLocalizations
    content = fix_const(content)

    # Fix 2: Revert field initializers
    content = fix_field_initializers(content)

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False


def main():
    print("Fixing mega patch errors...")
    fixed = 0
    for root, dirs, files in os.walk(LIB):
        dirs[:] = [d for d in dirs if d not in {'l10n', 'generated'}]
        for fname in sorted(files):
            if not fname.endswith('.dart'): continue
            fp = os.path.join(root, fname)
            if process_file(fp):
                rel = os.path.relpath(fp, PROJECT).replace('\\', '/')
                print(f"  Fixed: {rel}")
                fixed += 1
    print(f"\nFixed {fixed} files")


if __name__ == '__main__':
    main()
