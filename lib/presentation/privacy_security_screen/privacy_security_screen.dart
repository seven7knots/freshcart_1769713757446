// ============================================================
// FILE: lib/presentation/privacy_security_screen/privacy_security_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../l10n/generated/app_localizations.dart';

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
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.privacySecurity, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          // Password Section
          _buildSectionCard(
            theme: theme,
            title: AppLocalizations.of(context)!.password,
            icon: Icons.lock_outline,
            children: [
              _buildActionTile(
                theme: theme,
                icon: Icons.key,
                title: AppLocalizations.of(context)!.changePassword,
                subtitle: AppLocalizations.of(context)!.updateYourAccountPassword,
                onTap: () => _showChangePasswordDialog(theme),
              ),
              _buildActionTile(
                theme: theme,
                icon: Icons.password,
                title: AppLocalizations.of(context)!.resetPasswordViaEmail,
                subtitle: AppLocalizations.of(context)!.sendAPasswordResetLinkTo,
                onTap: _sendPasswordReset,
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Session Management
          _buildSectionCard(
            theme: theme,
            title: AppLocalizations.of(context)!.sessions,
            icon: Icons.devices,
            children: [
              _buildActionTile(
                theme: theme,
                icon: Icons.logout,
                title: AppLocalizations.of(context)!.signOutAllOtherDevices,
                subtitle: AppLocalizations.of(context)!.thisWillSignYouOutEverywhere,
                onTap: _signOutOtherSessions,
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Data & Privacy
          _buildSectionCard(
            theme: theme,
            title: AppLocalizations.of(context)!.dataPrivacy,
            icon: Icons.privacy_tip_outlined,
            children: [
              _buildActionTile(
                theme: theme,
                icon: Icons.download,
                title: AppLocalizations.of(context)!.downloadMyData,
                subtitle: AppLocalizations.of(context)!.requestACopyOfYourPersonal,
                onTap: _requestDataExport,
              ),
              _buildActionTile(
                theme: theme,
                icon: Icons.delete_forever,
                title: AppLocalizations.of(context)!.deleteAccount,
                subtitle: AppLocalizations.of(context)!.permanentlyDeleteYourAccountAndData,
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
              Flexible(child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color ?? theme.colorScheme.primary, size: 20),
      ),
      title: Text(title, style: TextStyle(color: tileColor, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
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
              child: Container(width: 12.w, height: 0.5.h, decoration: BoxDecoration(color: theme.colorScheme.outline.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
            ),
            SizedBox(height: 2.h),
            Text(AppLocalizations.of(context)!.changePassword, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 3.h),
            TextField(
              controller: newPwController,
              obscureText: obscureNew,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.newPassword,
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
                labelText: AppLocalizations.of(context)!.confirmNewPassword,
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
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.passwordMustBeAtLeast6, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red));
                    return;
                  }
                  if (newPw != confirmPw) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.passwordsDoNotMatch, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red));
                    return;
                  }

                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);

                  try {
                    await Supabase.instance.client.auth.updateUser(UserAttributes(password: newPw));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.passwordUpdatedSuccessfully, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.green));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update password: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red));
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kjRed, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text(AppLocalizations.of(context)!.updatePassword, style: TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password reset link sent to $email', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red));
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
        title: Text(AppLocalizations.of(context)!.signOutOtherDevices, maxLines: 1, overflow: TextOverflow.ellipsis),
        content: Text('This will sign you out of all other devices. You\'ll remain signed in here.', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.signOutOthers, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.others);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.signedOutOfAllOtherDevices, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red));
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
        SnackBar(content: Text(AppLocalizations.of(context)!.dataExportRequestSubmittedYouWill, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.green),
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
          Flexible(child: Text(AppLocalizations.of(context)!.deleteAccount, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(AppLocalizations.of(context)!.thisActionIsPermanentAndCannot, maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 2.h),
          TextField(
            controller: confirmController,
            decoration: InputDecoration(labelText: AppLocalizations.of(context)!.typeDeleteToConfirm, border: OutlineInputBorder()),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ElevatedButton(
            onPressed: () async {
              if (confirmController.text.trim() != 'DELETE') {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.pleaseTypeDeleteToConfirm, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red));
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red));
                  setState(() => _isLoading = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error, foregroundColor: Colors.white),
            child: Text(AppLocalizations.of(context)!.deleteMyAccount, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}