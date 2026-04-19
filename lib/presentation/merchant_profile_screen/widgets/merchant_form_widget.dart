import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../models/merchant_model.dart';
import '../../../providers/merchant_provider.dart';
import '../../../l10n/generated/app_localizations.dart';

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

  static const List<String> _businessTypes = [
    'restaurant',
    'grocery',
    'pharmacy',
    'retail',
    'services',
    'bakery',
    'coffee',
    'marketplace',
    'electronics',
    'fashion',
    'beauty',
    'sports',
    'pets',
    'home',
    'other',
  ];

  String _businessTypeLabel(String type) {
    return type[0].toUpperCase() + type.substring(1);
  }

  @override
  void initState() {
    super.initState();
    _businessNameController =
        TextEditingController(text: widget.merchant?.businessName ?? '');
    _addressController =
        TextEditingController(text: widget.merchant?.address ?? '');
    _descriptionController =
        TextEditingController(text: widget.merchant?.description ?? '');

    // Ensure the selected business type is in our list, otherwise null
    final existingType = widget.merchant?.businessType;
    if (existingType != null && _businessTypes.contains(existingType)) {
      _selectedBusinessType = existingType;
    } else {
      _selectedBusinessType = null;
    }
  }

  @override
  void didUpdateWidget(covariant MerchantFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh controllers if merchant data changed (e.g. after reload)
    if (widget.merchant != oldWidget.merchant && widget.merchant != null) {
      _businessNameController.text = widget.merchant!.businessName;
      _addressController.text = widget.merchant!.address ?? '';
      _descriptionController.text = widget.merchant!.description ?? '';

      final existingType = widget.merchant!.businessType;
      setState(() {
        _selectedBusinessType =
            (existingType != null && _businessTypes.contains(existingType))
                ? existingType
                : null;
      });
    }
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
      // Update existing merchant — BUG 4 FIX:
      // Use merchant.id (the merchants table PK). If PGRST116 persists,
      // the provider's updateMerchant now also filters by user_id as fallback.
      success =
          await merchantProvider.updateMerchant(widget.merchant!.id, payload);
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.merchant == null
                ? AppLocalizations.of(context)!.merchantProfileCreatedSuccessfully
                : AppLocalizations.of(context)!.merchantProfileUpdatedSuccessfully, maxLines: 1, overflow: TextOverflow.ellipsis),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            merchantProvider.error ?? AppLocalizations.of(context)!.failedToSaveMerchantProfile, maxLines: 1, overflow: TextOverflow.ellipsis),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                Icon(
                  isEditMode ? Icons.edit : Icons.add_business,
                  color: theme.colorScheme.primary,
                  size: 24.sp,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditMode
                            ? AppLocalizations.of(context)!.editMerchantProfile
                            : AppLocalizations.of(context)!.createMerchantProfile,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 0.5.h),
                      Text(
                        isEditMode
                            ? AppLocalizations.of(context)!.updateYourBusinessInformation
                            : AppLocalizations.of(context)!.setUpYourMerchantAccount,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: theme.colorScheme.onSurfaceVariant,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Business Name
          Text(
            AppLocalizations.of(context)!.businessName2,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 1.h),
          TextFormField(
            controller: _businessNameController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.enterYourBusinessName,
              prefixIcon: const Icon(Icons.business),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppLocalizations.of(context)!.businessNameIsRequired;
              }
              return null;
            },
          ),
          SizedBox(height: 2.h),

          // Business Type
          Text(
            AppLocalizations.of(context)!.businessType,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 1.h),
          DropdownButtonFormField<String>(
            value: _selectedBusinessType,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.selectBusinessType,
              prefixIcon: const Icon(Icons.category),
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
                  _businessTypeLabel(type),
                  style: TextStyle(fontSize: 14.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
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
            AppLocalizations.of(context)!.address2,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 1.h),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.enterYourBusinessAddress,
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppLocalizations.of(context)!.addressIsRequired;
              }
              return null;
            },
          ),
          SizedBox(height: 2.h),

          // Description
          Text(
            AppLocalizations.of(context)!.description,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 1.h),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.describeYourBusinessOptional,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 48),
                child: Icon(Icons.description),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
            ),
            maxLines: 4,
          ),
          SizedBox(height: 3.h),

          // SESSION 20 FIX: Verification Status — use isApproved (not isVerified)
          // The merchant's status='approved' is what matters, not the separate
          // is_verified boolean which may not be set in the DB.
          if (isEditMode) ...[
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: widget.merchant!.isApproved
                    ? Colors.green.shade50
                    : widget.merchant!.isRejected
                        ? Colors.red.shade50
                        : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: widget.merchant!.isApproved
                      ? Colors.green.shade200
                      : widget.merchant!.isRejected
                          ? Colors.red.shade200
                          : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.merchant!.isApproved
                        ? Icons.verified
                        : widget.merchant!.isRejected
                            ? Icons.cancel
                            : Icons.pending,
                    color: widget.merchant!.isApproved
                        ? Colors.green
                        : widget.merchant!.isRejected
                            ? Colors.red
                            : Colors.orange,
                    size: 20.sp,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.merchant!.isApproved
                              ? AppLocalizations.of(context)!.verifiedMerchant
                              : widget.merchant!.isRejected
                                  ? AppLocalizations.of(context)!.applicationRejected
                                  : AppLocalizations.of(context)!.verificationPending,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: widget.merchant!.isApproved
                                ? Colors.green.shade800
                                : widget.merchant!.isRejected
                                    ? Colors.red.shade800
                                    : Colors.orange.shade800,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (!widget.merchant!.isApproved &&
                            !widget.merchant!.isRejected)
                          Padding(
                            padding: EdgeInsets.only(top: 0.5.h),
                            child: Text(
                              AppLocalizations.of(context)!.yourProfileIsUnderReview,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.orange.shade700,
                              ), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        if (widget.merchant!.isRejected &&
                            widget.merchant!.rejectionReason != null)
                          Padding(
                            padding: EdgeInsets.only(top: 0.5.h),
                            child: Text(
                              'Reason: ${widget.merchant!.rejectionReason}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.red.shade700,
                              ), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                      ],
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
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: merchantProvider.isLoading
                      ? SizedBox(
                          height: 20.sp,
                          width: 20.sp,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          isEditMode ? AppLocalizations.of(context)!.saveChanges2 : AppLocalizations.of(context)!.createMerchant,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              );
            },
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }
}