// ============================================================
// FILE: lib/presentation/profile_screen/widgets/settings_section_widget.dart
// ============================================================
// Updated: Added phone, WhatsApp icon mappings
// ============================================================

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

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
    final iconName = item["icon"] as String? ?? 'help';

    return InkWell(
      onTap: () => _handleItemTap(context, item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: BoxConstraints(minHeight: _getResponsiveItemHeight(context)),
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
                child: _buildIcon(iconName, iconColor, context),
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
                      fontSize: _getResponsiveFontSize(context, isLargeScreen ? 18 : isTablet ? 16 : 14),
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
                        fontSize: _getResponsiveFontSize(context, isLargeScreen ? 15 : isTablet ? 14 : 12),
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
                child: Icon(
                  Icons.chevron_right,
                  color: cs.onSurfaceVariant,
                  size: _getResponsiveChevronSize(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ICON BUILDER — supports special icons like WhatsApp
  // ============================================================

  Widget _buildIcon(String name, Color color, BuildContext context) {
    // Special case: WhatsApp-style chat icon with green tint
    if (name == 'whatsapp' || (name == 'chat' && color.value == const Color(0xFF25D366).value)) {
      return Icon(
        Icons.chat,
        color: const Color(0xFF25D366),
        size: _getResponsiveInnerIconSize(context),
      );
    }

    return Icon(
      _getIconData(name),
      color: color,
      size: _getResponsiveInnerIconSize(context),
    );
  }

  // ============================================================
  // ICON MAPPING
  // ============================================================

  IconData _getIconData(String name) {
    const iconMap = <String, IconData>{
      'history': Icons.history,
      'shopping_cart': Icons.shopping_cart,
      'shopping_bag': Icons.shopping_bag,
      'favorite': Icons.favorite,
      'person': Icons.person,
      'security': Icons.security,
      'notifications': Icons.notifications,
      'location_on': Icons.location_on,
      'schedule': Icons.schedule,
      'payment': Icons.payment,
      'account_balance_wallet': Icons.account_balance_wallet,
      'card_membership': Icons.card_membership,
      'language': Icons.language,
      'dark_mode': Icons.dark_mode,
      'help': Icons.help,
      'chat': Icons.chat,
      'info': Icons.info,
      'admin_panel_settings': Icons.admin_panel_settings,
      'pending_actions': Icons.pending_actions,
      'people': Icons.people,
      'share': Icons.share,
      'download': Icons.download,
      'edit': Icons.edit,
      'chevron_right': Icons.chevron_right,
      'verified': Icons.verified,
      'star': Icons.star,
      'stars': Icons.stars,
      'savings': Icons.savings,
      'local_shipping': Icons.local_shipping,
      'store': Icons.store,
      'delivery_dining': Icons.delivery_dining,
      'handshake': Icons.handshake,
      'phone': Icons.phone,
      'whatsapp': Icons.chat,
      'support_agent': Icons.support_agent,
    };
    return iconMap[name] ?? Icons.help_outline;
  }

  // ============================================================
  // TAP HANDLER
  // ============================================================

  void _handleItemTap(BuildContext context, Map<String, dynamic> item) {
    if (item["onTap"] != null) {
      (item["onTap"] as VoidCallback)();
      onItemTap?.call();
      return;
    }

    if (item["route"] != null) {
      Navigator.pushNamed(context, item["route"] as String);
      onItemTap?.call();
      return;
    }

    onItemTap?.call();
  }

  // ============================================================
  // RESPONSIVE HELPERS
  // ============================================================

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) return baseSize * 1.2;
    if (screenWidth > 600) return baseSize * 1.1;
    if (screenWidth < 360) return baseSize * 0.9;
    return baseSize;
  }

  double _getResponsiveHorizontalPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) return 6.w;
    if (screenWidth > 600) return 5.w;
    if (screenWidth < 360) return 3.w;
    return 4.w;
  }

  double _getResponsiveVerticalPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) return 2.5.h;
    if (screenWidth > 600) return 2.2.h;
    if (screenWidth < 360) return 1.5.h;
    return 2.h;
  }

  double _getResponsiveIconSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) return 14.w.clamp(50.0, 70.0);
    if (screenWidth > 600) return 12.w.clamp(40.0, 60.0);
    if (screenWidth < 360) return 8.w.clamp(28.0, 35.0);
    return 10.w.clamp(35.0, 45.0);
  }

  double _getResponsiveInnerIconSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) return 7.w.clamp(25.0, 35.0);
    if (screenWidth > 600) return 6.w.clamp(20.0, 30.0);
    if (screenWidth < 360) return 4.w.clamp(14.0, 18.0);
    return 5.w.clamp(18.0, 24.0);
  }

  double _getResponsiveSpacing(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) return 4.w;
    if (screenWidth > 600) return 3.5.w;
    if (screenWidth < 360) return 2.w;
    return 3.w;
  }

  double _getResponsiveChevronSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) return 6.w.clamp(20.0, 28.0);
    if (screenWidth > 600) return 5.5.w.clamp(18.0, 24.0);
    if (screenWidth < 360) return 4.w.clamp(12.0, 16.0);
    return 5.w.clamp(16.0, 20.0);
  }

  double _getResponsiveItemHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) return 80.0;
    if (screenWidth > 600) return 70.0;
    if (screenWidth < 360) return 60.0;
    return 65.0;
  }

  double _getResponsiveSubtitleSpacing(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) return 0.8.h;
    if (screenWidth < 360) return 0.3.h;
    return 0.5.h;
  }
}