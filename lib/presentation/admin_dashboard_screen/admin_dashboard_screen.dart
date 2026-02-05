import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/admin_provider.dart';
import '../../core/app_export.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isCheckingAdmin = false;

  @override
  void initState() {
    super.initState();
    _initializeAdminStatus();
  }

  Future<void> _initializeAdminStatus() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.checkAdminStatus();
    
    if (mounted) {
      debugPrint('[AdminDashboard] Admin status initialized: ${adminProvider.isAdmin}');
    }
  }

  Future<void> _debugAdminCheck() async {
    if (_isCheckingAdmin) return;
    
    setState(() {
      _isCheckingAdmin = true;
    });

    try {
      final client = Supabase.instance.client;

      // 1. Check current user
      final uid = client.auth.currentUser?.id;
      final email = client.auth.currentUser?.email;
      debugPrint('[DEBUG] ===== ADMIN CHECK START =====');
      debugPrint('[DEBUG] Current UID: $uid');
      debugPrint('[DEBUG] Current Email: $email');

      // 2. Check RPC directly
      final rpcResult = await client.rpc('is_admin');
      debugPrint('[DEBUG] RPC is_admin() result: $rpcResult');

      // 3. Check database user record
      final userRecord = await client
          .from('users')
          .select('id, email, role, is_active')
          .eq('id', uid ?? '')
          .maybeSingle();
      debugPrint('[DEBUG] Database user record: $userRecord');

      // 4. Check provider status
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      await adminProvider.checkAdminStatus();
      debugPrint('[DEBUG] AdminProvider.isAdmin: ${adminProvider.isAdmin}');
      debugPrint('[DEBUG] AdminProvider.error: ${adminProvider.error}');
      debugPrint('[DEBUG] ===== ADMIN CHECK END =====');

      if (!mounted) return;

      // Show comprehensive debug info
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'UID: ${uid ?? "null"}\n'
            'Email: ${email ?? "null"}\n'
            'DB Role: ${userRecord?['role'] ?? "not found"}\n'
            'RPC Result: $rpcResult\n'
            'Provider isAdmin: ${adminProvider.isAdmin}\n'
            'Error: ${adminProvider.error ?? "none"}',
            style: const TextStyle(fontSize: 11),
          ),
          duration: const Duration(seconds: 8),
          backgroundColor: adminProvider.isAdmin ? Colors.green : Colors.red,
          action: SnackBarAction(
            label: 'COPY',
            textColor: Colors.white,
            onPressed: () {
              debugPrint('Full debug info printed to console');
            },
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('[DEBUG] ===== ERROR =====');
      debugPrint('[DEBUG] Error: $e');
      debugPrint('[DEBUG] StackTrace: $stackTrace');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('DEBUG FAILED: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAdmin = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          // Debug button to manually check admin status
          IconButton(
            icon: _isCheckingAdmin
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.bug_report),
            onPressed: _isCheckingAdmin ? null : _debugAdminCheck,
            tooltip: 'Debug Admin Status',
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
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
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _debugAdminCheck,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check Admin Status'),
                  ),
                  const SizedBox(height: 12),
                  if (adminProvider.error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Error: ${adminProvider.error}',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            );
          }

          // Admin UI content
          return RefreshIndicator(
            onRefresh: () async {
              await adminProvider.checkAdminStatus();
              await adminProvider.loadDashboardStats();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.admin_panel_settings, size: 48),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome, Admin',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'You have full admin access',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Dashboard stats
                  if (adminProvider.dashboardStats != null) ...[
                    const Text(
                      'Dashboard Overview',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildStatsGrid(adminProvider.dashboardStats!),
                    const SizedBox(height: 24),
                  ],

                  // Quick actions
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActions(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Users',
          stats['total_users']?.toString() ?? '0',
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          'Active Users',
          stats['active_users']?.toString() ?? '0',
          Icons.verified_user, // Changed from person_check
          Colors.green,
        ),
        _buildStatCard(
          'Total Orders',
          stats['total_orders']?.toString() ?? '0',
          Icons.shopping_cart,
          Colors.orange,
        ),
        _buildStatCard(
          'Revenue',
          '\$${stats['total_revenue']?.toStringAsFixed(2) ?? '0.00'}',
          Icons.attach_money,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        _buildActionButton(
          context,
          'Manage Users',
          Icons.people_alt,
          AppRoutes.adminUsersManagement,
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          context,
          'Manage Orders',
          Icons.receipt_long,
          AppRoutes.enhancedOrderManagement,
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          context,
          'Manage Ads',
          Icons.campaign,
          AppRoutes.adminAdsManagement,
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          context,
          'Logistics',
          Icons.local_shipping,
          AppRoutes.adminLogisticsManagement,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    String route,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, route);
        },
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}