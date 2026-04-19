# ============================================================
# KJ Delivery — ProGuard Rules
# ============================================================

# ── Flutter ──────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ── Google Services (Maps, Auth, Analytics) ──────────────────
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ── Stripe (existing rules) ──────────────────────────────────
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider
-keep class com.stripe.** { *; }

# ── Supabase / GoTrue / Realtime ─────────────────────────────
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# ── Keep Gson / JSON serialization from being stripped ───────
-keepattributes Signature
-keepattributes *Annotation*
-keep class * extends com.google.gson.TypeAdapter { *; }