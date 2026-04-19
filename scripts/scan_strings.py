#!/usr/bin/env python3
"""Scan all Dart files under lib/ and extract hardcoded user-facing strings."""

import os
import re
import json
import sys

LIB_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'lib')

# Patterns that indicate user-facing strings
# We look for strings inside Text(), title:, label:, hintText:, etc.
PATTERNS = [
    # Text('...') or Text("...")
    r"""Text\(\s*(['"])(.*?)\1""",
    # title: '...' or title: "..."
    r"""title:\s*(['"])(.*?)\1""",
    # label: '...' or label: "..."
    r"""label:\s*(['"])(.*?)\1""",
    # hintText: '...' or hintText: "..."
    r"""hintText:\s*(['"])(.*?)\1""",
    # labelText: '...' or labelText: "..."
    r"""labelText:\s*(['"])(.*?)\1""",
    # helperText:
    r"""helperText:\s*(['"])(.*?)\1""",
    # errorText:
    r"""errorText:\s*(['"])(.*?)\1""",
    # tooltip:
    r"""tooltip:\s*(['"])(.*?)\1""",
    # semanticsLabel:
    r"""semanticsLabel:\s*(['"])(.*?)\1""",
    # content: Text('...')  - already covered by Text
    # AppBar title
    r"""AppBar\([^)]*title:\s*Text\(\s*(['"])(.*?)\1""",
    # SnackBar content
    r"""SnackBar\([^)]*content:\s*Text\(\s*(['"])(.*?)\1""",
    # showDialog / AlertDialog title
    r"""AlertDialog\([^)]*title:\s*Text\(\s*(['"])(.*?)\1""",
    # Tab(text: ...)
    r"""Tab\(\s*text:\s*(['"])(.*?)\1""",
    # BottomNavigationBarItem label
    r"""BottomNavigationBarItem\([^)]*label:\s*(['"])(.*?)\1""",
    # NavigationDestination label
    r"""NavigationDestination\([^)]*label:\s*(['"])(.*?)\1""",
    # ElevatedButton/TextButton child Text
    # DropdownMenuItem
    # ListTile title/subtitle
    r"""ListTile\([^)]*title:\s*Text\(\s*(['"])(.*?)\1""",
    r"""ListTile\([^)]*subtitle:\s*Text\(\s*(['"])(.*?)\1""",
]

# Strings to exclude (not user-facing)
EXCLUDE_PATTERNS = [
    r'^https?://',           # URLs
    r'^\$',                  # Interpolation
    r'^[a-z_]+$',           # snake_case identifiers
    r'^\d+$',              # pure numbers
    r'^[A-Z_]+$',          # CONSTANT identifiers
    r'^[a-z]+_[a-z]+',     # snake_case
    r'^\.',                 # file extensions
    r'^#[0-9a-fA-F]+$',    # color codes
    r'^assets/',            # asset paths
    r'^/',                  # route paths
    r'^\s*$',              # whitespace only
    r'^[{}()\[\]]$',       # brackets
    r'^\w+\.\w+$',         # property access
    r'^package:',           # package imports
]

def should_exclude(s):
    """Check if string should be excluded from localization."""
    s = s.strip()
    if len(s) <= 1:
        return True
    if not any(c.isalpha() for c in s):
        return True
    for pat in EXCLUDE_PATTERNS:
        if re.match(pat, s):
            return True
    return False

def make_key(s, seen_keys):
    """Generate a snake_case key from the string."""
    # Take first few words
    words = re.findall(r'[a-zA-Z]+', s)
    if not words:
        return None
    key = '_'.join(w.lower() for w in words[:5])
    key = re.sub(r'[^a-z0-9_]', '', key)
    if not key:
        return None
    # Deduplicate
    base = key
    counter = 2
    while key in seen_keys:
        key = f"{base}_{counter}"
        counter += 1
    return key

def scan_file(filepath):
    """Scan a single Dart file for hardcoded strings."""
    try:
        with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading {filepath}: {e}", file=sys.stderr)
        return []

    strings = []

    # Simple approach: find all quoted strings in user-facing contexts
    # Look for common patterns

    # Pattern 1: Text('...')  Text("...")
    for m in re.finditer(r"""Text\(\s*'([^'\\]*(?:\\.[^'\\]*)*)'\s*[,)]""", content):
        s = m.group(1)
        if not should_exclude(s):
            strings.append((s, filepath, m.start()))
    for m in re.finditer(r'''Text\(\s*"([^"\\]*(?:\\.[^"\\]*)*)"\s*[,)]''', content):
        s = m.group(1)
        if not should_exclude(s) and '$' not in s:
            strings.append((s, filepath, m.start()))

    # Pattern 2: title: '...'
    for m in re.finditer(r"""(?:title|label|hintText|labelText|helperText|errorText|tooltip|text):\s*'([^'\\]*(?:\\.[^'\\]*)*)'\s*[,)]""", content):
        s = m.group(1)
        if not should_exclude(s):
            strings.append((s, filepath, m.start()))
    for m in re.finditer(r'''(?:title|label|hintText|labelText|helperText|errorText|tooltip|text):\s*"([^"\\]*(?:\\.[^"\\]*)*)"\s*[,)]''', content):
        s = m.group(1)
        if not should_exclude(s) and '$' not in s:
            strings.append((s, filepath, m.start()))

    # Pattern 3: SnackBar messages - Text('...')  inside showSnackBar
    # Already covered by Text pattern

    # Pattern 4: Tab(text: '...')
    for m in re.finditer(r"""Tab\(\s*text:\s*'([^'\\]*)'\s*""", content):
        s = m.group(1)
        if not should_exclude(s):
            strings.append((s, filepath, m.start()))

    return strings

def main():
    all_strings = []
    seen = set()

    for root, dirs, files in os.walk(LIB_DIR):
        for fname in sorted(files):
            if not fname.endswith('.dart'):
                continue
            filepath = os.path.join(root, fname)
            results = scan_file(filepath)
            for s, fp, pos in results:
                if s not in seen:
                    seen.add(s)
                    rel_path = os.path.relpath(fp, os.path.dirname(LIB_DIR))
                    all_strings.append({
                        'string': s,
                        'file': rel_path.replace('\\', '/'),
                    })

    # Sort by string
    all_strings.sort(key=lambda x: x['string'].lower())

    # Generate keys
    seen_keys = set()
    result = {}
    for item in all_strings:
        key = make_key(item['string'], seen_keys)
        if key:
            seen_keys.add(key)
            result[key] = {
                'en': item['string'],
                'file': item['file'],
            }

    # Output as JSON
    print(json.dumps(result, indent=2, ensure_ascii=False))
    print(f"\n// Total unique strings found: {len(result)}", file=sys.stderr)

if __name__ == '__main__':
    main()
