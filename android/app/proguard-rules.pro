# KJ Delivery ProGuard Rules
# Keep Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.location.** { *; }

# Keep Firebase
-keep class com.google.firebase.** { *; }

# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**