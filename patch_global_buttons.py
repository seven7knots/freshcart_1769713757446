"""Issue 2: Global button system fix.

- Rewrite ElevatedButtonThemeData (state-aware bg, overlay, 56 height, text height 1.3).
- Add OutlinedButtonThemeData and TextButtonThemeData with matching overlay.
- Fix AI Meal Planning Generate / Regenerate / Add-to-Cart (green) buttons.
- Fix Shopping Cart Checkout minimumSize.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent


def patch_theme(path: Path) -> None:
    s = path.read_text(encoding='utf-8')

    # Replace ElevatedButtonThemeData block + insert OutlinedButton / TextButton overlay
    old_elevated = """      // Buttons — rounded, taller, modern
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),"""

    new_elevated = """      // Buttons — rounded, modern, brand-aware pressed state.
      // overlayColor/backgroundColor resolve states so press darkens to #B8070F
      // instead of Flutter's default white-wash tint on bright red.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          minimumSize: WidgetStateProperty.all(const Size(double.infinity, 56)),
          tapTargetSize: MaterialTapTargetSize.padded,
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          elevation: WidgetStateProperty.all(0),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return cs.onSurface.withOpacity(0.5);
            }
            return cs.onPrimary;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return cs.onSurface.withOpacity(0.12);
            }
            if (states.contains(WidgetState.pressed)) {
              return const Color(0xFFB8070F);
            }
            return cs.primary;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return const Color(0xFFB8070F).withOpacity(0.15);
            }
            if (states.contains(WidgetState.hovered)) {
              return const Color(0xFFB8070F).withOpacity(0.08);
            }
            return null;
          }),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          minimumSize: WidgetStateProperty.all(const Size(double.infinity, 52)),
          tapTargetSize: MaterialTapTargetSize.padded,
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return const Color(0xFFB8070F).withOpacity(0.12);
            }
            return null;
          }),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return const Color(0xFFB8070F);
            }
            return cs.primary;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return const Color(0xFFB8070F).withOpacity(0.1);
            }
            return null;
          }),
        ),
      ),"""

    if old_elevated not in s:
        raise SystemExit("theme: ElevatedButtonThemeData block not found verbatim")
    s = s.replace(old_elevated, new_elevated)
    path.write_text(s, encoding='utf-8')
    print(f"patched {path.relative_to(ROOT)}")


def patch_meal_planning(path: Path) -> None:
    s = path.read_text(encoding='utf-8')

    # 1) Generate Meal Plan button — remove SizedBox fixed height, use styleFrom-compatible sizing.
    old_generate = """              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generateMealPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3.w),
                    ),
                  ),
                  child: _isGenerating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          AppLocalizations.of(context)!.generateMealPlan,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),"""

    new_generate = """              ElevatedButton(
                onPressed: _isGenerating ? null : _generateMealPlan,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isGenerating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.2,
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.generateMealPlan,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
              ),"""

    if old_generate not in s:
        raise SystemExit("meal planning: Generate button block not found verbatim")
    s = s.replace(old_generate, new_generate)

    # 2) Add Grocery List to Cart (green bar) — replace fixed SizedBox with Container + Material + InkWell.
    old_green = """        // Add to Cart button
        SizedBox(
          width: double.infinity,
          height: 6.h,
          child: ElevatedButton.icon(
            onPressed: _isAddingToCart ? null : _addAllToCart,
            icon: _isAddingToCart
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.shopping_cart, color: Colors.white),
            label: Text(
              _isAddingToCart ? AppLocalizations.of(context)!.addingToCart : AppLocalizations.of(context)!.addGroceryListToCart,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3.w)),
            ),
          ),
        ),"""

    new_green = """        // Add to Cart bar — Container + InkWell so press feedback is a clean white overlay,
        // not a wash-out. minHeight 56 for proper tap target; Expanded label with ellipsis.
        Material(
          color: Colors.green.shade700,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _isAddingToCart ? null : _addAllToCart,
            splashColor: Colors.white.withOpacity(0.2),
            highlightColor: Colors.white.withOpacity(0.1),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isAddingToCart
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.shopping_cart, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isAddingToCart
                            ? AppLocalizations.of(context)!.addingToCart
                            : AppLocalizations.of(context)!.addGroceryListToCart,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),"""

    if old_green not in s:
        raise SystemExit("meal planning: green Add-to-Cart block not found verbatim")
    s = s.replace(old_green, new_green)

    # 3) Regenerate Plan outlined button — remove fixed height, let theme size it.
    old_regen = """        SizedBox(
          width: double.infinity,
          height: 5.h,
          child: OutlinedButton.icon(
            onPressed: _isGenerating ? null : _generateMealPlan,
            icon: const Icon(Icons.refresh, color: Colors.white70),
            label: Text(
              AppLocalizations.of(context)!.regeneratePlan,
              style: TextStyle(color: Colors.white70, fontSize: 13.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3.w)),
            ),
          ),
        ),"""

    new_regen = """        OutlinedButton.icon(
          onPressed: _isGenerating ? null : _generateMealPlan,
          icon: const Icon(Icons.refresh, color: Colors.white70),
          label: Text(
            AppLocalizations.of(context)!.regeneratePlan,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            side: const BorderSide(color: Colors.white24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),"""

    if old_regen not in s:
        raise SystemExit("meal planning: Regenerate block not found verbatim")
    s = s.replace(old_regen, new_regen)

    path.write_text(s, encoding='utf-8')
    print(f"patched {path.relative_to(ROOT)}")


def patch_shopping_cart(path: Path) -> None:
    s = path.read_text(encoding='utf-8')
    old = "style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 52)),"
    new = "style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),"
    if old not in s:
        raise SystemExit("shopping cart: Checkout minimumSize line not found verbatim")
    s = s.replace(old, new)
    path.write_text(s, encoding='utf-8')
    print(f"patched {path.relative_to(ROOT)}")


patch_theme(ROOT / 'lib/theme/app_theme.dart')
patch_meal_planning(ROOT / 'lib/presentation/ai_meal_planning_screen/ai_meal_planning_screen.dart')
patch_shopping_cart(ROOT / 'lib/presentation/shopping_cart_screen/shopping_cart_screen.dart')
print("done")
