import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/generated/app_localizations.dart';

class AdminEditButtonWidget extends StatelessWidget {
  final String contentType;
  final VoidCallback onEdit;

  const AdminEditButtonWidget({
    super.key,
    required this.contentType,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: _getIconForContentType(contentType),
            size: 48,
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: 2.h),
          Text(
            'Edit ${_getContentTypeLabel(contentType)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 1.h),
          Text(
            AppLocalizations.of(context)!.tapToManageThisContent,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 2.h),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              onEdit();
            },
            icon: CustomIconWidget(
              iconName: 'edit',
              color: theme.colorScheme.surface,
              size: 20,
            ),
            label: Text(AppLocalizations.of(context)!.editNow, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  String _getIconForContentType(String type) {
    switch (type) {
      case 'ad':
        return 'campaign';
      case 'product':
        return 'inventory_2';
      case 'category':
        return 'category';
      case 'store':
        return 'store';
      case 'offer':
        return 'local_offer';
      case 'carousel':
        return 'view_carousel';
      case 'marketplace':
        return 'shopping_bag';
      default:
        return 'edit';
    }
  }

  String _getContentTypeLabel(String type) {
    switch (type) {
      case 'ad':
        return 'Advertisement';
      case 'product':
        return 'Product';
      case 'category':
        return 'Category';
      case 'store':
        return 'Store';
      case 'offer':
        return 'Offer';
      case 'carousel':
        return 'Carousel';
      case 'marketplace':
        return 'Marketplace Listing';
      default:
        return 'Content';
    }
  }
}