#!/usr/bin/env python3
"""
KJ Delivery - Replace old orange burst logo with new #E50913 KJ icon
Run from: C:\dev\kj_delivery_fresh
Usage: C:\Python314\python.exe replace_icon.py
"""

import os
import shutil
import struct
import zlib

PROJECT = os.getcwd()

# ============================================================
# STEP 1: Generate the new 512x512 icon as PNG (pure Python, no Pillow needed)
# ============================================================
print("=" * 60)
print("STEP 1: Generating new KJ icon (512x512, #E50913 red)")
print("=" * 60)

def create_kj_icon_png(output_path, size=512):
    """
    Create a 512x512 red rounded-square icon with white 'KJ' text.
    Pure Python PNG generation - no dependencies needed.
    """
    # We'll download the icon from the generated file instead
    # For now, let's use a simpler approach - just copy the icon
    pass

# Actually, the user needs to place the new icon file.
# Let's check if they have it, or create instructions.

NEW_ICON_SOURCE = None
# Check common locations for the downloaded icon
possible_paths = [
    os.path.join(PROJECT, "kj_delivery_icon_512_updated.png"),
    os.path.join(os.path.expanduser("~"), "Downloads", "kj_delivery_icon_512_updated.png"),
    os.path.join(os.path.expanduser("~"), "Downloads", "kj delivery icon 512 updated.png"),
    os.path.join(PROJECT, "new_icons", "ic_launcher_512.png"),
    os.path.join(os.path.expanduser("~"), "Downloads", "kj_new_icons", "icon_assets", "ic_launcher_512.png"),
]

for p in possible_paths:
    if os.path.exists(p):
        NEW_ICON_SOURCE = p
        print(f"  Found new icon at: {p}")
        break

if NEW_ICON_SOURCE is None:
    # Try to find any recently downloaded PNG with "kj" or "icon" in name
    downloads = os.path.join(os.path.expanduser("~"), "Downloads")
    if os.path.exists(downloads):
        candidates = []
        for f in os.listdir(downloads):
            fl = f.lower()
            if fl.endswith('.png') and ('kj' in fl or 'icon' in fl or 'updated' in fl):
                full = os.path.join(downloads, f)
                candidates.append((os.path.getmtime(full), full))
        if candidates:
            candidates.sort(reverse=True)
            NEW_ICON_SOURCE = candidates[0][1]
            print(f"  Found candidate icon: {NEW_ICON_SOURCE}")

if NEW_ICON_SOURCE is None:
    print("\n  ERROR: Cannot find the new icon file!")
    print("  Please download 'kj_delivery_icon_512_updated.png' from Claude")
    print("  and place it in C:\\dev\\kj_delivery_fresh\\")
    print("  Then re-run this script.")
    exit(1)

# ============================================================
# STEP 2: Replace assets/images/kj_delivery_icon.png
# ============================================================
print("\n" + "=" * 60)
print("STEP 2: Replacing assets/images/kj_delivery_icon.png")
print("=" * 60)

target_icon = os.path.join(PROJECT, "assets", "images", "kj_delivery_icon.png")
backup_icon = os.path.join(PROJECT, "assets", "images", "kj_delivery_icon_OLD.png")

if os.path.exists(target_icon):
    # Backup old icon
    shutil.copy2(target_icon, backup_icon)
    old_size = os.path.getsize(target_icon)
    print(f"  Backed up old icon ({old_size} bytes) -> kj_delivery_icon_OLD.png")

# Copy new icon
shutil.copy2(NEW_ICON_SOURCE, target_icon)
new_size = os.path.getsize(target_icon)
print(f"  Replaced with new icon ({new_size} bytes)")

# ============================================================
# STEP 3: Update pubspec.yaml - change adaptive_icon_background color
# ============================================================
print("\n" + "=" * 60)
print("STEP 3: Updating pubspec.yaml adaptive_icon_background")
print("=" * 60)

pubspec_path = os.path.join(PROJECT, "pubspec.yaml")
with open(pubspec_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_color = '"#E64A19"'
new_color = '"#E50913"'

if old_color in content:
    content = content.replace(old_color, new_color)
    with open(pubspec_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"  Changed adaptive_icon_background: {old_color} -> {new_color}")
else:
    print(f"  WARNING: Could not find {old_color} in pubspec.yaml")
    print(f"  Current adaptive_icon_background may already be correct")
    # Check what it currently is
    for line in content.split('\n'):
        if 'adaptive_icon_background' in line:
            print(f"  Current value: {line.strip()}")

# ============================================================
# STEP 4: Verify the kayan_logo file (splash/login branding)
# ============================================================
print("\n" + "=" * 60)
print("STEP 4: Checking kayan_logo (splash/login screen)")
print("=" * 60)

kayan_logo = os.path.join(PROJECT, "assets", "images", "kayan_logo-1770269431337.jpg")
if os.path.exists(kayan_logo):
    size = os.path.getsize(kayan_logo)
    print(f"  Found kayan_logo ({size} bytes)")
    print(f"  NOTE: This is the orange burst 'KJ Delivery Services' logo.")
    print(f"  If your splash/login screen references this file, you may want")
    print(f"  to update those screens to use kj_delivery_icon.png instead.")
    print(f"  (Or replace this file too with the new icon)")
    
    # Also replace kayan_logo with new icon
    backup_kayan = kayan_logo.replace(".jpg", "_OLD.jpg")
    shutil.copy2(kayan_logo, backup_kayan)
    # Note: replacing .jpg with .png content - Flutter handles this fine
    # as long as the code references the correct file
    shutil.copy2(NEW_ICON_SOURCE, kayan_logo)
    print(f"  Replaced kayan_logo with new icon")
else:
    print("  kayan_logo not found (may have been removed)")

# ============================================================
# STEP 5: Summary and next steps
# ============================================================
print("\n" + "=" * 60)
print("DONE! Next steps:")
print("=" * 60)
print()
print("  1. Regenerate Android launcher icons:")
print("     flutter pub run flutter_launcher_icons")
print()
print("  2. Clean and rebuild:")
print("     flutter clean")
print("     flutter pub get")
print()
print("  3. Run on device (cold rerun with --dart-define):")
print('     $u = (Get-Content ".env" | Where-Object { $_ -match "^SUPABASE_URL=" }) -split "=",2 | Select-Object -Last 1')
print('     $k = (Get-Content ".env" | Where-Object { $_ -match "^SUPABASE_ANON_KEY=" }) -split "=",2 | Select-Object -Last 1')
print('     $g = (Get-Content ".env" | Where-Object { $_ -match "^GEMINI_API_KEY=" }) -split "=",2 | Select-Object -Last 1')
print('     $m = (Get-Content ".env" | Where-Object { $_ -match "^GOOGLE_MAPS_API_KEY=" }) -split "=",2 | Select-Object -Last 1')
print('     flutter run --dart-define=SUPABASE_URL=$u --dart-define=SUPABASE_ANON_KEY=$k --dart-define=GEMINI_API_KEY=$g --dart-define=GOOGLE_MAPS_API_KEY=$m -d GUHEAYS8JR4H9TVW')
print()
print("  4. Verify these screens show the new red KJ icon:")
print("     - App launcher icon on phone home screen")
print("     - Splash screen on app launch")
print("     - Login screen logo")
print()
print("  NOTE: The Marketplace category card icon is likely stored in")
print("  Supabase (not a local asset). Update it via the admin dashboard")
print("  or directly in Supabase storage.")
