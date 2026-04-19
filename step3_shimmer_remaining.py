"""
Session 42 — Replace CircularProgressIndicator with shimmer loading
in customer-facing screens.

Targets:
  1. deals_of_day_widget.dart        → ShimmerProductRow
  2. featured_categories_widget.dart  → ShimmerProductRow
  3. recent_orders_widget.dart        → ShimmerProductRow
  4. top_stores_widget.dart           → ShimmerProductRow
  5. order_history_screen.dart        → ShimmerOrderCard list
  6. stores_screen.dart               → ShimmerStoreList
  7. shopping_cart_screen.dart        → ShimmerStoreList

Run: C:\Python314\python.exe step3_shimmer_remaining.py
"""

import os
import re

ROOT = r"C:\dev\kj_delivery_fresh\lib"
SHIMMER_IMPORT = "import '../../../widgets/shimmer_placeholder.dart';"
SHIMMER_IMPORT_2UP = "import '../../widgets/shimmer_placeholder.dart';"

PATCHED = []
FAILED = []


def add_import(content, import_line):
    """Add import if not already present."""
    if "shimmer_placeholder.dart" in content:
        return content
    # Insert after last import line
    lines = content.split("\n")
    last_import_idx = 0
    for i, line in enumerate(lines):
        if line.strip().startswith("import "):
            last_import_idx = i
    lines.insert(last_import_idx + 1, import_line)
    return "\n".join(lines)


def patch_file(rel_path, old_text, new_text, import_line):
    """Replace old_text with new_text in file, add import."""
    full_path = os.path.join(ROOT, rel_path)
    if not os.path.exists(full_path):
        FAILED.append((rel_path, "FILE NOT FOUND"))
        return

    with open(full_path, "r", encoding="utf-8") as f:
        content = f.read()

    if old_text not in content:
        # Try with normalized whitespace
        FAILED.append((rel_path, "PATTERN NOT FOUND"))
        print(f"  SKIP {rel_path} — pattern not found")
        return

    content = content.replace(old_text, new_text, 1)
    content = add_import(content, import_line)

    with open(full_path, "w", encoding="utf-8") as f:
        f.write(content)

    PATCHED.append(rel_path)
    print(f"  OK   {rel_path}")


def patch_regex(rel_path, pattern, replacement, import_line):
    """Regex-based replacement for multi-line patterns."""
    full_path = os.path.join(ROOT, rel_path)
    if not os.path.exists(full_path):
        FAILED.append((rel_path, "FILE NOT FOUND"))
        return

    with open(full_path, "r", encoding="utf-8") as f:
        content = f.read()

    new_content, count = re.subn(pattern, replacement, content, count=1, flags=re.DOTALL)
    if count == 0:
        FAILED.append((rel_path, "REGEX NOT MATCHED"))
        print(f"  SKIP {rel_path} — regex not matched")
        return

    new_content = add_import(new_content, import_line)

    with open(full_path, "w", encoding="utf-8") as f:
        f.write(new_content)

    PATCHED.append(rel_path)
    print(f"  OK   {rel_path}")


def main():
    print("=" * 60)
    print("Session 42 — Shimmer Loading for Remaining Screens")
    print("=" * 60)

    # ── 1. deals_of_day_widget.dart ──
    # Replace the _buildLoadingState method's SizedBox content
    print("\n[1/7] deals_of_day_widget.dart")
    patch_regex(
        r"presentation\home_screen\widgets\deals_of_day_widget.dart",
        # Match the entire _buildLoadingState method
        r"Widget _buildLoadingState\(BuildContext context\) \{.*?return Container\(.*?child: Column\(.*?children: \[.*?Padding\(.*?\),\s*SizedBox\(height: 1\.h\),\s*SizedBox\(\s*height: 28\.h,\s*child: Center\(\s*child: CircularProgressIndicator\(\s*color: Theme\.of\(context\)\.colorScheme\.primary,\s*\),\s*\),\s*\),\s*\],\s*\),\s*\);\s*\}",
        # Replace with shimmer version
        """Widget _buildLoadingState(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'local_fire_department',
                  color: Theme.of(context).colorScheme.error,
                  size: 6.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Deals of the Day',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.h),
          const ShimmerProductRow(),
        ],
      ),
    );
  }""",
        SHIMMER_IMPORT,
    )

    # ── 2. featured_categories_widget.dart ──
    print("\n[2/7] featured_categories_widget.dart")
    patch_file(
        r"presentation\home_screen\widgets\featured_categories_widget.dart",
        """  Widget _buildLoadingState() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      height: 28.h,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }""",
        """  Widget _buildLoadingState() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: const ShimmerProductRow(),
    );
  }""",
        SHIMMER_IMPORT,
    )

    # ── 3. recent_orders_widget.dart ──
    print("\n[3/7] recent_orders_widget.dart")
    patch_file(
        r"presentation\home_screen\widgets\recent_orders_widget.dart",
        """  Widget _buildLoadingState(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      height: 25.h,
      child: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
    );
  }""",
        """  Widget _buildLoadingState(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: const ShimmerProductRow(),
    );
  }""",
        SHIMMER_IMPORT,
    )

    # ── 4. top_stores_widget.dart ──
    print("\n[4/7] top_stores_widget.dart")
    patch_file(
        r"presentation\home_screen\widgets\top_stores_widget.dart",
        """  Widget _buildLoadingState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      child: const Center(child: CircularProgressIndicator()),
    );
  }""",
        """  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: ShimmerProductRow(),
    );
  }""",
        SHIMMER_IMPORT,
    )

    # ── 5. order_history_screen.dart ──
    # Replace the full-screen loading body (Center + Column with spinner + text)
    print("\n[5/7] order_history_screen.dart")
    patch_file(
        r"presentation\order_history_screen\order_history_screen.dart",
        """      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: 2.h),
                  Text('Loading orders...', style: theme.textTheme.bodyMedium),
                ],
              ),
            )""",
        """      body: _isLoading
          ? const ShimmerFullPage()""",
        SHIMMER_IMPORT_2UP,
    )

    # ── 6. stores_screen.dart ──
    print("\n[6/7] stores_screen.dart")
    patch_file(
        r"presentation\stores_screen\stores_screen.dart",
        "_isLoading ? const Center(child: CircularProgressIndicator())",
        "_isLoading ? const ShimmerStoreList()",
        SHIMMER_IMPORT_2UP,
    )

    # ── 7. shopping_cart_screen.dart ──
    print("\n[7/7] shopping_cart_screen.dart")
    patch_file(
        r"presentation\shopping_cart_screen\shopping_cart_screen.dart",
        "loading: () => const Center(child: CircularProgressIndicator()),",
        "loading: () => const ShimmerFullPage(),",
        SHIMMER_IMPORT_2UP,
    )

    # ── Summary ──
    print("\n" + "=" * 60)
    print(f"PATCHED: {len(PATCHED)} files")
    for p in PATCHED:
        print(f"  + {p}")
    if FAILED:
        print(f"\nFAILED:  {len(FAILED)} files")
        for path, reason in FAILED:
            print(f"  ! {path} — {reason}")
    print("\nNow: stop app → flutter clean → rebuild")
    print("=" * 60)


if __name__ == "__main__":
    main()
