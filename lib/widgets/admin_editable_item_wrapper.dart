import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../presentation/admin_edit_overlay_system_screen/widgets/content_edit_modal_widget.dart';
import '../providers/admin_provider.dart';
import '../services/ads_service.dart';
import '../services/product_service.dart';
import '../services/store_service.dart';
import '../services/supabase_service.dart';

class AdminEditableItemWrapper extends StatelessWidget {
  final Widget child;
  final String contentType;
  final String? contentId;
  final Map<String, dynamic>? contentData;
  final VoidCallback? onDeleted;
  final VoidCallback? onUpdated;
  final Alignment menuAlignment;
  final EdgeInsets menuPadding;
  final bool showBorder;

  const AdminEditableItemWrapper({
    super.key,
    required this.child,
    required this.contentType,
    this.contentId,
    this.contentData,
    this.onDeleted,
    this.onUpdated,
    this.menuAlignment = Alignment.topRight,
    this.menuPadding = const EdgeInsets.all(4),
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    if (!adminProvider.isAdmin || !adminProvider.isEditMode) return child;

    return Stack(children: [
      Container(
        decoration: showBorder ? BoxDecoration(
          border: Border.all(color: Colors.orange.withAlpha(128), width: 2, strokeAlign: BorderSide.strokeAlignOutside),
          borderRadius: BorderRadius.circular(12),
        ) : null,
        child: child,
      ),
      Positioned(
        top: menuPadding.top,
        right: menuAlignment == Alignment.topRight ? menuPadding.right : null,
        left: menuAlignment == Alignment.topLeft ? menuPadding.left : null,
        child: _MenuButton(contentType: contentType, contentId: contentId, contentData: contentData, onDeleted: onDeleted, onUpdated: onUpdated),
      ),
    ]);
  }
}

class _MenuButton extends StatelessWidget {
  final String contentType;
  final String? contentId;
  final Map<String, dynamic>? contentData;
  final VoidCallback? onDeleted;
  final VoidCallback? onUpdated;

  const _MenuButton({required this.contentType, this.contentId, this.contentData, this.onDeleted, this.onUpdated});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () { HapticFeedback.mediumImpact(); _showMenu(context); },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(1.5.w),
          decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 4, offset: const Offset(0, 2))]),
          child: Icon(Icons.more_vert, color: Colors.white, size: 4.w),
        ),
      ),
    );
  }

  String get _label {
    switch (contentType) {
      case 'ad': case 'carousel': return 'Banner';
      case 'product': return 'Product';
      case 'category': return 'Category';
      case 'store': return 'Store';
      case 'marketplace': return 'Listing';
      default: return 'Item';
    }
  }

  bool get _isActive {
    if (contentData == null) return true;
    return contentData!['is_active'] == true || contentData!['is_available'] == true || contentData!['status'] == 'active';
  }

  void _showMenu(BuildContext context) {
    final theme = Theme.of(context);
    final itemName = contentData?['name'] ?? contentData?['title'] ?? _label;

    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 12.w, height: 0.5.h, margin: EdgeInsets.only(bottom: 2.h),
              decoration: BoxDecoration(color: theme.colorScheme.outline.withAlpha(77), borderRadius: BorderRadius.circular(2))),
            Text('Edit $_label: $itemName', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 2.h),
            // Edit
            _tile(ctx, Icons.edit, Colors.blue, 'Edit $_label', () { Navigator.pop(ctx); _openEdit(context); }),
            SizedBox(height: 1.h),
            // Change Image
            _tile(ctx, Icons.image, Colors.purple, 'Change Image', () { Navigator.pop(ctx); _openEdit(context); }),
            SizedBox(height: 1.h),
            // Toggle Active
            _tile(ctx, _isActive ? Icons.visibility_off : Icons.visibility, Colors.orange,
              _isActive ? 'Deactivate' : 'Activate', () { Navigator.pop(ctx); _toggleActive(context); }),
            SizedBox(height: 1.h),
            // Delete
            _tile(ctx, Icons.delete, Colors.red, 'Delete $_label', () { Navigator.pop(ctx); _confirmDelete(context); }, isDanger: true),
            SizedBox(height: 2.h),
          ]),
        )),
      ),
    );
  }

  Widget _tile(BuildContext ctx, IconData icon, Color color, String title, VoidCallback onTap, {bool isDanger = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isDanger ? Colors.red : null)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _openEdit(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => ContentEditModalWidget(
        contentType: contentType == 'carousel' ? 'ad' : contentType,
        contentId: contentId, contentData: contentData,
        onSaved: () { Navigator.pop(ctx); onUpdated?.call();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$_label updated'), backgroundColor: Colors.green)); },
      ),
    );
  }

  Future<void> _toggleActive(BuildContext context) async {
    final newActive = !_isActive;
    try {
      switch (contentType) {
        case 'store':
          if (contentId != null) await StoreService.updateStore(contentId!, {'is_active': newActive});
        case 'product':
          if (contentId != null) await ProductService.updateProduct(contentId!, {'is_available': newActive});
        case 'ad': case 'carousel':
          if (contentId != null) await AdsService().updateAd(contentId!, {'status': newActive ? 'active' : 'paused'});
        case 'category':
          if (contentId != null) await SupabaseService.client.from('categories').update({'is_active': newActive}).eq('id', contentId!);
        default:
          break;
      }
      onUpdated?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$_label ${newActive ? "activated" : "deactivated"}'),
          backgroundColor: Colors.orange,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Delete $_label?'),
      content: const Text('This action cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () { Navigator.pop(ctx); _doDelete(context); },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: const Text('Delete'),
        ),
      ],
    ));
  }

  Future<void> _doDelete(BuildContext context) async {
    try {
      switch (contentType) {
        case 'store':
          if (contentId != null) await StoreService.deleteStore(contentId!);
        case 'product':
          if (contentId != null) await ProductService.deleteProduct(contentId!);
        case 'ad': case 'carousel':
          if (contentId != null) await AdsService().deleteAd(contentId!);
        case 'category':
          if (contentId != null) await SupabaseService.client.from('categories').delete().eq('id', contentId!);
        default:
          break;
      }
      onDeleted?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$_label deleted'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }
}