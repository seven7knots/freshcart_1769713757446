import sys

file_path = r"C:\dev\kj_delivery_fresh\lib\presentation\order_tracking_screen\order_tracking_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# FIX: Wrap _subscribeToOrder() in addPostFrameCallback so it runs AFTER the build
# This is the patched version (after fix_order_tracking_dispose.py was applied)
old_block = '''    if (orderId != null && orderId != _orderId) {
      _orderId = orderId;
      // SESSION 44: Cache notifier for safe dispose
      _orderTrackingNotifier = ref.read(orderTrackingProvider.notifier);
      _subscribeToOrder();
    }'''

new_block = '''    if (orderId != null && orderId != _orderId) {
      _orderId = orderId;
      // SESSION 44: Cache notifier for safe dispose
      _orderTrackingNotifier = ref.read(orderTrackingProvider.notifier);
      // SESSION 44: Defer to avoid "modify provider during build" crash
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _subscribeToOrder();
      });
    }'''

assert old_block in content, "ERROR: Could not find didChangeDependencies block (was fix 1 applied?)"
content = content.replace(old_block, new_block, 1)

# Also need the WidgetsBinding import — it comes from flutter/widgets.dart
# which is already pulled in via flutter/material.dart, so no new import needed.

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("DONE — order_tracking_screen.dart patched (provider-during-build crash fixed)")
