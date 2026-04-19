import sys

file_path = r"C:\dev\kj_delivery_fresh\lib\presentation\order_tracking_screen\order_tracking_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# ---- FIX 1: Add a cached notifier field after the existing state fields ----
old_fields = '''  bool _hasRated = false;      // SESSION 20: Track if user already rated driver
  bool _hasRatedStore = false; // SESSION 34: Track if user already rated store'''

new_fields = '''  bool _hasRated = false;      // SESSION 20: Track if user already rated driver
  bool _hasRatedStore = false; // SESSION 34: Track if user already rated store

  // SESSION 44: Cache notifier ref so dispose() doesn't crash
  // (ref.read() is illegal after widget unmount)
  dynamic _orderTrackingNotifier;'''

assert old_fields in content, "ERROR: Could not find state fields block"
content = content.replace(old_fields, new_fields, 1)

# ---- FIX 2: Cache the notifier in didChangeDependencies ----
old_dep = '''    if (orderId != null && orderId != _orderId) {
      _orderId = orderId;
      _subscribeToOrder();
    }'''

new_dep = '''    if (orderId != null && orderId != _orderId) {
      _orderId = orderId;
      // SESSION 44: Cache notifier for safe dispose
      _orderTrackingNotifier = ref.read(orderTrackingProvider.notifier);
      _subscribeToOrder();
    }'''

assert old_dep in content, "ERROR: Could not find didChangeDependencies orderId block"
content = content.replace(old_dep, new_dep, 1)

# ---- FIX 3: Replace dispose() to use cached notifier with try-catch ----
old_dispose = '''  @override
  void dispose() {
    ref.read(orderTrackingProvider.notifier).unsubscribe();
    super.dispose();
  }'''

new_dispose = '''  @override
  void dispose() {
    // SESSION 44: Use cached notifier — ref.read() crashes after unmount
    try {
      _orderTrackingNotifier?.unsubscribe();
    } catch (_) {
      // Swallow — widget is being torn down, nothing to do
    }
    super.dispose();
  }'''

assert old_dispose in content, "ERROR: Could not find dispose() block"
content = content.replace(old_dispose, new_dispose, 1)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("DONE — order_tracking_screen.dart patched (dispose crash fixed)")
