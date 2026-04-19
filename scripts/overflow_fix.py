#!/usr/bin/env python3
"""
OVERFLOW FIX: Add maxLines + TextOverflow.ellipsis to Text widgets
that display dynamic content (names, addresses, descriptions).
Wrap Row Text children in Flexible where needed.
"""

import os, re

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJECT, 'lib')

stats = {'files': 0, 'text_fixes': 0, 'flex_fixes': 0, 'scroll_fixes': 0}


def add_overflow_to_text_widgets(content):
    """
    Find Text widgets that take dynamic content and add maxLines + overflow.
    Patterns we target:
    1. Text(variable) — single arg, dynamic content
    2. Text('string $var') — interpolated content
    3. Text(obj.field)
    4. Text(obj.field ?? 'default')
    But ONLY when there's no maxLines/overflow already.
    """
    count = 0
    new_content = content

    # Pattern: Text(<dynamic content>) without maxLines or overflow
    # Approach: find Text( ... ) calls and check what's inside
    # Use a parser-like approach: find Text( and then balance parens

    result = []
    i = 0
    while i < len(new_content):
        # Find next Text(
        idx = new_content.find('Text(', i)
        if idx == -1:
            result.append(new_content[i:])
            break

        # Check it's actually a Text widget call (not within another word)
        if idx > 0 and (new_content[idx-1].isalnum() or new_content[idx-1] == '_'):
            result.append(new_content[i:idx+5])
            i = idx + 5
            continue

        # Append everything up to this Text(
        result.append(new_content[i:idx])

        # Find matching close paren
        depth = 1
        p = idx + 5
        in_str = None
        while p < len(new_content) and depth > 0:
            c = new_content[p]
            if in_str:
                if c == in_str and new_content[p-1] != '\\':
                    in_str = None
            elif c in ("'", '"'):
                in_str = c
            elif c == '(':
                depth += 1
            elif c == ')':
                depth -= 1
            p += 1

        # full text widget call: new_content[idx:p]
        text_call = new_content[idx:p]

        # Skip if already has maxLines or overflow
        if 'maxLines' in text_call or 'overflow' in text_call:
            result.append(text_call)
            i = p
            continue

        # Skip if it's a multi-arg Text with style only (no dynamic risk)
        # Skip simple short string literals like Text('OK') Text('Cancel')
        # Heuristic: if Text contains only a short literal string (< 30 chars) AND no $/.+, skip
        # Find first arg
        inner = text_call[5:-1].strip()  # remove "Text(" and ")"

        # Check if first arg is a simple short string
        # Match: 'short text' or "short text"
        simple_string = re.match(r"^['\"]([^'\"\\$]{0,40})['\"]\s*[,)]?\s*$", inner)
        if simple_string and not any(c in inner for c in ['$', '\\']):
            result.append(text_call)
            i = p
            continue

        # Check if it's a localized string (AppLocalizations) - usually short UI labels
        if inner.startswith('AppLocalizations.of') and ',' not in inner.split(',')[0] if ',' in inner else inner.startswith('AppLocalizations.of') and inner.count('.') < 5:
            # Localized strings vary by language - safer to add overflow
            pass

        # Now we need to add maxLines: 1, overflow: TextOverflow.ellipsis
        # before the closing )
        # Be careful: text_call ends with )
        # Insert before the final )

        # Determine if there's already a comma before )
        new_text_call = text_call[:-1].rstrip()
        if new_text_call.endswith(','):
            new_text_call += ' maxLines: 1, overflow: TextOverflow.ellipsis)'
        else:
            new_text_call += ', maxLines: 1, overflow: TextOverflow.ellipsis)'

        result.append(new_text_call)
        count += 1
        i = p

    return ''.join(result), count


def wrap_text_in_flexible_in_rows(content):
    """
    Find Row(children: [...]) where Text is a direct child without Flexible.
    This is harder to do safely with regex - skip for now.
    Better approach: focus on the most common pattern - Row with Text + Icon/Spacer.
    """
    # This is too complex to do safely without breaking layouts.
    # Skip for this pass.
    return content, 0


def add_resize_to_scaffold(content):
    """Skip — Scaffold's default behavior already handles keyboard."""
    return content, 0


def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    # Skip files that are not user-facing or are services
    rel = os.path.relpath(filepath, LIB).replace('\\', '/')
    if rel.startswith('services/') or rel.startswith('models/') or rel.startswith('providers/'):
        return False

    # Add overflow to Text widgets
    content, n_text = add_overflow_to_text_widgets(content)
    stats['text_fixes'] += n_text

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        stats['files'] += 1
        return True
    return False


def main():
    print("=== OVERFLOW FIX ===\n")

    # Process presentation/ and widgets/
    dart_files = []
    for sub in ['presentation', 'widgets', 'features']:
        sub_path = os.path.join(LIB, sub)
        if not os.path.exists(sub_path): continue
        for root, dirs, files in os.walk(sub_path):
            dirs[:] = [d for d in dirs if d not in {'l10n', 'generated'}]
            for fname in sorted(files):
                if fname.endswith('.dart'):
                    dart_files.append(os.path.join(root, fname))

    print(f"Scanning {len(dart_files)} files...\n")

    for fp in dart_files:
        if process_file(fp):
            pass  # don't print every file

    print(f"=== RESULTS ===")
    print(f"  Files modified: {stats['files']}")
    print(f"  Text overflow fixes: {stats['text_fixes']}")


if __name__ == '__main__':
    main()
