# fix22d.py
path = 'lib/presentation/shopping_cart_screen/shopping_cart_screen.dart'
with open(path, 'rb') as f:
    text = f.read().decode('utf-8').replace('\r\n', '\n')

# Find and replace the entire bottomNavigationBar return block
old = """          return SafeArea(
            child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            color: theme.scaffoldBackgroundColor,
            child: SizedBox(width: double.infinity, height: 6.h, child: ElevatedButton(
              onPressed: () => _proceedToCheckout(items),
              child: Text('Checkout \u2022 \$${total.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w700)),
            )),
            ),
          );"""

new = """          return Padding(
            padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 2.h),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 52)),
              onPressed: () => _proceedToCheckout(items),
              child: Text('Checkout \u2022 \$${total.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w700)),
            ),
          );"""

if old in text:
    text = text.replace(old, new, 1)
    print('shopping_cart_screen.dart: checkout button simplified OK')
else:
    print('FAILED - pattern not found, printing lines:')
    for i, line in enumerate(text.splitlines()):
        if 'SafeArea' in line or 'proceedToCheckout' in line or '6.h' in line:
            print(f'  {i+1}: {repr(line)}')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

print('fix22d done')
