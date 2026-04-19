#!/usr/bin/env python3
"""
Fix errors from theme audit:
1. 'theme' undefined - revert to original hardcoded color where theme var is missing
2. const with theme.xxx - remove const
3. 'theme' shadowing parameter name
"""

import os, re, json

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJECT, 'lib')

stats = {'reverted': 0, 'const_fixed': 0, 'files': 0}

# Reverse map: theme expression -> original hardcoded color
REVERSE_MAP = {
    'theme.colorScheme.surface': 'Colors.white',
    'theme.colorScheme.onSurface': 'Colors.black87',
    'theme.colorScheme.onSurfaceVariant': 'Colors.grey',
    'theme.colorScheme.outlineVariant': 'Colors.grey[300]',
    'theme.colorScheme.outline': 'Colors.grey[400]',
    'theme.colorScheme.surfaceContainerHighest': 'Colors.grey[100]',
    'theme.scaffoldBackgroundColor': 'Color(0xFFF5F5F5)',
}


def has_theme_variable(content, line_idx, lines):
    """Check if 'theme' is defined as a local variable accessible at this line."""
    # Look backwards for 'final theme = Theme.of(context)' or 'theme =' or ThemeData theme
    for j in range(line_idx - 1, max(0, line_idx - 50), -1):
        l = lines[j].strip()
        if 'final theme = Theme.of(context)' in l:
            return True
        if 'theme = Theme.of(context)' in l:
            return True
        if 'ThemeData theme' in l:
            return True
        if ', theme,' in l or '(theme)' in l:
            return True
    # Also check if it's a build method with theme defined at top
    # Check for class-level theme definition
    for j in range(max(0, line_idx - 100), line_idx):
        l = lines[j].strip()
        if 'final theme = Theme.of(context)' in l:
            return True
    return False


def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    lines = content.split('\n')
    new_lines = []
    reverted = 0
    const_fixed = 0

    for i, line in enumerate(lines):
        # Check if this line uses theme.xxx
        if 'theme.' in line and 'Theme.of' not in line and 'theme ==' not in line and 'themeMode' not in line and 'themeProvider' not in line and 'AppTheme' not in line:
            # Check if theme variable is accessible
            if not has_theme_variable(content, i, lines):
                # Theme not accessible - revert to hardcoded colors
                for theme_expr, hardcoded in REVERSE_MAP.items():
                    if theme_expr in line:
                        line = line.replace(theme_expr, hardcoded)
                        reverted += 1

        new_lines.append(line)

    content = '\n'.join(new_lines)

    # Fix const issues - remove const from widgets containing theme.xxx
    widgets = ['Text','Icon','SizedBox','Padding','Column','Row','Container',
               'Center','Scaffold','AlertDialog','DropdownMenuItem','TextSpan',
               'InfoWindow','PopupMenuItem','ListTile','SnackBar','Chip','Card',
               'Tab','SwitchListTile','CheckboxListTile','Tooltip',
               'ElevatedButton','TextButton','OutlinedButton','CircleAvatar',
               'BoxDecoration','InputDecoration','TextStyle','EdgeInsets',
               'BorderSide','RoundedRectangleBorder','Divider','CircularProgressIndicator']

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
            if 'theme.' in content[ps:p]:
                content = content[:idx] + content[idx+6:]
                const_fixed += 1
            else:
                idx += len(pat)

    # const [...] with theme
    idx = 0
    while True:
        idx = content.find('const [', idx)
        if idx == -1: break
        d = 1; p = idx + 7
        while p < len(content) and d > 0:
            if content[p] == '[': d += 1
            elif content[p] == ']': d -= 1
            p += 1
        if 'theme.' in content[idx+7:p]:
            content = content[:idx] + content[idx+6:]
            const_fixed += 1
        else:
            idx += 7

    # Fix 'theme' shadowing issue: where a function parameter is called 'theme'
    # and we're trying to use Theme.of(context).
    # Pattern: prefix_shadowed_by_local_declaration
    # This happens when there's a parameter called 'theme' and we reference theme.colorScheme
    # We need to use a different variable name

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        stats['reverted'] += reverted
        stats['const_fixed'] += const_fixed
        stats['files'] += 1
        return True
    return False


def main():
    print("Fixing theme audit errors...\n")

    for root, dirs, files in os.walk(LIB):
        dirs[:] = [d for d in dirs if d not in {'l10n', 'generated'}]
        for fname in sorted(files):
            if not fname.endswith('.dart'): continue
            fp = os.path.join(root, fname)
            if fix_file(fp):
                rel = os.path.relpath(fp, PROJECT).replace('\\', '/')
                print(f"  {rel}")

    print(f"\n=== RESULTS ===")
    print(f"  Files: {stats['files']}")
    print(f"  Colors reverted (no theme var): {stats['reverted']}")
    print(f"  Const removed (theme.xxx): {stats['const_fixed']}")


if __name__ == '__main__':
    main()
