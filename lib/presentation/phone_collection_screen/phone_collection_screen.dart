// ============================================================
// FILE: lib/presentation/phone_collection_screen/phone_collection_screen.dart
// ============================================================
// SESSION 27 FIX:
// - Professional phone input with flag emojis + bottom sheet picker
// - Strips leading zeros before prepending country code
// - Better error message for duplicate phone numbers
// SESSION 28 FIX:
// - Country picker bottom sheet overflow fixed
// SESSION 31 FIX:
// - Bug #7: Pre-populate phone if DB already has one
// - On duplicate key (23505): check if phone belongs to this user
// - Added "Skip for now" escape hatch
// SESSION 32 FIX:
// - _savePhone now uses direct upsert (onConflict: 'id') instead of
//   authProvider.updateProfile(). This bypasses the generic error
//   wrapper in updateProfile that swallowed the raw 23505 message,
//   causing "Failed to update profile" with no way to detect the
//   duplicate and navigate forward silently.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../l10n/generated/app_localizations.dart';

class PhoneCollectionScreen extends StatefulWidget {
  const PhoneCollectionScreen({super.key});

  @override
  State<PhoneCollectionScreen> createState() => _PhoneCollectionScreenState();
}

class _PhoneCollectionScreenState extends State<PhoneCollectionScreen> {
  final _phoneController = TextEditingController();
  String _selectedCountryCode = '+961';
  bool _isLoading = false;
  String? _phoneError;

  final List<Map<String, String>> _countryCodes = [
    {'code': '+961', 'country': 'LB', 'flag': '🇱🇧', 'name': 'Lebanon'},
    {'code': '+1', 'country': 'US', 'flag': '🇺🇸', 'name': 'United States'},
    {'code': '+44', 'country': 'UK', 'flag': '🇬🇧', 'name': 'United Kingdom'},
    {'code': '+91', 'country': 'IN', 'flag': '🇮🇳', 'name': 'India'},
    {'code': '+971', 'country': 'AE', 'flag': '🇦🇪', 'name': 'UAE'},
    {'code': '+966', 'country': 'SA', 'flag': '🇸🇦', 'name': 'Saudi Arabia'},
    {'code': '+33', 'country': 'FR', 'flag': '🇫🇷', 'name': 'France'},
    {'code': '+49', 'country': 'DE', 'flag': '🇩🇪', 'name': 'Germany'},
  ];

  Map<String, String> get _selectedCountry =>
      _countryCodes.firstWhere((c) => c['code'] == _selectedCountryCode);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillExistingPhone();
    });
  }

  Future<void> _prefillExistingPhone() async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return;
      final row = await SupabaseService.client
          .from('users')
          .select('phone')
          .eq('id', user.id)
          .maybeSingle();
      final existingPhone = row?['phone'] as String?;
      if (existingPhone != null && existingPhone.trim().isNotEmpty) {
        for (final c in _countryCodes) {
          if (existingPhone.startsWith(c['code']!)) {
            final digits = existingPhone.substring(c['code']!.length);
            if (mounted) {
              setState(() {
                _selectedCountryCode = c['code']!;
                _phoneController.text = digits;
              });
            }
            return;
          }
        }
        if (mounted) {
          setState(() => _phoneController.text = existingPhone);
        }
      }
    } catch (e) { debugPrint('[PHONE_COLLECTION_SCREEN] Silent error: $e'); }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _validatePhone(String v) {
    setState(() {
      if (v.isEmpty) {
        _phoneError = 'Phone number is required';
      } else if (v.length < 7) {
        _phoneError = 'Please enter a valid number';
      } else {
        _phoneError = null;
      }
    });
  }

  bool get _isValid =>
      _phoneController.text.isNotEmpty && _phoneError == null;

  /// Navigate to role-appropriate home screen, clearing the navigation stack.
  void _navigateForward() {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final targetRoute = authProvider.getHomeRouteForUser();
    Navigator.pushNamedAndRemoveUntil(
      context,
      targetRoute,
      (route) => false,
    );
  }

  Future<void> _savePhone() async {
    _validatePhone(_phoneController.text);
    if (!_isValid) return;

    setState(() => _isLoading = true);

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _phoneError = AppLocalizations.of(context)!.notAuthenticatedPleaseSignInAgain;
          _isLoading = false;
        });
        return;
      }

      final digits =
          _phoneController.text.trim().replaceFirst(RegExp(r'^0+'), '');
      final fullPhone = '$_selectedCountryCode$digits';

      // SESSION 32 FIX: Use direct upsert keyed on `id` instead of
      // authProvider.updateProfile(). The old path went through
      // updateProfile() which caught ALL exceptions and returned the
      // generic string "Failed to update profile", swallowing the raw
      // PostgreSQL error code (23505). Our duplicate-key detection in
      // the error handler never fired because it was looking for "23505"
      // in a string that only said "Failed to update profile".
      //
      // upsert with onConflict:'id' means:
      //   - Row exists for this user → UPDATE phone (no unique violation
      //     unless a DIFFERENT user owns this number)
      //   - Row doesn't exist → INSERT
      // This is the correct semantics and surfaces the real error when
      // a different account already owns the number.
      try {
        await SupabaseService.client.from('users').upsert(
          {'id': user.id, 'phone': fullPhone},
          onConflict: 'id',
        );

        // Refresh cached user data so authProvider.phone is up to date
        if (mounted) {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          await authProvider.refreshUserRole(force: true);
        }

        if (!mounted) return;
        HapticFeedback.mediumImpact();
        _navigateForward();
        return;
      } catch (e) {
        final raw = e.toString().toLowerCase();

        // 23505 = unique_violation — this phone belongs to another account
        if (raw.contains('23505') ||
            raw.contains('unique') ||
            raw.contains('duplicate')) {
          // Double-check: maybe this number actually belongs to THIS user
          // (edge case where upsert still fires the constraint somehow)
          try {
            final row = await SupabaseService.client
                .from('users')
                .select('phone')
                .eq('id', user.id)
                .maybeSingle();
            final dbPhone = row?['phone'] as String?;
            if (dbPhone != null && dbPhone == fullPhone) {
              debugPrint('[PHONE] Duplicate is own phone – navigating forward');
              HapticFeedback.mediumImpact();
              if (mounted) _navigateForward();
              return;
            }
          } catch (e) { debugPrint('[PHONE_COLLECTION_SCREEN] Silent error: $e'); }

          setState(() {
            _phoneError =
                'This phone number is already registered to another account';
            _isLoading = false;
          });
        } else {
          debugPrint('[PHONE] Save error: $e');
          setState(() {
            _phoneError = AppLocalizations.of(context)!.somethingWentWrongPleaseTryAgain;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phoneError = AppLocalizations.of(context)!.somethingWentWrongPleaseTryAgain;
          _isLoading = false;
        });
      }
    }
  }

  void _showCountryCodePicker() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12.w,
                  height: 0.5.h,
                  margin: EdgeInsets.symmetric(vertical: 1.5.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.selectCountry,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 1.h),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(sheetContext).size.height * 0.55,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _countryCodes.length,
                    itemBuilder: (_, i) {
                      final c = _countryCodes[i];
                      final isSelected = c['code'] == _selectedCountryCode;
                      return ListTile(
                        leading: Text(
                          c['flag']!,
                          style: TextStyle(fontSize: 22.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                        title: Text(
                          c['name']!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text(
                          c['code']!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        selected: isSelected,
                        selectedTileColor:
                            theme.colorScheme.primary.withOpacity(0.05),
                        onTap: () {
                          setState(() => _selectedCountryCode = c['code']!);
                          _validatePhone(_phoneController.text);
                          Navigator.pop(sheetContext);
                        },
                      );
                    },
                  ),
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = SupabaseService.client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name'] ??
        user?.email?.split('@')[0] ??
        'there';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 6.h),

              Container(
                width: 22.w,
                height: 22.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.phone_android_rounded,
                  size: 12.w,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 3.h),

              Text(
                'Welcome, $userName!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 1.h),

              Text(
                'We need your phone number so our drivers\ncan reach you for deliveries.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 4.h),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalizations.of(context)!.phoneNumber,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              SizedBox(height: 1.h),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _showCountryCodePicker,
                    child: Container(
                      height: 6.5.h,
                      padding: EdgeInsets.symmetric(horizontal: 3.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedCountry['flag']!,
                            style: TextStyle(fontSize: 18.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                          SizedBox(width: 1.5.w),
                          Text(
                            _selectedCountryCode,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ), maxLines: 1, overflow: TextOverflow.ellipsis),
                          SizedBox(width: 1.w),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),

                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onChanged: _validatePhone,
                      onSubmitted: (_) => _isValid ? _savePhone() : null,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(15),
                      ],
                      decoration: InputDecoration(
                        hintText: _selectedCountryCode == '+961'
                            ? '71 234 567'
                            : AppLocalizations.of(context)!.phoneNumber3,
                        prefixIcon: Icon(Icons.phone_outlined,
                            size: 5.w,
                            color: Colors.grey),
                        errorText: _phoneError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.grey.shade400.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalizations.of(context)!.yourDriverWillUseThisTo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              SizedBox(height: 4.h),

              SizedBox(
                width: double.infinity,
                height: 6.5.h,
                child: ElevatedButton(
                  onPressed: _isValid && !_isLoading ? _savePhone : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.kjRed,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        Colors.grey.shade400.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: _isValid ? 4 : 0,
                    shadowColor: AppTheme.kjRed.withOpacity(0.3),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context)!.continueToApp,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),

              SizedBox(height: 2.h),
              TextButton(
                onPressed: _isLoading ? null : _navigateForward,
                child: Text(
                  AppLocalizations.of(context)!.skipForNow,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13.sp,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),

              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }
}