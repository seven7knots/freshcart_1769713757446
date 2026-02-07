import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../providers/admin_provider.dart';

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
  @override
  Widget build(BuildContext context) {
    final isActive = widget.user['is_active'] as bool? ?? true;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
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
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor:
              AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
          child: Text(
            (widget.user['full_name'] as String? ?? 'U')[0].toUpperCase(),
            style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.user['full_name'] ?? 'Unknown User',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                widget.user['email'] ?? 'No email',
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Information',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        _buildInfoRow('Phone', widget.user['phone'] ?? 'Not provided'),
        _buildInfoRow('Role',
            (widget.user['role'] as String? ?? 'customer').toUpperCase()),
        _buildInfoRow(
          'Wallet Balance',
          '\$${(widget.user['wallet_balance'] ?? 0).toStringAsFixed(2)}',
        ),
        _buildInfoRow(
          'Total Orders',
          widget.user['order_count']?.toString() ?? '0',
        ),
        _buildInfoRow(
          'Status',
          (widget.user['is_active'] as bool? ?? true) ? 'Active' : 'Inactive',
        ),
        _buildInfoRow(
          'Verified',
          (widget.user['is_verified'] as bool? ?? false) ? 'Yes' : 'No',
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(bool isActive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        _buildActionButton(
          icon: Icons.account_balance_wallet,
          label: 'Adjust Wallet Balance',
          onTap: _showWalletAdjustmentDialog,
        ),
        SizedBox(height: 1.h),
        _buildActionButton(
          icon: isActive ? Icons.block : Icons.check_circle,
          label: isActive ? 'Suspend Account' : 'Activate Account',
          color: isActive ? Colors.red : Colors.green,
          onTap: () => _toggleUserStatus(isActive),
        ),
        SizedBox(height: 1.h),
        _buildActionButton(
          icon: Icons.receipt_long,
          label: 'View Order History',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Order history coming soon')),
            );
          },
        ),
        SizedBox(height: 1.h),
        _buildActionButton(
          icon: Icons.history,
          label: 'View Transactions',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transactions view coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color ?? AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                label,
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showWalletAdjustmentDialog() {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust Wallet Balance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: 'Enter amount (positive to add, negative to deduct)',
                prefixText: '\$ ',
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Enter reason for adjustment',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              final reason = reasonController.text.trim();

              if (amount == null || reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid amount and reason'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _adjustWalletBalance(amount, reason);
            },
            child: const Text('Adjust'),
          ),
        ],
      ),
    );
  }

  Future<void> _adjustWalletBalance(double amount, String reason) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    final success = await adminProvider.adjustWalletBalance(
      userId: widget.user['id'] as String,
      amount: amount,
      reason: reason,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wallet balance adjusted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        widget.onRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(adminProvider.error ?? 'Failed to adjust wallet balance'),
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
        title: Text(currentStatus ? 'Suspend Account' : 'Activate Account'),
        content: Text(
          currentStatus
              ? 'Are you sure you want to suspend this user account? They will not be able to access the app.'
              : 'Are you sure you want to activate this user account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentStatus ? Colors.red : Colors.green,
            ),
            child: Text(currentStatus ? 'Suspend' : 'Activate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

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
                  ? 'User account suspended successfully'
                  : 'User account activated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        widget.onRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(adminProvider.error ?? 'Failed to update user status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
