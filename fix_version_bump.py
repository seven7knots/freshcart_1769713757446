"""SESSION 44: Bump version from 1.0.0+1 to 1.1.0+2 for Play Store upload."""

file_path = r"C:\dev\kj_delivery_fresh\pubspec.yaml"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

old = "version: 1.0.0+1"
new = "version: 1.1.0+2"

assert old in content, f"ERROR: Could not find '{old}' in pubspec.yaml"
content = content.replace(old, new, 1)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print(f"DONE — version bumped from 1.0.0+1 to 1.1.0+2")
