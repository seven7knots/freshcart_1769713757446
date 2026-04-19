"""SESSION 44: Remove onboarding page 4 (Loyalty Rewards) — robust version."""

file_path = r"C:\dev\kj_delivery_fresh\lib\presentation\onboarding_screen\onboarding_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

# Find the block that contains "Loyalty Rewards"
start_idx = None
end_idx = None

for i, line in enumerate(lines):
    if "Loyalty Rewards" in line:
        # Walk backwards to find the opening brace of this map entry
        for j in range(i, -1, -1):
            if lines[j].strip() == "{":
                start_idx = j
                break
        # Walk forward to find the closing brace + comma
        for j in range(i, len(lines)):
            stripped = lines[j].strip()
            if stripped == "}," or stripped == "}":
                end_idx = j
                break
        break

assert start_idx is not None, "ERROR: Could not find Loyalty Rewards block start"
assert end_idx is not None, "ERROR: Could not find Loyalty Rewards block end"

print(f"Found page 4 block at lines {start_idx+1}-{end_idx+1}")
print(f"Removing {end_idx - start_idx + 1} lines")

# Remove those lines
del lines[start_idx:end_idx + 1]

with open(file_path, "w", encoding="utf-8") as f:
    f.writelines(lines)

print("DONE — Onboarding page 4 (Loyalty Rewards) removed. Now 3 pages.")

# Also find and delete the onboarding_4 image
import os
import glob
img_patterns = [
    r"C:\dev\kj_delivery_fresh\assets\images\onboarding\onboarding_4.*",
    r"C:\dev\kj_delivery_fresh\assets\images\onboarding\onboarding4.*",
]
for pattern in img_patterns:
    for f in glob.glob(pattern):
        os.remove(f)
        print(f"Deleted image: {f}")

# List remaining onboarding images
onb_dir = r"C:\dev\kj_delivery_fresh\assets\images\onboarding"
if os.path.exists(onb_dir):
    print(f"\nRemaining onboarding images:")
    for f in os.listdir(onb_dir):
        print(f"  {f}")
