import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';

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
        _errorMessage = 'Please select a role to apply for';
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
          const SnackBar(
            content: Text(
              'Application submitted successfully! You will be notified once reviewed.',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error submitting application. Please try again.';
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
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Role Upgrade Request',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Apply for Role Upgrade',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Select the role you want to apply for and provide the required information',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Role',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        _buildRoleCard(
          role: 'driver',
          title: 'Driver',
          description:
              'Deliver orders and earn money on your schedule. Requirements: Valid license, vehicle, and clean driving record.',
          icon: Icons.delivery_dining,
        ),
        SizedBox(height: 2.h),
        _buildRoleCard(
          role: 'merchant',
          title: 'Merchant',
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
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.1)
                    : AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
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
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                          : null,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Application Details',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        TextFormField(
          controller: _experienceController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Experience',
            hintText: 'Describe your relevant experience',
            filled: true,
            fillColor: AppTheme.lightTheme.colorScheme.surface,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please describe your experience';
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
              labelText: 'Vehicle Information',
              hintText: 'Make, model, year, and license plate',
              filled: true,
              fillColor: AppTheme.lightTheme.colorScheme.surface,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please provide vehicle information';
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
              labelText: 'Business Name',
              hintText: 'Enter your business name',
              filled: true,
              fillColor: AppTheme.lightTheme.colorScheme.surface,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please provide business name';
              }
              return null;
            },
          ),
          SizedBox(height: 2.h),
          TextFormField(
            controller: _businessAddressController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Business Address',
              hintText: 'Enter your business address',
              filled: true,
              fillColor: AppTheme.lightTheme.colorScheme.surface,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please provide business address';
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
            labelText: 'Additional Notes (Optional)',
            hintText: 'Any additional information you would like to provide',
            filled: true,
            fillColor: AppTheme.lightTheme.colorScheme.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
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
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
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
          activeColor: AppTheme.lightTheme.colorScheme.primary,
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 1.5.h),
            child: Text(
              'I agree to the terms and conditions and confirm that all information provided is accurate',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 6.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
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
                    AppTheme.lightTheme.colorScheme.onPrimary,
                  ),
                ),
              )
            : Text(
                'Submit Application',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onPrimary,
                ),
              ),
      ),
    );
  }
}
