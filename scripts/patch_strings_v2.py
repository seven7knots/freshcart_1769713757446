#!/usr/bin/env python3
"""
Replace hardcoded English strings with AppLocalizations calls in all Dart files.
V2: More robust pattern matching, handles edge cases.
Uses Python to avoid PowerShell ${} interpolation issues.
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

# Create reverse mapping: string -> key (longest strings first for priority)
string_to_key = {}
for key, string_val in key_to_string.items():
    string_to_key[string_val] = key

# Files/dirs to skip
SKIP_DIRS = {'l10n', 'generated'}
SKIP_FILES = {
    'app_export.dart',
    'locale_provider.dart',
    'language_selection_screen.dart',
}

stats = {'files_modified': 0, 'replacements': 0}

def add_localization_import(content, file_path):
    """Add AppLocalizations import to the file."""
    rel = os.path.relpath(
        os.path.join(LIB_DIR, 'l10n', 'generated'),
        os.path.dirname(file_path)
    ).replace('\\', '/')
    import_line = f"import '{rel}/app_localizations.dart';"

    # Check if already imported
    if 'app_localizations.dart' in content:
        return content

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


def process_file(filepath):
    """Process a single Dart file and replace strings."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        return False

    original = content
    replacement_count = 0

    # Sort strings longest first to avoid partial replacements
    sorted_strings = sorted(string_to_key.keys(), key=len, reverse=True)

    for string_val in sorted_strings:
        key = string_to_key[string_val]

        # Skip very short strings that could cause false positives
        if len(string_val) <= 2:
            continue

        for quote in ["'", '"']:
            quoted = f"{quote}{string_val}{quote}"
            if quoted not in content:
                continue

            localized = f"AppLocalizations.of(context)!.{key}"

            # Find and replace in UI contexts
            # We look for patterns like:
            #   Text('string'  ->  Text(AppLocalizations.of(context)!.key
            #   title: 'string' -> title: AppLocalizations.of(context)!.key
            #   label: 'string' -> label: AppLocalizations.of(context)!.key
            # etc.

            # Pattern A: Text('string' (opening of Text widget)
            pattern_text = f"Text(\\s*{re.escape(quoted)}"
            if re.search(pattern_text, content):
                content = re.sub(pattern_text, f"Text({localized}", content)
                replacement_count += 1

            # Pattern B: property: 'string' (named parameter or property)
            properties = [
                'title', 'label', 'hintText', 'labelText', 'helperText',
                'errorText', 'tooltip', 'text', 'message', 'hint',
                'description', 'placeholder', 'emptyText', 'prefixText',
                'suffixText', 'counterText', 'header',
            ]
            for prop in properties:
                pattern_prop = f"({prop}:\\s*){re.escape(quoted)}"
                replacement_prop = f"\\g<1>{localized}"
                new_content = re.sub(pattern_prop, replacement_prop, content)
                if new_content != content:
                    content = new_content
                    replacement_count += 1

            # Pattern C: child: Text('string'
            pattern_child_text = f"(child:\\s*Text\\(\\s*){re.escape(quoted)}"
            if re.search(pattern_child_text, content):
                content = re.sub(pattern_child_text, f"\\g<1>{localized}", content)
                replacement_count += 1

            # Pattern D: subtitle: Text('string'
            pattern_sub_text = f"(subtitle:\\s*Text\\(\\s*){re.escape(quoted)}"
            if re.search(pattern_sub_text, content):
                content = re.sub(pattern_sub_text, f"\\g<1>{localized}", content)
                replacement_count += 1

            # Pattern E: content: Text('string'
            pattern_content_text = f"(content:\\s*Text\\(\\s*){re.escape(quoted)}"
            if re.search(pattern_content_text, content):
                content = re.sub(pattern_content_text, f"\\g<1>{localized}", content)
                replacement_count += 1

            # Pattern F: Tab(text: 'string'
            pattern_tab = f"(Tab\\(\\s*text:\\s*){re.escape(quoted)}"
            if re.search(pattern_tab, content):
                content = re.sub(pattern_tab, f"\\g<1>{localized}", content)
                replacement_count += 1

    if content != original and replacement_count > 0:
        # Add import
        content = add_localization_import(content, filepath)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)

        stats['files_modified'] += 1
        stats['replacements'] += replacement_count
        return True

    return False


def main():
    dart_files = []
    for root, dirs, files in os.walk(LIB_DIR):
        dir_name = os.path.basename(root)
        if dir_name in SKIP_DIRS:
            continue
        # Also skip walking into l10n
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]

        for fname in sorted(files):
            if not fname.endswith('.dart'):
                continue
            if fname in SKIP_FILES:
                continue
            filepath = os.path.join(root, fname)
            dart_files.append(filepath)

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
