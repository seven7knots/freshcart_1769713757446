import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/generated/app_localizations.dart';

class SearchSuggestionsWidget extends StatelessWidget {
  final List<String> recentSearches;
  final List<String> trendingProducts;
  final List<String> categories;
  final Function(String)? onSuggestionTap;
  final VoidCallback? onClearRecentSearches;

  const SearchSuggestionsWidget({
    super.key,
    required this.recentSearches,
    required this.trendingProducts,
    required this.categories,
    this.onSuggestionTap,
    this.onClearRecentSearches,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If nothing to show, return empty
    final hasContent = recentSearches.isNotEmpty ||
        trendingProducts.isNotEmpty ||
        categories.isNotEmpty;

    if (!hasContent) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (recentSearches.isNotEmpty) ...[
              _buildSectionHeader(
                context,
                theme,
                'Recent Searches',
                onClearRecentSearches,
              ),
              _buildSuggestionsList(context, theme, recentSearches, Icons.history),
              Divider(
                color: theme.colorScheme.outline.withOpacity(0.2),
                height: 1,
              ),
            ],
            if (trendingProducts.isNotEmpty) ...[
              _buildSectionHeader(context, theme, AppLocalizations.of(context)!.trendingProducts),
              _buildSuggestionsList(context, theme, trendingProducts, Icons.trending_up),
              if (categories.isNotEmpty)
                Divider(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  height: 1,
                ),
            ],
            if (categories.isNotEmpty) ...[
              _buildSectionHeader(context, theme, AppLocalizations.of(context)!.categories),
              _buildSuggestionsList(context, theme, categories, Icons.category),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    ThemeData theme,
    String title, [
    VoidCallback? onClear,
  ]) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ), maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (onClear != null)
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onClear();
              },
              child: Text(
                'Clear',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(
    BuildContext context,
    ThemeData theme,
    List<String> suggestions,
    IconData iconData,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return ListTile(
          leading: Icon(
            iconData,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          title: Text(
            suggestion,
            style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () {
            HapticFeedback.lightImpact();
            onSuggestionTap?.call(suggestion);
          },
          trailing: Icon(
            Icons.north_west,
            color: theme.colorScheme.onSurfaceVariant,
            size: 16,
          ),
        );
      },
    );
  }
}