#!/usr/bin/env python3
"""
Wrap Text widgets inside Row children with Flexible() to prevent overflow.
This is critical for layouts where text could push other widgets off screen.

Strategy: Find Row(children: [...]) blocks and look for Text(...) that
appears alongside Icon, Container, or other Text widgets.
"""

import os, re

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJECT, 'lib')

stats = {'files': 0, 'wraps': 0}


def find_row_blocks(content):
    """Find all 'Row(' blocks and yield (start, end) indices."""
    blocks = []
    i = 0
    while i < len(content):
        idx = content.find('Row(', i)
        if idx == -1: break

        # Verify it's a real Row constructor (preceded by space, comma, paren, etc.)
        if idx > 0 and (content[idx-1].isalnum() or content[idx-1] == '_'):
            i = idx + 4
            continue

        # Find matching close paren
        depth = 1
        p = idx + 4
        in_str = None
        while p < len(content) and depth > 0:
            c = content[p]
            if in_str:
                if c == in_str and content[p-1] != '\\':
                    in_str = None
            elif c in ("'", '"'):
                in_str = c
            elif c == '(':
                depth += 1
            elif c == ')':
                depth -= 1
            p += 1

        blocks.append((idx, p))
        i = p

    return blocks


def wrap_text_in_flexible(content):
    """Find Text(...) directly in Row children list and wrap with Flexible."""
    count = 0
    blocks = find_row_blocks(content)

    # Process in reverse so indices stay valid
    for start, end in reversed(blocks):
        block = content[start:end]

        # Find children: [...] in this Row
        children_match = re.search(r'children:\s*\[', block)
        if not children_match:
            continue

        children_start_in_block = children_match.end()
        # Find matching ]
        depth = 1
        p = children_start_in_block
        in_str = None
        while p < len(block) and depth > 0:
            c = block[p]
            if in_str:
                if c == in_str and block[p-1] != '\\':
                    in_str = None
            elif c in ("'", '"'):
                in_str = c
            elif c == '[':
                depth += 1
            elif c == ']':
                depth -= 1
            p += 1

        children_block = block[children_start_in_block:p-1]

        # Now find Text(...) that are direct children (not nested in another widget)
        # Direct children start after a comma at depth 0 or at the start of the list
        # We need to identify top-level expressions in the children list

        new_children = []
        i = 0
        modified = False
        depth_local = 0
        in_str_local = None
        last_split = 0

        # Walk through children and split by top-level commas
        children_items = []
        for j, c in enumerate(children_block):
            if in_str_local:
                if c == in_str_local and (j == 0 or children_block[j-1] != '\\'):
                    in_str_local = None
            elif c in ("'", '"'):
                in_str_local = c
            elif c in '([{<':
                depth_local += 1
            elif c in ')]}>':
                depth_local -= 1
            elif c == ',' and depth_local == 0:
                children_items.append(children_block[last_split:j])
                last_split = j + 1
        children_items.append(children_block[last_split:])

        # Now check each child item: if it starts with Text( and isn't already wrapped
        new_items = []
        local_modified = False
        for item in children_items:
            stripped = item.strip()
            if stripped.startswith('Text(') and not stripped.startswith('TextSpan'):
                # Check it's actually Text widget call (look at first char before Text)
                # Wrap with Flexible
                # Preserve leading whitespace
                leading_ws = item[:len(item) - len(item.lstrip())]
                wrapped = leading_ws + 'Flexible(child: ' + stripped + ')'
                new_items.append(wrapped)
                local_modified = True
                count += 1
            else:
                new_items.append(item)

        if local_modified:
            new_children_block = ','.join(new_items)
            new_block = block[:children_start_in_block] + new_children_block + block[p-1:]
            content = content[:start] + new_block + content[end:]

    return content, count


def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    rel = os.path.relpath(filepath, LIB).replace('\\', '/')
    if rel.startswith('services/') or rel.startswith('models/') or rel.startswith('providers/'):
        return False

    content, n = wrap_text_in_flexible(content)
    stats['wraps'] += n

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        stats['files'] += 1
        return True
    return False


def main():
    print("=== FLEXIBLE WRAP FIX ===\n")

    dart_files = []
    for sub in ['presentation', 'widgets', 'features']:
        sp = os.path.join(LIB, sub)
        if not os.path.exists(sp): continue
        for root, dirs, files in os.walk(sp):
            dirs[:] = [d for d in dirs if d not in {'l10n', 'generated'}]
            for fname in sorted(files):
                if fname.endswith('.dart'):
                    dart_files.append(os.path.join(root, fname))

    print(f"Scanning {len(dart_files)} files...\n")

    for fp in dart_files:
        process_file(fp)

    print(f"=== RESULTS ===")
    print(f"  Files modified: {stats['files']}")
    print(f"  Text widgets wrapped in Flexible: {stats['wraps']}")


if __name__ == '__main__':
    main()
