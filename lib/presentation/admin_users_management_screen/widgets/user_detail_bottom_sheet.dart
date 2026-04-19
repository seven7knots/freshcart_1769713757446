// ============================================================
// FILE: lib/presentation/admin_users_management_screen/widgets/user_detail_bottom_sheet.dart
// ============================================================
// SESSION 27 FIXES:
// - Removed "Adjust Wallet Balance" action (no wallet system)
// - Removed "View Transactions" action (no wallet system)
// - Removed "Wallet Balance" from info section
// - Fixed "View Order History" to navigate to order management
// - Fixed "Remove Merchant Role" with direct DB fallback
// - Fixed "Suspend Account" state refresh
// SESSION 28 FIXES:
// - Fixed "Remove Merchant Role" FK violation (orders_store_id_fkey):
//   Now nullifies store_id on all orders before deleting stores
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/supabase_service.dart';
import '../../../l10n/generated/app_localizations.dart';

class UserDetailBottomSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onRefresh;

  const UserDetailBottomSheet({
    super.key,
    required this.user,
    required this.onRefresh,
  });

  @override
  State<UserDetailBottomSheet> createState() => _UserDetailBottomSheetState();
}

class _UserDetailBottomSheetState extends State<UserDetailBottomSheet> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = widget.user['is_active'] as bool? ?? true;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            Expanded(
              child: _isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.all(4.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          SizedBox(height: 3.h),
                          _buildInfoSection(),
                          SizedBox(height: 3.h),
                          _buildActionsSection(isActive),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor:
              theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Text(
            (widget.user['full_name'] as String? ?? 'U')[0].toUpperCase(),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.user['full_name'] ?? AppLocalizations.of(context)!.unknownUser,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 0.5.h),
              Text(
                widget.user['email'] ?? AppLocalizations.of(context)!.noEmail,
                style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.userInformation,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 2.h),
        _buildInfoRow(AppLocalizations.of(context)!.phone, widget.user['phone'] ?? AppLocalizations.of(context)!.notProvided),
        _buildInfoRow(AppLocalizations.of(context)!.role,
            (widget.user['role'] as String? ?? 'customer').toUpperCase()),
        _buildInfoRow(
          'Total Orders',
          widget.user['order_count']?.toString() ?? '0',
        ),
        _buildInfoRow(
          'Status',
          (widget.user['is_active'] as bool? ?? true) ? AppLocalizations.of(context)!.active2 : AppLocalizations.of(context)!.inactive2,
        ),
        _buildInfoRow(
          'Verified',
          (widget.user['is_verified'] as bool? ?? false) ? AppLocalizations.of(context)!.yes2 : AppLocalizations.of(context)!.no2,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Flexible(child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildActionsSection(bool isActive) {
    final theme = Theme.of(context);
    final role = (widget.user['role'] as String? ?? '').toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.actions,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 2.h),
        _buildActionButton(
          icon: isActive ? Icons.block : Icons.check_circle,
          label: isActive ? AppLocalizations.of(context)!.suspendAccount : AppLocalizations.of(context)!.activateAccount,
          color: isActive ? Colors.red : Colors.green,
          onTap: () => _toggleUserStatus(isActive),
        ),
        SizedBox(height: 1.h),
        _buildActionButton(
          icon: Icons.receipt_long,
          label: AppLocalizations.of(context)!.viewOrderHistory,
          onTap: () => _viewOrderHistory(),
        ),
        if (role == 'driver') ...[
          SizedBox(height: 1.h),
          _buildActionButton(
            icon: Icons.person_remove,
            label: AppLocalizations.of(context)!.removeDriverRole,
            color: Colors.deepOrange,
            onTap: _removeDriverRole,
          ),
        ],
        if (role == 'merchant') ...[
          SizedBox(height: 1.h),
          _buildActionButton(
            icon: Icons.store_mall_directory,
            label: AppLocalizations.of(context)!.removeMerchantRole,
            color: Colors.deepOrange,
            onTap: _removeMerchantRole,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color ?? theme.colorScheme.primary,
              size: 24,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _viewOrderHistory() {
    Navigator.pop(context);
    Navigator.pushNamed(
      context,
      AppRoutes.enhancedOrderManagement,
      arguments: {'filterUserId': widget.user['id']},
    );
  }

  Future<void> _removeDriverRole() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.removeDriverRole, maxLines: 1, overflow: TextOverflow.ellipsis),
        content: Text(
          AppLocalizations.of(context)!.thisWillDeleteTheDriverRecord, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            child: Text(AppLocalizations.of(context)!.removeDriver, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      final userId = widget.user['id'] as String;

      try {
        await SupabaseService.client.rpc('admin_remove_driver_role', params: {
          'p_user_id': userId,
        });
      } catch (rpcError) {
        debugPrint('[ADMIN] RPC admin_remove_driver_role not available, using direct update: $rpcError');

        await SupabaseService.client
            .from('drivers')
            .delete()
            .eq('user_id', userId);

        await SupabaseService.client
            .from('users')
            .update({'role': 'customer'})
            .eq('id', userId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.driverRoleRemovedUserIsNow, maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing driver role: $e', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // SESSION 28 FIX: Null out store_id on orders before deleting stores
  // to avoid FK violation (orders_store_id_fkey)
  Future<void> _removeMerchantRole() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.removeMerchantRole, maxLines: 1, overflow: TextOverflow.ellipsis),
        content: const Text(
          'This will delete the merchant record and their stores, and reset this user to a customer. Their historical orders will be preserved but unlinked from the store.\n\nThis action cannot be undone.', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            child: Text(AppLocalizations.of(context)!.removeMerchant, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      final userId = widget.user['id'] as String;

      // Try RPC first
      try {
        await SupabaseService.client.rpc('admin_remove_merchant_role', params: {
          'p_user_id': userId,
        });
      } catch (rpcError) {
        debugPrint('[ADMIN] RPC admin_remove_merchant_role not available, using direct fallback: $rpcError');

        // 1. Get merchant record
        final merchant = await SupabaseService.client
            .from('merchants')
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();

        if (merchant != null) {
          final merchantId = merchant['id'] as String;

          // 2. Get all store IDs for this merchant
          final storeRows = await SupabaseService.client
              .from('stores')
              .select('id')
              .eq('merchant_id', merchantId);

          final storeIds = (storeRows as List)
              .map((s) => s['id'] as String)
              .toList();

          if (storeIds.isNotEmpty) {
            // 3. SESSION 28 FIX: Null out store_id on orders referencing these
            //    stores BEFORE deleting them — prevents orders_store_id_fkey
            //    FK violation (PostgrestException code 23503)
            await SupabaseService.client
                .from('orders')
                .update({'store_id': null}).inFilter('store_id', storeIds);

            debugPrint('[ADMIN] Nullified store_id on orders for stores: $storeIds');

            // 4. Delete stores (FK is now clear)
            await SupabaseService.client
                .from('stores')
                .delete()
                .eq('merchant_id', merchantId);
          }

          // 5. Delete merchant record
          await SupabaseService.client
              .from('merchants')
              .delete()
              .eq('id', merchantId);
        }

        // 6. Reset user role to customer
        await SupabaseService.client
            .from('users')
            .update({'role': 'customer'})
            .eq('id', userId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.merchantRoleRemovedUserIsNow, maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing merchant role: $e', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleUserStatus(bool currentStatus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentStatus ? AppLocalizations.of(context)!.suspendAccount : AppLocalizations.of(context)!.activateAccount, maxLines: 1, overflow: TextOverflow.ellipsis),
        content: Text(
          currentStatus
              ? AppLocalizations.of(context)!.areYouSureYouWantTo8
              : AppLocalizations.of(context)!.areYouSureYouWantTo7, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentStatus ? Colors.red : Colors.green,
            ),
            child: Text(currentStatus ? AppLocalizations.of(context)!.suspend : AppLocalizations.of(context)!.activate, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    final success = await adminProvider.updateUserStatus(
      userId: widget.user['id'] as String,
      isActive: !currentStatus,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentStatus
                  ? AppLocalizations.of(context)!.userAccountSuspendedSuccessfully
                  : AppLocalizations.of(context)!.userAccountActivatedSuccessfully, maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        widget.onRefresh();
      } else {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(adminProvider.error ?? AppLocalizations.of(context)!.failedToUpdateUserStatus, maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}