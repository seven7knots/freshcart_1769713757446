#!/usr/bin/env python3
r"""
KJ Delivery - Fix UTC timestamps to display in local time
Run from: C:\dev\kj_delivery_fresh
Usage: C:\Python314\python.exe fix_utc_timestamps.py
"""

import os

PROJECT = os.getcwd()
fixes = []

def patch_file(rel_path, old_str, new_str, description):
    full_path = os.path.join(PROJECT, rel_path)
    if not os.path.exists(full_path):
        print(f"  SKIP (not found): {rel_path}")
        return False
    
    with open(full_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if old_str not in content:
        print(f"  SKIP (pattern not found): {rel_path}")
        print(f"    Looking for: {old_str[:80]}...")
        return False
    
    content = content.replace(old_str, new_str, 1)
    with open(full_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    fixes.append(rel_path)
    print(f"  FIXED: {rel_path}")
    print(f"    {description}")
    return True


print("=" * 60)
print("KJ Delivery - Fix UTC Timestamps to Local Time")
print("=" * 60)

# === 1. admin_applications_screen.dart:566 ===
print("\n--- Fix 1: Admin Applications Screen ---")
patch_file(
    r"lib\presentation\admin_applications_screen\admin_applications_screen.dart",
    "return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';",
    "final local = date.toLocal();\n    return '${local.day}/${local.month}/${local.year} at ${local.hour}:${local.minute.toString().padLeft(2, '0')}';",
    "Added .toLocal() for admin application timestamps"
)

# === 2. AI chat message_bubble_widget.dart:475 ===
print("\n--- Fix 2: AI Chat Message Bubble ---")
patch_file(
    r"lib\presentation\ai_chat_assistant_screen\widgets\message_bubble_widget.dart",
    "return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';",
    "final local = timestamp.toLocal();\n    return '${local.hour}:${local.minute.toString().padLeft(2, '0')}';",
    "Added .toLocal() for AI chat message timestamps"
)

# === 3. driver_home_screen.dart:619 ===
print("\n--- Fix 3: Driver Home Screen ---")
patch_file(
    r"lib\presentation\driver_home_screen\driver_home_screen.dart",
    "'Ordered: ${createdAt.day}/${createdAt.month} at ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}'",
    "'Ordered: ${createdAt.toLocal().day}/${createdAt.toLocal().month} at ${createdAt.toLocal().hour}:${createdAt.toLocal().minute.toString().padLeft(2, '0')}'",
    "Added .toLocal() for driver order timestamps"
)

# === 4. enhanced_order_management_screen.dart:643 ===
print("\n--- Fix 4: Enhanced Order Management ---")
patch_file(
    r"lib\presentation\enhanced_order_management_screen\enhanced_order_management_screen.dart",
    "'${createdAt.day}/${createdAt.month} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}'",
    "'${createdAt.toLocal().day}/${createdAt.toLocal().month} ${createdAt.toLocal().hour}:${createdAt.toLocal().minute.toString().padLeft(2, '0')}'",
    "Added .toLocal() for order management timestamps"
)

# === 5. marketplace_chat message_bubble_widget.dart:158 ===
print("\n--- Fix 5: Marketplace Chat Message Bubble ---")
patch_file(
    r"lib\presentation\marketplace_chat_screen\widgets\message_bubble_widget.dart",
    "return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';",
    "final local = timestamp.toLocal();\n    return '${local.hour}:${local.minute.toString().padLeft(2, '0')}';",
    "Added .toLocal() for marketplace chat timestamps"
)

# === 6. merchant_analytics_screen.dart:387 ===
print("\n--- Fix 6: Merchant Analytics (display) ---")
patch_file(
    r"lib\presentation\merchant_analytics_screen\merchant_analytics_screen.dart",
    "? '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}'",
    "? '${createdAt.toLocal().day}/${createdAt.toLocal().month}/${createdAt.toLocal().year} ${createdAt.toLocal().hour}:${createdAt.toLocal().minute.toString().padLeft(2, '0')}'",
    "Added .toLocal() for merchant analytics timestamps"
)

# === 7. merchant_analytics_screen.dart:670-671 (hour counting) ===
print("\n--- Fix 7: Merchant Analytics (hour counts) ---")
patch_file(
    r"lib\presentation\merchant_analytics_screen\merchant_analytics_screen.dart",
    "hourCounts[createdAt.hour] =\n                (hourCounts[createdAt.hour] ?? 0) + 1;",
    "hourCounts[createdAt.toLocal().hour] =\n                (hourCounts[createdAt.toLocal().hour] ?? 0) + 1;",
    "Added .toLocal() for merchant analytics hour distribution"
)

# === 8. merchant_store_screen.dart:785 ===
print("\n--- Fix 8: Merchant Store Screen ---")
patch_file(
    r"lib\presentation\merchant_store_screen\merchant_store_screen.dart",
    "'${createdAt.day}/${createdAt.month} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}'",
    "'${createdAt.toLocal().day}/${createdAt.toLocal().month} ${createdAt.toLocal().hour}:${createdAt.toLocal().minute.toString().padLeft(2, '0')}'",
    "Added .toLocal() for merchant store order timestamps"
)

# === Summary ===
print("\n" + "=" * 60)
print(f"DONE! Fixed {len(fixes)} files:")
for f in fixes:
    print(f"  - {f}")
print()
print("All timestamps now convert from UTC to device local time.")
print("Lebanon (EET) = UTC+2 (winter) / UTC+3 (summer DST)")
print()
print("Next: Cold rerun on OPPO to verify:")
print('  flutter run --dart-define=... -d GUHEAYS8JR4H9TVW')
