import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/ads_service.dart';
import '../../../services/marketplace_service.dart';
import '../../../services/product_service.dart';
import '../../../services/store_service.dart';
import '../../../theme/app_theme.dart';

class ContentEditModalWidget extends StatefulWidget {
  final String contentType;
  final String? contentId;
  final Map<String, dynamic>? contentData;
  final VoidCallback onSaved;

  const ContentEditModalWidget({
    super.key,
    required this.contentType,
    this.contentId,
    this.contentData,
    required this.onSaved,
  });

  @override
  State<ContentEditModalWidget> createState() => _ContentEditModalWidgetState();
}

class _ContentEditModalWidgetState extends State<ContentEditModalWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    if (widget.contentData != null) {
      _titleController.text =
          widget.contentData!['title'] ?? widget.contentData!['name'] ?? '';
      _descriptionController.text = widget.contentData!['description'] ?? '';
      _priceController.text = widget.contentData!['price']?.toString() ?? '';
      _isActive = widget.contentData!['is_active'] ??
          widget.contentData!['status'] == 'active';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveContent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      switch (widget.contentType) {
        case 'ad':
          await _saveAd();
          break;
        case 'product':
          await _saveProduct();
          break;
        case 'store':
          await _saveStore();
          break;
        case 'marketplace':
          await _saveMarketplaceListing();
          break;
        default:
          throw Exception('Unsupported content type');
      }

      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAd() async {
    final adsService = AdsService();
    if (widget.contentId != null) {
      await adsService.updateAd(widget.contentId!, {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'status': _isActive ? 'active' : 'paused',
      });
    }
  }

  Future<void> _saveProduct() async {
    final productService = ProductService();
    if (widget.contentId != null) {
      // ProductService only provides read operations, not update operations
    }
  }

  Future<void> _saveStore() async {
    final storeService = StoreService();
    if (widget.contentId != null) {
      // StoreService only provides read operations, not update operations
    }
  }

  Future<void> _saveMarketplaceListing() async {
    final marketplaceService = MarketplaceService();
    if (widget.contentId != null) {
      await marketplaceService.updateListing(
        widget.contentId!,
        {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'price': double.tryParse(_priceController.text),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                'Edit ${widget.contentType.toUpperCase()}',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.all(4.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title or Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 2.h),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                      ),
                      if (widget.contentType == 'product' ||
                          widget.contentType == 'marketplace') ...[
                        SizedBox(height: 2.h),
                        TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            border: OutlineInputBorder(),
                            prefixText: '\$',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                      SizedBox(height: 2.h),
                      SwitchListTile(
                        title: const Text('Active or Available'),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() => _isActive = value);
                        },
                      ),
                      SizedBox(height: 3.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveContent,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
