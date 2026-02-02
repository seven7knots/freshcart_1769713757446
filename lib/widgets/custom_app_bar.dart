import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_export.dart';
import './custom_image_widget.dart';

/// Custom app bar widget implementing Contemporary Minimalist Commerce design
/// with contextual actions and adaptive behavior for grocery delivery app
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final AppBarVariant variant;
  final VoidCallback? onCartPressed;
  final int? cartItemCount;
  final VoidCallback? onSearchPressed;
  final bool showSearch;
  final bool showCart;
  final bool showLogo;
  final bool pinned;
  final bool floating;

  const CustomAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle = false,
    this.variant = AppBarVariant.primary,
    this.onCartPressed,
    this.cartItemCount,
    this.onSearchPressed,
    this.showSearch = true,
    this.showCart = true,
    this.showLogo = true,
    this.pinned = true,
    this.floating = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      title: title != null ? Text(title!) : null,
      leading: showLogo ? _buildLogoLeading(context) : leading,
      automaticallyImplyLeading: !showLogo && automaticallyImplyLeading,
      centerTitle: centerTitle,
      elevation: variant == AppBarVariant.transparent ? 0 : 0,
      backgroundColor: _getBackgroundColor(colorScheme),
      foregroundColor: _getForegroundColor(colorScheme),
      surfaceTintColor:
          variant == AppBarVariant.transparent ? Colors.transparent : null,
      systemOverlayStyle: _getSystemOverlayStyle(),
      actions: _buildActions(context),
      scrolledUnderElevation: 2,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
    );
  }

  Widget _buildLogoLeading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CustomImageWidget(
        imageUrl: 'assets/images/image-1761892441301.png',
        width: 40,
        height: 40,
        fit: BoxFit.contain,
        semanticLabel:
            'KJ Delivery App Logo - Black line-art icon of a grocery bag filled with fresh produce including leafy vegetables, bottle, and herbs. Darker and bolder version for better visibility.',
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final List<Widget> actionWidgets = [];

    // Search action
    if (showSearch) {
      actionWidgets.add(
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: onSearchPressed ?? () => _navigateToSearch(context),
          tooltip: 'Search products',
        ),
      );
    }

    // Cart action with badge
    if (showCart) {
      actionWidgets.add(
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: onCartPressed ?? () => _navigateToCart(context),
                tooltip: 'Shopping cart',
              ),
              if (cartItemCount != null && cartItemCount! > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      cartItemCount! > 99 ? '99+' : cartItemCount.toString(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onError,
                            fontWeight: FontWeight.w600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Add custom actions if provided
    if (actions != null) {
      actionWidgets.addAll(actions!);
    }

    return actionWidgets;
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    switch (variant) {
      case AppBarVariant.primary:
        return colorScheme.surface;
      case AppBarVariant.transparent:
        return Colors.transparent;
      case AppBarVariant.surface:
        return colorScheme.surface;
    }
  }

  Color _getForegroundColor(ColorScheme colorScheme) {
    switch (variant) {
      case AppBarVariant.primary:
        return colorScheme.onSurface;
      case AppBarVariant.transparent:
        return colorScheme.onSurface;
      case AppBarVariant.surface:
        return colorScheme.onSurface;
    }
  }

  SystemUiOverlayStyle _getSystemOverlayStyle() {
    switch (variant) {
      case AppBarVariant.primary:
        return SystemUiOverlayStyle.dark;
      case AppBarVariant.transparent:
        return SystemUiOverlayStyle.dark;
      case AppBarVariant.surface:
        return SystemUiOverlayStyle.dark;
    }
  }

  void _navigateToSearch(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/search-screen');
  }

  void _navigateToCart(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/shopping-cart-screen');
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Variants for different app bar styles
enum AppBarVariant {
  primary,
  transparent,
  surface,
}
