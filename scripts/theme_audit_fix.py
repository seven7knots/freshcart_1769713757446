#!/usr/bin/env python3
"""
THEME AUDIT: Replace hardcoded colors with theme-aware alternatives.
Preserves brand red (#E50913) and white-on-red intentional styling.

Strategy:
- Colors.white for backgrounds → theme.colorScheme.surface
- Colors.white for text → theme.colorScheme.onPrimary (on colored bg) or theme.colorScheme.onSurface
- Colors.black for text → theme.colorScheme.onSurface
- Colors.black87 for text → theme.colorScheme.onSurface
- Colors.grey → theme.colorScheme.onSurfaceVariant (text) or theme.colorScheme.outline (borders)
- Colors.grey[100/200] backgrounds → theme.colorScheme.surfaceContainerHighest
- Colors.grey[300] → theme.colorScheme.outlineVariant
- Colors.grey[600/700] → theme.colorScheme.onSurfaceVariant
- Color(0xFF212121) etc → theme.colorScheme.onSurface
- Color(0xFFF5F5F5) etc → theme.scaffoldBackgroundColor
- boxShadow black → theme.shadowColor

Context-aware: only replace when it's clear the color is for
text/background/icon, not when it's part of a brand-colored widget.
"""

import os, re

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJECT, 'lib')

stats = {'files': 0, 'replacements': 0}

# Lines containing these keywords indicate the color is on a branded/primary
# background where white IS correct (e.g., white text on red AppBar)
BRAND_CONTEXT_KEYWORDS = [
    'AppTheme.kjRed', 'kjRed', 'primary', 'E50913', 'E50914',
    'backgroundColor: Colors.red', 'backgroundColor: AppTheme',
    'ElevatedButton.styleFrom', 'backgroundColor: theme.colorScheme.primary',
    'Colors.green', 'Colors.blue', 'Colors.red', 'Colors.orange',
    'SnackBar', 'FloatingActionButton',
]

def is_on_brand_background(line, prev_lines):
    """Check if this line is in a context where white/black is intentional."""
    context = line + ' '.join(prev_lines[-5:])
    for kw in BRAND_CONTEXT_KEYWORDS:
        if kw in context:
            return True
    return False


def fix_colors_in_file(filepath):
    """Replace hardcoded colors with theme-aware alternatives."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    lines = content.split('\n')
    new_lines = []
    reps = 0

    # Check if file already has theme variable
    has_theme_var = 'final theme = Theme.of(context)' in content or 'theme = Theme.of(context)' in content

    for i, line in enumerate(lines):
        orig_line = line
        prev = lines[max(0,i-5):i]

        # Skip comments
        stripped = line.strip()
        if stripped.startswith('//'):
            new_lines.append(line)
            continue

        # ── BACKGROUNDS ──

        # Colors.grey[100] → theme.colorScheme.surfaceContainerHighest
        if 'Colors.grey[100]' in line and 'backgroundColor' in line:
            line = line.replace('Colors.grey[100]', 'theme.colorScheme.surfaceContainerHighest')
            reps += 1
        if 'Colors.grey[200]' in line and ('background' in line.lower() or 'color:' in line):
            line = line.replace('Colors.grey[200]', 'theme.colorScheme.surfaceContainerHighest')
            reps += 1

        # Colors.white as container/card background (NOT on red buttons)
        # Pattern: color: Colors.white in Container/decoration context
        if re.search(r'(?:color|backgroundColor):\s*Colors\.white\b', line):
            if not is_on_brand_background(line, prev):
                # Check if this is clearly a background (not foreground)
                if 'foregroundColor' not in line and 'textColor' not in line:
                    line = re.sub(r'((?:color|backgroundColor):\s*)Colors\.white\b', r'\1theme.colorScheme.surface', line)
                    reps += 1

        # Color(0xFFFFFFFF) background
        if 'Color(0xFFFFFFFF)' in line and 'foreground' not in line:
            if not is_on_brand_background(line, prev):
                line = line.replace('Color(0xFFFFFFFF)', 'theme.colorScheme.surface')
                reps += 1

        # Color(0xFFF5F5F5) light grey background
        if 'Color(0xFFF5F5F5)' in line:
            line = line.replace('Color(0xFFF5F5F5)', 'theme.scaffoldBackgroundColor')
            reps += 1

        # Color(0xFFF8F8F8) / Color(0xFFFAFAFA) light backgrounds
        for hex_bg in ['Color(0xFFF8F8F8)', 'Color(0xFFFAFAFA)', 'Color(0xFFEEEEEE)',
                       'Color(0xFFF0F0F0)', 'Color(0xFFE8E8E8)']:
            if hex_bg in line:
                line = line.replace(hex_bg, 'theme.colorScheme.surfaceContainerHighest')
                reps += 1

        # ── TEXT COLORS ──

        # Colors.black87 for text → onSurface
        if 'Colors.black87' in line:
            if 'foreground' in line or 'color:' in line.lower() or 'TextStyle' in line:
                line = line.replace('Colors.black87', 'theme.colorScheme.onSurface')
                reps += 1

        # Colors.black for text/icon (NOT shadows or overlays)
        if 'Colors.black' in line and 'Colors.black87' not in line:
            # Only replace if it's clearly for text/icon, not shadow/overlay
            if '.withOpacity' not in line and '.withValues' not in line and '.withAlpha' not in line:
                if any(kw in line for kw in ['color:', 'TextStyle', 'Icon(', 'foreground']):
                    if not is_on_brand_background(line, prev):
                        line = line.replace('Colors.black', 'theme.colorScheme.onSurface')
                        reps += 1

        # Colors.grey[600] / Colors.grey[700] / Colors.grey.shade600 for text
        for shade in ['Colors.grey[600]', 'Colors.grey[700]', 'Colors.grey.shade600', 'Colors.grey.shade700']:
            if shade in line:
                line = line.replace(shade, 'theme.colorScheme.onSurfaceVariant')
                reps += 1

        # Colors.grey[300] for borders/dividers
        if 'Colors.grey[300]' in line:
            line = line.replace('Colors.grey[300]', 'theme.colorScheme.outlineVariant')
            reps += 1
        if 'Colors.grey[400]' in line:
            line = line.replace('Colors.grey[400]', 'theme.colorScheme.outline')
            reps += 1

        # Plain Colors.grey for text → onSurfaceVariant
        if re.search(r'Colors\.grey\b(?!\[)', line):
            if 'TextStyle' in line or 'color:' in line or 'Icon(' in line:
                line = re.sub(r'Colors\.grey\b(?!\[)', 'theme.colorScheme.onSurfaceVariant', line)
                reps += 1

        # ── HARDCODED HEX COLORS ──

        # Dark text colors
        for dark_hex in ['Color(0xFF212121)', 'Color(0xFF1A1A1A)', 'Color(0xFF111111)',
                         'Color(0xFF333333)', 'Color(0xFF2D2D2D)']:
            if dark_hex in line:
                line = line.replace(dark_hex, 'theme.colorScheme.onSurface')
                reps += 1

        # Medium grey text
        for med_hex in ['Color(0xFF666666)', 'Color(0xFF757575)', 'Color(0xFF9E9E9E)',
                        'Color(0xFF888888)', 'Color(0xFF999999)', 'Color(0xFF444444)']:
            if med_hex in line:
                line = line.replace(med_hex, 'theme.colorScheme.onSurfaceVariant')
                reps += 1

        # Light grey borders
        for lt_hex in ['Color(0xFFE0E0E0)', 'Color(0xFFBDBDBD)', 'Color(0xFFCCCCCC)',
                       'Color(0xFFDDDDDD)', 'Color(0xFFD5D5D5)']:
            if lt_hex in line:
                line = line.replace(lt_hex, 'theme.colorScheme.outlineVariant')
                reps += 1

        # ── DIALOG / BOTTOM SHEET BACKGROUNDS ──

        # backgroundColor: Colors.white in showDialog/showModalBottomSheet
        # Already handled by the general Colors.white background rule above

        if line != orig_line:
            new_lines.append(line)
        else:
            new_lines.append(orig_line)

    content = '\n'.join(new_lines)

    if reps > 0 and content != original:
        # Ensure 'theme' variable is available
        # If we used theme.xxx but there's no theme variable, we need to check
        # Most files already have: final theme = Theme.of(context);
        # For files that don't, we can't safely add it (we don't know where context is)
        # So we verify and skip if theme is not defined

        if 'theme.' in content and not has_theme_var:
            # Check if theme is used as a parameter name in the method
            if 'ThemeData theme' not in content and ', theme,' not in content:
                # Revert - we can't use theme without it being defined
                content = original
                reps = 0

    if content != original and reps > 0:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        stats['files'] += 1
        stats['replacements'] += reps
        return True
    return False


def main():
    print("=== THEME AUDIT FIX ===\n")

    dart_files = []
    for root, dirs, files in os.walk(os.path.join(LIB, 'presentation')):
        for fname in sorted(files):
            if fname.endswith('.dart'):
                dart_files.append(os.path.join(root, fname))
    for root, dirs, files in os.walk(os.path.join(LIB, 'widgets')):
        for fname in sorted(files):
            if fname.endswith('.dart'):
                dart_files.append(os.path.join(root, fname))

    print(f"Scanning {len(dart_files)} files...\n")

    for filepath in dart_files:
        if fix_colors_in_file(filepath):
            rel = os.path.relpath(filepath, PROJECT).replace('\\', '/')
            print(f"  {rel}")

    print(f"\n=== RESULTS ===")
    print(f"  Files modified: {stats['files']}")
    print(f"  Color replacements: {stats['replacements']}")


if __name__ == '__main__':
    main()
