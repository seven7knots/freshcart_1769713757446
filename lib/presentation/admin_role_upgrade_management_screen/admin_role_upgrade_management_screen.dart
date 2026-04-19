import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

class AdminRoleUpgradeManagementScreen extends StatefulWidget {
  const AdminRoleUpgradeManagementScreen({super.key});

  @override
  State<AdminRoleUpgradeManagementScreen> createState() =>
      _AdminRoleUpgradeManagementScreenState();
}

class _AdminRoleUpgradeManagementScreenState
    extends State<AdminRoleUpgradeManagementScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String _filterStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await SupabaseService.client
          .from('role_upgrade_requests')
          .select('*')
          .eq('status', _filterStatus)
          .order('created_at', ascending: false);

      setState(() {
        _requests = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('[ADMIN_ROLE_UPGRADE] Error loading requests: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading requests: $e', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _approveRequest(Map<String, dynamic> request) async {
    try {
      await SupabaseService.client
          .from('role_upgrade_requests')
          .update({'status': 'approved'}).eq('id', request['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.requestApprovedSuccessfully, maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.green,
          ),
        );
        _loadRequests();
      }
    } catch (e) {
      debugPrint('[ADMIN_ROLE_UPGRADE] Error approving request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving request: $e', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(
      Map<String, dynamic> request, String reason) async {
    try {
      await SupabaseService.client.from('role_upgrade_requests').update({
        'status': 'rejected',
        'rejection_reason': reason,
      }).eq('id', request['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request rejected', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.orange,
          ),
        );
        _loadRequests();
      }
    } catch (e) {
      debugPrint('[ADMIN_ROLE_UPGRADE] Error rejecting request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting request: $e', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRejectDialog(Map<String, dynamic> request) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.rejectRequest, maxLines: 1, overflow: TextOverflow.ellipsis),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.rejectionReason,
            hintText: AppLocalizations.of(context)!.provideAReasonForRejection,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _rejectRequest(request, reasonController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(AppLocalizations.of(context)!.reject, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.roleUpgradeRequests,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _requests.isEmpty
                    ? _buildEmptyState()
                    : _buildRequestsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          _buildFilterChip('Pending', 'pending'),
          SizedBox(width: 2.w),
          _buildFilterChip(AppLocalizations.of(context)!.approved, 'approved'),
          SizedBox(width: 2.w),
          _buildFilterChip('Rejected', 'rejected'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String status) {
    final isSelected = _filterStatus == status;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _filterStatus = status;
        });
        _loadRequests();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 20.w,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 2.h),
          Text(
            'No $_filterStatus requests',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final theme = Theme.of(context);
    final requestedRole = request['requested_role'] ?? '';
    final status = request['status'] ?? '';
    final applicationData =
        request['application_data'] as Map<String, dynamic>? ?? {};

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    requestedRole == 'driver'
                        ? Icons.delivery_dining
                        : Icons.store,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['full_name'] ?? AppLocalizations.of(context)!.unknown,
                        style:
                            theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        request['email'] ?? '',
                        style:
                            theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurfaceVariant,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    requestedRole.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w600,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildInfoRow(AppLocalizations.of(context)!.phone, request['phone'] ?? AppLocalizations.of(context)!.nA),
            _buildInfoRow(AppLocalizations.of(context)!.experience, applicationData['experience'] ?? AppLocalizations.of(context)!.nA),
            if (requestedRole == 'driver')
              _buildInfoRow(
                  'Vehicle', applicationData['vehicle_info'] ?? AppLocalizations.of(context)!.nA),
            if (requestedRole == 'merchant') ...[
              _buildInfoRow(
                  'Business', applicationData['business_name'] ?? AppLocalizations.of(context)!.nA),
              _buildInfoRow(
                  'Address', applicationData['business_address'] ?? AppLocalizations.of(context)!.nA),
            ],
            if (status == 'pending') ...[
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveRequest(request),
                      icon: const Icon(Icons.check),
                      label: Text(AppLocalizations.of(context)!.approve, maxLines: 1, overflow: TextOverflow.ellipsis),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showRejectDialog(request),
                      icon: const Icon(Icons.close),
                      label: Text(AppLocalizations.of(context)!.reject, maxLines: 1, overflow: TextOverflow.ellipsis),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (status == 'rejected' &&
                request['rejection_reason'] != null) ...[
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'Rejection Reason: ${request['rejection_reason']}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 25.w,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}