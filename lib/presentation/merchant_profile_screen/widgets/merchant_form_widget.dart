import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../models/merchant_model.dart';
import '../../../providers/merchant_provider.dart';

class MerchantFormWidget extends StatefulWidget {
  final Merchant? merchant;
  final String userId;
  final VoidCallback onSuccess;

  const MerchantFormWidget({
    super.key,
    this.merchant,
    required this.userId,
    required this.onSuccess,
  });

  @override
  State<MerchantFormWidget> createState() => _MerchantFormWidgetState();
}

class _MerchantFormWidgetState extends State<MerchantFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessNameController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  String? _selectedBusinessType;

  final List<String> _businessTypes = [
    'restaurant',
    'grocery',
    'pharmacy',
    'retail',
    'services',
  ];

  @override
  void initState() {
    super.initState();
    _businessNameController =
        TextEditingController(text: widget.merchant?.businessName ?? '');
    _addressController =
        TextEditingController(text: widget.merchant?.address ?? '');
    _descriptionController =
        TextEditingController(text: widget.merchant?.description ?? '');
    _selectedBusinessType = widget.merchant?.businessType;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final merchantProvider = context.read<MerchantProvider>();

    final payload = {
      'business_name': _businessNameController.text.trim(),
      'address': _addressController.text.trim(),
      'description': _descriptionController.text.trim(),
      if (_selectedBusinessType != null) 'business_type': _selectedBusinessType,
    };

    bool success;
    if (widget.merchant == null) {
      // Create new merchant
      success = await merchantProvider.createMerchant(widget.userId, payload);
    } else {
      // Update existing merchant
      success =
          await merchantProvider.updateMerchant(widget.merchant!.id, payload);
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.merchant == null
                ? 'Merchant profile created successfully'
                : 'Merchant profile updated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
      widget.onSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            merchantProvider.error ?? 'Failed to save merchant profile',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.merchant != null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                Icon(
                  isEditMode ? Icons.edit : Icons.add_business,
                  color: Colors.blue,
                  size: 24.sp,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditMode
                            ? 'Edit Merchant Profile'
                            : 'Create Merchant Profile',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        isEditMode
                            ? 'Update your business information'
                            : 'Set up your merchant account',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Business Name
          Text(
            'Business Name *',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          TextFormField(
            controller: _businessNameController,
            decoration: InputDecoration(
              hintText: 'Enter your business name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Business name is required';
              }
              return null;
            },
          ),
          SizedBox(height: 2.h),

          // Business Type
          Text(
            'Business Type',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          DropdownButtonFormField<String>(
            initialValue: _selectedBusinessType,
            decoration: InputDecoration(
              hintText: 'Select business type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
            ),
            items: _businessTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  type[0].toUpperCase() + type.substring(1),
                  style: TextStyle(fontSize: 14.sp),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBusinessType = value;
              });
            },
          ),
          SizedBox(height: 2.h),

          // Address
          Text(
            'Address *',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              hintText: 'Enter your business address',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Address is required';
              }
              return null;
            },
          ),
          SizedBox(height: 2.h),

          // Description
          Text(
            'Description',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: 'Describe your business (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
            ),
            maxLines: 4,
          ),
          SizedBox(height: 3.h),

          // Verification Status (Edit mode only)
          if (isEditMode) ...[
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: widget.merchant!.isVerified
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: widget.merchant!.isVerified
                      ? Colors.green.shade200
                      : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.merchant!.isVerified
                        ? Icons.verified
                        : Icons.pending,
                    color: widget.merchant!.isVerified
                        ? Colors.green
                        : Colors.orange,
                    size: 20.sp,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      widget.merchant!.isVerified
                          ? 'Verified Merchant'
                          : 'Verification Pending',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: widget.merchant!.isVerified
                            ? Colors.green.shade800
                            : Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 3.h),
          ],

          // Submit Button
          Consumer<MerchantProvider>(
            builder: (context, merchantProvider, child) {
              return SizedBox(
                width: double.infinity,
                height: 6.h,
                child: ElevatedButton(
                  onPressed: merchantProvider.isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: merchantProvider.isLoading
                      ? SizedBox(
                          height: 20.sp,
                          width: 20.sp,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          isEditMode ? 'Save Changes' : 'Create Merchant',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
