#!/usr/bin/env python3
"""Scan all Dart files under lib/ and extract hardcoded user-facing strings.
V2: Better filtering, separates clean strings from interpolated ones."""

import os
import re
import json
import sys

LIB_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'lib')

def should_exclude(s):
    """Check if string should be excluded from localization."""
    s = s.strip()
    if len(s) <= 1:
        return True
    if not any(c.isalpha() for c in s):
        return True
    # Exclude various non-user-facing patterns
    excludes = [
        r'^https?://',           # URLs
        r'^[a-z_]+$',           # pure snake_case identifiers
        r'^\d',                 # starts with number but check below
        r'^[A-Z_]+$',          # CONSTANT identifiers
        r'^\.',                 # file extensions
        r'^#[0-9a-fA-F]+$',    # color codes
        r'^assets/',            # asset paths
        r'^/[a-z\-]+',         # route paths
        r'^\s*$',              # whitespace only
        r'^package:',           # package imports
        r'^[a-z]+_[a-z_]+$',   # snake_case identifiers
        r'^\[',                 # array-like
        r'^debugPrint',         # debug stuff
        r'^SELECT|^INSERT|^UPDATE|^DELETE|^CREATE|^DROP',  # SQL
        r'^application/|^image/|^text/',  # MIME types
        r'^[A-Z][a-z]+[A-Z]',  # camelCase class names
        r'^\w+\(\)$',          # function calls
        r'^\w+\.\w+\.\w+',     # chained property access
        r'^Bearer ',             # auth headers
        r'^Content-Type',        # HTTP headers
    ]
    for pat in excludes:
        if re.match(pat, s):
            return True
    # Allow strings starting with numbers if they have words (like "24/7 Support")
    if re.match(r'^\d', s) and any(c.isalpha() for c in s):
        return False
    if re.match(r'^\d+$', s):
        return True
    return False

def make_key(s, seen_keys):
    """Generate a camelCase key from the string."""
    # Clean the string
    clean = re.sub(r'[^a-zA-Z0-9\s]', ' ', s)
    words = clean.split()
    if not words:
        return None
    # camelCase
    key = words[0].lower() + ''.join(w.capitalize() for w in words[1:6])
    key = re.sub(r'[^a-zA-Z0-9]', '', key)
    if not key or len(key) < 2:
        return None
    # Deduplicate
    base = key
    counter = 2
    while key in seen_keys:
        key = f"{base}{counter}"
        counter += 1
    return key

def extract_strings_from_file(filepath):
    """Extract all user-facing strings from a Dart file."""
    try:
        with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
            content = f.read()
            lines = content.split('\n')
    except Exception as e:
        return []

    results = []

    # Contexts where strings are user-facing
    # We scan line by line for common patterns
    for line_num, line in enumerate(lines, 1):
        stripped = line.strip()

        # Skip comments and imports
        if stripped.startswith('//') or stripped.startswith('import ') or stripped.startswith('export '):
            continue
        if stripped.startswith('debugPrint') or stripped.startswith('print('):
            continue

        # Find all single-quoted strings in user-facing contexts
        # Context patterns: Text(, title:, label:, hintText:, etc.
        contexts = [
            r"Text\(\s*'",
            r"title:\s*'",
            r"label:\s*'",
            r"hintText:\s*'",
            r"labelText:\s*'",
            r"helperText:\s*'",
            r"errorText:\s*'",
            r"tooltip:\s*'",
            r"text:\s*'",
            r"message:\s*'",
            r"content:\s*Text\(\s*'",
            r"child:\s*Text\(\s*'",
            r"subtitle:\s*Text\(\s*'",
            r"Tab\(\s*text:\s*'",
            r"BottomNavigationBarItem\([^)]*label:\s*'",
            r"NavigationDestination\([^)]*label:\s*'",
            r"AppBar\([^)]*title:\s*Text\(\s*'",
            r"header:\s*Text\(\s*'",
            r"hint:\s*'",
            r"description:\s*'",
            r"placeholder:\s*'",
            r"emptyText:\s*'",
            r"prefixText:\s*'",
            r"suffixText:\s*'",
            r"counterText:\s*'",
        ]

        for ctx in contexts:
            for m in re.finditer(ctx + r"([^']*)'", line):
                s = m.group(1) if m.lastindex else ''
                # Get the captured string
                groups = m.groups()
                if groups:
                    s = groups[-1]
                if s and not should_exclude(s) and '$' not in s:
                    results.append((s, line_num))

        # Also check double-quoted strings (less common in Dart)
        for ctx in [c.replace("'", '"') for c in contexts]:
            for m in re.finditer(ctx + r'([^"]*)"', line):
                groups = m.groups()
                if groups:
                    s = groups[-1]
                    if s and not should_exclude(s) and '$' not in s:
                        results.append((s, line_num))

    return results

def main():
    all_strings = {}  # string -> {files: [...], key: ...}
    seen_strings = {}

    for root, dirs, files in os.walk(LIB_DIR):
        for fname in sorted(files):
            if not fname.endswith('.dart'):
                continue
            filepath = os.path.join(root, fname)
            results = extract_strings_from_file(filepath)
            rel_path = os.path.relpath(filepath, os.path.dirname(LIB_DIR)).replace('\\', '/')

            for s, line_num in results:
                if s not in seen_strings:
                    seen_strings[s] = {
                        'locations': [f"{rel_path}:{line_num}"],
                    }
                else:
                    loc = f"{rel_path}:{line_num}"
                    if loc not in seen_strings[s]['locations']:
                        seen_strings[s]['locations'].append(loc)

    # Generate keys and output
    seen_keys = set()
    output = {}
    for s in sorted(seen_strings.keys(), key=str.lower):
        key = make_key(s, seen_keys)
        if key:
            seen_keys.add(key)
            output[key] = s

    # Output the ARB-compatible dict
    print(json.dumps(output, indent=2, ensure_ascii=False))
    print(f"\n// Total unique clean strings: {len(output)}", file=sys.stderr)

if __name__ == '__main__':
    main()
