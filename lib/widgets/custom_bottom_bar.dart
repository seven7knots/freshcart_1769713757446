import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/animated_press_button.dart';
import '../l10n/generated/app_localizations.dart';

/// Custom bottom navigation bar
/// Light mode: Red background, white icons/text
/// Dark mode: Dark surface background, red selected / grey unselected
/// AI Mate icon: auto_awesome (sparkle) instead of smart_toy
///
/// UPDATED: Wrapped in Material so the parent Scaffold can properly measure
/// the bar height and inset the body content above it (fixes 46px overflow).
class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final BottomBarVariant variant;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.variant = BottomBarVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Material(
      elevation: 8,
      color: isLight ? AppTheme.kjRed : AppTheme.surfaceDark,
      child: Container(
        decoration: BoxDecoration(
          color: isLight ? AppTheme.kjRed : AppTheme.surfaceDark,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.10),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: AppLocalizations.of(context)!.home,
                  tooltip: AppLocalizations.of(context)!.browseProducts,
                ),
                _buildNavItem(
                  context: context,
                  index: 1,
                  icon: Icons.search_outlined,
                  activeIcon: Icons.search_rounded,
                  label: AppLocalizations.of(context)!.search,
                  tooltip: AppLocalizations.of(context)!.searchProducts,
                ),
                _buildAiMateNavItem(
                  context: context,
                  index: 2,
                ),
                _buildNavItem(
                  context: context,
                  index: 3,
                  icon: Icons.store_outlined,
                  activeIcon: Icons.store_rounded,
                  label: AppLocalizations.of(context)!.stores,
                  tooltip: AppLocalizations.of(context)!.browseAllStores,
                ),
                _buildNavItem(
                  context: context,
                  index: 4,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: AppLocalizations.of(context)!.profile,
                  tooltip: AppLocalizations.of(context)!.userProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// AI Mate button — uses auto_awesome icon (sparkle)
  Widget _buildAiMateNavItem({
    required BuildContext context,
    required int index,
  }) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final isSelected = currentIndex == index;

    // Colors based on theme
    final Color selectedColor;
    final Color unselectedColor;

    if (isLight) {
      // Light mode: red bar → white icons
      selectedColor = Colors.white;
      unselectedColor = Colors.white.withOpacity(0.60);
    } else {
      // Dark mode: dark bar → red selected, grey unselected
      selectedColor = AppTheme.kjRedDark;
      unselectedColor = theme.colorScheme.onSurfaceVariant;
    }

    return Expanded(
      child: AnimatedPressButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onTap?.call(index);
        },
        child: Tooltip(
          message: AppLocalizations.of(context)!.aiMateYourSmartAssistant,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? selectedColor.withOpacity(isLight ? 0.20 : 0.12)
                      : Colors.transparent,
                ),
                child: Icon(
                  isSelected ? Icons.auto_awesome : Icons.auto_awesome_outlined,
                  color: isSelected ? selectedColor : unselectedColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppLocalizations.of(context)!.aiMate,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? selectedColor : unselectedColor,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String tooltip,
  }) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final isSelected = currentIndex == index;

    // Colors based on theme
    final Color selectedColor;
    final Color unselectedColor;

    if (isLight) {
      // Light mode: red bar → white icons
      selectedColor = Colors.white;
      unselectedColor = Colors.white.withOpacity(0.60);
    } else {
      // Dark mode: dark bar → red selected, grey unselected
      selectedColor = theme.colorScheme.primary;
      unselectedColor = theme.colorScheme.onSurfaceVariant;
    }

    return Expanded(
      child: AnimatedPressButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onTap?.call(index);
        },
        child: Tooltip(
          message: tooltip,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? selectedColor : unselectedColor,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? selectedColor : unselectedColor,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  // No longer used for color — kept for variant API compatibility
  Color _getBackgroundColor(ColorScheme colorScheme) {
    switch (variant) {
      case BottomBarVariant.primary:
        return colorScheme.surface;
      case BottomBarVariant.transparent:
        return colorScheme.surface.withOpacity(0.95);
    }
  }
}

enum BottomBarVariant {
  primary,
  transparent,
}