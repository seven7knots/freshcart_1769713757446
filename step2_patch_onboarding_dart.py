"""
Step 2: Patch onboarding Dart files to use local assets instead of Unsplash URLs.
Run from project root: C:\Python314\python.exe step2_patch_onboarding_dart.py
"""

import os
import re

PROJECT_ROOT = r"C:\dev\kj_delivery_fresh"

# URL-to-asset mapping
URL_MAP = {
    "https://images.unsplash.com/photo-1730145313984-838b35077667": "assets/images/onboarding/onboarding_1.jpg",
    "https://images.unsplash.com/photo-1572504586329-2650fedc583d": "assets/images/onboarding/onboarding_2.jpg",
    "https://images.unsplash.com/photo-1544365712-91cd4904cd07": "assets/images/onboarding/onboarding_3.jpg",
    "https://images.unsplash.com/photo-1614110073736-1778d27f588a": "assets/images/onboarding/onboarding_4.jpg",
}


def patch_onboarding_screen():
    """Replace Unsplash URLs with asset paths in onboarding_screen.dart"""
    filepath = os.path.join(
        PROJECT_ROOT,
        "lib", "presentation", "onboarding_screen", "onboarding_screen.dart",
    )
    if not os.path.exists(filepath):
        print(f"NOT FOUND: {filepath}")
        return False

    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    original = content
    replacements = 0

    for url, asset_path in URL_MAP.items():
        # Match the full URL including any query params (w=, q=, etc.)
        pattern = re.escape(url) + r'[^\'\"]*'
        matches = re.findall(pattern, content)
        if matches:
            for match in matches:
                # Replace the URL string with asset path
                content = content.replace(match, asset_path)
                replacements += 1
                print(f"  Replaced URL → {asset_path}")

    if replacements == 0:
        print(f"  WARNING: No URLs found in {os.path.basename(filepath)}")
        print("  Printing lines 25-65 for manual inspection:")
        lines = original.split("\n")
        for i, line in enumerate(lines[24:65], start=25):
            if "unsplash" in line.lower() or "image" in line.lower() or "http" in line.lower():
                print(f"    L{i}: {line.rstrip()}")
        return False

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"  PATCHED onboarding_screen.dart ({replacements} URL(s) replaced)")
    return True


def patch_slide_widget():
    """
    Replace CustomImageWidget(imageUrl: ...) with Image.asset(...) in
    onboarding_slide_widget.dart.

    Handles two possible patterns:
      1. CustomImageWidget(imageUrl: 'assets/...')
      2. CustomImageWidget(imageUrl: variable)
    """
    # Try to find the slide widget file
    search_dir = os.path.join(PROJECT_ROOT, "lib", "presentation", "onboarding_screen")
    slide_file = None

    for root, dirs, files in os.walk(search_dir):
        for f in files:
            if "slide" in f.lower() and f.endswith(".dart"):
                slide_file = os.path.join(root, f)
                break
    
    if not slide_file:
        # Also check widgets/ subfolder
        widgets_dir = os.path.join(search_dir, "widgets")
        if os.path.exists(widgets_dir):
            for f in os.listdir(widgets_dir):
                if "slide" in f.lower() and f.endswith(".dart"):
                    slide_file = os.path.join(widgets_dir, f)
                    break

    if not slide_file:
        print(f"  WARNING: Could not find slide widget file in {search_dir}")
        print("  Searching broader...")
        for root, dirs, files in os.walk(os.path.join(PROJECT_ROOT, "lib")):
            for f in files:
                if "onboarding" in f.lower() and "slide" in f.lower():
                    print(f"    Found: {os.path.join(root, f)}")
        return False

    print(f"  Found slide widget: {slide_file}")

    with open(slide_file, "r", encoding="utf-8") as f:
        content = f.read()

    original = content

    # Pattern 1: CustomImageWidget(imageUrl: 'assets/images/onboarding/...')
    # Replace with Image.asset('assets/images/onboarding/...', fit: BoxFit.cover)
    pattern1 = r"CustomImageWidget\(\s*imageUrl:\s*['\"]([^'\"]+)['\"]\s*(?:,\s*[^)]+)?\)"
    
    def replace_with_asset(match):
        path = match.group(1)
        if path.startswith("assets/"):
            return f"Image.asset(\n                '{path}',\n                fit: BoxFit.cover,\n                width: double.infinity,\n              )"
        # If it's still a URL (shouldn't happen after step 2a), leave it
        return match.group(0)

    new_content = re.sub(pattern1, replace_with_asset, content)

    # Pattern 2: CustomImageWidget(imageUrl: someVariable)
    # Replace with Image.asset(someVariable, fit: BoxFit.cover)
    pattern2 = r"CustomImageWidget\(\s*imageUrl:\s*([a-zA-Z_][a-zA-Z0-9_.]*)\s*(?:,\s*[^)]+)?\)"

    def replace_with_asset_var(match):
        var_name = match.group(1)
        return f"Image.asset(\n                {var_name},\n                fit: BoxFit.cover,\n                width: double.infinity,\n              )"

    new_content = re.sub(pattern2, replace_with_asset_var, new_content)

    if new_content == original:
        print("  WARNING: No CustomImageWidget patterns found")
        print("  Showing image-related lines for manual inspection:")
        for i, line in enumerate(original.split("\n"), start=1):
            low = line.lower()
            if "image" in low or "custom" in low or "asset" in low:
                print(f"    L{i}: {line.rstrip()}")
        return False

    with open(slide_file, "w", encoding="utf-8") as f:
        f.write(new_content)

    print(f"  PATCHED {os.path.basename(slide_file)}")
    return True


def patch_pubspec():
    """Ensure assets/images/onboarding/ is declared in pubspec.yaml"""
    pubspec_path = os.path.join(PROJECT_ROOT, "pubspec.yaml")
    
    with open(pubspec_path, "r", encoding="utf-8") as f:
        content = f.read()

    asset_line = "    - assets/images/onboarding/"

    if "assets/images/onboarding/" in content:
        print("  pubspec.yaml already has onboarding asset path")
        return True

    # Find the assets: section and add our line
    # Look for existing asset declarations
    if "assets:" not in content:
        print("  ERROR: No 'assets:' section found in pubspec.yaml")
        print("  Please add manually under flutter:")
        print("    assets:")
        print(f"  {asset_line}")
        return False

    # Insert after the last existing asset line
    lines = content.split("\n")
    insert_idx = None
    in_assets = False

    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped == "assets:" or stripped.startswith("assets:"):
            in_assets = True
            insert_idx = i + 1
            continue
        if in_assets:
            if stripped.startswith("- "):
                insert_idx = i + 1
            elif stripped and not stripped.startswith("#"):
                # End of assets section
                break

    if insert_idx is not None:
        lines.insert(insert_idx, asset_line)
        with open(pubspec_path, "w", encoding="utf-8") as f:
            f.write("\n".join(lines))
        print(f"  PATCHED pubspec.yaml (added onboarding asset path at line {insert_idx + 1})")
        return True
    else:
        print("  WARNING: Could not find insertion point in pubspec.yaml")
        print(f"  Please add manually: {asset_line}")
        return False


def main():
    print("=" * 60)
    print("KJ Delivery — Onboarding Local Assets Patch")
    print("=" * 60)

    # Verify images exist
    img_dir = os.path.join(PROJECT_ROOT, "assets", "images", "onboarding")
    missing = []
    for i in range(1, 5):
        path = os.path.join(img_dir, f"onboarding_{i}.jpg")
        if not os.path.exists(path):
            missing.append(f"onboarding_{i}.jpg")
    
    if missing:
        print(f"\nERROR: Missing images in {img_dir}:")
        for m in missing:
            print(f"  - {m}")
        print("\nRun step1_download_onboarding_images.py first!")
        return

    print("\n[1/3] Patching onboarding_screen.dart (URLs → asset paths)...")
    patch_onboarding_screen()

    print("\n[2/3] Patching slide widget (CustomImageWidget → Image.asset)...")
    patch_slide_widget()

    print("\n[3/3] Patching pubspec.yaml (declare asset folder)...")
    patch_pubspec()

    print("\n" + "=" * 60)
    print("DONE. Now:")
    print("  1. Stop the app")
    print("  2. Run: flutter clean")
    print("  3. Rebuild and deploy to device")
    print("=" * 60)


if __name__ == "__main__":
    main()
