"""
Step 1: Download onboarding images from Unsplash and save as local assets.
Run from project root: C:\Python314\python.exe step1_download_onboarding_images.py
"""

import os
import urllib.request

PROJECT_ROOT = r"C:\dev\kj_delivery_fresh"
OUTPUT_DIR = os.path.join(PROJECT_ROOT, "assets", "images", "onboarding")

# Unsplash URLs mapped to local filenames
# Using w=800 quality for good mobile display without bloating APK
IMAGES = {
    "onboarding_1.jpg": "https://images.unsplash.com/photo-1730145313984-838b35077667?w=800&q=80",
    "onboarding_2.jpg": "https://images.unsplash.com/photo-1572504586329-2650fedc583d?w=800&q=80",
    "onboarding_3.jpg": "https://images.unsplash.com/photo-1544365712-91cd4904cd07?w=800&q=80",
    "onboarding_4.jpg": "https://images.unsplash.com/photo-1614110073736-1778d27f588a?w=800&q=80",
}

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print(f"Saving to: {OUTPUT_DIR}\n")

    for filename, url in IMAGES.items():
        dest = os.path.join(OUTPUT_DIR, filename)
        if os.path.exists(dest):
            print(f"SKIP  {filename} (already exists)")
            continue
        print(f"Downloading {filename} ...")
        try:
            urllib.request.urlretrieve(url, dest)
            size_kb = os.path.getsize(dest) / 1024
            print(f"  OK  {size_kb:.0f} KB")
        except Exception as e:
            print(f"  FAIL  {e}")

    print("\nDone! Now run step2_patch_onboarding_dart.py")

if __name__ == "__main__":
    main()
