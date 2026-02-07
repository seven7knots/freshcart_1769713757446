import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/ads_service.dart';
import '../../../services/marketplace_service.dart';
import '../../../services/product_service.dart';
import '../../../services/store_service.dart';
import '../../../services/supabase_service.dart';
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
  final _imageUrlController = TextEditingController();
  final _linkTargetController = TextEditingController();

  bool _isLoading = false;
  bool _isActive = true;

  bool get _isCreate => widget.contentId == null;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final data = widget.contentData;
    if (data == null) return;

    _titleController.text = (data['title'] ?? data['name'] ?? '').toString();
    _descriptionController.text = (data['description'] ?? '').toString();

    final price = data['price'];
    if (price != null) {
      _priceController.text = price.toString();
    }

    _imageUrlController.text =
        (data['image_url'] ?? data['imageUrl'] ?? data['cover_image_url'] ?? '')
            .toString();

    _linkTargetController.text =
        (data['target_route'] ?? data['link_target'] ?? data['deeplink'] ?? '')
            .toString();

    _isActive = _extractIsActive(widget.contentType, data);
  }

  bool _extractIsActive(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'ad':
        final status = (data['status'] ?? '').toString().toLowerCase();
        if (status.isNotEmpty) return status == 'active';
        return (data['is_active'] ?? true) == true;
      case 'product':
        return (data['is_available'] ?? data['is_active'] ?? true) == true;
      case 'store':
        return (data['is_active'] ?? true) == true;
      case 'marketplace':
        return (data['is_active'] ?? data['status'] == 'active') == true;
      case 'category':
        return (data['is_active'] ?? true) == true;
      default:
        return true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _linkTargetController.dispose();
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
        case 'category':
          await _saveCategory();
          break;
        default:
          throw Exception('Unsupported content type: ${widget.contentType}');
      }

      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAd() async {
    final adsService = AdsService();
    final payload = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'status': _isActive ? 'active' : 'paused',
      if (_imageUrlController.text.trim().isNotEmpty)
        'image_url': _imageUrlController.text.trim(),
      if (_linkTargetController.text.trim().isNotEmpty)
        'target_route': _linkTargetController.text.trim(),
    };

    if (_isCreate) {
      await adsService.createAd(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        format: 'banner',
        imageUrl: _imageUrlController.text.trim().isNotEmpty
            ? _imageUrlController.text.trim()
            : '',
        linkType: 'external',
        externalUrl: _linkTargetController.text.trim().isNotEmpty
            ? _linkTargetController.text.trim()
            : null,
      );
      return;
    }

    await adsService.updateAd(widget.contentId!, payload);
  }

  Future<void> _saveProduct() async {
    final payload = <String, dynamic>{
      'name': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0,
      'is_available': _isActive,
      if (_imageUrlController.text.trim().isNotEmpty)
        'image_url': _imageUrlController.text.trim(),
    };

    if (_isCreate) {
      final storeId = (widget.contentData?['store_id'] ??
              widget.contentData?['storeId'] ??
              '')
          .toString()
          .trim();
      if (storeId.isEmpty) {
        throw Exception('Missing store_id for product creation');
      }
      payload['store_id'] = storeId;

      await ProductService.createProduct(
        storeId: storeId,
        name: payload['name'] as String,
        description: payload['description'] as String?,
        price: payload['price'] as double,
        isAvailable: payload['is_available'] as bool,
        imageUrl: payload['image_url'] as String?,
      );
      return;
    }

    await ProductService.updateProduct(widget.contentId!, payload);
  }

  Future<void> _saveStore() async {
    final payload = <String, dynamic>{
      'name': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'is_active': _isActive,
      if (_imageUrlController.text.trim().isNotEmpty)
        'image_url': _imageUrlController.text.trim(),
    };

    if (_isCreate) {
      await StoreService.createStore(
        name: payload['name'] as String,
        description: payload['description'] as String?,
        isActive: payload['is_active'] as bool,
        imageUrl: payload['image_url'] as String?,
      );
      return;
    }

    await StoreService.updateStore(widget.contentId!, payload);
  }

  Future<void> _saveMarketplaceListing() async {
    final marketplaceService = MarketplaceService();

    if (_isCreate) {
      throw Exception('Marketplace creation is handled in listing flow');
    }

    await marketplaceService.updateListing(
      widget.contentId!,
      {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()),
        'is_active': _isActive,
        if (_imageUrlController.text.trim().isNotEmpty)
          'image_url': _imageUrlController.text.trim(),
      },
    );
  }

  Future<void> _saveCategory() async {
    final payload = <String, dynamic>{
      'name': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'is_active': _isActive,
      if (_imageUrlController.text.trim().isNotEmpty)
        'image_url': _imageUrlController.text.trim(),
    };

    if (_isCreate) {
      await SupabaseService.client.from('categories').insert(payload);
      return;
    }

    await SupabaseService.client
        .from('categories')
        .update(payload)
        .eq('id', widget.contentId!);
  }

  @override
  Widget build(BuildContext context) {
    final supportsPrice =
        widget.contentType == 'product' || widget.contentType == 'marketplace';

    final supportsImage = widget.contentType == 'ad' ||
        widget.contentType == 'product' ||
        widget.contentType == 'store' ||
        widget.contentType == 'category';

    final supportsLinkTarget = widget.contentType == 'ad';

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.55,
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
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_isCreate ? 'Create' : 'Edit'} ${widget.contentType.toUpperCase()}',
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.h),
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
                          if (value == null || value.trim().isEmpty) {
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
                      if (supportsPrice) ...[
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
                      if (supportsImage) ...[
                        SizedBox(height: 2.h),
                        TextFormField(
                          controller: _imageUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Image URL',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      if (supportsLinkTarget) ...[
                        SizedBox(height: 2.h),
                        TextFormField(
                          controller: _linkTargetController,
                          decoration: const InputDecoration(
                            labelText: 'Link Target (route/deeplink)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      SizedBox(height: 2.h),
                      SwitchListTile(
                        title: const Text('Active'),
                        value: _isActive,
                        onChanged: _isLoading
                            ? null
                            : (value) => setState(() => _isActive = value),
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
                              : Text(_isCreate ? 'Create' : 'Save Changes'),
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
