import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/generated/app_localizations.dart';

class DriverApplicationScreen extends StatefulWidget {
  const DriverApplicationScreen({super.key});

  @override
  State<DriverApplicationScreen> createState() => _DriverApplicationScreenState();
}

class _DriverApplicationScreenState extends State<DriverApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _vehiclePlateController = TextEditingController();

  String _selectedVehicleType = 'motorcycle';
  bool _acceptedTerms = false;

  final List<Map<String, dynamic>> _vehicleTypes = [
    {'value': 'motorcycle', 'label': 'Motorcycle', 'icon': Icons.two_wheeler},
    {'value': 'car', 'label': 'Car', 'icon': Icons.directions_car},
    {'value': 'bicycle', 'label': 'Bicycle', 'icon': Icons.pedal_bike},
    {'value': 'van', 'label': 'Van', 'icon': Icons.airport_shuttle},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _fullNameController.text = authProvider.fullName ?? '';
    _phoneController.text = authProvider.phone ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _vehiclePlateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.becomeADriver, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Check if already has pending application
          if (authProvider.hasPendingDriverApplication) {
            return _buildPendingState();
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  SizedBox(height: 3.h),

                  // Vehicle Type Selection
                  _buildSectionTitle(AppLocalizations.of(context)!.vehicleType),
                  SizedBox(height: 1.h),
                  _buildVehicleTypeSelector(),
                  SizedBox(height: 3.h),

                  // Personal Information
                  _buildSectionTitle(AppLocalizations.of(context)!.personalInformation),
                  SizedBox(height: 1.h),
                  _buildTextField(
                    controller: _fullNameController,
                    label: AppLocalizations.of(context)!.fullName2,
                    hint: AppLocalizations.of(context)!.enterYourFullName,
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppLocalizations.of(context)!.fullNameIsRequired;
                      }
                      if (value.trim().length < 3) {
                        return AppLocalizations.of(context)!.nameMustBeAtLeast3;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 2.h),
                  _buildTextField(
                    controller: _phoneController,
                    label: AppLocalizations.of(context)!.phoneNumber2,
                    hint: '+1 (555) 123-4567',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppLocalizations.of(context)!.phoneNumberIsRequired;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 3.h),

                  // Vehicle & License Information
                  _buildSectionTitle(AppLocalizations.of(context)!.vehicleLicense),
                  SizedBox(height: 1.h),
                  _buildTextField(
                    controller: _vehiclePlateController,
                    label: AppLocalizations.of(context)!.vehiclePlateNumber,
                    hint: AppLocalizations.of(context)!.abc1234,
                    icon: Icons.confirmation_number,
                  ),
                  SizedBox(height: 2.h),
                  _buildTextField(
                    controller: _licenseController,
                    label: AppLocalizations.of(context)!.driverLicenseNumber,
                    hint: AppLocalizations.of(context)!.enterYourLicenseNumber,
                    icon: Icons.badge,
                  ),
                  SizedBox(height: 3.h),

                  // Requirements Info
                  _buildRequirementsBox(),
                  SizedBox(height: 3.h),

                  // Terms and Conditions
                  _buildTermsCheckbox(),
                  SizedBox(height: 3.h),

                  // Submit Button
                  _buildSubmitButton(authProvider),
                  SizedBox(height: 4.h),

                  // Info Box
                  _buildInfoBox(),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.delivery_dining,
              color: Colors.white,
              size: 10.w,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.earnOnYourSchedule,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 0.5.h),
                Text(
                  AppLocalizations.of(context)!.deliverOrdersAndEarnMoneyOn,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.9),
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
      ), maxLines: 1, overflow: TextOverflow.ellipsis);
  }

  Widget _buildVehicleTypeSelector() {
    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: _vehicleTypes.map((type) {
        final isSelected = _selectedVehicleType == type['value'];
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                type['icon'] as IconData,
                size: 4.w,
                color: isSelected ? Colors.white : null,
              ),
              SizedBox(width: 1.w),
              Flexible(child: Text(type['label'] as String, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          selected: isSelected,
          selectedColor: Colors.blue,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedVehicleType = type['value'] as String);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildRequirementsBox() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist, color: Colors.amber.shade700, size: 5.w),
              SizedBox(width: 2.w),
              Flexible(child: Text(
                AppLocalizations.of(context)!.requirements,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade800,
                ), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          SizedBox(height: 1.h),
          _buildRequirementItem('Valid driver\'s license'),
          _buildRequirementItem(AppLocalizations.of(context)!.vehicleInGoodWorkingCondition),
          _buildRequirementItem(AppLocalizations.of(context)!.smartphoneWithGps),
          _buildRequirementItem(AppLocalizations.of(context)!.cleanDrivingRecord),
          _buildRequirementItem(AppLocalizations.of(context)!.minimum18YearsOld),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 0.5.h),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.amber.shade700, size: 4.w),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.amber.shade900,
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
          value: _acceptedTerms,
          onChanged: (value) {
            setState(() => _acceptedTerms = value ?? false);
          },
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
            child: Padding(
              padding: EdgeInsets.only(top: 1.h),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.black87,
                  ),
                  children: [
                    TextSpan(text: AppLocalizations.of(context)!.iAgreeToThe),
                    TextSpan(
                      text: AppLocalizations.of(context)!.termsOfService,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: AppLocalizations.of(context)!.andText),
                    TextSpan(
                      text: AppLocalizations.of(context)!.driverAgreement,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: AppLocalizations.of(context)!.andIConfirmThatIMeet),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: authProvider.isLoading || !_acceptedTerms
            ? null
            : () => _submitApplication(authProvider),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          backgroundColor: Colors.blue,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: authProvider.isLoading
            ? SizedBox(
                height: 5.w,
                width: 5.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send, color: Colors.white),
                  SizedBox(width: 2.w),
                  Flexible(child: Text(
                    AppLocalizations.of(context)!.submitApplication,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 5.w),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.whatHappensNext,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 0.5.h),
                Text(
                  '1. Our team will review your application\n'
                  '2. You\'ll receive a notification once approved\n'
                  '3. You can then go online and start accepting deliveries',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.blue.shade700,
                    height: 1.5,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.hourglass_top,
                size: 15.w,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              AppLocalizations.of(context)!.applicationUnderReview,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 1.h),
            Text(
              'Your driver application is being reviewed by our team. We\'ll notify you once it\'s processed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 4.h),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: Text(AppLocalizations.of(context)!.goBack, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitApplication(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseAcceptTheTermsAndConditions, maxLines: 1, overflow: TextOverflow.ellipsis),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await authProvider.applyAsDriver(
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      vehicleType: _selectedVehicleType,
      vehiclePlate: _vehiclePlateController.text.trim().isEmpty
          ? null
          : _vehiclePlateController.text.trim(),
      licenseNumber: _licenseController.text.trim().isEmpty
          ? null
          : _licenseController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.applicationSubmittedSuccessfully, maxLines: 1, overflow: TextOverflow.ellipsis),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? AppLocalizations.of(context)!.failedToSubmitApplication, maxLines: 1, overflow: TextOverflow.ellipsis),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

