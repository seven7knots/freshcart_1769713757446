import 'package:flutter/material.dart';

import '../../providers/admin_provider.dart';
import '../../models/merchant_model.dart';
import '../../models/driver_model.dart';
import '../../core/app_export.dart';

/// Admin Applications Screen
/// Displays and manages pending merchant and driver applications
/// Now properly handles Driver model type
class AdminApplicationsScreen extends StatefulWidget {
  const AdminApplicationsScreen({super.key});

  @override
  State<AdminApplicationsScreen> createState() => _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState extends State<AdminApplicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _rejectionReasonController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rejectionReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.loadPendingApplications();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applications'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Consumer<AdminProvider>(
              builder: (context, admin, _) => Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.store),
                    const SizedBox(width: 8),
                    const Text('Merchants'),
                    if (admin.pendingMerchants.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${admin.pendingMerchants.length}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Consumer<AdminProvider>(
              builder: (context, admin, _) => Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.delivery_dining),
                    const SizedBox(width: 8),
                    const Text('Drivers'),
                    if (admin.pendingDrivers.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${admin.pendingDrivers.length}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!adminProvider.isAdmin) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Access Denied',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You do not have admin privileges.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildMerchantsList(adminProvider),
              _buildDriversList(adminProvider),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // MERCHANTS TAB
  // ============================================================

  Widget _buildMerchantsList(AdminProvider adminProvider) {
    final merchants = adminProvider.pendingMerchants;

    if (merchants.isEmpty) {
      return _buildEmptyState(
        icon: Icons.store_outlined,
        title: 'No Pending Merchant Applications',
        subtitle: 'All merchant applications have been processed.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: merchants.length,
        itemBuilder: (context, index) {
          final merchant = merchants[index];
          return _buildMerchantCard(merchant);
        },
      ),
    );
  }

  Widget _buildMerchantCard(Merchant merchant) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with logo and business name
            Row(
              children: [
                // Logo
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    image: merchant.logoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(merchant.logoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: merchant.logoUrl == null
                      ? Icon(Icons.store,
                          color: colorScheme.primary, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                // Business info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        merchant.businessName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (merchant.businessType != null)
                        Text(
                          merchant.businessType!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PENDING',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Details
            if (merchant.description != null) ...[
              _buildDetailRow(
                  Icons.description, 'Description', merchant.description!),
              const SizedBox(height: 8),
            ],
            if (merchant.address != null) ...[
              _buildDetailRow(Icons.location_on, 'Address', merchant.address!),
              const SizedBox(height: 8),
            ],
            if (merchant.userEmail != null) ...[
              _buildDetailRow(Icons.email, 'Email', merchant.userEmail!),
              const SizedBox(height: 8),
            ],
            _buildDetailRow(
              Icons.calendar_today,
              'Applied',
              _formatDate(merchant.createdAt),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(
                      context: context,
                      title: 'Reject Merchant',
                      onReject: (reason) =>
                          _rejectMerchant(merchant.id, reason),
                    ),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Reject',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveMerchant(merchant.id),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DRIVERS TAB
  // ============================================================

  Widget _buildDriversList(AdminProvider adminProvider) {
    final drivers = adminProvider.pendingDrivers;

    if (drivers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.delivery_dining_outlined,
        title: 'No Pending Driver Applications',
        subtitle: 'All driver applications have been processed.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: drivers.length,
        itemBuilder: (context, index) {
          final driver = drivers[index];
          return _buildDriverCard(driver);
        },
      ),
    );
  }

  Widget _buildDriverCard(Driver driver) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar and name
            Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(30),
                    image: driver.avatarUrl != null
                        ? DecorationImage(
                            image: NetworkImage(driver.avatarUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: driver.avatarUrl == null
                      ? Icon(Icons.person,
                          color: colorScheme.primary, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                // Driver info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            driver.vehicleType.icon,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            driver.vehicleType.displayName,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PENDING',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Details
            _buildDetailRow(Icons.phone, 'Phone', driver.phone),
            const SizedBox(height: 8),
            if (driver.email != null) ...[
              _buildDetailRow(Icons.email, 'Email', driver.email!),
              const SizedBox(height: 8),
            ],
            if (driver.vehiclePlate != null) ...[
              _buildDetailRow(
                  Icons.directions_car, 'Plate', driver.vehiclePlate!),
              const SizedBox(height: 8),
            ],
            if (driver.licenseNumber != null) ...[
              _buildDetailRow(Icons.badge, 'License', driver.licenseNumber!),
              const SizedBox(height: 8),
            ],
            _buildDetailRow(
              Icons.calendar_today,
              'Applied',
              _formatDate(driver.createdAt),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(
                      context: context,
                      title: 'Reject Driver',
                      onReject: (reason) => _rejectDriver(driver.id, reason),
                    ),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Reject',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveDriver(driver.id),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPER WIDGETS
  // ============================================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadApplications,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _approveMerchant(String merchantId) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    final confirm = await _showConfirmDialog(
      title: 'Approve Merchant',
      message:
          'Are you sure you want to approve this merchant application? They will gain merchant privileges immediately.',
    );

    if (confirm != true) return;

    final success = await adminProvider.approveMerchant(merchantId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Merchant approved successfully!'
            : 'Failed to approve merchant'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _rejectMerchant(String merchantId, String? reason) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    final success =
        await adminProvider.rejectMerchant(merchantId, reason: reason);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(success ? 'Merchant rejected' : 'Failed to reject merchant'),
        backgroundColor: success ? Colors.orange : Colors.red,
      ),
    );
  }

  Future<void> _approveDriver(String driverId) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    final confirm = await _showConfirmDialog(
      title: 'Approve Driver',
      message:
          'Are you sure you want to approve this driver application? They will gain driver privileges immediately.',
    );

    if (confirm != true) return;

    final success = await adminProvider.approveDriver(driverId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            success ? 'Driver approved successfully!' : 'Failed to approve driver'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _rejectDriver(String driverId, String? reason) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    final success = await adminProvider.rejectDriver(driverId, reason: reason);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Driver rejected' : 'Failed to reject driver'),
        backgroundColor: success ? Colors.orange : Colors.red,
      ),
    );
  }

  // ============================================================
  // DIALOGS
  // ============================================================

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog({
    required BuildContext context,
    required String title,
    required Function(String?) onReject,
  }) {
    _rejectionReasonController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for rejection (optional):'),
            const SizedBox(height: 16),
            TextField(
              controller: _rejectionReasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g., Missing documents, Invalid information...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final reason = _rejectionReasonController.text.trim();
              onReject(reason.isEmpty ? null : reason);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}