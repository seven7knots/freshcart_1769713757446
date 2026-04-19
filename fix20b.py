# fix20b.py
# Wrap CustomImageWidget at line 238 in a SizedBox to provide bounded width.

with open('lib/presentation/category_stores_screen/category_stores_screen.dart', 'rb') as f:
    raw = f.read()
text = raw.decode('utf-8').replace('\r\n', '\n')
lines = text.splitlines()

# Find the CustomImageWidget block starting with width: double.infinity
start = None
for i, line in enumerate(lines):
    if 'CustomImageWidget(' in line:
        # Check next few lines for double.infinity
        snippet = '\n'.join(lines[i:i+6])
        if 'double.infinity' in snippet:
            start = i
            break

if start is None:
    print('FAILED: could not find CustomImageWidget with double.infinity')
else:
    # Find the closing ), of this widget call
    end = None
    depth = 0
    for i in range(start, min(start+20, len(lines))):
        for ch in lines[i]:
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
                if depth == 0:
                    end = i
                    break
        if end is not None:
            break

    if end is None:
        print('FAILED: could not find closing paren')
    else:
        print(f'Found block: lines {start+1} to {end+1}')
        print('Original:')
        for l in lines[start:end+1]:
            print(f'  {repr(l)}')

        # Get the indent of the CustomImageWidget line
        indent = len(lines[start]) - len(lines[start].lstrip())
        ind = ' ' * indent

        # Extract height value
        height_val = '18.h'
        for l in lines[start:end+1]:
            if 'height:' in l and 'h,' in l:
                height_val = l.strip().replace('height:', '').replace(',', '').strip()
                break

        # Extract imageUrl line
        image_line = None
        for l in lines[start:end+1]:
            if 'imageUrl:' in l:
                image_line = l.strip()
                break

        # Extract semanticLabel line
        semantic_line = None
        for l in lines[start:end+1]:
            if 'semanticLabel:' in l:
                semantic_line = l.strip()
                break

        new_block = [
            f'{ind}SizedBox(',
            f'{ind}  height: {height_val},',
            f'{ind}  width: double.infinity,',
            f'{ind}  child: CustomImageWidget(',
            f'{ind}    {image_line}',
            f'{ind}    height: {height_val},',
            f'{ind}    fit: BoxFit.cover,',
            f'{ind}    {semantic_line}',
            f'{ind}  ),',
            f'{ind}),',
        ]

        lines = lines[:start] + new_block + lines[end+1:]
        with open('lib/presentation/category_stores_screen/category_stores_screen.dart', 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines) + '\n')
        print('category_stores_screen.dart: SizedBox wrapper added OK')

print('fix20b done')
