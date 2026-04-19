# fix20.py
# Replace width: double.infinity in category_stores_screen CustomImageWidget.
# The Stack inside ClipRRect provides no bounded width, so double.infinity
# cascades up causing "RenderCustomMultiChildLayoutBox infinite size" crash.
# Fix: remove explicit width and wrap in SizedBox.expand instead.

with open('lib/presentation/category_stores_screen/category_stores_screen.dart', 'rb') as f:
    raw = f.read()
text = raw.decode('utf-8').replace('\r\n', '\n')

old = """                  CustomImageWidget(
                    imageUrl: store.imageUrl ?? 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5',
                    width: double.infinity,
                    height: 18.h,
                    fit: BoxFit.cover,
                    semanticLabel: 'Store: \${store.name}',
                  ),"""

new = """                  SizedBox(
                    height: 18.h,
                    width: double.infinity,
                    child: CustomImageWidget(
                      imageUrl: store.imageUrl ?? 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5',
                      height: 18.h,
                      fit: BoxFit.cover,
                      semanticLabel: 'Store: \${store.name}',
                    ),
                  ),"""

if old in text:
    text = text.replace(old, new, 1)
    print('category_stores_screen.dart: SizedBox wrapper added OK')
else:
    print('category_stores_screen.dart: FAILED - printing CustomImageWidget lines:')
    for i, line in enumerate(text.splitlines()):
        if 'CustomImageWidget' in line or 'double.infinity' in line:
            print(f'  {i+1}: {repr(line)}')

with open('lib/presentation/category_stores_screen/category_stores_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print('fix20 done')
