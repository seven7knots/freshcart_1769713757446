import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SettingsSectionWidget extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final VoidCallback? onItemTap;

  const SettingsSectionWidget({
    super.key,
    required this.title,
    required this.items,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 1.h),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
                fontSize: _getResponsiveFontSize(context, 16),
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: cs.outline.withOpacity(0.10),
              indent: _getResponsiveHorizontalPadding(context),
              endIndent: _getResponsiveHorizontalPadding(context),
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildSettingsItem(context, item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    final iconColor = (item["iconColor"] as Color?) ?? cs.primary;

    return InkWell(
      onTap: () => _handleItemTap(context, item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: BoxConstraints(
          minHeight: _getResponsiveItemHeight(context),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: _getResponsiveHorizontalPadding(context),
          vertical: _getResponsiveVerticalPadding(context),
        ),
        child: Row(
          children: [
            Container(
              width: _getResponsiveIconSize(context),
              height: _getResponsiveIconSize(context),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: item["icon"] as String,
                  color: iconColor,
                  size: _getResponsiveInnerIconSize(context),
                ),
              ),
            ),
            SizedBox(width: _getResponsiveSpacing(context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item["title"] as String,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                      fontSize: _getResponsiveFontSize(
                        context,
                        isLargeScreen
                            ? 18
                            : isTablet
                                ? 16
                                : 14,
                      ),
                    ),
                    maxLines: isTablet ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item["subtitle"] != null) ...[
                    SizedBox(height: _getResponsiveSubtitleSpacing(context)),
                    Text(
                      item["subtitle"] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: _getResponsiveFontSize(
                          context,
                          isLargeScreen
                              ? 15
                              : isTablet
                                  ? 14
                                  : 12,
                        ),
                      ),
                      maxLines: isTablet ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: _getResponsiveSpacing(context) * 0.5),
            if (item["trailing"] != null)
              item["trailing"] as Widget
            else
              Container(
                padding: EdgeInsets.all(isTablet ? 8 : 4),
                child: CustomIconWidget(
                  iconName: 'chevron_right',
                  color: cs.onSurfaceVariant,
                  size: _getResponsiveChevronSize(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Responsive helper methods
  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) {
      return baseSize * 1.2; // Large screens (desktop)
    } else if (screenWidth > 600) {
      return baseSize * 1.1; // Tablets
    } else if (screenWidth < 360) {
      return baseSize * 0.9; // Small phones
    }
    return baseSize; // Standard phones
  }

  double _getResponsiveHorizontalPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) {
      return 6.w; // More padding for large screens
    } else if (screenWidth > 600) {
      return 5.w; // Medium padding for tablets
    } else if (screenWidth < 360) {
      return 3.w; // Less padding for small phones
    }
    return 4.w; // Default padding
  }

  double _getResponsiveVerticalPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) {
      return 2.5.h; // More padding for large screens
    } else if (screenWidth > 600) {
      return 2.2.h; // Medium padding for tablets
    } else if (screenWidth < 360) {
      return 1.5.h; // Less padding for small phones
    }
    return 2.h; // Default padding
  }

  double _getResponsiveIconSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) {
      return 14.w.clamp(50.0, 70.0); // Larger icons for desktop with max limit
    } else if (screenWidth > 600) {
      return 12.w.clamp(40.0, 60.0); // Medium icons for tablets
    } else if (screenWidth < 360) {
      return 8.w.clamp(28.0, 35.0); // Smaller icons for small phones
    }
    return 10.w.clamp(35.0, 45.0); // Default icon size with limits
  }

  double _getResponsiveInnerIconSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) {
      return 7.w.clamp(25.0, 35.0); // Larger inner icons for desktop
    } else if (screenWidth > 600) {
      return 6.w.clamp(20.0, 30.0); // Medium inner icons for tablets
    } else if (screenWidth < 360) {
      return 4.w.clamp(14.0, 18.0); // Smaller inner icons for small phones
    }
    return 5.w.clamp(18.0, 24.0); // Default inner icon size
  }

  double _getResponsiveSpacing(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) {
      return 4.w; // More spacing for large screens
    } else if (screenWidth > 600) {
      return 3.5.w; // Medium spacing for tablets
    } else if (screenWidth < 360) {
      return 2.w; // Less spacing for small phones
    }
    return 3.w; // Default spacing
  }

  double _getResponsiveChevronSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) {
      return 6.w.clamp(20.0, 28.0); // Larger chevron for desktop
    } else if (screenWidth > 600) {
      return 5.5.w.clamp(18.0, 24.0); // Medium chevron for tablets
    } else if (screenWidth < 360) {
      return 4.w.clamp(12.0, 16.0); // Smaller chevron for small phones
    }
    return 5.w.clamp(16.0, 20.0); // Default chevron size
  }

  double _getResponsiveItemHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) {
      return 80.0; // Taller items for desktop
    } else if (screenWidth > 600) {
      return 70.0; // Medium height for tablets
    } else if (screenWidth < 360) {
      return 60.0; // Shorter items for small phones
    }
    return 65.0; // Default item height
  }

  double _getResponsiveSubtitleSpacing(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) {
      return 0.8.h; // More spacing for larger screens
    } else if (screenWidth < 360) {
      return 0.3.h; // Less spacing for small phones
    }
    return 0.5.h; // Default spacing
  }

  void _handleItemTap(BuildContext context, Map<String, dynamic> item) {
    if (item["route"] != null) {
      Navigator.pushNamed(context, item["route"] as String);
    }
    onItemTap?.call();
  }
}
