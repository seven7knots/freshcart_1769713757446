"""SESSION 44: Remove onboarding page 4 (Loyalty Rewards & Savings) entirely."""

file_path = r"C:\dev\kj_delivery_fresh\lib\presentation\onboarding_screen\onboarding_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

old_page4 = """    {
      "title": "Loyalty Rewards\\n& Savings",
      "description":
          "Earn points with every purchase and unlock exclusive deals. Save more while shopping for premium quality groceries.",
      "imageUrl":
          "assets/images/onboarding/onboarding_4.jpg",
      "semanticLabel":
          "Golden loyalty card with reward points and discount badges surrounded by fresh groceries and coins",
    },"""

assert old_page4 in content, "ERROR: Could not find onboarding page 4 block"
content = content.replace(old_page4, "", 1)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("DONE — Onboarding page 4 (Loyalty Rewards) removed. Now 3 pages.")
