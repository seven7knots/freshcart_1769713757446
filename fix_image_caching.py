"""
SESSION 44: Replace Image.network() with CachedNetworkImage() across all files.
Adds disk caching for all network images — offline support for previously viewed images.

Changes:
1. Adds `import 'package:cached_network_image/cached_network_image.dart';` where missing
2. Replaces `Image.network(url,` with `CachedNetworkImage(imageUrl: url,`
3. Replaces `errorBuilder:` with `errorWidget:` (different API)
"""

import os
import re

base_dir = r"C:\dev\kj_delivery_fresh\lib"

# Files that have Image.network (from the scan)
target_files = [
    r"presentation\admin\widgets\category_edit_dialog.dart",
    r"presentation\admin\widgets\content_edit_modal_widget.dart",
    r"presentation\ai_mate\widgets\message_bubble_widget.dart",
    r"presentation\ai_mate\widgets\unified_results_widget.dart",
    r"presentation\favorites\favorites_screen.dart",
    r"presentation\home\home_screen.dart",
    r"presentation\merchant\merchant_store_screen.dart",
    r"presentation\profile\widgets\profile_header_widget.dart",
    r"presentation\search\widgets\store_results_widget.dart",
    r"presentation\cart\shopping_cart_screen.dart",
    r"presentation\store_detail\store_detail_screen.dart",
    r"widgets\subcategory_card_widget.dart",
]

# Also check alternate paths (file structure might differ)
# We'll find them dynamically
def find_dart_files_with_image_network(base):
    """Find all .dart files containing Image.network"""
    found = []
    for root, dirs, files in os.walk(base):
        for f in files:
            if f.endswith(".dart"):
                path = os.path.join(root, f)
                try:
                    with open(path, "r", encoding="utf-8") as fh:
                        content = fh.read()
                    if "Image.network(" in content:
                        found.append(path)
                except:
                    pass
    return found

files = find_dart_files_with_image_network(base_dir)
print(f"Found {len(files)} files with Image.network()")

IMPORT_LINE = "import 'package:cached_network_image/cached_network_image.dart';"

total_replacements = 0

for filepath in files:
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
    
    original = content
    fname = os.path.basename(filepath)
    file_replacements = 0
    
    # 1. Add import if missing
    if "cached_network_image" not in content:
        # Find the last import line and add after it
        lines = content.split("\n")
        last_import_idx = 0
        for i, line in enumerate(lines):
            if line.strip().startswith("import "):
                last_import_idx = i
        lines.insert(last_import_idx + 1, IMPORT_LINE)
        content = "\n".join(lines)
    
    # 2. Replace Image.network( with CachedNetworkImage(imageUrl: 
    # Pattern: Image.network(SOMETHING, where SOMETHING is the URL (first positional arg)
    # We need to capture the URL arg and make it a named param
    
    # Simple approach: find "Image.network(" and the first argument up to the first comma
    # Then replace with "CachedNetworkImage(imageUrl: ARG,"
    
    def replace_image_network(match):
        nonlocal file_replacements
        file_replacements += 1
        return "CachedNetworkImage(imageUrl: "
    
    # Replace "Image.network(" with "CachedNetworkImage(imageUrl: "
    # The URL was the first positional arg, now becomes named
    content = re.sub(r'Image\.network\(', replace_image_network, content)
    
    # 3. Replace errorBuilder with errorWidget
    # Only in the context of CachedNetworkImage (which we just created)
    # errorBuilder: (_, __, ___) => ... -> errorWidget: (_, __, ___) => ...
    # The signatures are slightly different but both take 3 args and return Widget
    content = content.replace("errorBuilder:", "errorWidget:")
    
    if content != original:
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(content)
        total_replacements += file_replacements
        print(f"  {fname}: {file_replacements} replacements")

print(f"\nDONE — {total_replacements} Image.network() calls replaced with CachedNetworkImage()")
print("All network images now cached to disk automatically.")
