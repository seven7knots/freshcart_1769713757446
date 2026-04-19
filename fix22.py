# fix22.py
# Fix checkout button cut off by system navigation bar.
# Replace SafeArea minimum with explicit bottom padding using MediaQuery.

path = 'lib/presentation/shopping_cart_screen/shopping_cart_screen.dart'
with open(path, 'rb') as f:
    text = f.read().decode('utf-8').replace('\r\n', '\n')

old = """          return SafeArea(
            minimum: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: SizedBox(width: double.infinity, height: 6.h, child: ElevatedButton(
              onPressed: () => _proceedToCheckout(items),
              child: Text('Checkout \u2022 \$${total.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w700)),
            )),
          );"""

new = """          final bottomPadding = MediaQuery.of(context).padding.bottom;
          return Container(
            padding: EdgeInsets.only(
              left: 4.w, right: 4.w,
              top: 1.h,
              bottom: bottomPadding + 1.h,
            ),
            color: theme.scaffoldBackgroundColor,
            child: SizedBox(width: double.infinity, height: 6.h, child: ElevatedButton(
              onPressed: () => _proceedToCheckout(items),
              child: Text('Checkout \u2022 \$${total.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w700)),
            )),
          );"""

if old in text:
    text = text.replace(old, new, 1)
    print('shopping_cart_screen.dart: checkout button fix OK')
else:
    print('FAILED - printing nearby lines:')
    for i, line in enumerate(text.splitlines()):
        if 'SafeArea' in line or 'Checkout' in line:
            print(f'  {i+1}: {repr(line)}')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

print('fix22 done')
