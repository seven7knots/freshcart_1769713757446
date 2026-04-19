#!/usr/bin/env python3
"""Fix the specific remaining 35 errors after mega patch."""

import os, re, json

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJECT, 'lib')

with open(os.path.join(LIB, 'l10n', 'app_en.arb'), 'r', encoding='utf-8') as f:
    en = json.load(f)
k2s = {k: v for k, v in en.items() if not k.startswith('@@')}

def revert_all_loc(content):
    """Revert all AppLocalizations.of(context)!.key to 'string'."""
    def repl(m):
        key = m.group(1)
        return f"'{k2s[key]}'" if key in k2s else m.group(0)
    return re.sub(r"AppLocalizations\.of\(context\)!\.(\w+)", repl, content)

def fix_const_map(content):
    """Change 'const types = <...>{...}' to 'final types = <...>{...}' when it has AppLocalizations."""
    content = re.sub(r'\bconst\s+(types\s*=\s*<)', r'final \1', content)
    content = re.sub(r'\bconst\s+(_timeLabels\s*=\s*<)', r'final \1', content)
    # Generic: const <SomeType>{...} containing AppLocalizations -> final
    idx = 0
    while True:
        m = re.search(r'\bconst\s+(\w+\s*=\s*<[^>]+>\s*\{)', content[idx:])
        if not m: break
        ai = idx + m.start()
        # Check if this const block contains AppLocalizations
        bs = content.index('{', ai)
        d = 1; p = bs + 1
        while p < len(content) and d > 0:
            if content[p] == '{': d += 1
            elif content[p] == '}': d -= 1
            p += 1
        if 'AppLocalizations' in content[bs:p]:
            content = content[:ai] + 'final ' + content[ai+6:]
        else:
            idx = ai + m.end() - m.start()
    return content

def fix_file(filepath, strategy='revert'):
    """Fix a specific file. strategy: 'revert' reverts ALL loc calls, 'const' fixes const only."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    original = content

    if strategy == 'revert':
        content = revert_all_loc(content)
    elif strategy == 'const':
        content = fix_const_map(content)

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        rel = os.path.relpath(filepath, PROJECT).replace('\\', '/')
        print(f"  Fixed: {rel}")
        return True
    return False


files = {
    # content_edit_modal_widget.dart: const map with AppLocalizations -> revert to plain strings
    'lib/presentation/admin_edit_overlay_system_screen/widgets/content_edit_modal_widget.dart': 'const',
    # category_listings_screen.dart: const map with AppLocalizations
    'lib/presentation/category_listings_screen/category_listings_screen.dart': 'const',
    # marketplace_ad_box_widget.dart: field initializer
    'lib/presentation/marketplace_screen/widgets/marketplace_ad_box_widget.dart': 'revert',
    # splash_screen.dart: field initializer
    'lib/presentation/splash_screen/splash_screen.dart': 'revert',
    # driver_rating_dialog.dart: field initializer
    'lib/widgets/driver_rating_dialog.dart': 'revert',
    # store_results_widget.dart: context not available
    'lib/presentation/search_screen/widgets/store_results_widget.dart': 'revert',
}

print("Fixing specific remaining errors...")
for relpath, strategy in files.items():
    fp = os.path.join(PROJECT, relpath.replace('/', os.sep))
    if os.path.exists(fp):
        fix_file(fp, strategy)
    else:
        print(f"  NOT FOUND: {relpath}")

print("Done!")
