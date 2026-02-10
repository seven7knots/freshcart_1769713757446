import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/animated_press_button.dart';

/// Custom bottom navigation bar implementing Contemporary Minimalist Commerce design
/// with adaptive navigation and haptic feedback.
///
/// UPDATED:
/// - Removed Cart from bottom bar (cart is only in the top bar now)
/// - Added AI Mate at index 2 (replaces Cart)
/// - Final order: Home(0), Search(1), AI Mate(2), Stores(3), Profile(4)
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
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: _getBackgroundColor(colorScheme),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
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
                label: 'Home',
                tooltip: 'Browse products',
              ),
              _buildNavItem(
                context: context,
                index: 1,
                icon: Icons.search_outlined,
                activeIcon: Icons.search_rounded,
                label: 'Search',
                tooltip: 'Search products',
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
                label: 'Stores',
                tooltip: 'Browse all stores',
              ),
              _buildNavItem(
                context: context,
                index: 4,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                tooltip: 'User profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Special AI Mate button with brand red accent
  Widget _buildAiMateNavItem({
    required BuildContext context,
    required int index,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = currentIndex == index;

    return Expanded(
      child: AnimatedPressButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onTap?.call(index);
        },
        child: Tooltip(
          message: 'AI Mate – Your smart assistant',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppTheme.kjRed.withOpacity(0.12)
                      : Colors.transparent,
                ),
                child: Icon(
                  isSelected ? Icons.smart_toy : Icons.smart_toy_outlined,
                  color: isSelected ? AppTheme.kjRed : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'AI Mate',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? AppTheme.kjRed : colorScheme.onSurfaceVariant,
                ),
              ),
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
    final colorScheme = theme.colorScheme;
    final isSelected = currentIndex == index;

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
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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