# KJ DELIVERY — PRE-PUBLISH AUDIT — CLAUDE CODE HANDOFF v2

**Date:** April 18, 2026
**Previous session:** Claude.ai (web) — completed Items 1–2
**This session:** Claude Code (terminal) — complete Items 3–12

---

## PERSON & WORKFLOW PREFERENCES (READ FIRST)

- Operator: **Amir Al Andary**, founder of SevenKnots (sevenknots.co), Lebanon.
- Test device: **Samsung S23 Ultra**.
- Test credentials: `customer@sevenknots.com` / `KJtest2026!`
- **Be proactive and directive.** Lead, don't ask. Move fast. No unnecessary back-and-forth.
- **PowerShell only** — use semicolons (`;`) never `&&` for command chaining.
- **Dart file edits:** use Python patch scripts — PowerShell corrupts `${}` interpolation.
- **Deploys:** `npx vercel --prod` (never git push).
- For large file replacements, prefer full-file writes over diffs.
- Use `Select-String` to verify deployments; unique filenames to avoid browser cache.

---

## PROJECT FACTS

- **Flutter project:** `C:\dev\kj_delivery_fresh`
- **Package:** `com.kjdelivery.app`
- **Last version:** `1.1.0+3` (probably bump to `1.1.0+4` after this audit)
- **Supabase project ID:** `uwjmeitzpxvohmqxfaxy` (region `ap-south-1`, Postgres 17.6.1, ACTIVE_HEALTHY)
- **Supabase MCP:** connected — you can run SQL directly.
- **Play Console:** Amir Al Andary, `seven7knots@gmail.com`, account ID `5444382569401952151`, Personal account, **verified & restriction lifted**. App in **Draft**.
- **Privacy policy URL:** `https://kjdelivery.com/privacy`
- **App icon color:** `#E50913`

---

## ITEM 1 — SSL & DOMAIN ✅ COMPLETE

- `https://kjdelivery.com/privacy` loads cleanly over HTTPS. Certificate is valid past the April 15 feared-expiry.
- Privacy policy content is comprehensive (covers Supabase, Google Maps, Firebase, Gemini, location, children's privacy, user rights).
- **Minor note:** privacy page shows only a phone number as contact. That's fine — Play Console sets the contact email separately.

---

## ITEM 2 — SUPABASE BACKEND ✅ COMPLETE

### What was found

- 54 public tables, 157 indexes, 138 existing RLS policies, 3 storage buckets (`marketplace-images`, `ads-images`, `uploads` — all public).
- **8 tables had RLS enabled with ZERO policies** (effectively locked out for auth users):
  `deliveries`, `driver_location_history`, `order_status_history`, `product_reviews`, `withdrawal_requests`, `audit_logs`, `ad_campaigns`, `meal_plans`.
- **`debug_auth` SECURITY DEFINER view** existed in public schema — auth-leak risk.
- **Realtime publication was EMPTY** — no live updates for any feature.
- **3 permissive policies** with `USING (true)` grants: `categories.authenticated_manage_categories` (ALL), `driver_ratings.Service role full access` (ALL on public), `notifications.Service can insert notifications` (INSERT on public).

### What was fixed (migration: `prepublish_audit_rls_realtime_fixes` — already applied)

1. **Dropped** `public.debug_auth` view.
2. **Dropped** `categories.authenticated_manage_categories`; added `admin_manage_categories` (admin-only writes, public read via existing `public_read_categories` stays).
3. **Dropped** `driver_ratings.Service role full access` (service_role bypasses RLS natively — policy was redundant hole).
4. **Replaced** `notifications.Service can insert notifications` with `notifications_authenticated_insert` (authenticated-only INSERT).
5. **Added full RLS policies** to the 5 user-facing zero-policy tables: `deliveries`, `driver_location_history`, `order_status_history`, `product_reviews`, `withdrawal_requests` — driver/customer/merchant/admin matrix mirroring existing `orders` patterns (admin check: `EXISTS (SELECT 1 FROM users u WHERE u.id=auth.uid() AND u.role='admin')`; driver check: `driver_id IN (SELECT id FROM drivers WHERE user_id=auth.uid())` with a fallback `OR driver_id = auth.uid()` for rows where it's stored directly; merchant check: via `stores.owner_user_id = auth.uid()`).
6. **Left untouched** (per Amir's decision): `audit_logs`, `ad_campaigns`, `meal_plans` — admin/service-role only, zero policies is intentional.
7. **Added to `supabase_realtime` publication:** `orders`, `order_status_history`, `deliveries`, `driver_location_history`, `messages`, `notifications`.
8. **Set `REPLICA IDENTITY FULL`** on those 6 tables so UPDATE events carry the full row (Flutter side needs full row for live tracking).

### ⚠️ CRITICAL FOLLOW-UP FOR CLAUDE CODE

The realtime fix is **database-side only**. You MUST verify the Flutter code actually subscribes to these channels. Grep the Dart source:

```powershell
cd C:\dev\kj_delivery_fresh
Get-ChildItem -Recurse -Include *.dart | Select-String -Pattern "onPostgresChanges|\.stream\(|RealtimeChannel" | Select-Object Path, LineNumber, Line
```

Specifically confirm subscriptions exist for:
- `orders` (customer order tracking screen, merchant incoming orders screen, driver assigned orders screen)
- `order_status_history` (customer tracking screen timeline)
- `driver_location_history` (customer live map)
- `deliveries` (driver dashboard)
- `notifications` (in-app notification bell)
- `messages` (customer↔driver chat, if exists)

If any subscription is missing, add it using the Supabase Flutter SDK pattern:

```dart
final channel = Supabase.instance.client
  .channel('orders-user-${userId}')
  .onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'orders',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'user_id',
      value: userId,
    ),
    callback: (payload) { /* handle */ },
  )
  .subscribe();
```

**Non-blocking Supabase items to leave for post-publish:**
- 50+ functions missing `SET search_path` — security best practice, no functional impact.
- PostGIS extension lives in `public` schema — cosmetic.
- Leaked password protection disabled in Auth (enable in Supabase dashboard → Authentication → Policies).
- Public storage buckets allow listing (minor enumeration exposure).

---

## ITEM 3 — APP BUILD & VERSION (START HERE)

Run in PowerShell:

```powershell
cd C:\dev\kj_delivery_fresh
Select-String -Path pubspec.yaml -Pattern "^version:"
Select-String -Path android\app\build.gradle -Pattern "signingConfig|versionCode|versionName"
Test-Path android\key.properties
Test-Path android\app\upload-keystore.jks
git status
git log -1 --format="%h %s %ci"
```

**Expected:** version `1.1.0+3`, keystore files present, release signing configured.

**Action after verification:**
1. Bump `pubspec.yaml` to `version: 1.1.0+4` (new build code for Play Store — required for every AAB upload).
2. `flutter clean ; flutter pub get`
3. `flutter build appbundle --dart-define-from-file=.env`
4. Verify output at `build\app\outputs\bundle\release\app-release.aab` (~65–75 MB expected).
5. `flutter build apk --dart-define-from-file=.env --split-per-abi` for side-load testing on S23 Ultra.

---

## ITEM 4 — FIREBASE SERVICES

1. `google-services.json` sanity check:
   ```powershell
   Select-String -Path android\app\google-services.json -Pattern "package_name|project_id"
   ```
   `package_name` must equal `com.kjdelivery.app`.
2. **FCM test:** trigger a test notification from Firebase Console → Cloud Messaging → Send test message, targeting the S23 Ultra's FCM token (grab from `users` table: `SELECT fcm_token FROM users WHERE email='customer@sevenknots.com'`).
3. **Crashlytics:** force a test crash from a debug build with `FirebaseCrashlytics.instance.crash()`, then verify it appears in Firebase Console → Crashlytics within ~5 min.

---

## ITEM 5 — API KEYS & CREDENTIALS

Check `.env` and platform config files for production values (NOT dev keys). Expected keys:

```powershell
Select-String -Path .env -Pattern "SUPABASE_URL|SUPABASE_ANON_KEY|GOOGLE_MAPS|GEMINI|GOOGLE_CLIENT_ID"
```

- `SUPABASE_URL` = `https://uwjmeitzpxvohmqxfaxy.supabase.co`
- `SUPABASE_ANON_KEY` = the publishable (anon) key from Supabase dashboard
- `GOOGLE_MAPS_API_KEY` = has Android + Places API enabled, restricted to `com.kjdelivery.app` + SHA-1
- `GEMINI_API_KEY` = valid for AI Mate chatbot
- Google OAuth client ID = matches SHA-1 of release keystore (critical — if wrong, Google Sign-In silently fails on prod)

**SHA-1 of release keystore** (must match Google Cloud Console OAuth client):
```powershell
keytool -list -v -keystore android\app\upload-keystore.jks -alias upload
```

---

## ITEMS 6–9 — FUNCTIONAL TESTING (BY ROLE)

Install the release APK on S23 Ultra:
```powershell
adb install -r build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

Walk the full matrix:

### Customer (test account: customer@sevenknots.com / KJtest2026!)
- Login (Google + Phone OTP)
- Browse → Category → Merchant → Product
- Search (full-text + fallback)
- AI Mate chatbot Q&A
- Add to cart → close/reopen (persistence)
- Checkout with Maps autocomplete
- Place cash-on-delivery order
- Track order through 5 statuses (placed → accepted → preparing → picked up → delivered) — watch for **live map updates** (this is the realtime fix landing)
- Receive push on each status change
- Rate merchant + driver

### Merchant
- Dashboard (today's orders, revenue)
- Receive new order alert
- Accept/reject with one tap
- Queue: new → preparing → ready
- Add/edit/delete product
- Open/close toggle
- Business hours

### Driver
- Online/offline toggle
- Receive delivery request
- Accept/reject
- Pickup & dropoff on map
- Status updates: picked up → on the way → delivered
- Earnings dashboard

### Admin
- Dashboard metrics
- User management
- Merchant & driver approval flows
- Order management with filters
- Category management (now admin-only after migration)
- Push broadcaster

---

## ITEM 10 — PLAY STORE LISTING

Go to Play Console → KJ Delivery → **Main store listing**, verify:

- App name: `KJ Delivery`
- Short description (≤80 chars)
- Full description (≤4000 chars)
- App icon (#E50913, 512×512)
- Feature graphic (1024×500)
- Phone screenshots (min 2, all current)
- Category: Food & Drink (or Lifestyle)
- Contact email: set (Play Console-level, not on privacy page)
- Privacy policy URL: `https://kjdelivery.com/privacy`

Content rating questionnaire and target audience must be completed — these are separate sections from Main store listing. Check **App content** → all sections green.

---

## ITEM 11 — DATA SAFETY

Play Console → App content → **Data safety**. Reflect accurately:
- Collects: Name, Email, Phone, Location (approximate + precise), Order history, Device ID, Crash logs, App interactions, Messages (if chat).
- Data is encrypted in transit: **Yes**.
- Users can request data deletion: **Yes** (via `kjdelivery.com/privacy` contact).
- Data shared with third parties: list Supabase, Firebase/Google, Google Maps, Gemini.

---

## ITEM 12 — LEGAL & COMPLIANCE FINAL SWEEP

```powershell
Get-ChildItem -Recurse -Include *.dart | Select-String -Pattern "TODO|FIXME|XXX|Lorem|placeholder|test.test|dummy" | Select-Object Path, LineNumber, Line
```

Walk the output — anything user-visible is a blocker. Anything in dev-only files is fine.

---

## POST-AUDIT PUBLISH FLOW

1. Upload AAB via Play Console → Production → Create new release.
2. Release name: `1.1.0 (4)`.
3. Release notes (English + Arabic):
   - EN: "Initial public release — order food, groceries, and more from local stores across Lebanon."
   - AR: "الإطلاق العام الأول — اطلب طعامك ومستلزماتك من المتاجر المحلية في لبنان."
4. Review changes → Submit for review.
5. First-time app review: 3–7 days is realistic (Google's stated 1–3 day range is the floor).
6. Monitor Play Console → Inbox for any policy flags; respond within 24h if one appears.

---

## IF YOU HIT A SUPABASE ISSUE IN THIS SESSION

You have the Supabase MCP. Re-run the security advisor after any schema change:

```
Call get_advisors(project_id='uwjmeitzpxvohmqxfaxy', type='security')
```

The project has `REPLICA IDENTITY FULL` set on the 6 realtime tables — don't undo that.

---

## RUNNING TALLY

- Item 1 SSL & Privacy: ✅
- Item 2 Supabase Backend: ✅
- Item 3 Build & Version: **START HERE**
- Items 4–12: pending

*Handoff generated April 18, 2026 by Claude (web) for Claude Code continuation.*
