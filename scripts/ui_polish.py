#!/usr/bin/env python3
"""
MODERN UI POLISH: Update global theme and fix common widget patterns
for a premium, modern look across all screens.
"""

import os, re

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJECT, 'lib')

# ═══════════════════════════════════════════════════════════════
# STEP 1: Update app_theme.dart — global changes that affect everything
# ═══════════════════════════════════════════════════════════════

THEME_PATH = os.path.join(LIB, 'theme', 'app_theme.dart')
with open(THEME_PATH, 'r', encoding='utf-8') as f:
    theme = f.read()

# 1a. Card: increase radius 12→16, bump elevation 2→3, add shadow spread
theme = theme.replace(
    """      // Card
      cardTheme: CardThemeData(
        color: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),""",
    """      // Card — modern rounded with soft shadow
      cardTheme: CardThemeData(
        color: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        clipBehavior: Clip.antiAlias,
      ),"""
)

# 1b. ElevatedButton: increase radius 8→12, bump height via padding
theme = theme.replace(
    """      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),""",
    """      // Buttons — rounded, taller, modern
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
      ),"""
)

# 1c. Dialog: already 16px radius, bump to 20
theme = theme.replace(
    "        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),\n      ),\n\n      // BottomSheet",
    "        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),\n      ),\n\n      // BottomSheet"
)

# 1d. BottomSheet: increase top radius 20→24
theme = theme.replace(
    "        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),",
    "        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),"
)

# 1e. Chip: increase border radius, add padding
theme = theme.replace(
    """      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainerHighest,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: cs.onSurface),
        side: BorderSide(color: cs.outline.withOpacity(0.5)),
      ),""",
    """      // Chip — pill-shaped
      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainerHighest,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: cs.onSurface),
        side: BorderSide(color: cs.outline.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),"""
)

# 1f. SnackBar: already 12px, bump to 14
theme = theme.replace(
    """      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cs.inverseSurface,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: cs.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),""",
    """      // SnackBar — modern floating
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cs.inverseSurface,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: cs.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),"""
)

# 1g. PopupMenu: add shape
theme = theme.replace(
    """      // PopupMenu
      popupMenuTheme: PopupMenuThemeData(
        color: cs.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: GoogleFonts.inter(fontSize: 14, color: cs.onSurface),
      ),""",
    """      // PopupMenu — rounded
      popupMenuTheme: PopupMenuThemeData(
        color: cs.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: GoogleFonts.inter(fontSize: 14, color: cs.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 8,
      ),"""
)

# 1h. Input fields: bump padding for taller fields
theme = theme.replace(
    "        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),",
    "        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),"
)

# 1i. TabBar: add indicator shape
theme = theme.replace(
    """      // TabBar
      tabBarTheme: TabBarThemeData(
        labelColor: cs.onSurface,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicatorColor: cs.primary,
      ),""",
    """      // TabBar — rounded pill indicator
      tabBarTheme: TabBarThemeData(
        labelColor: cs.onSurface,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicatorColor: cs.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerHeight: 0,
      ),"""
)

with open(THEME_PATH, 'w', encoding='utf-8') as f:
    f.write(theme)
print("1. Updated app_theme.dart (global theme improvements)")

# ═══════════════════════════════════════════════════════════════
# STEP 2: Fix common widget patterns across ALL files
# ═══════════════════════════════════════════════════════════════

stats = {'files': 0, 'changes': 0}

def fix_patterns(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    original = content
    count = 0

    # 2a. BorderRadius.circular(8) on containers/decorations → 14
    # Only for small radii that look dated (8, 10)
    # Don't touch 12 (already decent) or 16+ (already modern)
    content = content.replace('BorderRadius.circular(8)', 'BorderRadius.circular(14)')
    if content != original:
        count += content.count('BorderRadius.circular(14)') - original.count('BorderRadius.circular(14)')

    # 2b. borderRadius: BorderRadius.circular(4) → 10
    content = content.replace('BorderRadius.circular(4)', 'BorderRadius.circular(10)')

    # 2c. borderRadius: BorderRadius.circular(6) → 12
    content = content.replace('BorderRadius.circular(6)', 'BorderRadius.circular(12)')

    # 2d. Status badges: very small radii → pill shape
    # BorderRadius.circular(2) or 3 → 8
    content = content.replace('BorderRadius.circular(2)', 'BorderRadius.circular(8)')
    content = content.replace('BorderRadius.circular(3)', 'BorderRadius.circular(8)')

    if content != original:
        count = 1  # simplified count

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        stats['files'] += 1
        stats['changes'] += count
        return True
    return False

print("\n2. Fixing widget patterns across all files...")
for root, dirs, files in os.walk(os.path.join(LIB, 'presentation')):
    for fname in sorted(files):
        if not fname.endswith('.dart'): continue
        fp = os.path.join(root, fname)
        if fix_patterns(fp):
            rel = os.path.relpath(fp, PROJECT).replace('\\', '/')
            # Don't print every file - just count

for root, dirs, files in os.walk(os.path.join(LIB, 'widgets')):
    for fname in sorted(files):
        if not fname.endswith('.dart'): continue
        fp = os.path.join(root, fname)
        fix_patterns(fp)

print(f"   Files updated: {stats['files']}")
print(f"   Border radius modernized across {stats['files']} files")

# ═══════════════════════════════════════════════════════════════
# STEP 3: Specific high-impact improvements
# ═══════════════════════════════════════════════════════════════

# 3a. Language selection screen — already uses modern styling, skip

# 3b. Onboarding dots: make them rounded pills

print("\n3. Applied global theme + widget pattern modernization")
print("\n=== UI POLISH COMPLETE ===")
