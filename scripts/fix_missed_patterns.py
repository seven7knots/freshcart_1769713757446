#!/usr/bin/env python3
"""
Fix the THREE MISSED PATTERNS:
1. Map literal values: "title": "Shopping Cart"
2. Deeply indented multi-line Text() widgets
3. Positional string args to helper methods

Strategy:
- Phase 1: Scan all Dart files for hardcoded strings in these contexts
- Phase 2: Add new ARB keys for any strings not yet present
- Phase 3: Replace hardcoded strings with AppLocalizations calls
- Phase 4: Regenerate l10n classes
"""

import os, re, json, sys

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJECT, 'lib')
L10N = os.path.join(LIB, 'l10n')

# Load existing ARB
with open(os.path.join(L10N, 'app_en.arb'), 'r', encoding='utf-8') as f:
    en_arb = json.load(f)

# Reverse mapping: existing string → key
existing_str_to_key = {}
for k, v in en_arb.items():
    if not k.startswith('@@') and isinstance(v, str):
        existing_str_to_key[v] = k

SKIP_DIRS = {'l10n', 'generated'}
SKIP_FILES = {'locale_provider.dart', 'language_selection_screen.dart', 'app_export.dart'}

# Files where AppLocalizations cannot be used (no BuildContext)
NO_CONTEXT_FILES = {'services', 'models', 'theme', 'providers'}


def is_no_context_file(filepath):
    rel = os.path.relpath(filepath, LIB).replace('\\', '/')
    return any(rel.startswith(p + '/') for p in NO_CONTEXT_FILES)


def should_skip_string(s):
    """Skip technical/non-UI strings."""
    s = s.strip()
    if len(s) <= 1: return True
    if not any(c.isalpha() for c in s): return True
    if '$' in s: return True
    if '\\' in s: return True
    patterns = [
        r'^https?://', r'^assets/', r'^package:', r'^/[a-z\-]',
        r'^[a-z_]+$', r'^[A-Z_]+$', r'^[a-z]+_[a-z_]+$',
        r'^#[0-9a-fA-F]+$', r'^\.', r'^application/|^image/|^text/',
        r'^[a-z]+\.[a-z]+',  # property access
        r'^debug', r'^Bearer ', r'^Content-Type',
    ]
    for p in patterns:
        if re.match(p, s): return True
    # Skip if it's a single technical word like "active", "pending"
    # These are state strings used as DB enum values
    db_enums = {'active', 'pending', 'confirmed', 'preparing', 'ready', 'picked_up',
                'on_the_way', 'delivered', 'cancelled', 'rejected', 'admin', 'driver',
                'merchant', 'customer', 'inactive', 'food', 'grocery'}
    if s.lower() in db_enums: return True
    return False


def make_key(s, seen):
    """Generate a unique camelCase key."""
    clean = re.sub(r'[^a-zA-Z0-9\s]', ' ', s)
    words = clean.split()
    if not words: return None
    key = words[0].lower() + ''.join(w.capitalize() for w in words[1:6])
    key = re.sub(r'[^a-zA-Z0-9]', '', key)
    if not key or len(key) < 2: return None
    if re.match(r'^\d', key): key = 'n' + key
    dart_kw = {'continue','default','in','is','new','return','switch','this','var',
               'void','while','do','for','if','else','class','try','catch','throw'}
    if key in dart_kw: key = key + 'Text'
    base = key
    c = 2
    while key in seen:
        key = f"{base}{c}"
        c += 1
    return key


# ═══════════════════════════════════════════════════════════════
# PHASE 1: Scan and collect strings + their locations
# ═══════════════════════════════════════════════════════════════

# Each entry: (filepath, line_index, col, original, prefix_context)
# We'll generate replacements per location
all_strings = {}  # string_value -> set of (filepath, replacement_id)
location_records = []  # list of {filepath, search_pattern, replace_pattern, string}


def scan_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    if is_no_context_file(filepath):
        return []

    findings = []

    # ── PATTERN 1: Map literal values ──
    # Pattern: "key": "string value"  or  'key': 'string value'
    # Where key is one of: title, subtitle, label, name, description,
    # text, message, hint, placeholder
    # The VALUE part is what we want to localize
    for m in re.finditer(
        r'''(["'])(title|subtitle|label|name|description|text|message|hint|placeholder|caption|header|category|status)\1\s*:\s*(["'])([^"'\\]+)\3''',
        content
    ):
        value = m.group(4)
        if not should_skip_string(value):
            findings.append({
                'pattern': 1,
                'full_match': m.group(0),
                'value': value,
                'value_quote': m.group(3),
                'value_start': m.start(3),  # quote char position
                'key_part': m.group(0)[:m.start(3) - m.start(0)],  # "title": part
            })

    # ── PATTERN 2: Deeply indented multi-line Text() ──
    # Pattern: Text(\n<spaces>'string',  or  Text(\n<spaces>"string",
    for m in re.finditer(
        r'''Text\(\s*\n(\s+)(["'])([^"'\\\n]+)\2\s*,''',
        content
    ):
        value = m.group(3)
        if not should_skip_string(value):
            findings.append({
                'pattern': 2,
                'full_match': m.group(0),
                'value': value,
                'value_quote': m.group(2),
                'indent': m.group(1),
            })

    # ── PATTERN 3: Positional string arguments to method calls ──
    # Match: _methodName(... 'string' ...) or methodName(Icons.X, 'String', ...)
    # This is tricky. Let's match specific known patterns:
    # - _buildXxx(... , 'String', ...)
    # - showXxx(... , 'String', ...)
    # We look for: string literal that is NOT preceded by 'something:'
    # within a method call argument list

    # Strategy: find lines like:
    #   _buildMgmtTile(Icons.people, 'Users', Colors.blue, ...)
    #   _buildStatCard('Total Orders', count, ...)
    # We use a regex that finds quoted strings not preceded by `key:`
    # AND surrounded by other args or at the start of an arg list

    # Pattern: (Icons.X, 'String' or , 'String', or ('String',
    # Be conservative: require it to be preceded by `(` or `, ` AND
    # followed by `, ` or `)`

    # Look for helper method calls: _methodName( or showXxx( or buildXxx(
    method_call_pattern = re.compile(
        r'''(_\w+|show\w+|build\w+)\(([^)]*)\)''',
        re.MULTILINE
    )
    # Walk through method calls and find quoted strings inside
    for mc in method_call_pattern.finditer(content):
        method_name = mc.group(1)
        args_block = mc.group(2)

        # Skip method names that are clearly not UI builders
        # Skip: showDialog (handled differently), debugPrint
        if method_name in {'showDialog', 'debugPrint', 'print', 'log'}:
            continue

        # Find string literals in args that are NOT named (no `key:` before)
        # Use a simple approach: split by commas at depth 0
        # For each arg, if it's a plain quoted string (not part of `key:`), localize it
        # We'll find them as positions inside content

        # Find all quoted strings in this method call
        for sm in re.finditer(r'''(["'])([^"'\\\n]+)\1''', mc.group(0)):
            value = sm.group(2)
            if should_skip_string(value):
                continue

            # Check what's before this string in the local context
            # If preceded by ': ' it's a named argument value, skip
            # If preceded by ', ' or '( ' or '(' it's a positional argument
            local_start = sm.start()
            # Look back up to 5 chars
            prev = mc.group(0)[max(0, local_start - 5):local_start]
            if ':' in prev[-3:]:
                continue  # named argument
            if prev.endswith('(') or prev.endswith(', ') or prev.endswith(','):
                # It's a positional arg
                findings.append({
                    'pattern': 3,
                    'full_match': sm.group(0),  # 'Users'
                    'value': value,
                    'value_quote': sm.group(1),
                    'method_name': method_name,
                })

    return findings


# ═══════════════════════════════════════════════════════════════
# Run scan
# ═══════════════════════════════════════════════════════════════

print("=== Phase 1: Scanning ===\n")

all_files = []
for root, dirs, files in os.walk(LIB):
    dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
    for fname in sorted(files):
        if not fname.endswith('.dart') or fname in SKIP_FILES:
            continue
        all_files.append(os.path.join(root, fname))

# Collect all unique strings to localize
unique_strings = set()
file_findings = {}  # filepath -> list of findings

for fp in all_files:
    findings = scan_file(fp)
    if findings:
        file_findings[fp] = findings
        for f in findings:
            unique_strings.add(f['value'])

print(f"Files with hardcoded strings: {len(file_findings)}")
print(f"Unique strings to localize: {len(unique_strings)}")

# ═══════════════════════════════════════════════════════════════
# PHASE 2: Add missing strings to ARBs
# ═══════════════════════════════════════════════════════════════

print("\n=== Phase 2: Adding to ARB files ===")

# Load Arabic ARB
with open(os.path.join(L10N, 'app_ar.arb'), 'r', encoding='utf-8') as f:
    ar_arb = json.load(f)

# Comprehensive Arabic translations for the missed strings
AR_TRANSLATIONS = {
    # Profile menu items (the main ones the user mentioned)
    "Shopping Cart": "سلة التسوق",
    "Continue your shopping": "تابع تسوقك",
    "Favorites": "المفضلة",
    "Your saved items": "منتجاتك المحفوظة",
    "Personal Information": "المعلومات الشخصية",
    "Name, email, phone number": "الاسم، البريد، رقم الهاتف",
    "Become a Partner": "كن شريكاً",
    "Apply as a merchant or driver": "تقدّم كتاجر أو سائق",
    "Privacy & Security": "الخصوصية والأمان",
    "Password, account security": "كلمة المرور وأمان الحساب",
    "Notification Preferences": "تفضيلات الإشعارات",
    "Manage notifications": "إدارة الإشعارات",
    "Order History": "سجل الطلبات",
    "View past orders and reorder": "عرض الطلبات السابقة وإعادة الطلب",
    "My Addresses": "عناويني",
    "Manage your saved addresses": "إدارة عناوينك المحفوظة",
    "Delivery Preferences": "تفضيلات التوصيل",
    "Customize delivery options": "تخصيص خيارات التوصيل",
    "Help & Support": "المساعدة والدعم",
    "Get help with your orders": "احصل على مساعدة بطلباتك",
    "About KJ Delivery": "حول KJ Delivery",
    "App version and info": "إصدار التطبيق ومعلوماته",
    "Theme": "المظهر",
    "Light, dark, or system": "فاتح، داكن، أو حسب النظام",
    "Language": "اللغة",
    "Choose app language": "اختر لغة التطبيق",
    "Sign Out": "تسجيل الخروج",
    "Sign out of your account": "تسجيل الخروج من حسابك",
    "Admin Dashboard": "لوحة تحكم المسؤول",
    "Full system management": "الإدارة الكاملة للنظام",
    "User Management": "إدارة المستخدمين",
    "View and manage all users": "عرض وإدارة جميع المستخدمين",
    "Order Management": "إدارة الطلبات",
    "Monitor and manage orders": "مراقبة وإدارة الطلبات",

    # Home screen sections (the ones the user mentioned)
    "Top Stores": "أفضل المتاجر",
    "Quick Add": "إضافة سريعة",
    "Recent Orders": "الطلبات الأخيرة",
    "See All": "عرض الكل",
    "Featured Categories": "الفئات المميزة",
    "Deals of the Day": "عروض اليوم",
    "Categories": "الفئات",
    "Browse all stores": "تصفح جميع المتاجر",
    "Browse Categories": "تصفح الفئات",

    # Admin dashboard tiles (the ones the user mentioned)
    "Users": "المستخدمون",
    "Orders": "الطلبات",
    "Applications": "الطلبات",
    "Ads": "الإعلانات",
    "Logistics": "اللوجستيات",
    "Categories Management": "إدارة الفئات",
    "Content Management": "إدارة المحتوى",
    "Content": "المحتوى",
    "Edit System": "نظام التعديل",
    "Subscriptions": "الاشتراكات",
    "Settings": "الإعدادات",
    "Analytics": "التحليلات",
    "Reports": "التقارير",
    "Drivers": "السائقون",
    "Merchants": "التجار",
    "Customers": "العملاء",
    "Marketplace": "السوق",
    "Stores": "المتاجر",
    "Products": "المنتجات",
    "Reviews": "التقييمات",
    "Messages": "الرسائل",
    "Notifications": "الإشعارات",
    "Profile": "الملف الشخصي",
    "Search": "بحث",
    "Home": "الرئيسية",
    "Cart": "السلة",
    "Checkout": "الدفع",
    "Tracking": "التتبع",
    "Wallet": "المحفظة",
    "Payments": "المدفوعات",
    "History": "السجل",
    "Status": "الحالة",
    "Type": "النوع",
    "Date": "التاريخ",
    "Time": "الوقت",
    "Price": "السعر",
    "Quantity": "الكمية",
    "Total": "الإجمالي",
    "Subtotal": "المجموع الفرعي",
    "Tax": "الضريبة",
    "Delivery": "التوصيل",
    "Discount": "الخصم",
    "Promo Code": "رمز الخصم",

    # Common merchant labels
    "Total Orders": "إجمالي الطلبات",
    "Today's Orders": "طلبات اليوم",
    "Today's Revenue": "إيرادات اليوم",
    "Total Revenue": "إجمالي الإيرادات",
    "Average Order": "متوسط الطلب",
    "Pending Orders": "الطلبات المعلّقة",
    "Active Orders": "الطلبات النشطة",
    "Completed Orders": "الطلبات المكتملة",
    "Cancelled Orders": "الطلبات الملغاة",
    "Total Products": "إجمالي المنتجات",
    "Total Stores": "إجمالي المتاجر",
    "Total Users": "إجمالي المستخدمين",
    "Total Drivers": "إجمالي السائقين",
    "Total Merchants": "إجمالي التجار",
    "Active Stores": "المتاجر النشطة",

    # Common driver labels
    "Earnings Today": "أرباح اليوم",
    "Deliveries Today": "توصيلات اليوم",
    "Active": "نشط",
    "Pending": "معلّق",
    "Completed": "مكتمل",
    "Cancelled": "ملغي",
    "In Progress": "قيد التنفيذ",

    # Generic UI words
    "View": "عرض",
    "Edit": "تعديل",
    "Delete": "حذف",
    "Add": "إضافة",
    "Save": "حفظ",
    "Cancel": "إلغاء",
    "Confirm": "تأكيد",
    "Update": "تحديث",
    "Close": "إغلاق",
    "Back": "رجوع",
    "Next": "التالي",
    "Previous": "السابق",
    "Done": "تم",
    "Submit": "إرسال",
    "Refresh": "تحديث",
    "Loading": "جارٍ التحميل",
    "Error": "خطأ",
    "Success": "نجاح",
    "Warning": "تحذير",
    "Info": "معلومات",

    # User profile subtitles
    "View order history": "عرض سجل الطلبات",
    "Your favorite products": "منتجاتك المفضلة",
    "Manage your shopping cart": "إدارة سلة التسوق",
    "Loyalty rewards & points": "مكافآت الولاء والنقاط",
    "App preferences": "تفضيلات التطبيق",
    "Choose your language": "اختر لغتك",
    "Toggle dark theme": "تبديل المظهر الداكن",
    "Logout from account": "تسجيل الخروج من الحساب",
}


def add_string(value):
    """Add a string to ARBs and return its key."""
    if value in existing_str_to_key:
        return existing_str_to_key[value]

    key = make_key(value, set(en_arb.keys()))
    if not key: return None

    en_arb[key] = value
    ar_arb[key] = AR_TRANSLATIONS.get(value, value)
    existing_str_to_key[value] = key
    return key


# Add all unique strings
added = 0
for s in sorted(unique_strings):
    if s not in existing_str_to_key:
        if add_string(s):
            added += 1

# Save ARBs
with open(os.path.join(L10N, 'app_en.arb'), 'w', encoding='utf-8') as f:
    json.dump(en_arb, f, indent=2, ensure_ascii=False)
with open(os.path.join(L10N, 'app_ar.arb'), 'w', encoding='utf-8') as f:
    json.dump(ar_arb, f, indent=2, ensure_ascii=False)

print(f"Added {added} new strings to ARBs")
print(f"Total ARB strings now: {len([k for k in en_arb if not k.startswith('@@')])}")

# ═══════════════════════════════════════════════════════════════
# PHASE 3: Patch Dart files
# ═══════════════════════════════════════════════════════════════

print("\n=== Phase 3: Patching Dart files ===\n")

stats = {'files': 0, 'p1': 0, 'p2': 0, 'p3': 0}


def add_loc_import(content, filepath):
    if 'app_localizations.dart' in content:
        return content
    rel = os.path.relpath(os.path.join(LIB, 'l10n', 'generated'), os.path.dirname(filepath)).replace('\\', '/')
    imp = f"import '{rel}/app_localizations.dart';"
    lines = content.split('\n')
    last = -1
    for i, l in enumerate(lines):
        if l.strip().startswith('import ') and l.strip().endswith(';'):
            last = i
    if last >= 0:
        lines.insert(last + 1, imp)
    return '\n'.join(lines)


def patch_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    p1_count = 0
    p2_count = 0
    p3_count = 0

    # ── PATTERN 1: Map literal values ──
    # "title": "Shopping Cart" → "title": AppLocalizations.of(context)!.shoppingCart
    def replace_map_value(m):
        nonlocal p1_count
        key_quote = m.group(1)
        key_name = m.group(2)
        val_quote = m.group(3)
        value = m.group(4)

        if should_skip_string(value):
            return m.group(0)

        loc_key = existing_str_to_key.get(value)
        if not loc_key:
            return m.group(0)

        p1_count += 1
        return f'{key_quote}{key_name}{key_quote}: AppLocalizations.of(context)!.{loc_key}'

    content = re.sub(
        r'''(["'])(title|subtitle|label|name|description|text|message|hint|placeholder|caption|header|category|status)\1\s*:\s*(["'])([^"'\\]+)\3''',
        replace_map_value,
        content
    )

    # ── PATTERN 2: Deeply indented multi-line Text() ──
    def replace_text_widget(m):
        nonlocal p2_count
        indent = m.group(1)
        val_quote = m.group(2)
        value = m.group(3)

        if should_skip_string(value):
            return m.group(0)

        loc_key = existing_str_to_key.get(value)
        if not loc_key:
            return m.group(0)

        p2_count += 1
        return f'Text(\n{indent}AppLocalizations.of(context)!.{loc_key},'

    content = re.sub(
        r'''Text\(\s*\n(\s+)(["'])([^"'\\\n]+)\2\s*,''',
        replace_text_widget,
        content
    )

    # ── PATTERN 3: Positional args to helper methods ──
    # _buildMgmtTile(Icons.people, 'Users', Colors.blue, ...) → 'Users' becomes loc call
    # We need to find: helper method call → find positional string args

    # Find all method calls and process them
    def replace_in_method_call(m):
        nonlocal p3_count
        method_name = m.group(1)
        full_call = m.group(0)

        if method_name in {'showDialog', 'debugPrint', 'print', 'log'}:
            return full_call

        # Find quoted strings in the args
        # Replace each one if it's a positional arg (not preceded by `key:`)
        new_call = full_call

        # Walk through string literals
        offset = 0
        for sm in list(re.finditer(r'''(["'])([^"'\\\n]+)\1''', full_call)):
            value = sm.group(2)
            if should_skip_string(value):
                continue

            local_start = sm.start()
            prev = full_call[max(0, local_start - 5):local_start]
            if ':' in prev[-3:]:
                continue

            # Don't treat it as positional if it's the value of a `key: 'val'` pattern
            # (the colon check above handles direct cases)
            if prev.endswith('(') or prev.endswith(', ') or prev.endswith(','):
                loc_key = existing_str_to_key.get(value)
                if not loc_key:
                    continue

                # Replace this specific occurrence in new_call
                old = sm.group(0)
                new = f'AppLocalizations.of(context)!.{loc_key}'
                # Replace only the first occurrence at position local_start + offset
                # in new_call
                pos = local_start + offset
                if new_call[pos:pos+len(old)] == old:
                    new_call = new_call[:pos] + new + new_call[pos+len(old):]
                    offset += len(new) - len(old)
                    p3_count += 1

        return new_call

    content = re.sub(
        r'''(_\w+|show\w+|build\w+)\([^)]*\)''',
        replace_in_method_call,
        content,
        flags=re.MULTILINE
    )

    if content != original:
        # Add import
        content = add_loc_import(content, filepath)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        stats['files'] += 1
        stats['p1'] += p1_count
        stats['p2'] += p2_count
        stats['p3'] += p3_count
        return True
    return False


for fp in all_files:
    if is_no_context_file(fp):
        continue
    if patch_file(fp):
        rel = os.path.relpath(fp, PROJECT).replace('\\', '/')
        print(f"  {rel}")

print(f"\n=== RESULTS ===")
print(f"  Files modified: {stats['files']}")
print(f"  Pattern 1 (map values): {stats['p1']}")
print(f"  Pattern 2 (multi-line Text): {stats['p2']}")
print(f"  Pattern 3 (positional args): {stats['p3']}")

# ═══════════════════════════════════════════════════════════════
# PHASE 4: Regenerate localizations
# ═══════════════════════════════════════════════════════════════

print("\n=== Phase 4: Regenerating localizations ===")
os.system('flutter gen-l10n')
print("Done!")
