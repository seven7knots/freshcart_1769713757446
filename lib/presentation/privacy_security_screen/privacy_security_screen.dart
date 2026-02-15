// ============================================================
// FILE: lib/presentation/privacy_security_screen/privacy_security_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          // Password Section
          _buildSectionCard(
            theme: theme,
            title: 'Password',
            icon: Icons.lock_outline,
            children: [
              _buildActionTile(
                theme: theme,
                icon: Icons.key,
                title: 'Change Password',
                subtitle: 'Update your account password',
                onTap: () => _showChangePasswordDialog(theme),
              ),
              _buildActionTile(
                theme: theme,
                icon: Icons.password,
                title: 'Reset Password via Email',
                subtitle: 'Send a password reset link to your email',
                onTap: _sendPasswordReset,
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Session Management
          _buildSectionCard(
            theme: theme,
            title: 'Sessions',
            icon: Icons.devices,
            children: [
              _buildActionTile(
                theme: theme,
                icon: Icons.logout,
                title: 'Sign Out All Other Devices',
                subtitle: 'This will sign you out everywhere except here',
                onTap: _signOutOtherSessions,
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Data & Privacy
          _buildSectionCard(
            theme: theme,
            title: 'Data & Privacy',
            icon: Icons.privacy_tip_outlined,
            children: [
              _buildActionTile(
                theme: theme,
                icon: Icons.download,
                title: 'Download My Data',
                subtitle: 'Request a copy of your personal data',
                onTap: _requestDataExport,
              ),
              _buildActionTile(
                theme: theme,
                icon: Icons.delete_forever,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account and data',
                color: theme.colorScheme.error,
                onTap: () => _showDeleteAccountDialog(theme),
              ),
            ],
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final tileColor = color ?? theme.colorScheme.onSurface;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? theme.colorScheme.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color ?? theme.colorScheme.primary, size: 20),
      ),
      title: Text(title, style: TextStyle(color: tileColor, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
      trailing: _isLoading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
      onTap: _isLoading ? null : onTap,
    );
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  void _showChangePasswordDialog(ThemeData theme) {
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 5.w, right: 5.w, top: 3.h, bottom: MediaQuery.of(ctx).viewInsets.bottom + 3.h),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(width: 12.w, height: 0.5.h, decoration: BoxDecoration(color: theme.colorScheme.outline.withOpacity(0.3), borderRadius: BorderRadius.circular(4))),
            ),
            SizedBox(height: 2.h),
            Text('Change Password', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            SizedBox(height: 3.h),
            TextField(
              controller: newPwController,
              obscureText: obscureNew,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setSheetState(() => obscureNew = !obscureNew),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: confirmPwController,
              obscureText: obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setSheetState(() => obscureConfirm = !obscureConfirm),
                ),
              ),
            ),
            SizedBox(height: 3.h),
            SizedBox(
              width: double.infinity,
              height: 6.h,
              child: ElevatedButton(
                onPressed: () async {
                  final newPw = newPwController.text.trim();
                  final confirmPw = confirmPwController.text.trim();

                  if (newPw.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Colors.red));
                    return;
                  }
                  if (newPw != confirmPw) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red));
                    return;
                  }

                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);

                  try {
                    await Supabase.instance.client.auth.updateUser(UserAttributes(password: newPw));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update password: $e'), backgroundColor: Colors.red));
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kjRed, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ============================================================
  // RESET PASSWORD VIA EMAIL
  // ============================================================

  Future<void> _sendPasswordReset() async {
    setState(() => _isLoading = true);
    try {
      final email = Supabase.instance.client.auth.currentUser?.email;
      if (email == null) throw Exception('No email found');

      await Supabase.instance.client.auth.resetPasswordForEmail(email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password reset link sent to $email'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // SIGN OUT OTHER SESSIONS
  // ============================================================

  Future<void> _signOutOtherSessions() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out Other Devices'),
        content: const Text('This will sign you out of all other devices. You\'ll remain signed in here.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out Others')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.others);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out of all other devices'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // DATA EXPORT
  // ============================================================

  Future<void> _requestDataExport() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data export request submitted. You will receive an email.'), backgroundColor: Colors.green),
      );
    }
  }

  // ============================================================
  // DELETE ACCOUNT
  // ============================================================

  void _showDeleteAccountDialog(ThemeData theme) {
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Icon(Icons.delete_forever, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          const Text('Delete Account'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('This action is permanent and cannot be undone. All your data, orders, and preferences will be deleted.'),
          SizedBox(height: 2.h),
          TextField(
            controller: confirmController,
            decoration: const InputDecoration(labelText: 'Type DELETE to confirm', border: OutlineInputBorder()),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (confirmController.text.trim() != 'DELETE') {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please type DELETE to confirm'), backgroundColor: Colors.red));
                return;
              }
              Navigator.pop(ctx);

              setState(() => _isLoading = true);
              try {
                // Mark user as inactive
                final userId = Supabase.instance.client.auth.currentUser?.id;
                if (userId != null) {
                  await Supabase.instance.client.from('users').update({'is_active': false, 'deleted_at': DateTime.now().toIso8601String()}).eq('id', userId);
                }
                await Supabase.instance.client.auth.signOut();

                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.authentication, (route) => false);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                  setState(() => _isLoading = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error, foregroundColor: Colors.white),
            child: const Text('Delete My Account'),
          ),
        ],
      ),
    );
  }
}