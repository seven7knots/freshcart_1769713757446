// ============================================================
// FILE: lib/presentation/marketplace_screen/widgets/marketplace_search_bar_widget.dart
// ============================================================
// SESSION 28 REDESIGN:
// - Cleaner, more modern search field
// - Better visual weight and rounded style
// ============================================================

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';

class MarketplaceSearchBarWidget extends StatefulWidget {
  final Function(String) onSearchChanged;

  const MarketplaceSearchBarWidget({super.key, required this.onSearchChanged});

  @override
  State<MarketplaceSearchBarWidget> createState() =>
      _MarketplaceSearchBarWidgetState();
}

class _MarketplaceSearchBarWidgetState
    extends State<MarketplaceSearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 0.5.h),
      child: TextField(
        controller: _controller,
        onChanged: widget.onSearchChanged,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 13.sp,
        ),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchListings,
          hintStyle: TextStyle(
            fontSize: 13.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            child: Icon(
              Icons.search_rounded,
              color: _hasText
                  ? AppTheme.kjRed
                  : theme.colorScheme.onSurfaceVariant,
              size: 5.5.w,
            ),
          ),
          suffixIcon: _hasText
              ? IconButton(
                  icon: Icon(Icons.cancel_rounded,
                      color: theme.colorScheme.onSurfaceVariant, size: 5.w),
                  onPressed: () {
                    _controller.clear();
                    widget.onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: isDark
              ? theme.colorScheme.surfaceContainerHighest
              : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.12),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppTheme.kjRed, width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 4.w,
            vertical: 1.5.h,
          ),
        ),
      ),
    );
  }
}