#!/usr/bin/env python3
"""
FINAL FIX:
1. Re-run Pattern 1 v2 (with corrected regex)
2. Fix const/init errors using a CORRECTED method detection that
   handles generic types like List<Map<String, dynamic>>.
"""

import os, re, json

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJECT, 'lib')
L10N = os.path.join(LIB, 'l10n')

with open(os.path.join(L10N, 'app_en.arb'), 'r', encoding='utf-8') as f:
    en_arb = json.load(f)

str_to_key = {v: k for k, v in en_arb.items() if not k.startswith('@@') and isinstance(v, str)}
k2s = {k: v for k, v in en_arb.items() if not k.startswith('@@')}

SKIP_DIRS = {'l10n', 'generated'}
SKIP_FILES = {'locale_provider.dart', 'language_selection_screen.dart', 'app_export.dart'}
NO_CONTEXT = {'services/', 'models/', 'theme/', 'providers/'}


def is_no_context(filepath):
    rel = os.path.relpath(filepath, LIB).replace('\\', '/')
    return any(rel.startswith(p) for p in NO_CONTEXT)


def should_skip(s):
    s = s.strip()
    if len(s) <= 1: return True
    if not any(c.isalpha() for c in s): return True
    if '$' in s: return True
    if chr(92) in s: return True
    pats = [
        r'^https?://', r'^assets/', r'^package:', r'^/[a-z\-]',
        r'^[a-z_]+$', r'^[A-Z_]+$', r'^[a-z]+_[a-z_]+$',
        r'^#[0-9a-fA-F]+$', r'^\.', r'^[a-z]+\.[a-z]+',
    ]
    for p in pats:
        if re.match(p, s): return True
    return False


# ═══════════════════════════════════════════════════════════════
# PHASE A: Patch Pattern 1 with corrected regex
# ═══════════════════════════════════════════════════════════════

stats = {'p1_files': 0, 'p1_reps': 0, 'fix_files': 0}


def patch_p1(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    original = content
    reps = 0

    # CORRECT regex: only exclude actual quotes and newline
    pattern = re.compile(
        r'''(["'])(title|subtitle|label|name|description|text|message|hint|placeholder|caption|header|category|status)(["'])\s*:\s*(["'])([^"'\n]+)(["'])'''
    )

    def replace(m):
        nonlocal reps
        kq1 = m.group(1); key_name = m.group(2); kq2 = m.group(3)
        vq1 = m.group(4); value = m.group(5); vq2 = m.group(6)
        if kq1 != kq2 or vq1 != vq2: return m.group(0)
        if should_skip(value): return m.group(0)
        loc_key = str_to_key.get(value)
        if not loc_key: return m.group(0)
        reps += 1
        return f'{kq1}{key_name}{kq2}: AppLocalizations.of(context)!.{loc_key}'

    content = pattern.sub(replace, content)

    if content != original:
        if 'app_localizations.dart' not in content:
            rel = os.path.relpath(os.path.join(LIB, 'l10n', 'generated'), os.path.dirname(filepath)).replace('\\', '/')
            imp = f"import '{rel}/app_localizations.dart';"
            lines = content.split('\n')
            last = -1
            for i, l in enumerate(lines):
                if l.strip().startswith('import ') and l.strip().endswith(';'):
                    last = i
            if last >= 0:
                lines.insert(last + 1, imp)
            content = '\n'.join(lines)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        stats['p1_files'] += 1
        stats['p1_reps'] += reps


# ═══════════════════════════════════════════════════════════════
# PHASE B: Fix const/initializer errors with CORRECT method detection
# ═══════════════════════════════════════════════════════════════

def fix_const_in_content(content):
    """Remove const from collections/widgets containing AppLocalizations."""
    # const [...]
    idx = 0
    while True:
        idx = content.find('const [', idx)
        if idx == -1: break
        d = 1; p = idx + 7
        while p < len(content) and d > 0:
            if content[p] == '[': d += 1
            elif content[p] == ']': d -= 1
            p += 1
        if 'AppLocalizations' in content[idx+7:p]:
            content = content[:idx] + content[idx+6:]
        else:
            idx += 7

    # const {...}
    idx = 0
    while True:
        m = re.search(r'\bconst\s+\{', content[idx:])
        if not m: break
        ai = idx + m.start()
        bs = content.index('{', ai)
        d = 1; p = bs + 1
        while p < len(content) and d > 0:
            if content[p] == '{': d += 1
            elif content[p] == '}': d -= 1
            p += 1
        if 'AppLocalizations' in content[bs:p]:
            content = content[:ai] + content[ai+6:]
        else:
            idx = ai + m.end() - m.start()

    # const <Type>[...]
    idx = 0
    while True:
        m = re.search(r'\bconst\s+<[^>]+>\s*\[', content[idx:])
        if not m: break
        ai = idx + m.start()
        bs = content.index('[', ai)
        d = 1; p = bs + 1
        while p < len(content) and d > 0:
            if content[p] == '[': d += 1
            elif content[p] == ']': d -= 1
            p += 1
        if 'AppLocalizations' in content[bs:p]:
            content = content[:ai] + content[ai+6:]
        else:
            idx = ai + m.end() - m.start()

    # const <Type>{...}
    idx = 0
    while True:
        m = re.search(r'\bconst\s+<[^>]+>\s*\{', content[idx:])
        if not m: break
        ai = idx + m.start()
        bs = content.index('{', ai)
        d = 1; p = bs + 1
        while p < len(content) and d > 0:
            if content[p] == '{': d += 1
            elif content[p] == '}': d -= 1
            p += 1
        if 'AppLocalizations' in content[bs:p]:
            content = content[:ai] + content[ai+6:]
        else:
            idx = ai + m.end() - m.start()

    # const Widget(...)
    widgets = ['Text','Icon','SizedBox','Padding','Column','Row','Container',
               'Center','Scaffold','AlertDialog','DropdownMenuItem','TextSpan',
               'InfoWindow','PopupMenuItem','ListTile','SnackBar','Chip','Card',
               'Tab','SwitchListTile','CheckboxListTile','RadioListTile','Tooltip',
               'ElevatedButton','TextButton','OutlinedButton','BottomNavigationBarItem',
               'NavigationDestination','InputDecoration','BoxDecoration','TextStyle',
               'Expanded','Flexible','Wrap','SimpleDialog','BottomSheet','IconButton',
               'FloatingActionButton','CircleAvatar','CircularProgressIndicator',
               'Divider','BorderSide','EdgeInsets','RoundedRectangleBorder']
    for w in widgets:
        pat = f'const {w}('
        idx = 0
        while True:
            idx = content.find(pat, idx)
            if idx == -1: break
            ps = idx + len(pat) - 1
            d = 1; p = ps + 1
            while p < len(content) and d > 0:
                c = content[p]
                if c == '(': d += 1
                elif c == ')': d -= 1
                elif c in ("'",'"'):
                    q = c; p += 1
                    while p < len(content) and content[p] != q:
                        if content[p] == '\\': p += 1
                        p += 1
                p += 1
            if 'AppLocalizations' in content[ps:p]:
                content = content[:idx] + content[idx+6:]
            else:
                idx += len(pat)

    return content


def is_method_signature(line):
    """Detect Dart method signatures including generic return types."""
    stripped = line.strip()
    # Match patterns like:
    #   void method(...)
    #   Future<T> method(...)
    #   List<Map<String, dynamic>> method(...)
    #   static Type method(...)
    #   Map<K, V> method(...)
    # Key pattern: starts with type (possibly generic), then identifier, then (
    # Use a flexible pattern: word(<...>)? identifier (
    return bool(re.match(
        r'^\s*(?:@override\s+)?(?:static\s+)?(?:Future|Stream|void|Widget|String|int|double|bool|Map|List|Set|Iterable|dynamic|State|num|var|final|late)\s*(?:<[^>]*(?:<[^>]*>[^>]*)*>)?\s+\w+\s*\(',
        line
    )) or bool(re.match(
        r'^\s*(?:@override\s+)?(?:static\s+)?[A-Z]\w*(?:<[^>]*(?:<[^>]*>[^>]*)*>)?\s+_?\w+\s*\(',
        line
    ))


def fix_field_initializers_in_content(content):
    """Revert AppLocalizations only in TRUE field initializers (class-level)."""
    lines = content.split('\n')
    new_lines = []
    in_method = False
    method_depth = 0
    brace_depth = 0
    in_class = False
    class_depth = 0

    for line in lines:
        # Detect class entry
        if re.match(r'\s*class\s+\w+', line) and '{' in line:
            in_class = True
            class_depth = brace_depth

        # Detect method entry
        if not in_method and is_method_signature(line) and '{' in line:
            in_method = True
            method_depth = brace_depth

        # Update brace depth AFTER setting in_method
        prev_depth = brace_depth
        brace_depth += line.count('{') - line.count('}')

        # Check if we exited the method
        if in_method and brace_depth <= method_depth:
            in_method = False

        # Revert ONLY if we're at class level (not in a method) AND have AppLocalizations
        if in_class and not in_method and 'AppLocalizations.of(context)!' in line:
            # We're directly in class body — this is a field initializer
            def repl(m):
                key = m.group(1)
                if key in k2s:
                    return f"'{k2s[key]}'"
                return m.group(0)
            line = re.sub(r"AppLocalizations\.of\(context\)!\.(\w+)", repl, line)

        new_lines.append(line)

    return '\n'.join(new_lines)


def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    if 'AppLocalizations' not in content:
        return False
    original = content

    content = fix_const_in_content(content)
    content = fix_field_initializers_in_content(content)

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        stats['fix_files'] += 1
        return True
    return False


def main():
    print("=== PHASE A: Patch Pattern 1 with corrected regex ===\n")
    for root, dirs, files in os.walk(LIB):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for fname in sorted(files):
            if not fname.endswith('.dart') or fname in SKIP_FILES: continue
            fp = os.path.join(root, fname)
            if is_no_context(fp): continue
            patch_p1(fp)
    print(f"P1: {stats['p1_files']} files, {stats['p1_reps']} replacements\n")

    print("=== PHASE B: Fix errors (correct method detection) ===\n")
    for root, dirs, files in os.walk(LIB):
        dirs[:] = [d for d in dirs if d not in {'l10n', 'generated'}]
        for fname in sorted(files):
            if not fname.endswith('.dart'): continue
            fp = os.path.join(root, fname)
            fix_file(fp)
    print(f"Fix: {stats['fix_files']} files")


if __name__ == '__main__':
    main()
