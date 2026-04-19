#!/usr/bin/env python3
"""
DEEP BUG AUDIT FIX: Fix silent catches, setState-after-dispose,
undisposed controllers, and other critical issues across entire codebase.
"""

import os, re

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJECT, 'lib')

stats = {'silent_catches': 0, 'mounted_guards': 0, 'disposals': 0, 'files': 0}


def fix_silent_catches(content, filepath):
    """Replace catch (_) {} with catch (e) { debugPrint(...); }"""
    rel = os.path.relpath(filepath, PROJECT).replace('\\', '/')
    tag = rel.split('/')[-1].replace('.dart', '').upper()

    count = 0

    # Pattern 1: catch (_) {}  (empty block on same line)
    def replace_empty_catch(m):
        nonlocal count
        count += 1
        indent = m.group(1) or ''
        return f"{indent}catch (e) {{ debugPrint('[{tag}] Silent error: $e'); }}"

    content = re.sub(
        r'(\s*)catch\s*\(_\)\s*\{\s*\}',
        replace_empty_catch,
        content
    )

    # Pattern 2: } catch (_) {  with empty body across lines
    # This is harder - the scanner found them as single-line, so pattern 1 should catch most.

    stats['silent_catches'] += count
    return content, count


def fix_set_state_after_dispose(content, filepath):
    """Add mounted checks before setState calls in async methods."""
    count = 0

    # Find async methods that call setState
    # Strategy: find lines with 'setState(' that are inside async methods
    # and don't have a preceding 'if (!mounted) return;' or 'if (mounted)'

    lines = content.split('\n')
    new_lines = []
    in_async = False
    async_depth = 0

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Detect async method entry
        if 'async' in line and ('{' in line) and ('(' in line):
            in_async = True

        # Check if this line has setState
        if 'setState(' in stripped and in_async:
            # Check if previous lines (up to 3) have a mounted check
            has_guard = False
            for j in range(max(0, i-3), i):
                if 'mounted' in lines[j]:
                    has_guard = True
                    break

            if not has_guard:
                # Get indentation
                indent = line[:len(line) - len(line.lstrip())]
                # Add mounted check before setState
                new_lines.append(f"{indent}if (!mounted) return;")
                count += 1

        new_lines.append(line)

    if count > 0:
        content = '\n'.join(new_lines)

    stats['mounted_guards'] += count
    return content, count


def add_controller_disposal(content, filepath):
    """Add dispose() calls for TextEditingControllers missing them."""
    # Find all controller field declarations
    controller_pattern = r'(final\s+)?(\w+)\s*=\s*TextEditingController\(\)'
    controllers = re.findall(controller_pattern, content)

    if not controllers:
        return content, 0

    # Get controller variable names
    controller_names = [m[1] for m in controllers]

    # Check which ones already have dispose
    missing_dispose = []
    for name in controller_names:
        if f'{name}.dispose()' not in content:
            missing_dispose.append(name)

    if not missing_dispose:
        return content, 0

    # Check if this is a StatefulWidget State class
    if 'extends State<' not in content:
        return content, 0

    # Check if dispose() method exists
    if '@override\n  void dispose()' in content or '@override\n  void dispose() ' in content:
        # Find existing dispose method and add missing disposals
        # Find the line with 'super.dispose()'
        lines = content.split('\n')
        new_lines = []
        for line in lines:
            if 'super.dispose()' in line.strip():
                indent = line[:len(line) - len(line.lstrip())]
                for name in missing_dispose:
                    new_lines.append(f'{indent}{name}.dispose();')
            new_lines.append(line)
        content = '\n'.join(new_lines)
    else:
        # No dispose method - add one before the last closing brace of the class
        dispose_lines = '\n'.join(f'    {name}.dispose();' for name in missing_dispose)
        dispose_method = f'''
  @override
  void dispose() {{
{dispose_lines}
    super.dispose();
  }}
'''
        # Find the build method and insert dispose before it
        build_idx = content.find('  @override\n  Widget build(')
        if build_idx == -1:
            build_idx = content.find('@override\n  Widget build(')
        if build_idx > 0:
            content = content[:build_idx] + dispose_method + '\n' + content[build_idx:]
        else:
            # Fallback: insert before last }
            last_brace = content.rfind('}')
            if last_brace > 0:
                content = content[:last_brace] + dispose_method + content[last_brace:]

    count = len(missing_dispose)
    stats['disposals'] += count
    return content, count


def add_scroll_controller_disposal(content, filepath):
    """Add dispose for ScrollControllers missing it."""
    sc_pattern = r'(final\s+)?(\w+)\s*=\s*ScrollController\(\)'
    controllers = re.findall(sc_pattern, content)
    if not controllers:
        return content, 0

    names = [m[1] for m in controllers]
    missing = [n for n in names if f'{n}.dispose()' not in content]

    if not missing or 'extends State<' not in content:
        return content, 0

    lines = content.split('\n')
    new_lines = []
    added = False
    for line in lines:
        if 'super.dispose()' in line.strip() and not added:
            indent = line[:len(line) - len(line.lstrip())]
            for name in missing:
                new_lines.append(f'{indent}{name}.dispose();')
            added = True
        new_lines.append(line)

    if added:
        content = '\n'.join(new_lines)
        stats['disposals'] += len(missing)
        return content, len(missing)

    return content, 0


def process_file(filepath):
    """Process a single Dart file for all bug categories."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception:
        return False

    original = content
    total_fixes = 0

    # 1. Fix silent catches
    content, n = fix_silent_catches(content, filepath)
    total_fixes += n

    # 2. Fix setState-after-dispose (only in presentation files)
    rel = os.path.relpath(filepath, LIB).replace('\\', '/')
    if rel.startswith('presentation/'):
        content, n = fix_set_state_after_dispose(content, filepath)
        total_fixes += n

    # 3. Add controller disposal
    content, n = add_controller_disposal(content, filepath)
    total_fixes += n

    # 4. Add scroll controller disposal
    content, n = add_scroll_controller_disposal(content, filepath)
    total_fixes += n

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        stats['files'] += 1
        return True
    return False


def main():
    print("=== DEEP BUG AUDIT FIX ===\n")

    dart_files = []
    for root, dirs, files in os.walk(LIB):
        dirs[:] = [d for d in dirs if d not in {'l10n', 'generated'}]
        for fname in sorted(files):
            if fname.endswith('.dart'):
                dart_files.append(os.path.join(root, fname))

    print(f"Scanning {len(dart_files)} Dart files...\n")

    for filepath in dart_files:
        if process_file(filepath):
            rel = os.path.relpath(filepath, PROJECT).replace('\\', '/')
            print(f"  Fixed: {rel}")

    print(f"\n=== RESULTS ===")
    print(f"  Files modified: {stats['files']}")
    print(f"  Silent catches fixed: {stats['silent_catches']}")
    print(f"  Mounted guards added: {stats['mounted_guards']}")
    print(f"  Controller disposals added: {stats['disposals']}")


if __name__ == '__main__':
    main()
