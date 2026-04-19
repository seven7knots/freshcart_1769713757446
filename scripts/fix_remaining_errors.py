#!/usr/bin/env python3
"""Fix remaining errors from localization patching."""

import os
import re

PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB_DIR = os.path.join(PROJECT_DIR, 'lib')


def fix_file(filepath, fixes):
    """Apply fixes to a file. fixes is a list of (old, new) tuples."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    for old, new in fixes:
        if old in content:
            content = content.replace(old, new)
            print(f"  Fixed in {os.path.relpath(filepath, PROJECT_DIR)}: {old[:60]}...")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)


def revert_service_files():
    """Revert localization in service files that don't have BuildContext."""
    service_files = [
        os.path.join(LIB_DIR, 'services', 'gemini_service.dart'),
        os.path.join(LIB_DIR, 'services', 'push_notification_service.dart'),
    ]

    for filepath in service_files:
        if not os.path.exists(filepath):
            continue

        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        if 'AppLocalizations' not in content:
            continue

        # Find all AppLocalizations.of(context)!.xxx patterns and try to revert
        # We need to find what they were originally
        # Since services don't have context, we should revert these
        # The pattern is: AppLocalizations.of(context)!.keyName
        # We need to look up what keyName maps to in the clean_strings.json

        import json
        with open(os.path.join(PROJECT_DIR, 'scripts', 'clean_strings.json'), 'r', encoding='utf-8') as f:
            key_to_string = json.load(f)

        # Fix renamed keys
        renames = {'961XxXxxXxx': 'phoneNumberPlaceholder', 'continue': 'continueText', 'type': 'typeText'}
        for old, new in renames.items():
            if old in key_to_string:
                key_to_string[new] = key_to_string.pop(old)

        # Find and revert all AppLocalizations calls
        pattern = r"AppLocalizations\.of\(context\)!\.(\w+)"
        matches = list(re.finditer(pattern, content))

        for m in reversed(matches):  # reverse to not mess up indices
            key = m.group(1)
            if key in key_to_string:
                original = f"'{key_to_string[key]}'"
                content = content[:m.start()] + original + content[m.end():]
                print(f"  Reverted in {os.path.relpath(filepath, PROJECT_DIR)}: {key}")

        # Remove the import if we reverted everything
        if 'AppLocalizations' not in content.replace("import", ""):
            content = re.sub(r"import '[^']*app_localizations\.dart';\n?", '', content)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)


def fix_truncated_strings():
    """Fix strings that were truncated due to backslash escaping."""

    # login_form_widget.dart - enterYourEmailAndWe issue
    filepath = os.path.join(LIB_DIR, 'presentation', 'authentication_screen', 'widgets', 'login_form_widget.dart')
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # The original string was: "Enter your email and we'll send you a reset link"
        # but it got truncated at the backslash in "we\\"
        # The ARB key is enterYourEmailAndWe with value "Enter your email and we\\"
        # This is a broken extraction - revert to hardcoded
        # Find the broken pattern and replace with the original string
        content = re.sub(
            r"AppLocalizations\.of\(context\)!\.enterYourEmailAndWe[^'\"]*",
            "'Enter your email and we\\'ll send you a reset link'",
            content
        )

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  Fixed truncated string in login_form_widget.dart")

    # privacy_security_screen.dart - thisWillSignYouOutOf issue
    filepath = os.path.join(LIB_DIR, 'presentation', 'privacy_security_screen', 'privacy_security_screen.dart')
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        content = re.sub(
            r"AppLocalizations\.of\(context\)!\.thisWillSignYouOutOf[^'\"]*",
            "'This will sign you out of all other devices. You\\'ll remain signed in here.'",
            content
        )

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  Fixed truncated string in privacy_security_screen.dart")

    # product_grid_widget.dart - tryAdjustingYourSearchOrFilters issue
    filepath = os.path.join(LIB_DIR, 'presentation', 'search_screen', 'widgets', 'product_grid_widget.dart')
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        content = re.sub(
            r"AppLocalizations\.of\(context\)!\.tryAdjustingYourSearchOrFilters[^'\"]*",
            "'Try adjusting your search or filters to find what you\\'re looking for'",
            content
        )

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  Fixed truncated string in product_grid_widget.dart")


def fix_remaining_const():
    """Find and fix any remaining const errors with AppLocalizations."""
    for root, dirs, files in os.walk(LIB_DIR):
        dirs[:] = [d for d in dirs if d not in {'l10n', 'generated'}]
        for fname in files:
            if not fname.endswith('.dart'):
                continue

            filepath = os.path.join(root, fname)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()

            if 'AppLocalizations' not in content:
                continue

            original = content

            # More aggressive const removal for remaining cases
            # Find "const " before any expression containing AppLocalizations
            # Pattern: const <anything>AppLocalizations<anything>
            # We need to find const expressions that span multiple lines

            # Approach: find all "const " occurrences and check if the expression
            # they prefix contains AppLocalizations

            idx = 0
            while idx < len(content):
                match = re.search(r'\bconst\s+', content[idx:])
                if not match:
                    break

                const_start = idx + match.start()
                after_const = const_start + match.end() - match.start()

                # Find the extent of this const expression
                # It could be: const Widget(...), const [...], const {key: val}
                # Look for the opening bracket
                rest = content[after_const:]

                # Skip type annotations like const <Type>
                type_match = re.match(r'<[^>]+>\s*', rest)
                if type_match:
                    rest = rest[type_match.end():]
                    after_const += type_match.end()

                # Find opening bracket
                if rest and rest[0] in '([{':
                    open_bracket = rest[0]
                    close_bracket = {'(': ')', '[': ']', '{': '}'}[open_bracket]
                    depth = 1
                    pos = 1
                    while pos < len(rest) and depth > 0:
                        if rest[pos] == open_bracket:
                            depth += 1
                        elif rest[pos] == close_bracket:
                            depth -= 1
                        pos += 1

                    expr_content = rest[:pos]
                    if 'AppLocalizations' in expr_content:
                        # Remove the const
                        content = content[:const_start] + content[after_const:]
                        # Don't advance - re-check from same position
                        continue

                idx = const_start + 1

            if content != original:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
                rel = os.path.relpath(filepath, PROJECT_DIR).replace('\\', '/')
                print(f"  Fixed remaining const in: {rel}")


def main():
    print("Fixing remaining errors...\n")

    print("1. Reverting service files (no BuildContext)...")
    revert_service_files()

    print("\n2. Fixing truncated strings...")
    fix_truncated_strings()

    print("\n3. Fixing remaining const errors...")
    fix_remaining_const()

    print("\nDone!")


if __name__ == '__main__':
    main()
