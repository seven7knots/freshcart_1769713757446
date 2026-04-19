#!/usr/bin/env python3
"""
MEGA PATCH: Add ALL remaining UI strings to ARBs and patch Dart files.
Filters out technical identifiers, seed data, and demo content.
"""

import os, re, json

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJECT, 'lib')
L10N = os.path.join(LIB, 'l10n')

# Load remaining strings
with open(os.path.join(PROJECT, 'scripts', 'mega_remaining.json'), 'r', encoding='utf-8') as f:
    remaining = json.load(f)

# ══════════════════════════════════════════════════════════════
# FILTER: Remove non-UI strings
# ══════════════════════════════════════════════════════════════

SKIP_PATTERNS = [
    # Internal identifiers / API params
    r'app-startup', r'supabase-auth', r'token-refresh', r'auth-provider',
    r'postRefresh', r'post-refresh', r'approveDriver', r'approveMerchant',
    r'^com\.kj', r'^@mipmap', r'^country:', r'^claude-haiku',
    r'^admin@', r'^ads-images', r'^barcode scanner', r'^inventory_',
    # Model names, technical
    r'^claude', r'^gemini',
    # Seed data - specific names
    r'^Ahmed Hassan', r'^Admin User', r'^seven7knots',
    # Seed product/store descriptions (demo data in seed_service.dart)
    r'^Antibacterial hand', r'^Authentic Lebanese', r'^Cold brew',
    r'^Complete first aid', r'^Chicken Caesar', r'^Chicken Shawarma Plate',
    r'^Beef Burger', r'^Fresh produce',
    # URL/path patterns
    r'^com\.kjdelivery', r'^reset-password',
    # Reason strings
    r'^reason:', r'^admin-check',
]

def should_skip_entry(key, val):
    low = val.lower()
    for p in SKIP_PATTERNS:
        if re.search(p, val, re.IGNORECASE):
            return True
    # Skip if it's a pure place name (from seed_service Lebanese locations)
    # These are proper nouns that don't need translation
    lebanese_places = [
        'Achrafieh', 'Antelias', 'Baabda', 'Baalbek', 'Badaro', 'Batroun',
        'Beit Mery', 'Beiteddine', 'Bhamdoun', 'Bikfaya', 'Bint Jbeil',
        'Bourj Hammoud', 'Broummana', 'Bsharri', 'Byblos', 'Chekka',
        'Chouf', 'Chtaura', 'Dbayeh', 'Dekwaneh', 'Dora', 'Ehden',
        'Fanar', 'Faqra', 'Faraya', 'Gemmayzeh', 'Hadat', 'Halba',
        'Hamra', 'Hazmieh', 'Hermel', 'Jal el Dib', 'Jbeil', 'Jdeideh',
        'Jounieh', 'Jouniyeh', 'Jun', 'Jiyyeh', 'Kaslik', 'Keserwan',
        'Kfarhbab', 'Koura', 'Mar Mikhael', 'Metn', 'Mina', 'Monnot',
        'Nabatieh', 'Nahr el Kalb', 'Rabieh', 'Ras Beirut', 'Raouche',
        'Saida', 'Sarba', 'Sidon', 'Sin el Fil', 'Sodeco', 'Sour',
        'Tabarja', 'Tannourine', 'Tripoli', 'Tyre', 'Verdun', 'Zahle',
        'Zouk Mikael', 'Zouk Mosbeh', 'Aley', 'Aanjar', 'Zahleh',
    ]
    if val.strip() in lebanese_places:
        return True
    # Skip combined place strings
    if val in ['Beirut Central District', 'Beirut Central District, Lebanon',
               'Capital, Lebanon', 'Achrafieh, Beirut', 'Beirut Area',
               'Beirut & Suburbs', 'Beqaa Valley', 'All Beirut', 'All Lebanon',
               'North Lebanon', 'South Lebanon', 'Mount Lebanon', 'Beirut']:
        return True
    # Skip time slot strings (seed data)
    if re.match(r'^\d+:\d+ [AP]M', val):
        return True
    if val in ['12 AM', '12 PM']:
        return True
    # Skip strings that are clearly internal/technical
    if val in ['#N/A', '(empty name)', '@mipmap/ic_launcher', 'AI Mate Chat',
               'claude-haiku-4-5-20251001']:
        return True
    return False

# Filter
filtered = {}
skipped = 0
for key, val in remaining.items():
    if should_skip_entry(key, val):
        skipped += 1
    else:
        filtered[key] = val

print(f"Total remaining: {len(remaining)}")
print(f"Skipped (technical/seed/places): {skipped}")
print(f"UI strings to add: {len(filtered)}")

# ══════════════════════════════════════════════════════════════
# ARABIC TRANSLATIONS
# ══════════════════════════════════════════════════════════════

AR = {
    # Admin screens
    "newPromotion": "عرض ترويجي جديد",
    "unknownAd": "إعلان غير معروف",
    "adPreviewImage": "صورة معاينة الإعلان",
    "selectImage": "اختر صورة",
    "selectStore": "اختر متجر",
    "selectCategory": "اختر فئة",
    "selectProduct": "اختر منتج",
    "selectCollection": "اختر مجموعة",
    "selectTarget": "اختر الهدف",
    "unknown2": "غير معروف",
    "notSet": "غير محدد",
    "merchantApprovedSuccessfully": "تم الموافقة على التاجر بنجاح!",
    "failedToApproveMerchant": "فشل في الموافقة على التاجر",
    "required2": "مطلوب",
    "unnamed": "بدون اسم",
    "unknownStore": "متجر غير معروف",
    "allContent": "كل المحتوى",
    "adsBanners": "الإعلانات واللافتات",
    "food": "طعام",
    "grocery": "بقالة",
    "restaurant": "مطعم",
    "marketplace2": "السوق",
    "electronics": "إلكترونيات",
    "fashion": "أزياء",
    "beauty": "جمال",
    "sports": "رياضة",
    "other2": "أخرى",
    "general2": "عام",
    "loadingStores": "جارٍ تحميل المتاجر...",

    # Profile & settings
    "shoppingCart3": "سلة التسوق",
    "continueYourShopping": "تابع تسوقك",
    "yourSavedItems": "منتجاتك المحفوظة",
    "personalInformation": "المعلومات الشخصية",
    "updateYourDetails": "تحديث بياناتك",
    "deliveryAddresses2": "عناوين التوصيل",
    "manageYourAddresses": "إدارة عناوينك",
    "notificationPreferences2": "تفضيلات الإشعارات",
    "manageNotifications": "إدارة الإشعارات",
    "privacySecurity2": "الخصوصية والأمان",
    "manageYourPrivacy": "إدارة خصوصيتك",
    "becomeAPartner2": "كن شريكاً",
    "earnWithKjDelivery": "اكسب مع KJ Delivery",
    "inviteFriends": "ادعُ أصدقاء",
    "shareKjDelivery": "شارك KJ Delivery",
    "aboutKjDelivery": "حول KJ Delivery",
    "helpFeedback": "المساعدة والملاحظات",

    # Home
    "topStores2": "أفضل المتاجر",
    "seeAll2": "عرض الكل",
    "quickAdd2": "إضافة سريعة",
    "yourFrequentlyPurchasedItems": "منتجاتك المشتراة بكثرة",
    "recentOrders2": "الطلبات الأخيرة",
    "reorderYourFavorites": "أعد طلب مفضلاتك",
    "featuredCategories2": "الفئات المميزة",
    "dealsOfTheDay2": "عروض اليوم",

    # Search
    "searchForProducts": "ابحث عن منتجات",
    "noResults": "لا توجد نتائج",
    "tryDifferentKeywords": "جرب كلمات مختلفة",

    # Store detail
    "products2": "المنتجات",
    "about2": "حول",
    "reviews2": "التقييمات",
    "info2": "المعلومات",
    "currentlyClosedCheckBackLater": "مغلق حالياً، تحقق لاحقاً",

    # Cart
    "emptyCartMessage": "سلتك فارغة",
    "promoCodeHint": "أدخل رمز الخصم",
    "proceedToCheckout": "المتابعة للدفع",
    "cartTotal": "إجمالي السلة",

    # Checkout
    "deliveryAddress2": "عنوان التوصيل",
    "contactPhone": "هاتف الاتصال",
    "deliveryInstructionsHint": "تعليمات التوصيل (اختياري)",
    "reviewOrder": "مراجعة الطلب",
    "paymentMethod2": "طريقة الدفع",
    "placeOrderButton": "تقديم الطلب",

    # Order tracking
    "orderPlaced2": "تم تقديم الطلب",
    "yourOrderIsBeingReviewedByThe": "يتم مراجعة طلبك من المتجر",
    "storeAcceptedYourOrderAssigning": "قبل المتجر طلبك، جارٍ تعيين سائق",
    "aDriverHasBeenAssignedTo": "تم تعيين سائق لطلبك.",
    "yourOrderIsOnItsWay": "طلبك في الطريق!",
    "yourOrderHasBeenDelivered": "تم توصيل طلبك. بالهناء!",
    "orderWasRejected": "تم رفض الطلب",
    "orderHasBeenCancelled": "تم إلغاء الطلب",
    "processingYourOrder2": "جارٍ معالجة طلبك...",

    # Status labels
    "openNow2": "مفتوح الآن",
    "closedNow": "مغلق الآن",
    "almostReady": "شبه جاهز...",

    # Onboarding
    "welcomeToKjDelivery2": "مرحباً بك في KJ Delivery",
    "discoverLocalStoresAndProducts": "اكتشف المتاجر والمنتجات المحلية",
    "freshGroceriesDeliveredToYourDoor": "بقالة طازجة إلى باب منزلك",
    "orderFromYourFavoriteStoresAnd": "اطلب من متاجرك المفضلة وتتبع التوصيل",
    "trackYourDeliveryInRealTime": "تتبع توصيلك في الوقت الفعلي",
    "getStarted2": "ابدأ الآن",

    # Merchant
    "closeStore2": "إغلاق المتجر",
    "openStore2": "فتح المتجر",
    "addProduct4": "إضافة منتج",
    "importProducts": "استيراد المنتجات",
    "downloadCsvTemplate2": "تحميل قالب CSV",
    "chooseFile2": "اختر ملفاً",
    "storeIsNowClosed2": "المتجر مغلق الآن",
    "storeIsNowOpen2": "المتجر مفتوح الآن",
    "markAvailable2": "تحديد كمتوفر",
    "markUnavailable2": "تحديد كغير متوفر",
    "feature2": "تمييز",
    "unfeature2": "إلغاء التمييز",
    "customersCanPlaceOrders2": "يمكن للعملاء تقديم الطلبات",
    "ordersPaused2": "الطلبات متوقفة",
    "operatingHours3": "ساعات العمل",
    "closed2": "مغلق",

    # Driver
    "youAreNowOnline2": "أنت الآن متصل",
    "youAreNowOffline2": "أنت الآن غير متصل",
    "youAreOnline2": "أنت متصل",
    "youAreOffline2": "أنت غير متصل",
    "navigateToStore2": "الانتقال إلى المتجر",
    "navigateToCustomer2": "الانتقال إلى العميل",
    "online3": "متصل",
    "offline3": "غير متصل",

    # Dialogs & messages
    "areYouSureYouWantTo7": "هل أنت متأكد أنك تريد تفعيل حساب هذا المستخدم؟",
    "areYouSureYouWantTo8": "هل أنت متأكد أنك تريد تعليق حساب هذا المستخدم؟ لن يتمكن من الوصول إلى التطبيق.",
    "areYouSureYouWantTo9": "هل أنت متأكد أنك تريد حذف هذا العنوان؟",
    "areYouSureYouWantTo10": "هل أنت متأكد أنك تريد إزالة هذا المنتج من سلتك؟",
    "removeThisItem": "إزالة هذا المنتج؟",
    "deleteThisAddress": "حذف هذا العنوان؟",
    "clearAllItems": "مسح جميع المنتجات؟",

    # Misc UI
    "applyFilters": "تطبيق الفلاتر",
    "resetFilters": "إعادة تعيين الفلاتر",
    "browseCategories": "تصفح الفئات",
    "browseMarketplace": "تصفح السوق",
    "browseStores2": "تصفح المتاجر",
    "allListings": "كل الإعلانات",
    "noItemsYet": "لا توجد عناصر بعد",
    "noResults2": "لا توجد نتائج",
    "noMoreItems": "لا مزيد من العناصر",
    "loadingMore": "جارٍ تحميل المزيد...",
    "pullToRefresh": "اسحب للتحديث",
    "checkingLocation": "جارٍ التحقق من الموقع...",
    "searchHere": "ابحث هنا",
    "enterLocation": "أدخل الموقع",
    "chooseFromMap": "اختر من الخريطة",
    "useMyLocation": "استخدم موقعي",
    "savedSuccessfully": "تم الحفظ بنجاح",
    "deletedSuccessfully2": "تم الحذف بنجاح",
    "updatedSuccessfully2": "تم التحديث بنجاح",
    "copied": "تم النسخ",
    "shared": "تم المشاركة",
    "sentSuccessfully": "تم الإرسال بنجاح",
    "failedPleaseTryAgain": "فشلت العملية. يرجى المحاولة مرة أخرى",
    "noInternetConnection": "لا يوجد اتصال بالإنترنت",
    "connectionError": "خطأ في الاتصال",
    "serverError": "خطأ في الخادم",
    "sessionExpired": "انتهت الجلسة",
    "pleaseLoginAgain": "يرجى تسجيل الدخول مرة أخرى",
    "permissionDenied": "تم رفض الإذن",
    "cameraPermissionRequired": "إذن الكاميرا مطلوب",
    "locationPermissionRequired": "إذن الموقع مطلوب",

    # Categories (content_edit_modal store types)
    "food2": "طعام",
    "grocery2": "بقالة",
    "restaurant2": "مطعم",
    "marketplace3": "سوق",
    "electronics2": "إلكترونيات",
    "fashion2": "أزياء",
    "beauty2": "جمال",
    "sports2": "رياضة",

    # Subscription
    "createPlan2": "إنشاء خطة",
    "editPlan2": "تعديل الخطة",
    "activate2": "تفعيل",
    "deactivate2": "تعطيل",
    "comparePlans2": "مقارنة الخطط",
    "hideComparison2": "إخفاء المقارنة",
    "subscribe3": "اشتراك",
    "currentPlan2": "الخطة الحالية",

    # Time periods
    "morning69": "الصباح (6-9)",
    "morning912": "الصباح (9-12)",
    "afternoon125": "بعد الظهر (12-5)",
    "evening510": "المساء (5-10)",
    "anytime": "أي وقت",
    "today2": "اليوم",
    "tomorrow": "غداً",
    "thisWeek2": "هذا الأسبوع",
    "23Hours": "2-3 ساعات",
    "3045Minutes": "30-45 دقيقة",

    # Form & validation
    "fieldIsRequired": "هذا الحقل مطلوب",
    "invalidInput": "إدخال غير صالح",
    "tooShort": "قصير جداً",
    "tooLong": "طويل جداً",

    # Chat/messaging
    "typeAMessage2": "اكتب رسالة...",
    "sendMessage2": "إرسال رسالة",
    "noMessagesYet": "لا توجد رسائل بعد",
    "startConversation": "ابدأ محادثة",

    # AI
    "askAnything2": "اسأل أي شيء",
    "askMeAnything2": "اسألني أي شيء...",
    "thinkingDots": "جارٍ التفكير...",
    "generating": "جارٍ التوليد...",

    # Quick suggestions
    "whatStoresAreOpen": "ما المتاجر المفتوحة؟",
    "showMeDeals": "أرني العروض",
    "findCheapestGroceries": "أوجد أرخص بقالة",
    "findNearbyStores": "أوجد متاجر قريبة",
    "whatCanIOrder": "ماذا يمكنني أن أطلب؟",

    # Quick suggestion labels from chat
    "cheapItalianFoodOpenNow": "طعام إيطالي رخيص مفتوح الآن",
    "cleanersAvailableToday": "عمال تنظيف متوفرون اليوم",
    "canYouDeliverToAchrafieh": "هل يمكنكم التوصيل إلى الأشرفية؟",
    "canYouNegotiatePrice": "هل يمكن التفاوض على السعر؟",
    "isThisStillAvailable": "هل هذا لا يزال متوفراً؟",
    "whatIsYourBestPrice": "ما أفضل سعر لديك؟",

    # Marketplace
    "allCategories2": "كل الفئات",
    "forSale": "للبيع",
    "forRent": "للإيجار",
    "wantedToBuy": "مطلوب للشراء",
    "freeStuff": "مجاني",
    "condition": "الحالة",
    "newCondition": "جديد",
    "usedLikeNew": "مستعمل - كالجديد",
    "usedGood": "مستعمل - جيد",
    "usedFair": "مستعمل - مقبول",
    "beTheFirstToCreateA": "كن أول من ينشئ إعلاناً!",

    # Marketplace categories
    "vehiclesMotors": "سيارات ومحركات",
    "propertyForSale": "عقارات للبيع",
    "propertyForRent": "عقارات للإيجار",
    "electronicsCategory": "إلكترونيات",
    "furnitureGarden": "أثاث وحدائق",
    "fashionBeauty": "أزياء وجمال",
    "jobsServices": "وظائف وخدمات",
    "businessesIndustrial": "أعمال وصناعة",
    "kidsStuff": "مستلزمات الأطفال",
    "sportsLeisure": "رياضة وترفيه",
    "communityEvents": "مجتمع وفعاليات",
    "petsAnimals": "حيوانات أليفة",
    "homeAppliances": "أجهزة منزلية",
    "booksLearning": "كتب وتعليم",
    "healthWellness": "صحة وعافية",

    # Delivery
    "leaveAtDoor": "اتركه عند الباب",
    "ringDoorbell": "رن الجرس",
    "callOnArrival": "اتصل عند الوصول",
    "dontRingDoorbell": "لا ترن الجرس",

    # Notification channels
    "orderUpdates": "تحديثات الطلبات",
    "promotionsOffers": "العروض والترويجات",
    "driverUpdates": "تحديثات السائق",
    "chatMessages": "رسائل المحادثة",

    # Payment
    "cashOnDelivery2": "الدفع عند الاستلام",
    "creditDebitCard": "بطاقة ائتمان/خصم",
    "walletBalance": "رصيد المحفظة",

    # Empty states
    "noStoresNearby": "لا توجد متاجر قريبة",
    "noProductsInCategory": "لا توجد منتجات في هذه الفئة",
    "noActiveDeliveries": "لا توجد توصيلات نشطة",
    "noPendingOrders": "لا توجد طلبات معلّقة",

    # Misc
    "adPreview": "معاينة الإعلان",
    "adSubtitle": "عنوان فرعي للإعلان",
    "checkOutSpecialOffers": "اطلع على العروض الخاصة",
    "checkOutOurLatestOffer": "اطلع على أحدث عروضنا!",
    "cancelledByCustomer": "ملغي من العميل",
    "couldNotCalculateExactFeeUsing": "تعذر حساب الرسوم بدقة، يتم استخدام السعر الأساسي",
    "couldNotDetermineYourEmailPlease": "تعذر تحديد بريدك الإلكتروني. يرجى العودة والمحاولة مرة أخرى.",
    "action": "إجراء",
    "aFriend": "صديق",

    # Loading states
    "loading2": "جارٍ التحميل...",
    "pleaseWait2": "يرجى الانتظار...",
    "savingChanges": "جارٍ حفظ التغييرات...",
    "submitting": "جارٍ الإرسال...",
    "uploading2": "جارٍ الرفع...",

    # No data found in system prompt
    "noProductsCurrentlyInInventory": "(لا توجد منتجات في المخزون حالياً)",
    "noStoresCurrentlyListed": "(لا توجد متاجر مدرجة حالياً)",

    # Coffee, cleaningServices etc (marketplace category examples)
    "coffee": "قهوة",
    "cleaningServices": "خدمات تنظيف",
    "bakery2": "مخبز",

    # Seeding / admin
    "seedingDemoProducts": "جارٍ بذر المنتجات التجريبية...",
    "resetComplete": "اكتملت إعادة التعيين",
    "dataSeeded": "تم بذر البيانات",

    # China (country in phone picker)
    "china": "الصين",
}


def update_arbs():
    """Add new strings to both ARB files."""
    en_path = os.path.join(L10N, 'app_en.arb')
    ar_path = os.path.join(L10N, 'app_ar.arb')

    with open(en_path, 'r', encoding='utf-8') as f:
        en = json.load(f)
    with open(ar_path, 'r', encoding='utf-8') as f:
        ar = json.load(f)

    added = 0
    dart_kw = {'continue','default','in','is','new','return','switch','this','var','void','while','do','for','if','else','class','try','catch','throw','super'}

    for key, val in filtered.items():
        safe_key = key
        if key in dart_kw:
            safe_key = key + 'Text'
        if re.match(r'^\d', key):
            safe_key = 'n' + key

        if safe_key not in en:
            en[safe_key] = val
            ar[safe_key] = AR.get(key, AR.get(safe_key, val))
            added += 1

    with open(en_path, 'w', encoding='utf-8') as f:
        json.dump(en, f, indent=2, ensure_ascii=False)
    with open(ar_path, 'w', encoding='utf-8') as f:
        json.dump(ar, f, indent=2, ensure_ascii=False)
    print(f"Added {added} new strings to ARB files")
    return added


def patch_dart_files():
    """Replace hardcoded strings with AppLocalizations calls."""
    # Load final EN ARB for reverse mapping
    with open(os.path.join(L10N, 'app_en.arb'), 'r', encoding='utf-8') as f:
        en = json.load(f)

    s2k = {}
    for k, v in en.items():
        if not k.startswith('@@'):
            s2k[v] = k

    skip_dirs = {'l10n', 'generated'}
    skip_files = {'locale_provider.dart', 'language_selection_screen.dart', 'app_export.dart'}

    # Only replace strings that are in our filtered set
    target_strings = set(filtered.values())
    sorted_strings = sorted(target_strings, key=len, reverse=True)

    total_reps = 0
    files_mod = 0

    for root, dirs, files in os.walk(LIB):
        dirs[:] = [d for d in dirs if d not in skip_dirs]
        for fname in sorted(files):
            if not fname.endswith('.dart') or fname in skip_files:
                continue

            filepath = os.path.join(root, fname)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()

            # Skip model files, services, providers, theme (no BuildContext)
            rel = os.path.relpath(filepath, LIB).replace('\\', '/')
            no_context = any(rel.startswith(p) for p in ['models/', 'services/', 'theme/', 'providers/', 'routes/'])

            original = content
            reps = 0

            for sval in sorted_strings:
                if sval not in content:
                    continue
                key = s2k.get(sval)
                if not key:
                    continue
                if '\\' in sval:
                    continue

                loc = f"AppLocalizations.of(context)!.{key}"

                for quote in ["'", '"']:
                    quoted = f"{quote}{sval}{quote}"
                    if quoted not in content:
                        continue

                    # UI context prefixes
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
                            if no_context:
                                continue  # can't use AppLocalizations here
                            content = content.replace(target, pfx + loc)
                            reps += 1

                    # Ternary: ? 'val' : 'val'
                    if not no_context:
                        for sep in ['? ', ': ']:
                            target = sep + quoted
                            if target in content:
                                content = content.replace(target, sep + loc)
                                reps += 1

                    # Assignment: = 'val';
                    if not no_context:
                        target = f"= {quoted};"
                        if target in content:
                            content = content.replace(target, f"= {loc};")
                            reps += 1

            if content != original and reps > 0:
                # Remove const from expressions with AppLocalizations
                content = _fix_const(content)
                # Add import
                content = _add_import(content, filepath)
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
                rel2 = os.path.relpath(filepath, PROJECT).replace('\\', '/')
                print(f"  {rel2} ({reps})")
                total_reps += reps
                files_mod += 1

    print(f"\nTotal: {files_mod} files, {total_reps} replacements")


def _add_import(content, filepath):
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


def _fix_const(content):
    widgets = ['Text','Icon','SizedBox','Padding','Column','Row','Container','Center',
               'Scaffold','AlertDialog','DropdownMenuItem','TextSpan','InfoWindow',
               'PopupMenuItem','ListTile','SnackBar','Chip','Card','Tab',
               'BottomNavigationBarItem','NavigationDestination','SwitchListTile',
               'CheckboxListTile','RadioListTile','Tooltip','ElevatedButton',
               'TextButton','OutlinedButton']
    for w in widgets:
        pat = f'const {w}('
        idx = 0
        while True:
            idx = content.find(pat, idx)
            if idx == -1: break
            ps = idx + len(pat) - 1
            d = 1; p = ps + 1
            while p < len(content) and d > 0:
                c = content[p]
                if c == '(': d += 1
                elif c == ')': d -= 1
                elif c in ("'",'"'):
                    q = c; p += 1
                    while p < len(content) and content[p] != q:
                        if content[p] == '\\': p += 1
                        p += 1
                p += 1
            if 'AppLocalizations' in content[ps:p]:
                content = content[:idx] + content[idx+6:]
            else:
                idx += len(pat)
    # const [...]
    idx = 0
    while True:
        idx = content.find('const [', idx)
        if idx == -1: break
        d = 1; p = idx + 7
        while p < len(content) and d > 0:
            if content[p] == '[': d += 1
            elif content[p] == ']': d -= 1
            p += 1
        if 'AppLocalizations' in content[idx+7:p]:
            content = content[:idx] + content[idx+6:]
        else:
            idx += 7
    # const {...}
    idx = 0
    while True:
        m = re.search(r'\bconst\s+\{', content[idx:])
        if not m: break
        ai = idx + m.start()
        bs = content.index('{', ai)
        d = 1; p = bs + 1
        while p < len(content) and d > 0:
            if content[p] == '{': d += 1
            elif content[p] == '}': d -= 1
            p += 1
        if 'AppLocalizations' in content[bs:p]:
            content = content[:ai] + content[ai+6:]
        else:
            idx = ai + m.end() - m.start()
    return content


def main():
    print("=== MEGA PATCH ===\n")
    print("Step 1: Update ARB files")
    update_arbs()

    print("\nStep 2: Regenerate localizations")
    os.system('flutter gen-l10n')

    print("\nStep 3: Patch Dart files")
    patch_dart_files()

    print("\n=== DONE ===")


if __name__ == '__main__':
    main()
