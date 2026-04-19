#!/usr/bin/env python3
"""
MEGA SCAN: Find EVERY remaining hardcoded English string in ALL Dart files.
Covers Text(), title:, label:, hintText:, ternary, return, SnackBar, Dialog, etc.
"""

import os, re, json, sys

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJECT, 'lib')

# Load existing ARB keys
with open(os.path.join(LIB, 'l10n', 'app_en.arb'), 'r', encoding='utf-8') as f:
    existing_en = json.load(f)
existing_values = set(v for k, v in existing_en.items() if not k.startswith('@@'))

SKIP_DIRS = {'l10n', 'generated'}
SKIP_FILES = {'locale_provider.dart', 'language_selection_screen.dart', 'app_export.dart'}

def should_skip(s):
    s = s.strip()
    if len(s) <= 1: return True
    alpha = sum(1 for c in s if c.isalpha())
    if alpha < 2: return True
    if '$' in s: return True  # interpolation
    patterns = [
        r'^https?://', r'^assets/', r'^package:', r'^/[a-z\-]',
        r'^[a-z_]+$', r'^[A-Z_]+$', r'^[a-z]+_[a-z_]+$',
        r'^#[0-9a-fA-F]+$', r'^\.',
        r'^SELECT |^INSERT |^UPDATE |^DELETE |^CREATE ',
        r'^application/|^image/|^text/',
        r'^Bearer ', r'^Content-Type',
        r'^\w+\.\w+$',
        r'^inventory_\d',
    ]
    for p in patterns:
        if re.match(p, s): return True
    return False

def extract_strings(line, line_num):
    """Extract all user-facing quoted strings from a line."""
    results = []
    stripped = line.strip()

    # Skip non-UI lines
    if stripped.startswith('//') or stripped.startswith('import ') or stripped.startswith('export '):
        return results
    if 'debugPrint' in stripped or stripped.startswith('print(') or stripped.startswith('log('):
        return results
    if 'AppLocalizations' in stripped:
        return results

    # Extract single-quoted strings in UI contexts
    # Wide net: any single-quoted string that appears after a UI keyword
    ui_patterns = [
        # Direct widget constructors
        (r"Text\(\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'Text'),
        # Named parameters
        (r"(?:title|label|hintText|labelText|helperText|errorText|tooltip|text|message|hint|description|actionLabel|placeholder|emptyText|prefixText|suffixText|counterText|header|semanticsLabel):\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'param'),
        # Widget params with Text child
        (r"(?:child|subtitle|content|title):\s*Text\(\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'widget_text'),
        # TextSpan
        (r"TextSpan\(\s*text:\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'textspan'),
        # Tab
        (r"Tab\(\s*text:\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'tab'),
        # BottomNavigationBarItem / NavigationDestination
        (r"(?:BottomNavigationBarItem|NavigationDestination)\([^)]*label:\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'nav'),
        # SnackBar content
        (r"SnackBar\(\s*content:\s*Text\(\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'snackbar'),
        # showDialog title/content
        (r"AlertDialog\([^)]*title:\s*Text\(\s*'([^'\\]*(?:\\.[^'\\]*)*)'", 'dialog'),
        # Ternary expressions
        (r"\?\s*'([^'\\]+)'", 'ternary_true'),
        (r":\s*'([^'\\]+)'", 'ternary_false'),
        # Return statements
        (r"return\s+'([^'\\]*)'\s*;", 'return'),
        # Assignment to String variable
        (r"=\s*'([^'\\]+)'\s*;", 'assign'),
    ]

    for pattern, ctx in ui_patterns:
        for m in re.finditer(pattern, line):
            s = m.group(1)
            if should_skip(s): continue
            if s in existing_values: continue  # already in ARB
            results.append({'line': line_num, 'string': s, 'context': ctx})

    return results

def scan_file(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
        lines = f.readlines()
    results = []
    for i, line in enumerate(lines, 1):
        results.extend(extract_strings(line, i))
    return results

def make_key(s, seen):
    clean = re.sub(r'[^a-zA-Z0-9\s]', ' ', s)
    words = clean.split()
    if not words: return None
    key = words[0].lower() + ''.join(w.capitalize() for w in words[1:6])
    key = re.sub(r'[^a-zA-Z0-9]', '', key)
    if not key or len(key) < 2: return None
    # Avoid Dart keywords
    dart_kw = {'continue','default','in','is','new','return','switch','this','var','void','while','do','for','if','else','class','try','catch','throw','super','abstract','enum','extends','implements'}
    if key in dart_kw: key += 'Text'
    base = key
    c = 2
    while key in seen or key in existing_en:
        key = f"{base}{c}"
        c += 1
    return key

def main():
    all_results = {}
    unique_strings = {}

    for root, dirs, files in os.walk(LIB):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for fname in sorted(files):
            if not fname.endswith('.dart') or fname in SKIP_FILES: continue
            fp = os.path.join(root, fname)
            results = scan_file(fp)
            if results:
                rel = os.path.relpath(fp, PROJECT).replace('\\', '/')
                all_results[rel] = results
                for r in results:
                    s = r['string']
                    if s not in unique_strings:
                        unique_strings[s] = {'files': [], 'ctx': r['context']}
                    unique_strings[s]['files'].append(f"{rel}:{r['line']}")

    # Generate keys
    seen_keys = set()
    output = {}
    for s in sorted(unique_strings.keys(), key=str.lower):
        key = make_key(s, seen_keys)
        if key:
            seen_keys.add(key)
            output[key] = {'en': s, 'locations': unique_strings[s]['files'][:3], 'ctx': unique_strings[s]['ctx']}

    # Print summary
    total_occ = sum(len(r) for r in all_results.values())
    print(f"=== MEGA SCAN RESULTS ===")
    print(f"Files with hardcoded strings: {len(all_results)}")
    print(f"Total occurrences: {total_occ}")
    print(f"Unique new strings: {len(output)}")
    print()

    for fp, results in sorted(all_results.items()):
        print(f"--- {fp} ({len(results)} strings) ---")
        for r in results:
            print(f"  L{r['line']:4d} [{r['context']:12s}] {r['string'][:90]}")

    # Save for patching
    save = {k: v['en'] for k, v in output.items()}
    outpath = os.path.join(PROJECT, 'scripts', 'mega_remaining.json')
    with open(outpath, 'w', encoding='utf-8') as f:
        json.dump(save, f, indent=2, ensure_ascii=False)
    print(f"\nSaved {len(save)} strings to {outpath}")

if __name__ == '__main__':
    main()
