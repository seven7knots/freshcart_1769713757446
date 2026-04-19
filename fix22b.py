# fix22b.py
# viewPadding.bottom is more reliable than padding.bottom on gesture-nav devices

path = 'lib/presentation/shopping_cart_screen/shopping_cart_screen.dart'
with open(path, 'rb') as f:
    text = f.read().decode('utf-8').replace('\r\n', '\n')

old = "          final bottomPadding = MediaQuery.of(context).padding.bottom;"
new = "          final bottomPadding = (MediaQuery.of(context).viewPadding.bottom).clamp(16.0, 48.0);"

if old in text:
    text = text.replace(old, new, 1)
    print('shopping_cart_screen.dart: viewPadding fix OK')
else:
    print('FAILED - line not found')
    for i, line in enumerate(text.splitlines()):
        if 'bottomPadding' in line or 'padding.bottom' in line:
            print(f'  {i+1}: {repr(line)}')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

print('fix22b done')
