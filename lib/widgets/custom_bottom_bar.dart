import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom bottom navigation bar implementing Contemporary Minimalist Commerce design
/// with adaptive navigation and haptic feedback for grocery delivery app
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
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex.clamp(0, 4), // Ensure valid index
          onTap: (index) {
            // Haptic feedback for better user experience
            HapticFeedback.lightImpact();

            // Call the provided onTap callback
            onTap?.call(index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: _getSelectedColor(colorScheme),
          unselectedItemColor: _getUnselectedColor(colorScheme),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
          items: _buildNavigationItems(context),
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildNavigationItems(BuildContext context) {
    return [
      BottomNavigationBarItem(
        icon: const Icon(Icons.home_outlined),
        activeIcon: const Icon(Icons.home_rounded),
        label: 'Home',
        tooltip: 'Browse products',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.search_outlined),
        activeIcon: const Icon(Icons.search_rounded),
        label: 'Search',
        tooltip: 'Search products',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.shopping_cart_outlined),
        activeIcon: const Icon(Icons.shopping_cart_rounded),
        label: 'Cart',
        tooltip: 'Shopping cart',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.receipt_long_outlined),
        activeIcon: const Icon(Icons.receipt_long_rounded),
        label: 'Orders',
        tooltip: 'Order history',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person_outline_rounded),
        activeIcon: const Icon(Icons.person_rounded),
        label: 'Profile',
        tooltip: 'User profile',
      ),
    ];
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    switch (variant) {
      case BottomBarVariant.primary:
        return colorScheme.surface;
      case BottomBarVariant.transparent:
        return colorScheme.surface.withValues(alpha: 0.95);
    }
  }

  Color _getSelectedColor(ColorScheme colorScheme) {
    return colorScheme.primary;
  }

  Color _getUnselectedColor(ColorScheme colorScheme) {
    return colorScheme.onSurfaceVariant;
  }
}

/// Variants for different bottom bar styles
enum BottomBarVariant {
  primary,
  transparent,
}
