import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom tab bar widget implementing Contemporary Minimalist Commerce design
/// with smooth animations and haptic feedback for grocery delivery app
class CustomTabBar extends StatelessWidget implements PreferredSizeWidget {
  final List<String> tabs;
  final TabController? controller;
  final ValueChanged<int>? onTap;
  final TabBarVariant variant;
  final bool isScrollable;
  final EdgeInsetsGeometry? labelPadding;

  const CustomTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.onTap,
    this.variant = TabBarVariant.primary,
    this.isScrollable = false,
    this.labelPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: _getBackgroundColor(colorScheme),
        border: variant == TabBarVariant.outlined
            ? Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              )
            : null,
      ),
      child: TabBar(
        controller: controller,
        onTap: (index) => _handleTap(context, index),
        tabs: _buildTabs(context),
        isScrollable: isScrollable,
        labelPadding: labelPadding ??
            (isScrollable
                ? const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                : const EdgeInsets.symmetric(vertical: 12)),
        labelColor: _getLabelColor(colorScheme),
        unselectedLabelColor: _getUnselectedLabelColor(colorScheme),
        labelStyle: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
        indicator: _buildIndicator(colorScheme),
        indicatorSize: TabBarIndicatorSize.label,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }

  List<Widget> _buildTabs(BuildContext context) {
    return tabs.map((tab) => Tab(text: tab)).toList();
  }

  void _handleTap(BuildContext context, int index) {
    // Haptic feedback for tab selection
    HapticFeedback.lightImpact();

    // Call the provided onTap callback
    onTap?.call(index);
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    switch (variant) {
      case TabBarVariant.primary:
        return colorScheme.surface;
      case TabBarVariant.outlined:
        return colorScheme.surface;
      case TabBarVariant.transparent:
        return Colors.transparent;
    }
  }

  Color _getLabelColor(ColorScheme colorScheme) {
    return colorScheme.primary;
  }

  Color _getUnselectedLabelColor(ColorScheme colorScheme) {
    return colorScheme.onSurfaceVariant;
  }

  Decoration _buildIndicator(ColorScheme colorScheme) {
    switch (variant) {
      case TabBarVariant.primary:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: colorScheme.primary,
        );
      case TabBarVariant.outlined:
        return BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.primary,
              width: 2,
            ),
          ),
        );
      case TabBarVariant.transparent:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: colorScheme.primary.withValues(alpha: 0.1),
        );
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);
}

/// Variants for different tab bar styles
enum TabBarVariant {
  primary,
  outlined,
  transparent,
}
