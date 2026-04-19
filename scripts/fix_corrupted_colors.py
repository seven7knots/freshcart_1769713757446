#!/usr/bin/env python3
"""Fix corrupted color identifiers from bad substring replacement."""

import os, re

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJECT, 'lib')

# Corrupted patterns → correct values
FIXES = {
    # onSurface replaced inside onSurfaceVariant
    'Colors.black87Variant': 'Colors.grey',
    'Colors.black8754': 'Colors.grey',  # from grey[400] corruption
    # surfaceContainerHighest corrupted
    'Colors.whiteContainerHighest': 'Colors.grey.shade200',
    # outlineVariant corrupted
    'Colors.grey[300]Variant': 'Colors.grey.shade300',
    # scaffoldBackgroundColor corrupted
    'Color(0xFFF5F5F5)BackgroundColor': 'Color(0xFFF5F5F5)',
    # theme references that leaked into non-theme contexts
}

# Also fix standalone theme.xxx references that should have been reverted
# but weren't because the revert order was wrong
THEME_TO_REVERT = [
    # Order matters! Longer strings first to avoid partial replacement
    ('theme.colorScheme.surfaceContainerHighest', 'Colors.grey.shade200'),
    ('theme.colorScheme.onSurfaceVariant', 'Colors.grey'),
    ('theme.colorScheme.outlineVariant', 'Colors.grey.shade300'),
    ('theme.colorScheme.onSurface', 'Colors.black87'),
    ('theme.colorScheme.outline', 'Colors.grey.shade400'),
    ('theme.colorScheme.surface', 'Colors.white'),
    ('theme.scaffoldBackgroundColor', 'Color(0xFFF5F5F5)'),
]

fixed = 0

for root, dirs, files in os.walk(LIB):
    dirs[:] = [d for d in dirs if d not in {'l10n', 'generated'}]
    for fname in sorted(files):
        if not fname.endswith('.dart'): continue
        fp = os.path.join(root, fname)

        with open(fp, 'r', encoding='utf-8') as f:
            content = f.read()

        original = content

        # Fix corrupted identifiers
        for bad, good in FIXES.items():
            if bad in content:
                content = content.replace(bad, good)

        # Check if theme variable exists in this file
        has_theme = ('final theme = Theme.of(context)' in content or
                     'final theme =' in content or
                     'ThemeData theme' in content or
                     'var theme = Theme.of(context)' in content)

        if not has_theme:
            # Revert any remaining theme.xxx references (longest first!)
            for theme_ref, fallback in THEME_TO_REVERT:
                if theme_ref in content:
                    content = content.replace(theme_ref, fallback)

        # Fix const issues with theme.xxx
        if has_theme and 'theme.' in content:
            # Remove const from expressions containing theme.
            for w in ['Text','Icon','SizedBox','Padding','Container','Center',
                      'BoxDecoration','InputDecoration','TextStyle','BorderSide',
                      'Divider','CircleAvatar','CircularProgressIndicator',
                      'ListTile','Card','Chip']:
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
                    else:
                        idx += len(pat)

        if content != original:
            with open(fp, 'w', encoding='utf-8') as f:
                f.write(content)
            rel = os.path.relpath(fp, PROJECT).replace('\\', '/')
            print(f"  {rel}")
            fixed += 1

print(f"\nFixed {fixed} files")
