import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

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
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recentSearches.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              'Recent Searches',
              onClearRecentSearches,
            ),
            _buildSuggestionsList(context, recentSearches, Icons.history),
            Divider(
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.2),
              height: 1,
            ),
          ],
          _buildSectionHeader(context, 'Trending Products'),
          _buildSuggestionsList(context, trendingProducts, Icons.trending_up),
          Divider(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
            height: 1,
          ),
          _buildSectionHeader(context, 'Categories'),
          _buildSuggestionsList(context, categories, Icons.category),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, [
    VoidCallback? onClear,
  ]) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          if (onClear != null)
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onClear();
              },
              child: Text(
                'Clear',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(
    BuildContext context,
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
          leading: CustomIconWidget(
            iconName: iconData.toString().split('.').last,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          title: Text(
            suggestion,
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          onTap: () {
            HapticFeedback.lightImpact();
            onSuggestionTap?.call(suggestion);
          },
          trailing: CustomIconWidget(
            iconName: 'north_west',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 16,
          ),
        );
      },
    );
  }
}
