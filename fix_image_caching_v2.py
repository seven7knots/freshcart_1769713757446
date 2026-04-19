"""
SESSION 44: Replace Image.network() with CachedNetworkImage() across all files.
"""

import os
import re

base_dir = r"C:\dev\kj_delivery_fresh\lib"

def find_dart_files_with_image_network(base):
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

    # 1. Add import if missing
    if "cached_network_image" not in content:
        lines = content.split("\n")
        last_import_idx = 0
        for i, line in enumerate(lines):
            if line.strip().startswith("import "):
                last_import_idx = i
        lines.insert(last_import_idx + 1, IMPORT_LINE)
        content = "\n".join(lines)

    # 2. Count and replace Image.network( -> CachedNetworkImage(imageUrl:
    count = content.count("Image.network(")
    content = content.replace("Image.network(", "CachedNetworkImage(imageUrl: ")

    # 3. Replace errorBuilder with errorWidget (CachedNetworkImage API)
    content = content.replace("errorBuilder:", "errorWidget:")

    if content != original:
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(content)
        total_replacements += count
        print(f"  {fname}: {count} replacements")

print(f"\nDONE — {total_replacements} Image.network() replaced with CachedNetworkImage()")
