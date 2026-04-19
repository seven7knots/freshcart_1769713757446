#!/usr/bin/env python3
"""
Deep scan for ALL remaining hardcoded English strings in Dart files.
Reports strings NOT yet wrapped in AppLocalizations.
"""

import os
import re
import json
import sys

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJECT, 'lib')

SKIP_DIRS = {'l10n', 'generated'}
SKIP_FILES = {'locale_provider.dart', 'language_selection_screen.dart', 'app_export.dart'}

# Load existing ARB keys for reference
with open(os.path.join(PROJECT, 'lib', 'l10n', 'app_en.arb'), 'r', encoding='utf-8') as f:
    existing_en = json.load(f)

def should_skip_string(s):
    s = s.strip()
    if len(s) <= 1:
        return True
    if not any(c.isalpha() for c in s):
        return True
    # Skip technical/non-user strings
    patterns = [
        r'^https?://', r'^assets/', r'^package:', r'^/[a-z\-]',
        r'^[a-z_]+$', r'^[A-Z_]+$', r'^[a-z]+_[a-z_]+$',
        r'^#[0-9a-fA-F]+$', r'^\.',
        r'^SELECT |^INSERT |^UPDATE |^DELETE ',
        r'^application/|^image/|^text/',
        r'^Bearer ', r'^Content-Type',
        r'^[a-z]+\.[a-z]+',  # property.access
        r'^\w+\(\)$',        # function()
    ]
    for p in patterns:
        if re.match(p, s):
            return True
    # Skip if only has digits and punctuation with a single letter
    alpha_count = sum(1 for c in s if c.isalpha())
    if alpha_count < 2:
        return True
    return False

def scan_file(filepath):
    """Scan a file for remaining hardcoded strings."""
    with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
        lines = f.readlines()

    results = []

    for line_num, line in enumerate(lines, 1):
        stripped = line.strip()

        # Skip lines that are comments, imports, debugPrint, print
        if stripped.startswith('//') or stripped.startswith('import ') or stripped.startswith('export '):
            continue
        if 'debugPrint' in stripped or stripped.startswith('print('):
            continue
        # Skip if already uses AppLocalizations
        if 'AppLocalizations' in stripped:
            continue

        # Find quoted strings in UI contexts
        # Context patterns before the quoted string
        contexts_single = [
            (r"Text\(\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'Text'),
            (r"title:\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'title'),
            (r"label:\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'label'),
            (r"hintText:\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'hintText'),
            (r"labelText:\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'labelText'),
            (r"helperText:\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'helperText'),
            (r"errorText:\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'errorText'),
            (r"tooltip:\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'tooltip'),
            (r"text:\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'text'),
            (r"message:\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'message'),
            (r"hint:\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'hint'),
            (r"description:\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'description'),
            (r"actionLabel:\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'actionLabel'),
            (r"subtitle:\s*Text\(\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'subtitle_text'),
            (r"content:\s*Text\(\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'content_text'),
            (r"child:\s*Text\(\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'child_text'),
            (r"header:\s*Text\(\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'header_text'),
            (r"TextSpan\(\s*text:\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'textspan'),
            (r"Tab\(\s*text:\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'tab_text'),
            (r"BottomNavigationBarItem\([^)]*label:\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'nav_label'),
            (r"NavigationDestination\([^)]*label:\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'nav_dest'),
        ]

        for pattern, ctx in contexts_single:
            for m in re.finditer(pattern, line):
                s = m.group(1)
                if '$' in s:
                    continue  # skip interpolated strings
                if should_skip_string(s):
                    continue
                results.append({
                    'line': line_num,
                    'string': s,
                    'context': ctx,
                })

        # Also check return statements with plain strings used in UI
        # e.g.: return 'Good Morning';
        ret_match = re.search(r"return\s+'([^'\\]*(?:\\.[^'\\]*)*)'\s*;", line)
        if ret_match:
            s = ret_match.group(1)
            if not should_skip_string(s) and '$' not in s:
                results.append({
                    'line': line_num,
                    'string': s,
                    'context': 'return',
                })

        # Check ternary/conditional string expressions
        # e.g.: isOpen ? 'Open' : 'Closed'
        for m in re.finditer(r"\?\s*'([^'\\]+)'\s*:\s*'([^'\\]+)'", line):
            for g in [1, 2]:
                s = m.group(g)
                if not should_skip_string(s) and '$' not in s:
                    results.append({
                        'line': line_num,
                        'string': s,
                        'context': 'ternary',
                    })

        # Check showSnackBar content
        snack_match = re.search(r"SnackBar\(\s*content:\s*Text\(\s*'([^'\\]*)'", line)
        if snack_match:
            s = snack_match.group(1)
            if not should_skip_string(s) and '$' not in s:
                results.append({
                    'line': line_num,
                    'string': s,
                    'context': 'snackbar',
                })

    return results


def main():
    all_results = {}
    total = 0

    for root, dirs, files in os.walk(LIB):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for fname in sorted(files):
            if not fname.endswith('.dart') or fname in SKIP_FILES:
                continue
            filepath = os.path.join(root, fname)
            results = scan_file(filepath)
            if results:
                rel = os.path.relpath(filepath, PROJECT).replace('\\', '/')
                all_results[rel] = results
                total += len(results)

    # Deduplicate strings
    unique_strings = {}
    for filepath, results in all_results.items():
        for r in results:
            s = r['string']
            if s not in unique_strings:
                unique_strings[s] = []
            unique_strings[s].append(f"{filepath}:{r['line']}")

    # Output
    print(f"=== REMAINING HARDCODED STRINGS ===")
    print(f"Total occurrences: {total}")
    print(f"Unique strings: {len(unique_strings)}")
    print()

    for filepath, results in sorted(all_results.items()):
        print(f"\n--- {filepath} ---")
        for r in results:
            print(f"  L{r['line']:4d} [{r['context']:12s}] {r['string'][:80]}")

    # Output unique strings as JSON for ARB generation
    output = {}
    for s in sorted(unique_strings.keys(), key=str.lower):
        # Generate a camelCase key
        clean = re.sub(r'[^a-zA-Z0-9\s]', ' ', s)
        words = clean.split()
        if not words:
            continue
        key = words[0].lower() + ''.join(w.capitalize() for w in words[1:6])
        key = re.sub(r'[^a-zA-Z0-9]', '', key)
        if not key or len(key) < 2:
            continue
        # Check collision with existing
        base = key
        counter = 2
        while key in existing_en or key in output:
            key = f"{base}{counter}"
            counter += 1
        output[key] = s

    # Write to file
    outpath = os.path.join(PROJECT, 'scripts', 'remaining_strings.json')
    with open(outpath, 'w', encoding='utf-8') as f:
        json.dump(output, f, indent=2, ensure_ascii=False)
    print(f"\nWrote {len(output)} unique strings to {outpath}")


if __name__ == '__main__':
    main()
