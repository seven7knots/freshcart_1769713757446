import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/auth_provider.dart';

class MerchantApplicationScreen extends StatefulWidget {
  const MerchantApplicationScreen({super.key});

  @override
  State<MerchantApplicationScreen> createState() => _MerchantApplicationScreenState();
}

class _MerchantApplicationScreenState extends State<MerchantApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedBusinessType = 'restaurant';
  bool _acceptedTerms = false;

  final List<Map<String, dynamic>> _businessTypes = [
    {'value': 'restaurant', 'label': 'Restaurant', 'icon': Icons.restaurant},
    {'value': 'grocery', 'label': 'Grocery Store', 'icon': Icons.local_grocery_store},
    {'value': 'pharmacy', 'label': 'Pharmacy', 'icon': Icons.local_pharmacy},
    {'value': 'retail', 'label': 'Retail Shop', 'icon': Icons.storefront},
    {'value': 'bakery', 'label': 'Bakery', 'icon': Icons.cake},
    {'value': 'electronics', 'label': 'Electronics', 'icon': Icons.devices},
    {'value': 'fashion', 'label': 'Fashion', 'icon': Icons.checkroom},
    {'value': 'services', 'label': 'Services', 'icon': Icons.handyman},
    {'value': 'other', 'label': 'Other', 'icon': Icons.category},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _emailController.text = authProvider.email ?? '';
    _phoneController.text = authProvider.phone ?? '';
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Merchant'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Check if already has pending application
          if (authProvider.hasPendingMerchantApplication) {
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

                  // Business Type Selection
                  _buildSectionTitle('Business Type *'),
                  SizedBox(height: 1.h),
                  _buildBusinessTypeSelector(),
                  SizedBox(height: 3.h),

                  // Business Information
                  _buildSectionTitle('Business Information'),
                  SizedBox(height: 1.h),
                  _buildTextField(
                    controller: _businessNameController,
                    label: 'Business Name *',
                    hint: 'Enter your business name',
                    icon: Icons.business,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Business name is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Business name must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 2.h),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Business Description',
                    hint: 'Describe your business (products, services, etc.)',
                    icon: Icons.description,
                    maxLines: 3,
                  ),
                  SizedBox(height: 2.h),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Business Address *',
                    hint: 'Enter your business address',
                    icon: Icons.location_on,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Business address is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 3.h),

                  // Contact Information
                  _buildSectionTitle('Contact Information'),
                  SizedBox(height: 1.h),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email Address *',
                    hint: 'your@email.com',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!value.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 2.h),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number *',
                    hint: '+1 (555) 123-4567',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      return null;
                    },
                  ),
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
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade400,
            Colors.green.shade600,
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.store,
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
                  'Start Selling Today',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Join our marketplace and reach thousands of customers',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
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
      ),
    );
  }

  Widget _buildBusinessTypeSelector() {
    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: _businessTypes.map((type) {
        final isSelected = _selectedBusinessType == type['value'];
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
              Text(type['label'] as String),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedBusinessType = type['value'] as String);
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
          borderRadius: BorderRadius.circular(12),
        ),
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
                    color: theme.colorScheme.onSurface,
                  ),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Merchant Agreement',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ', and I understand that my application will be reviewed by the admin team.'),
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
          backgroundColor: Colors.green,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
                  const Icon(Icons.send, color: Colors.white),
                  SizedBox(width: 2.w),
                  Text(
                    'Submit Application',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoBox() {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
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
                  'What happens next?',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '1. Our team will review your application\n'
                  '2. You\'ll receive a notification once approved\n'
                  '3. You can then create stores and start selling',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.blue.shade700,
                    height: 1.5,
                  ),
                ),
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
              'Application Under Review',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Your merchant application is being reviewed by our team. We\'ll notify you once it\'s processed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 4.h),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
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
        const SnackBar(
          content: Text('Please accept the terms and conditions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await authProvider.applyAsMerchant(
      businessName: _businessNameController.text.trim(),
      businessType: _selectedBusinessType,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      address: _addressController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to submit application'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

