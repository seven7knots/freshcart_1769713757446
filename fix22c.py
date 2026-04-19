# fix22c.py
path = 'lib/presentation/shopping_cart_screen/shopping_cart_screen.dart'
with open(path, 'rb') as f:
    text = f.read().decode('utf-8').replace('\r\n', '\n')

old = "          final bottomPadding = (MediaQuery.of(context).viewPadding.bottom).clamp(16.0, 48.0);\n          return Container(\n            padding: EdgeInsets.only(\n              left: 4.w, right: 4.w,\n              top: 1.h,\n              bottom: bottomPadding + 1.h,\n            ),\n            color: theme.scaffoldBackgroundColor,"

new = "          return SafeArea(\n            child: Container(\n            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),\n            color: theme.scaffoldBackgroundColor,"

if old in text:
    # Also need to close the extra Container with extra )
    # Find the closing of the Container and add )
    text = text.replace(old, new, 1)
    # Now close the SafeArea after the Container closes
    # The container ends with )),  (SizedBox closes, Container closes)
    # We need to add one more ) for SafeArea
    # Find the specific pattern after our change
    old_end = "            )),\n          );"
    new_end = "            )),\n            ),\n          );"
    if old_end in text:
        text = text.replace(old_end, new_end, 1)
        print('shopping_cart_screen.dart: SafeArea wrap OK')
    else:
        print('WARNING: could not find closing paren, checking...')
        for i, line in enumerate(text.splitlines()):
            if 'proceedToCheckout' in line or 'SizedBox' in line and '6.h' in line:
                print(f'  {i+1}: {repr(line)}')
else:
    print('FAILED - old pattern not found, printing bottomPadding lines:')
    for i, line in enumerate(text.splitlines()):
        if 'bottomPadding' in line or 'Container' in line and 'color: theme.scaffold' in line:
            print(f'  {i+1}: {repr(line)}')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

print('fix22c done')
