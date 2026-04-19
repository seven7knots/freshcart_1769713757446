#!/usr/bin/env python3
"""
Replace hardcoded English strings with AppLocalizations calls in all Dart files.
Uses Python to avoid PowerShell ${} interpolation issues.
"""

import os
import re
import json
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
LIB_DIR = os.path.join(PROJECT_DIR, 'lib')

# Load the string->key mapping (reverse of what we extracted)
with open(os.path.join(SCRIPT_DIR, 'clean_strings.json'), 'r', encoding='utf-8') as f:
    key_to_string = json.load(f)

# Fix renamed keys
if '961XxXxxXxx' in key_to_string:
    key_to_string['phoneNumberPlaceholder'] = key_to_string.pop('961XxXxxXxx')
if 'continue' in key_to_string:
    key_to_string['continueText'] = key_to_string.pop('continue')
if 'type' in key_to_string:
    key_to_string['typeText'] = key_to_string.pop('type')

# Create reverse mapping: string -> key
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

# Also skip model files, service files, and provider files (non-UI)
SKIP_PREFIXES = []  # We actually want to patch services too if they have UI strings

# Track statistics
stats = {'files_modified': 0, 'replacements': 0, 'skipped_interpolation': 0}

def needs_localization_import(content):
    """Check if file already has the AppLocalizations import."""
    return "import" in content and "app_localizations.dart" in content

def add_localization_import(content, file_path):
    """Add AppLocalizations import to the file."""
    # Calculate relative path to l10n/generated
    rel = os.path.relpath(
        os.path.join(LIB_DIR, 'l10n', 'generated'),
        os.path.dirname(file_path)
    ).replace('\\', '/')
    import_line = f"import '{rel}/app_localizations.dart';"

    # Find the last import line and add after it
    lines = content.split('\n')
    last_import_idx = -1
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith('import ') and stripped.endswith(';'):
            last_import_idx = i

    if last_import_idx >= 0:
        lines.insert(last_import_idx + 1, import_line)
        return '\n'.join(lines)
    else:
        # No imports found, add at top
        return import_line + '\n' + content

def replace_strings_in_file(filepath):
    """Replace hardcoded strings in a single Dart file."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            original = f.read()
    except Exception as e:
        return False

    content = original
    file_replacements = 0

    # Sort strings by length (longest first) to avoid partial matches
    sorted_strings = sorted(string_to_key.keys(), key=len, reverse=True)

    for string_val in sorted_strings:
        key = string_to_key[string_val]

        # Skip very short or ambiguous strings
        if len(string_val) <= 2:
            continue

        # Escape for regex
        escaped = re.escape(string_val)

        # Pattern 1: Text('string') or Text("string")
        # Replace with Text(AppLocalizations.of(context)!.key)
        for quote in ["'", '"']:
            esc_q = re.escape(quote)

            # Text('string') -> Text(AppLocalizations.of(context)!.key)
            pattern = rf"Text\(\s*{esc_q}{escaped}{esc_q}"
            replacement = f"Text(AppLocalizations.of(context)!.{key}"
            if re.search(pattern, content):
                content = re.sub(pattern, replacement, content)
                file_replacements += content.count(f"AppLocalizations.of(context)!.{key}") if file_replacements == 0 else 0

            # title: 'string' -> title: AppLocalizations.of(context)!.key
            for prop in ['title', 'label', 'hintText', 'labelText', 'helperText',
                        'errorText', 'tooltip', 'text', 'message', 'hint',
                        'description', 'placeholder', 'emptyText', 'prefixText',
                        'suffixText', 'counterText']:
                pattern = rf"({prop}:\s*){esc_q}{escaped}{esc_q}"
                replacement = rf"\g<1>AppLocalizations.of(context)!.{key}"
                new_content = re.sub(pattern, content, content)
                if new_content != content:
                    content = new_content

    # Simpler approach: just replace quoted strings in known contexts
    # Reset and do a simpler pass
    content = original
    file_replacements = 0

    for string_val in sorted_strings:
        key = string_to_key[string_val]
        if len(string_val) <= 2:
            continue

        for quote in ["'", '"']:
            quoted = f"{quote}{string_val}{quote}"
            localized = f"AppLocalizations.of(context)!.{key}"

            if quoted not in content:
                continue

            # Find all occurrences and check context
            idx = 0
            while True:
                idx = content.find(quoted, idx)
                if idx == -1:
                    break

                # Check what comes before this quoted string
                # Look back up to 80 chars for context
                prefix = content[max(0, idx-80):idx].strip()

                # User-facing contexts where we should replace
                ui_contexts = [
                    'Text(', 'title:', 'label:', 'hintText:', 'labelText:',
                    'helperText:', 'errorText:', 'tooltip:', 'text:',
                    'message:', 'hint:', 'content: Text(',
                    'child: Text(', 'subtitle: Text(', 'Tab(text:',
                    'description:', 'header: Text(',
                ]

                should_replace = False
                for ctx in ui_contexts:
                    if prefix.endswith(ctx) or prefix.endswith(ctx.rstrip()):
                        should_replace = True
                        break
                    # Also check with possible whitespace
                    ctx_base = ctx.rstrip('( :')
                    if ctx_base and (prefix.endswith(ctx_base + '(') or
                                    prefix.endswith(ctx_base + ': ') or
                                    prefix.endswith(ctx_base + ':') or
                                    prefix.endswith(ctx_base + '( ')):
                        should_replace = True
                        break

                if should_replace:
                    content = content[:idx] + localized + content[idx + len(quoted):]
                    file_replacements += 1
                    stats['replacements'] += 1
                    # Don't advance idx since we replaced
                else:
                    idx += len(quoted)

    if content != original:
        # Add import if needed
        if 'AppLocalizations.of(context)!' in content and not needs_localization_import(content):
            content = add_localization_import(content, filepath)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        stats['files_modified'] += 1
        return True

    return False

def main():
    dart_files = []
    for root, dirs, files in os.walk(LIB_DIR):
        # Skip certain directories
        dir_name = os.path.basename(root)
        if dir_name in SKIP_DIRS:
            continue

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
        modified = replace_strings_in_file(filepath)
        if modified:
            print(f"  Modified: {rel}")

    print(f"\nDone!")
    print(f"  Files modified: {stats['files_modified']}")
    print(f"  Total replacements: {stats['replacements']}")

if __name__ == '__main__':
    main()
