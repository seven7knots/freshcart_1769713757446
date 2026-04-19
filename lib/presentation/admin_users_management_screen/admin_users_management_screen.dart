// ============================================================
// FILE: lib/presentation/admin_users_management_screen/admin_users_management_screen.dart
// ============================================================
// SESSION 27 FIXES:
// - Removed Wallet Balance from user cards
// - Total Orders now shows actual count (provider loads order counts)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/admin_layout_wrapper.dart';
import './widgets/user_detail_bottom_sheet.dart';
import '../../l10n/generated/app_localizations.dart';

class AdminUsersManagementScreen extends StatefulWidget {
  const AdminUsersManagementScreen({super.key});

  @override
  State<AdminUsersManagementScreen> createState() =>
      _AdminUsersManagementScreenState();
}

class _AdminUsersManagementScreenState
    extends State<AdminUsersManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _filterRole;
  bool? _filterStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Deferred to avoid notifyListeners() during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.loadUsers(
      searchQuery:
          _searchController.text.isEmpty ? null : _searchController.text,
      filterRole: _filterRole,
      filterStatus: _filterStatus,
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.filterUsers, maxLines: 1, overflow: TextOverflow.ellipsis),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String?>(
              initialValue: _filterRole,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.role),
              items: [
                DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context)!.allRoles, maxLines: 1, overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'customer', child: Text(AppLocalizations.of(context)!.customer, maxLines: 1, overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'merchant', child: Text(AppLocalizations.of(context)!.merchant, maxLines: 1, overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'driver', child: Text(AppLocalizations.of(context)!.driver, maxLines: 1, overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'admin', child: Text(AppLocalizations.of(context)!.admin, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (value) {
                setState(() => _filterRole = value);
              },
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<bool?>(
              initialValue: _filterStatus,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.status),
              items: [
                DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context)!.allStatus, maxLines: 1, overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: true, child: Text(AppLocalizations.of(context)!.active, maxLines: 1, overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: false, child: Text(AppLocalizations.of(context)!.inactive, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (value) {
                setState(() => _filterStatus = value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterRole = null;
                _filterStatus = null;
              });
              Navigator.pop(context);
              _loadUsers();
            },
            child: Text(AppLocalizations.of(context)!.clear, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadUsers();
            },
            child: Text(AppLocalizations.of(context)!.apply, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdminLayoutWrapper(
      currentRoute: AppRoutes.adminUsersManagement,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          title: Text(
            AppLocalizations.of(context)!.usersManagement,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
              tooltip: AppLocalizations.of(context)!.filter,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(4.w),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchByNameEmailOrPhone,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _loadUsers();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onSubmitted: (_) => _loadUsers(),
              ),
            ),
            if (_filterRole != null || _filterStatus != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  children: [
                    if (_filterRole != null)
                      Chip(
                        label: Text('Role: $_filterRole', maxLines: 1, overflow: TextOverflow.ellipsis),
                        onDeleted: () {
                          setState(() => _filterRole = null);
                          _loadUsers();
                        },
                      ),
                    if (_filterRole != null && _filterStatus != null)
                      SizedBox(width: 2.w),
                    if (_filterStatus != null)
                      Chip(
                        label: Text(
                            'Status: ${_filterStatus! ? AppLocalizations.of(context)!.active2 : AppLocalizations.of(context)!.inactive2}', maxLines: 1, overflow: TextOverflow.ellipsis),
                        onDeleted: () {
                          setState(() => _filterStatus = null);
                          _loadUsers();
                        },
                      ),
                  ],
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      child: Consumer<AdminProvider>(
                        builder: (context, adminProvider, child) {
                          final users = adminProvider.users;

                          if (users.isEmpty) {
                            return Center(
                              child: Text(
                                AppLocalizations.of(context)!.noUsersFound,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ), maxLines: 1, overflow: TextOverflow.ellipsis),
                            );
                          }

                          return ListView.separated(
                            padding: EdgeInsets.all(4.w),
                            itemCount: users.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(height: 2.h),
                            itemBuilder: (context, index) {
                              final user = users[index];
                              return _buildUserCard(user);
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final theme = Theme.of(context);
    final isActive = user['is_active'] as bool? ?? true;
    final role = user['role'] as String? ?? 'customer';

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _showUserDetails(user);
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color:
                  theme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primary
                  .withValues(alpha: 0.1),
              child: Text(
                (user['full_name'] as String? ?? 'U')[0].toUpperCase(),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['full_name'] ?? AppLocalizations.of(context)!.unknownUser,
                    style:
                        theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 0.3.h),
                  Text(
                    user['email'] ?? AppLocalizations.of(context)!.noEmail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 0.5.h),
                  // SESSION 27: Show total orders inline instead of wallet
                  Text(
                    '${user['order_count'] ?? 0} orders',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: _getRoleColor(role).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style:
                        theme.textTheme.labelSmall?.copyWith(
                      color: _getRoleColor(role),
                      fontWeight: FontWeight.w600,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                SizedBox(height: 0.5.h),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: (isActive ? Colors.green : Colors.red)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'INACTIVE',
                    style:
                        theme.textTheme.labelSmall?.copyWith(
                      color: isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'merchant':
        return Colors.orange;
      case 'driver':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserDetailBottomSheet(
        user: user,
        onRefresh: _loadUsers,
      ),
    );
  }
}