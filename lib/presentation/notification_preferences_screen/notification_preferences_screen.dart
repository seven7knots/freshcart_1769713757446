// ============================================================
// FILE: lib/presentation/notification_preferences_screen/notification_preferences_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool _isLoading = true;

  // Notification preferences
  bool _orderUpdates = true;
  bool _promotions = true;
  bool _deliveryAlerts = true;
  bool _priceDrops = false;
  bool _newProducts = false;
  bool _weeklyDigest = false;
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _smsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final result = await Supabase.instance.client
          .from('user_notification_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (result != null && mounted) {
        setState(() {
          _orderUpdates = result['order_updates'] ?? true;
          _promotions = result['promotions'] ?? true;
          _deliveryAlerts = result['delivery_alerts'] ?? true;
          _priceDrops = result['price_drops'] ?? false;
          _newProducts = result['new_products'] ?? false;
          _weeklyDigest = result['weekly_digest'] ?? false;
          _pushEnabled = result['push_enabled'] ?? true;
          _emailEnabled = result['email_enabled'] ?? true;
          _smsEnabled = result['sms_enabled'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('[NOTIF_PREFS] Error loading: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final data = {
        'user_id': userId,
        'order_updates': _orderUpdates,
        'promotions': _promotions,
        'delivery_alerts': _deliveryAlerts,
        'price_drops': _priceDrops,
        'new_products': _newProducts,
        'weekly_digest': _weeklyDigest,
        'push_enabled': _pushEnabled,
        'email_enabled': _emailEnabled,
        'sms_enabled': _smsEnabled,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client
          .from('user_notification_preferences')
          .upsert(data, onConflict: 'user_id');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        actions: [
          TextButton(
            onPressed: _savePreferences,
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(4.w),
              children: [
                _buildSection(
                  theme: theme,
                  title: 'Order Notifications',
                  icon: Icons.receipt_long,
                  children: [
                    _buildToggle(theme, 'Order Updates', 'Status changes, confirmations', _orderUpdates, (v) => setState(() => _orderUpdates = v)),
                    _buildToggle(theme, 'Delivery Alerts', 'Driver assigned, arriving soon', _deliveryAlerts, (v) => setState(() => _deliveryAlerts = v)),
                  ],
                ),
                SizedBox(height: 2.h),
                _buildSection(
                  theme: theme,
                  title: 'Marketing',
                  icon: Icons.campaign,
                  children: [
                    _buildToggle(theme, 'Promotions & Offers', 'Deals, coupons, flash sales', _promotions, (v) => setState(() => _promotions = v)),
                    _buildToggle(theme, 'Price Drop Alerts', 'Items in your cart or favorites', _priceDrops, (v) => setState(() => _priceDrops = v)),
                    _buildToggle(theme, 'New Products', 'From stores you follow', _newProducts, (v) => setState(() => _newProducts = v)),
                    _buildToggle(theme, 'Weekly Digest', 'Summary of activity', _weeklyDigest, (v) => setState(() => _weeklyDigest = v)),
                  ],
                ),
                SizedBox(height: 2.h),
                _buildSection(
                  theme: theme,
                  title: 'Channels',
                  icon: Icons.send,
                  children: [
                    _buildToggle(theme, 'Push Notifications', 'On your device', _pushEnabled, (v) => setState(() => _pushEnabled = v)),
                    _buildToggle(theme, 'Email Notifications', 'To your registered email', _emailEnabled, (v) => setState(() => _emailEnabled = v)),
                    _buildToggle(theme, 'SMS Notifications', 'Text messages', _smsEnabled, (v) => setState(() => _smsEnabled = v)),
                  ],
                ),
                SizedBox(height: 4.h),
                SizedBox(
                  width: double.infinity,
                  height: 6.h,
                  child: ElevatedButton(
                    onPressed: _savePreferences,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kjRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Preferences', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ),
                SizedBox(height: 4.h),
              ],
            ),
    );
  }

  Widget _buildSection({required ThemeData theme, required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 1.h),
          child: Row(children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            SizedBox(width: 2.w),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ]),
        ),
        ...children,
        SizedBox(height: 1.h),
      ]),
    );
  }

  Widget _buildToggle(ThemeData theme, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.kjRed,
    );
  }
}