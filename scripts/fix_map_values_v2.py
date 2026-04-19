#!/usr/bin/env python3
"""
Fix Pattern 1 (map literal values) — V2 with CORRECTED character class.

Bug in v1: r'[^"'\\\n]' actually compiled to [^"'\\n] which excludes
backslash AND the letter 'n', causing strings like "Shopping Cart",
"Personal Information" to never match.

V2 fix: use [^"'\n] (exclude only quotes and actual newline).
"""

import os, re, json

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJECT, 'lib')
L10N = os.path.join(LIB, 'l10n')

with open(os.path.join(L10N, 'app_en.arb'), 'r', encoding='utf-8') as f:
    en_arb = json.load(f)

str_to_key = {}
for k, v in en_arb.items():
    if not k.startswith('@@') and isinstance(v, str):
        str_to_key[v] = k


SKIP_DIRS = {'l10n', 'generated'}
SKIP_FILES = {'locale_provider.dart', 'language_selection_screen.dart', 'app_export.dart'}
NO_CONTEXT = {'services/', 'models/', 'theme/', 'providers/'}


def is_no_context(filepath):
    rel = os.path.relpath(filepath, LIB).replace('\\', '/')
    return any(rel.startswith(p) for p in NO_CONTEXT)


def should_skip(s):
    s = s.strip()
    if len(s) <= 1: return True
    if not any(c.isalpha() for c in s): return True
    if '$' in s: return True
    if chr(92) in s: return True  # backslash
    pats = [
        r'^https?://', r'^assets/', r'^package:', r'^/[a-z\-]',
        r'^[a-z_]+$', r'^[A-Z_]+$', r'^[a-z]+_[a-z_]+$',
        r'^#[0-9a-fA-F]+$', r'^\.', r'^[a-z]+\.[a-z]+',
    ]
    for p in pats:
        if re.match(p, s): return True
    return False


stats = {'files': 0, 'reps': 0}


def patch_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    original = content
    reps = 0

    # FIXED character class — only exclude quotes and actual newline (no \\)
    pattern = re.compile(
        r'''(["'])(title|subtitle|label|name|description|text|message|hint|placeholder|caption|header|category|status)(["'])\s*:\s*(["'])([^"'\n]+)(["'])'''
    )

    def replace(m):
        nonlocal reps
        kq1 = m.group(1)
        key_name = m.group(2)
        kq2 = m.group(3)
        vq1 = m.group(4)
        value = m.group(5)
        vq2 = m.group(6)

        if kq1 != kq2 or vq1 != vq2:
            return m.group(0)
        if should_skip(value):
            return m.group(0)

        loc_key = str_to_key.get(value)
        if not loc_key:
            return m.group(0)

        reps += 1
        return f'{kq1}{key_name}{kq2}: AppLocalizations.of(context)!.{loc_key}'

    content = pattern.sub(replace, content)

    if content != original:
        if 'app_localizations.dart' not in content:
            rel = os.path.relpath(os.path.join(LIB, 'l10n', 'generated'), os.path.dirname(filepath)).replace('\\', '/')
            imp = f"import '{rel}/app_localizations.dart';"
            lines = content.split('\n')
            last = -1
            for i, l in enumerate(lines):
                if l.strip().startswith('import ') and l.strip().endswith(';'):
                    last = i
            if last >= 0:
                lines.insert(last + 1, imp)
            content = '\n'.join(lines)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        stats['files'] += 1
        stats['reps'] += reps
        return True
    return False


def main():
    print("=== Fix Pattern 1 V2 (correct char class) ===\n")

    for root, dirs, files in os.walk(LIB):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for fname in sorted(files):
            if not fname.endswith('.dart') or fname in SKIP_FILES:
                continue
            fp = os.path.join(root, fname)
            if is_no_context(fp):
                continue
            if patch_file(fp):
                rel = os.path.relpath(fp, PROJECT).replace('\\', '/')
                print(f"  {rel}")

    print(f"\nFiles: {stats['files']}, Replacements: {stats['reps']}")


if __name__ == '__main__':
    main()
