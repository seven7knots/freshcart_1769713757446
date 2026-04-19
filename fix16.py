# fix16.py
# Pre-fetch categories + stores in HomeScreen._loadInitialData()
# so widget-level queries hit the service cache and render immediately.

with open('lib/presentation/home_screen/home_screen.dart', 'rb') as f:
    raw = f.read()

text = raw.decode('utf-8').replace('\r\n', '\n')

old = "  Future<void> _loadInitialData() async {\n    await _loadLocalUserInfo();\n  }"

new = """  Future<void> _loadInitialData() async {
    await _loadLocalUserInfo();
    // Pre-warm service caches before waves mount.
    // CategoryService and StoreService deduplicate in-flight requests,
    // so when each widget fires its own fetch it hits the cache
    // and resolves instantly instead of waiting on a cold network call.
    CategoryService.getTopLevelCategories().ignore();
    StoreService.getAllStores(activeOnly: true, excludeDemo: true).ignore();
  }"""

if old in text:
    text = text.replace(old, new, 1)
    print('home_screen.dart: pre-fetch added OK')
else:
    print('home_screen.dart: FAILED - printing _loadInitialData lines:')
    for i, line in enumerate(text.splitlines()):
        if '_loadInitialData' in line or '_loadLocalUserInfo' in line:
            print(f'  {i+1}: {repr(line)}')

with open('lib/presentation/home_screen/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print('fix16 done')
