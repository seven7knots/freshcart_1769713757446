import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../l10n/generated/app_localizations.dart';

class RoleUpgradeRequestScreen extends StatefulWidget {
  const RoleUpgradeRequestScreen({super.key});

  @override
  State<RoleUpgradeRequestScreen> createState() =>
      _RoleUpgradeRequestScreenState();
}

class _RoleUpgradeRequestScreenState extends State<RoleUpgradeRequestScreen> {
  String? _selectedRole;
  final _formKey = GlobalKey<FormState>();
  final _experienceController = TextEditingController();
  final _vehicleInfoController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _additionalNotesController = TextEditingController();
  bool _acceptTerms = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _experienceController.dispose();
    _vehicleInfoController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole == null) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.pleaseSelectARoleToApply;
      });
      return;
    }

    if (!_acceptTerms) {
      setState(() {
        _errorMessage = 'Please accept the terms and conditions';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userResponse = await SupabaseService.client
          .from('users')
          .select('email, full_name, phone')
          .eq('id', user.id)
          .maybeSingle();

      if (userResponse == null) {
        throw Exception('User profile not found');
      }

      final applicationData = <String, dynamic>{
        'experience': _experienceController.text,
        'additional_notes': _additionalNotesController.text,
      };

      if (_selectedRole == 'driver') {
        applicationData['vehicle_info'] = _vehicleInfoController.text;
      } else if (_selectedRole == 'merchant') {
        applicationData['business_name'] = _businessNameController.text;
        applicationData['business_address'] = _businessAddressController.text;
      }

      await SupabaseService.client.from('role_upgrade_requests').insert({
        'user_id': user.id,
        'email': userResponse['email'],
        'full_name': userResponse['full_name'],
        'phone': userResponse['phone'],
        'requested_role': _selectedRole,
        'application_data': applicationData,
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.applicationSubmittedSuccessfullyYouWillBe, maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.errorSubmittingApplicationPleaseTryAgain;
      });
      debugPrint('[ROLE_UPGRADE] Submission error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
          AppLocalizations.of(context)!.roleUpgradeRequest,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 3.h),
                _buildRoleSelection(),
                if (_selectedRole != null) ...[
                  SizedBox(height: 3.h),
                  _buildApplicationForm(),
                ],
                if (_errorMessage != null) ...[
                  SizedBox(height: 2.h),
                  _buildErrorMessage(),
                ],
                SizedBox(height: 3.h),
                _buildTermsCheckbox(),
                SizedBox(height: 3.h),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.applyForRoleUpgrade,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 1.h),
        Text(
          AppLocalizations.of(context)!.selectTheRoleYouWantTo,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildRoleSelection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.selectRole,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 2.h),
        _buildRoleCard(
          role: 'driver',
          title: AppLocalizations.of(context)!.driver,
          description:
              'Deliver orders and earn money on your schedule. Requirements: Valid license, vehicle, and clean driving record.',
          icon: Icons.delivery_dining,
        ),
        SizedBox(height: 2.h),
        _buildRoleCard(
          role: 'merchant',
          title: AppLocalizations.of(context)!.merchant,
          description:
              'Sell your products and services on our platform. Requirements: Business registration and product inventory.',
          icon: Icons.store,
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
          _errorMessage = null;
        });
      },
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                        .withValues(alpha: 0.1)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: 8.w,
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : null,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 6.w,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationForm() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.applicationDetails,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 2.h),
        TextFormField(
          controller: _experienceController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.experience,
            hintText: AppLocalizations.of(context)!.describeYourRelevantExperience,
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.pleaseDescribeYourExperience;
            }
            return null;
          },
        ),
        SizedBox(height: 2.h),
        if (_selectedRole == 'driver') ...[
          TextFormField(
            controller: _vehicleInfoController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.vehicleInformation,
              hintText: AppLocalizations.of(context)!.makeModelYearAndLicensePlate,
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.pleaseProvideVehicleInformation;
              }
              return null;
            },
          ),
          SizedBox(height: 2.h),
        ],
        if (_selectedRole == 'merchant') ...[
          TextFormField(
            controller: _businessNameController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.businessName,
              hintText: AppLocalizations.of(context)!.enterYourBusinessName,
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.pleaseProvideBusinessName;
              }
              return null;
            },
          ),
          SizedBox(height: 2.h),
          TextFormField(
            controller: _businessAddressController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.businessAddress,
              hintText: AppLocalizations.of(context)!.enterYourBusinessAddress,
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.pleaseProvideBusinessAddress;
              }
              return null;
            },
          ),
          SizedBox(height: 2.h),
        ],
        TextFormField(
          controller: _additionalNotesController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.additionalNotesOptional,
            hintText: AppLocalizations.of(context)!.anyAdditionalInformationYouWouldLike,
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 5.w,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              _errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.red,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) {
            setState(() {
              _acceptTerms = value ?? false;
              if (_acceptTerms) _errorMessage = null;
            });
          },
          activeColor: theme.colorScheme.primary,
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 1.5.h),
            child: Text(
              AppLocalizations.of(context)!.iAgreeToTheTermsAnd,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 6.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 3.h,
                width: 3.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              )
            : Text(
                AppLocalizations.of(context)!.submitApplication,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onPrimary,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}