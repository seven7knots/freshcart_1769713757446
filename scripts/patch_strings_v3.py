#!/usr/bin/env python3
"""
Replace hardcoded English strings with AppLocalizations calls in all Dart files.
V3: Uses simple string replacement instead of regex for the actual string matching.
"""

import os
import re
import json
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
LIB_DIR = os.path.join(PROJECT_DIR, 'lib')

# Load the string->key mapping
with open(os.path.join(SCRIPT_DIR, 'clean_strings.json'), 'r', encoding='utf-8') as f:
    key_to_string = json.load(f)

# Fix renamed keys
renames = {'961XxXxxXxx': 'phoneNumberPlaceholder', 'continue': 'continueText', 'type': 'typeText'}
for old, new in renames.items():
    if old in key_to_string:
        key_to_string[new] = key_to_string.pop(old)

# Create reverse mapping
string_to_key = {}
for key, string_val in key_to_string.items():
    string_to_key[string_val] = key

SKIP_DIRS = {'l10n', 'generated'}
SKIP_FILES = {
    'app_export.dart',
    'locale_provider.dart',
    'language_selection_screen.dart',
}

stats = {'files_modified': 0, 'replacements': 0}


def add_localization_import(content, file_path):
    """Add AppLocalizations import to the file."""
    if 'app_localizations.dart' in content:
        return content

    rel = os.path.relpath(
        os.path.join(LIB_DIR, 'l10n', 'generated'),
        os.path.dirname(file_path)
    ).replace('\\', '/')
    import_line = f"import '{rel}/app_localizations.dart';"

    lines = content.split('\n')
    last_import_idx = -1
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith('import ') and stripped.endswith(';'):
            last_import_idx = i

    if last_import_idx >= 0:
        lines.insert(last_import_idx + 1, import_line)
    else:
        lines.insert(0, import_line)
    return '\n'.join(lines)


def replace_in_context(content, quoted_str, localized, contexts):
    """Replace quoted_str with localized value when preceded by a context pattern."""
    count = 0
    for ctx in contexts:
        target = ctx + quoted_str
        if target in content:
            replacement = ctx + localized
            content = content.replace(target, replacement)
            count += content.count(ctx + localized)

    return content, count


def process_file(filepath):
    """Process a single Dart file and replace strings."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception:
        return False

    original = content
    total_replacements = 0

    # Sort strings longest first
    sorted_strings = sorted(string_to_key.keys(), key=len, reverse=True)

    for string_val in sorted_strings:
        key = string_to_key[string_val]

        # Skip very short strings
        if len(string_val) <= 2:
            continue

        localized = f"AppLocalizations.of(context)!.{key}"

        for quote in ["'", '"']:
            quoted = f"{quote}{string_val}{quote}"
            if quoted not in content:
                continue

            # Define context prefixes that indicate UI-facing strings
            # Each prefix should end right before the quoted string
            prefixes = [
                # Text widget
                "Text(",
                "Text( ",
                "Text(\n",
                "Text(\n  ",
                "Text(\n    ",
                "Text(\n      ",
                "Text(\n        ",
                "Text(\n          ",
                "Text(\n            ",
                # Named parameters
                "title: ",
                "label: ",
                "hintText: ",
                "labelText: ",
                "helperText: ",
                "errorText: ",
                "tooltip: ",
                "text: ",
                "message: ",
                "hint: ",
                "placeholder: ",
                "emptyText: ",
                "prefixText: ",
                "suffixText: ",
                "counterText: ",
                "header: Text(",
                # Without space
                "title:",
                "label:",
                "hintText:",
                "labelText:",
                "helperText:",
                "errorText:",
                "tooltip:",
                "text:",
                "message:",
                "hint:",
                "placeholder:",
                # child/content/subtitle with Text
                "child: Text(",
                "child: Text( ",
                "subtitle: Text(",
                "subtitle: Text( ",
                "content: Text(",
                "content: Text( ",
                # Tab
                "Tab(text: ",
                "Tab(text:",
            ]

            for prefix in prefixes:
                target = prefix + quoted
                if target in content:
                    replacement = prefix + localized
                    old_content = content
                    content = content.replace(target, replacement)
                    if content != old_content:
                        total_replacements += 1

    if content != original and total_replacements > 0:
        content = add_localization_import(content, filepath)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        stats['files_modified'] += 1
        stats['replacements'] += total_replacements
        return True

    return False


def main():
    dart_files = []
    for root, dirs, files in os.walk(LIB_DIR):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for fname in sorted(files):
            if not fname.endswith('.dart'):
                continue
            if fname in SKIP_FILES:
                continue
            dart_files.append(os.path.join(root, fname))

    print(f"Processing {len(dart_files)} Dart files...")

    for filepath in dart_files:
        rel = os.path.relpath(filepath, PROJECT_DIR).replace('\\', '/')
        modified = process_file(filepath)
        if modified:
            print(f"  Modified: {rel}")

    print(f"\nDone!")
    print(f"  Files modified: {stats['files_modified']}")
    print(f"  Total replacements: {stats['replacements']}")


if __name__ == '__main__':
    main()
