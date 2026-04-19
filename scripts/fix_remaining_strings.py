#!/usr/bin/env python3
"""
Add remaining hardcoded strings to ARB files and patch all Dart files.
Handles ternary expressions, return statements, and all UI contexts.
"""

import os
import re
import json

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJECT, 'lib')
L10N = os.path.join(LIB, 'l10n')

# ── Load remaining strings ──
with open(os.path.join(PROJECT, 'scripts', 'remaining_strings.json'), 'r', encoding='utf-8') as f:
    remaining = json.load(f)

# ── Arabic translations for ALL remaining strings ──
AR = {
    "247Support": "دعم على مدار الساعة",
    "30Days": "30 يوم",
    "7Days": "7 أيام",
    "90Days": "90 يوم",
    "aDriverHasBeenAssignedAnd": "تم تعيين سائق وهو في طريقه إلى المتجر",
    "activate": "تفعيل",
    "activateAccount": "تفعيل الحساب",
    "active2": "نشط",
    "add2": "إضافة",
    "addCategory2": "إضافة فئة",
    "addGroceryListToCart": "إضافة قائمة البقالة إلى السلة",
    "addProduct3": "إضافة منتج",
    "addSubcategory2": "إضافة فئة فرعية",
    "addToFavorites": "إضافة إلى المفضلة",
    "addedToCart": "تمت الإضافة إلى السلة",
    "addedToFavorites": "تمت الإضافة إلى المفضلة",
    "addingToCart": "جارٍ الإضافة إلى السلة...",
    "addressIsRequired": "العنوان مطلوب",
    "administrator": "مسؤول",
    "advertisement": "إعلان",
    "aiRequestTimedOutPleaseTry2": "انتهت مهلة طلب الذكاء الاصطناعي. يرجى المحاولة مرة أخرى.",
    "all2": "الكل",
    "applicationPending": "الطلب معلّق",
    "applicationRejected": "تم رفض الطلب",
    "apply2": "تطبيق",
    "askAnything": "اسأل أي شيء",
    "askMeAnything": "اسألني أي شيء...",
    "assignToCategory": "تعيين لفئة",
    "available": "متوفر",
    "banner": "لافتة",
    "bicycle": "دراجة هوائية",
    "book": "حجز",
    "businessAddressIsRequired": "عنوان العمل مطلوب",
    "businessNameIsRequired": "اسم العمل مطلوب",
    "businessNameMustBeAtLeast": "اسم العمل يجب أن يكون 3 أحرف على الأقل",
    "cancelled": "ملغي",
    "car": "سيارة",
    "carousel2": "عرض دوار",
    "category2": "فئة",
    "categoryName2": "اسم الفئة *",
    "changeImage": "تغيير الصورة",
    "changeOnMap": "تغيير على الخريطة",
    "closeStore": "إغلاق المتجر",
    "comparePlans": "مقارنة الخطط",
    "confirmOrder": "تأكيد الطلب",
    "confirmed": "مؤكد",
    "content": "محتوى",
    "continue": "متابعة",
    "create2": "إنشاء",
    "createMerchant": "إنشاء تاجر",
    "createNewAd": "إنشاء إعلان جديد",
    "createPlan": "إنشاء خطة",
    "currentPlan": "الخطة الحالية",
    "customer2": "عميل",
    "dark2": "داكن",
    "darkMode": "الوضع الداكن",
    "deactivate": "تعطيل",
    "delivered": "تم التوصيل",
    "deliveryDetails": "تفاصيل التوصيل",
    "driver2": "سائق",
    "driverApprovedSuccessfully": "تم الموافقة على السائق بنجاح!",
    "driverAssigned2": "تم تعيين السائق",
    "driverRejected": "تم رفض السائق",
    "editAd": "تعديل الإعلان",
    "editCategory2": "تعديل الفئة",
    "editPlan": "تعديل الخطة",
    "editSubcategory": "تعديل الفئة الفرعية",
    "emailIsRequired": "البريد الإلكتروني مطلوب",
    "enterAValidEmail": "أدخل بريداً إلكترونياً صالحاً",
    "enterAValidPrice": "أدخل سعراً صالحاً",
    "enterYourEmailAndWeLl": "أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة التعيين",
    "failedToApproveDriver": "فشل في الموافقة على السائق",
    "failedToRejectDriver": "فشل في رفض السائق",
    "failedToRejectMerchant": "فشل في رفض التاجر",
    "failedToUpdateProfile": "فشل في تحديث الملف الشخصي",
    "feature": "تمييز",
    "fullNameIsRequired": "الاسم الكامل مطلوب",
    "goodAfternoon": "مساء الخير",
    "goodEvening": "مساء الخير",
    "goodMorning": "صباح الخير",
    "groceries": "بقالة",
    "hidden": "مخفي",
    "hideComparison": "إخفاء المقارنة",
    "iApologizeButIMHaving": "أعتذر، أواجه مشكلة في معالجة طلبك الآن. يرجى المحاولة مرة أخرى.",
    "importing": "جارٍ الاستيراد...",
    "inStock": "متوفر",
    "inStore": "في المتجر",
    "inTransit": "في الطريق",
    "inactive2": "غير نشط",
    "inheritedFromParent": "موروث من الأب",
    "inventory2": "inventory_2",
    "item": "عنصر",
    "justNow": "الآن",
    "kjDelivery": "KJ Delivery",
    "light2": "فاتح",
    "lightMode": "الوضع الفاتح",
    "listening": "جارٍ الاستماع...",
    "listing": "إعلان",
    "markAvailable": "تحديد كمتوفر",
    "markUnavailable": "تحديد كغير متوفر",
    "marketplaceListing": "إعلان السوق",
    "merchant2": "تاجر",
    "merchantRejected": "تم رفض التاجر",
    "motorcycle": "دراجة نارية",
    "moveToCart": "نقل إلى السلة",
    "mustBe0OrHigher": "يجب أن يكون 0 أو أعلى",
    "mustBeANumber": "يجب أن يكون رقماً",
    "mustBeAtLeast2Characters": "يجب أن يكون حرفين على الأقل",
    "nA": "غ/م",
    "nameIsRequired": "الاسم مطلوب",
    "nameMustBeAtLeast3": "الاسم يجب أن يكون 3 أحرف على الأقل",
    "navigateToCustomer": "الانتقال إلى العميل",
    "navigateToStore": "الانتقال إلى المتجر",
    "newDeliveryRequest2": "طلب توصيل جديد",
    "newOrder2": "طلب جديد!",
    "no2": "لا",
    "noRatingsYet": "لا توجد تقييمات بعد",
    "notAvailable": "غير متوفر",
    "now": "الآن",
    "offer": "عرض",
    "offline2": "غير متصل",
    "online2": "متصل",
    "openStore": "فتح المتجر",
    "orderAccepted2": "تم قبول الطلب",
    "orderCancelled2": "تم إلغاء الطلب",
    "orderDelivered": "تم توصيل الطلب",
    "orderPickedUp": "تم استلام الطلب",
    "orderPlaced": "تم تقديم الطلب",
    "orderRejected2": "تم رفض الطلب",
    "outOfStock2": "نفذ المخزون",
    "parentCategoryOptional": "الفئة الأم (اختياري)",
    "pending": "معلّق",
    "pharmacy": "صيدلية",
    "phoneNumber3": "رقم الهاتف",
    "phoneNumberIsRequired": "رقم الهاتف مطلوب",
    "pickOnMap2": "اختر على الخريطة",
    "pickedUp": "تم الاستلام",
    "pleaseDescribeYourExperience": "يرجى وصف خبرتك",
    "pleaseProvideBusinessAddress": "يرجى تقديم عنوان العمل",
    "pleaseProvideBusinessName": "يرجى تقديم اسم العمل",
    "pleaseProvideVehicleInformation": "يرجى تقديم معلومات المركبة",
    "preparing": "جارٍ التحضير",
    "priceIsRequired2": "السعر مطلوب",
    "priority2": "أولوية",
    "processing": "قيد المعالجة",
    "processingYourOrder": "جارٍ معالجة طلبك...",
    "product2": "منتج",
    "profileUpdated": "تم تحديث الملف الشخصي!",
    "ready": "جاهز",
    "recording": "جارٍ التسجيل...",
    "removeFromFavorites2": "إزالة من المفضلة",
    "removeSale2": "إزالة التخفيض",
    "removedFromFavorites2": "تم الإزالة من المفضلة",
    "resetDemoData2": "إعادة تعيين البيانات التجريبية",
    "resetting": "جارٍ إعادة التعيين...",
    "restaurants": "مطاعم",
    "retail": "تجزئة",
    "save2": "حفظ",
    "saveChanges2": "حفظ التغييرات",
    "seedDemoData": "بذر البيانات التجريبية",
    "seeding": "جارٍ البذر...",
    "service2": "خدمة",
    "services": "الخدمات",
    "setDeliveryAddress": "تعيين عنوان التوصيل",
    "setItemLocation": "تعيين موقع العنصر",
    "setSearchArea": "تعيين منطقة البحث",
    "setServiceZone": "تعيين منطقة الخدمة",
    "setStoreLocation": "تعيين موقع المتجر",
    "standard2": "عادي",
    "store2": "متجر",
    "storeAcceptedYourOrderAssigningA": "قبل المتجر طلبك، جارٍ تعيين سائق",
    "storeIsNowClosed": "المتجر مغلق الآن",
    "storeIsNowOpen": "المتجر مفتوح الآن",
    "subcategoryName": "اسم الفئة الفرعية *",
    "subscribe2": "اشتراك",
    "suspend": "تعليق",
    "suspendAccount": "تعليق الحساب",
    "system2": "النظام",
    "tapToAddPhoto": "اضغط لإضافة صورة",
    "tapToChangePhoto": "اضغط لتغيير الصورة",
    "thisOrderHasBeenCancelled": "تم إلغاء هذا الطلب",
    "thisWillSignYouOutOf": "سيتم تسجيل خروجك من جميع الأجهزة الأخرى. ستبقى مسجل الدخول هنا.",
    "titleIsRequired": "العنوان مطلوب",
    "tryAdjustingYourSearchOrFilters": "جرب تعديل بحثك أو الفلاتر للعثور على ما تبحث عنه",
    "unavailable2": "غير متوفر",
    "unfeature": "إلغاء التمييز",
    "unfortunatelyYourOrderWasRejected": "للأسف، تم رفض طلبك",
    "unknownLocation": "موقع غير معروف",
    "update": "تحديث",
    "updatedCart": "تم تحديث السلة",
    "uploading": "جارٍ الرفع...",
    "van": "فان",
    "view": "عرض",
    "visible": "مرئي",
    "whatsapp": "واتساب",
    "yes2": "نعم",
    "yesterday": "أمس",
    "youAreNowOffline": "أنت الآن غير متصل",
    "youAreNowOnline": "أنت الآن متصل",
    "youAreOffline": "أنت غير متصل",
    "youAreOnline": "أنت متصل",
    "yourOrderHasBeenDeliveredEnjoy": "تم توصيل طلبك. بالهناء والشفاء!",
    "yourOrderIsBeingReviewedBy": "طلبك قيد المراجعة من قبل المتجر",
    "yourOrderIsOnTheWay": "طلبك في الطريق إليك!",
    # Validation messages from signup form
    "atLeast7DigitsForLebanon": "7 أرقام على الأقل للبنان",
    "pleaseEnterAValidNumber": "يرجى إدخال رقم صالح",
    "passwordIsRequired": "كلمة المرور مطلوبة",
    "atLeast8Characters": "8 أحرف على الأقل",
    "needUppercaseLowercaseNumber": "يجب أن يحتوي على أحرف كبيرة وصغيرة وأرقام",
    "pleaseEnterYourFullName": "يرجى إدخال اسمك الكامل",
    "selectCountry": "اختر البلد",
    "savedAddresses": "العناوين المحفوظة",
    "selectDeliveryLocation": "اختر موقع التوصيل",
    "couldNotGetLocationPleaseEnable": "تعذر الحصول على الموقع. يرجى تفعيل GPS.",
    "searchOrTapToSelectLocation2": "ابحث أو اضغط لاختيار الموقع",
    "admin2": "ADMIN",
    "closedStatus": "مغلق",
    "customersCanPlaceOrders": "يمكن للعملاء تقديم الطلبات",
    "ordersPaused": "الطلبات متوقفة",
    "operatingHours2": "ساعات العمل",
    "shownInFeaturedSection": "معروض في قسم المميزة",
    "notFeatured": "غير مميز",
    "live": "مباشر",
    "ok2": "حسناً",
    "gps": "GPS",
    "recent": "الأخيرة",
    "andText": " و ",
}

# Also add extra strings we found that weren't in remaining_strings.json
EXTRA_STRINGS = {
    "atLeast7DigitsForLebanon": "At least 7 digits for Lebanon",
    "pleaseEnterAValidNumber": "Please enter a valid number",
    "passwordIsRequired": "Password is required",
    "atLeast8Characters": "At least 8 characters",
    "needUppercaseLowercaseNumber": "Need uppercase, lowercase & number",
    "pleaseEnterYourFullName": "Please enter your full name",
    "selectCountry": "Select Country",
    "savedAddresses": "Saved Addresses",
    "selectDeliveryLocation": "Select Delivery Location",
    "couldNotGetLocationPleaseEnable": "Could not get location. Please enable GPS.",
    "searchOrTapToSelectLocation2": "Search or tap to select location",
    "admin2": "ADMIN",
    "closedStatus": "Closed",
    "customersCanPlaceOrders": "Customers can place orders",
    "ordersPaused": "Orders paused",
    "operatingHours2": "Operating Hours",
    "shownInFeaturedSection": "Shown in featured section",
    "notFeatured": "Not featured",
    "live": "LIVE",
    "ok2": "OK",
    "gps": "GPS",
    "recent": "RECENT",
    "andText": " and ",
}


def update_arb_files():
    """Add all new strings to both ARB files."""
    # Load existing
    en_path = os.path.join(L10N, 'app_en.arb')
    ar_path = os.path.join(L10N, 'app_ar.arb')

    with open(en_path, 'r', encoding='utf-8') as f:
        en = json.load(f)
    with open(ar_path, 'r', encoding='utf-8') as f:
        ar = json.load(f)

    added = 0

    # Remove keys that clash with Dart keywords
    dart_keywords = {'continue', 'default', 'in', 'is', 'new', 'return', 'switch', 'this', 'var', 'void', 'while'}

    # Add remaining strings
    for key, en_val in remaining.items():
        # Fix keyword clashes
        safe_key = key
        if key in dart_keywords:
            safe_key = key + 'Text'

        if safe_key not in en:
            en[safe_key] = en_val
            ar[safe_key] = AR.get(key, AR.get(safe_key, en_val))
            added += 1

    # Add extra strings
    for key, en_val in EXTRA_STRINGS.items():
        if key not in en:
            en[key] = en_val
            ar[key] = AR.get(key, en_val)
            added += 1

    # Write back
    with open(en_path, 'w', encoding='utf-8') as f:
        json.dump(en, f, indent=2, ensure_ascii=False)
    with open(ar_path, 'w', encoding='utf-8') as f:
        json.dump(ar, f, indent=2, ensure_ascii=False)

    print(f"Added {added} new strings to ARB files")
    return added


def add_import_if_needed(content, filepath):
    """Add AppLocalizations import if not present."""
    if 'app_localizations.dart' in content:
        return content

    rel = os.path.relpath(
        os.path.join(LIB, 'l10n', 'generated'),
        os.path.dirname(filepath)
    ).replace('\\', '/')
    imp = f"import '{rel}/app_localizations.dart';"

    lines = content.split('\n')
    last_import = -1
    for i, line in enumerate(lines):
        if line.strip().startswith('import ') and line.strip().endswith(';'):
            last_import = i
    if last_import >= 0:
        lines.insert(last_import + 1, imp)
    else:
        lines.insert(0, imp)
    return '\n'.join(lines)


def build_reverse_map():
    """Build string -> key mapping from both remaining and extra."""
    # Load current en ARB for the full mapping
    with open(os.path.join(L10N, 'app_en.arb'), 'r', encoding='utf-8') as f:
        en = json.load(f)

    s2k = {}
    for key, val in en.items():
        if key.startswith('@@'):
            continue
        # We only want to map strings that are in our "remaining" or "extra" sets
        # to avoid re-replacing already-replaced strings
        s2k[val] = key
    return s2k


def patch_all_files(s2k):
    """Patch all Dart files replacing remaining hardcoded strings."""
    skip_dirs = {'l10n', 'generated'}
    skip_files = {'locale_provider.dart', 'language_selection_screen.dart', 'app_export.dart'}

    # Build the set of strings we want to replace (only the new ones)
    new_strings = set()
    for key, val in remaining.items():
        new_strings.add(val)
    for key, val in EXTRA_STRINGS.items():
        new_strings.add(val)

    # Sort longest first
    sorted_strings = sorted(new_strings, key=len, reverse=True)

    total_replacements = 0
    files_modified = 0

    for root, dirs, files in os.walk(LIB):
        dirs[:] = [d for d in dirs if d not in skip_dirs]
        for fname in sorted(files):
            if not fname.endswith('.dart') or fname in skip_files:
                continue

            filepath = os.path.join(root, fname)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()

            # Skip files that are services without context (except specific known ones)
            is_service = '/services/' in filepath.replace('\\', '/')
            is_model = '/models/' in filepath.replace('\\', '/')

            original = content
            file_reps = 0

            for string_val in sorted_strings:
                if string_val not in content:
                    continue

                key = s2k.get(string_val)
                if not key:
                    continue

                # Skip if this string contains backslash escapes that need special handling
                if '\\' in string_val:
                    continue

                loc = f"AppLocalizations.of(context)!.{key}"

                for quote in ["'", '"']:
                    quoted = f"{quote}{string_val}{quote}"
                    if quoted not in content:
                        continue

                    # ── Direct UI contexts ──
                    prefixes = [
                        "Text(", "Text( ",
                        "title: ", "title:",
                        "label: ", "label:",
                        "hintText: ", "hintText:",
                        "labelText: ", "labelText:",
                        "helperText: ", "helperText:",
                        "errorText: ", "errorText:",
                        "tooltip: ", "tooltip:",
                        "text: ", "text:",
                        "message: ", "message:",
                        "hint: ", "hint:",
                        "description: ", "description:",
                        "actionLabel: ", "actionLabel:",
                        "child: Text(", "child: Text( ",
                        "subtitle: Text(", "subtitle: Text( ",
                        "content: Text(", "content: Text( ",
                        "header: Text(", "header: Text( ",
                        "TextSpan(text: ", "TextSpan(text:",
                        "Tab(text: ", "Tab(text:",
                    ]

                    for pfx in prefixes:
                        target = pfx + quoted
                        if target in content:
                            replacement = pfx + loc
                            content = content.replace(target, replacement)
                            file_reps += 1

                    # ── Ternary expressions: ? 'string' : or : 'string' ──
                    # Pattern: ? 'val' or : 'val'
                    for sep in ['? ', '?', ': ', ':']:
                        target = sep + quoted
                        if target in content:
                            # Make sure we're not inside a comment/import
                            replacement = sep + loc
                            content = content.replace(target, replacement)
                            file_reps += 1

                    # ── Return statements: return 'string'; ──
                    target_ret = f"return {quoted};"
                    if target_ret in content:
                        # Skip in model/service files that don't have context
                        if is_service or is_model:
                            continue
                        content = content.replace(target_ret, f"return {loc};")
                        file_reps += 1

                    # ── SnackBar: SnackBar(content: Text('string' ──
                    target_snack = f"SnackBar(content: Text({quoted}"
                    if target_snack in content:
                        content = content.replace(target_snack, f"SnackBar(content: Text({loc}")
                        file_reps += 1

            if content != original and file_reps > 0:
                # Remove const before any expression containing our new AppLocalizations calls
                content = remove_invalid_const(content)
                content = add_import_if_needed(content, filepath)

                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)

                rel = os.path.relpath(filepath, PROJECT).replace('\\', '/')
                print(f"  {rel} ({file_reps} replacements)")
                total_replacements += file_reps
                files_modified += 1

    print(f"\nTotal: {files_modified} files, {total_replacements} replacements")


def remove_invalid_const(content):
    """Remove const from expressions that now contain AppLocalizations."""
    # Simple patterns
    widget_types = [
        'Text', 'Icon', 'SizedBox', 'Padding', 'Column', 'Row',
        'Container', 'Center', 'Expanded', 'Flexible', 'Wrap',
        'ListTile', 'Card', 'Chip', 'Tab', 'DropdownMenuItem',
        'AlertDialog', 'SimpleDialog', 'BottomSheet',
        'InputDecoration', 'TextStyle', 'BoxDecoration',
        'ElevatedButton', 'TextButton', 'OutlinedButton',
        'IconButton', 'FloatingActionButton',
        'AppBar', 'BottomNavigationBarItem', 'NavigationDestination',
        'SnackBar', 'Tooltip', 'PopupMenuItem', 'Scaffold',
        'InfoWindow', 'TextSpan',
    ]

    for widget in widget_types:
        pattern = f'const {widget}('
        idx = 0
        while True:
            idx = content.find(pattern, idx)
            if idx == -1:
                break
            # Find matching paren
            paren_start = idx + len(pattern) - 1
            depth = 1
            pos = paren_start + 1
            while pos < len(content) and depth > 0:
                c = content[pos]
                if c == '(': depth += 1
                elif c == ')': depth -= 1
                elif c in ("'", '"'):
                    q = c
                    pos += 1
                    while pos < len(content) and content[pos] != q:
                        if content[pos] == '\\': pos += 1
                        pos += 1
                pos += 1

            block = content[paren_start:pos]
            if 'AppLocalizations' in block:
                content = content[:idx] + content[idx + 6:]  # remove "const "
            else:
                idx += len(pattern)

    # Also handle const [ ... ] lists
    idx = 0
    while True:
        idx = content.find('const [', idx)
        if idx == -1:
            break
        bracket_start = idx + 6
        depth = 1
        pos = bracket_start + 1
        while pos < len(content) and depth > 0:
            if content[pos] == '[': depth += 1
            elif content[pos] == ']': depth -= 1
            pos += 1
        block = content[bracket_start:pos]
        if 'AppLocalizations' in block:
            content = content[:idx] + content[idx + 6:]
        else:
            idx += 7

    return content


def main():
    print("=== Step 1: Update ARB files ===")
    update_arb_files()

    print("\n=== Step 2: Regenerate localization classes ===")
    os.system('flutter gen-l10n')

    print("\n=== Step 3: Build reverse mapping ===")
    s2k = build_reverse_map()

    print(f"\n=== Step 4: Patch Dart files ({len(s2k)} mappings) ===")
    patch_all_files(s2k)

    print("\n=== Done! ===")


if __name__ == '__main__':
    main()
