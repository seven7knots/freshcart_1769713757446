import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/ads_service.dart';
import '../../../services/supabase_service.dart';
import '../../../l10n/generated/app_localizations.dart';

class AdCreationWizardWidget extends StatefulWidget {
  final Map<String, dynamic>? existingAd;
  final VoidCallback onAdCreated;

  const AdCreationWizardWidget({
    super.key,
    this.existingAd,
    required this.onAdCreated,
  });

  @override
  State<AdCreationWizardWidget> createState() => _AdCreationWizardWidgetState();
}

class _AdCreationWizardWidgetState extends State<AdCreationWizardWidget> {
  final AdsService _adsService = AdsService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _externalUrlController = TextEditingController();

  int _currentStep = 0;
  bool _isLoading = false;

  String _selectedFormat = 'carousel';
  File? _selectedImage;
  String? _uploadedImageUrl;
  String _selectedLinkType = 'store';
  String? _linkTargetId;
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedTargetType = 'global_home';
  String? _targetId;
  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];
  bool _isLoadingOptions = false;

  // Toggle to send push notification to all users
  bool _sendNotification = true;

  @override
  void initState() {
    super.initState();
    if (widget.existingAd != null) {
      _loadExistingAd();
    }
    _loadLinkOptions();
  }

  Future<void> _loadLinkOptions() async {
    setState(() => _isLoadingOptions = true);
    try {
      final storesResult = await SupabaseService.client
          .from('stores')
          .select('id, name')
          .order('name');
      _stores = List<Map<String, dynamic>>.from(storesResult);

      final catsResult = await SupabaseService.client
          .from('categories')
          .select('id, name')
          .order('name');
      _categories = List<Map<String, dynamic>>.from(catsResult);

      final prodsResult = await SupabaseService.client
          .from('products')
          .select('id, name')
          .eq('is_available', true)
          .order('name')
          .limit(50);
      _products = List<Map<String, dynamic>>.from(prodsResult);
    } catch (e) {
      debugPrint('[AD_WIZARD] Failed to load options: $e');
    }
    if (mounted) setState(() => _isLoadingOptions = false);
  }

  void _loadExistingAd() {
    final ad = widget.existingAd!;
    _titleController.text = ad['title'] ?? '';
    _descriptionController.text = ad['description'] ?? '';
    _selectedFormat = ad['format'] ?? 'carousel';
    _uploadedImageUrl = ad['image_url'];
    _selectedLinkType = ad['link_type'] ?? 'store';
    _linkTargetId = ad['link_target_id'];
    _externalUrlController.text = ad['external_url'] ?? '';
    if (ad['start_date'] != null) {
      _startDate = DateTime.parse(ad['start_date']);
    }
    if (ad['end_date'] != null) {
      _endDate = DateTime.parse(ad['end_date']);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _externalUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveAd() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String imageUrl = _uploadedImageUrl ?? '';

      if (_selectedImage != null) {
        imageUrl = await _adsService.uploadAdImage(_selectedImage!);
      }

      if (imageUrl.isEmpty) {
        throw Exception('Image is required');
      }

      if (widget.existingAd != null) {
        await _adsService.updateAd(widget.existingAd!['id'], {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'format': _selectedFormat,
          'image_url': imageUrl,
          'link_type': _selectedLinkType,
          'link_target_id': _linkTargetId,
          'external_url': _externalUrlController.text.isNotEmpty
              ? _externalUrlController.text
              : null,
          'start_date': _startDate?.toIso8601String(),
          'end_date': _endDate?.toIso8601String(),
        });
      } else {
        final ad = await _adsService.createAd(
          title: _titleController.text,
          description: _descriptionController.text,
          format: _selectedFormat,
          imageUrl: imageUrl,
          linkType: _selectedLinkType,
          linkTargetId: _linkTargetId,
          externalUrl: _externalUrlController.text.isNotEmpty
              ? _externalUrlController.text
              : null,
          startDate: _startDate,
          endDate: _endDate,
        );

        await _adsService.addTargetingRule(
          adId: ad['id'],
          targetType: _selectedTargetType,
          targetId: _targetId,
        );

        // Send push notification to all customers if toggled on
        if (_sendNotification) {
          final count = await _adsService.notifyCustomersAboutAd(
            adId: ad['id'],
            title: _titleController.text,
            description: _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
          );
          if (mounted && count > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Notification sent to $count users', maxLines: 1, overflow: TextOverflow.ellipsis),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }

      widget.onAdCreated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save ad: $e', maxLines: 1, overflow: TextOverflow.ellipsis)));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                widget.existingAd != null ? AppLocalizations.of(context)!.editAd : AppLocalizations.of(context)!.createNewAd,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: Stepper(
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < 3) {
                    setState(() => _currentStep++);
                  } else {
                    _saveAd();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep--);
                  }
                },
                controlsBuilder: (context, details) {
                  return Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : details.onStepContinue,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_currentStep == 3 ? AppLocalizations.of(context)!.save2 : AppLocalizations.of(context)!.continueText, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        SizedBox(width: 2.w),
                        if (_currentStep > 0)
                          TextButton(
                            onPressed: details.onStepCancel,
                            child: Text(AppLocalizations.of(context)!.back, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                    ),
                  );
                },
                steps: [
                  Step(
                    title: Text(AppLocalizations.of(context)!.formatContent, maxLines: 1, overflow: TextOverflow.ellipsis),
                    content: _buildFormatStep(context),
                    isActive: _currentStep >= 0,
                  ),
                  Step(
                    title: Text(AppLocalizations.of(context)!.imageUpload, maxLines: 1, overflow: TextOverflow.ellipsis),
                    content: _buildImageStep(context),
                    isActive: _currentStep >= 1,
                  ),
                  Step(
                    title: Text(AppLocalizations.of(context)!.deepLinking, maxLines: 1, overflow: TextOverflow.ellipsis),
                    content: _buildLinkingStep(context),
                    isActive: _currentStep >= 2,
                  ),
                  Step(
                    title: Text(AppLocalizations.of(context)!.targetingSchedule, maxLines: 1, overflow: TextOverflow.ellipsis),
                    content: _buildTargetingStep(context),
                    isActive: _currentStep >= 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatStep(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.selectAdFormat, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            children: [
              ChoiceChip(
                label: Text(AppLocalizations.of(context)!.carousel, maxLines: 1, overflow: TextOverflow.ellipsis),
                selected: _selectedFormat == 'carousel',
                onSelected: (selected) {
                  setState(() => _selectedFormat = 'carousel');
                },
              ),
              ChoiceChip(
                label: Text(AppLocalizations.of(context)!.rotatingBanner, maxLines: 1, overflow: TextOverflow.ellipsis),
                selected: _selectedFormat == 'rotating_banner',
                onSelected: (selected) {
                  setState(() => _selectedFormat = 'rotating_banner');
                },
              ),
              ChoiceChip(
                label: Text(AppLocalizations.of(context)!.fixedBanner, maxLines: 1, overflow: TextOverflow.ellipsis),
                selected: _selectedFormat == 'fixed_banner',
                onSelected: (selected) {
                  setState(() => _selectedFormat = 'fixed_banner');
                },
              ),
            ],
          ),
          SizedBox(height: 2.h),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.adTitle,
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.titleIsRequired;
              }
              return null;
            },
          ),
          SizedBox(height: 2.h),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.description,
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildImageStep(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.uploadAdImage, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 2.h),
        if (_selectedImage != null || _uploadedImageUrl != null)
          Container(
            height: 20.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                  : CustomImageWidget(
                      imageUrl: _uploadedImageUrl!,
                      fit: BoxFit.cover,
                      semanticLabel: AppLocalizations.of(context)!.adPreviewImage,
                    ),
            ),
          ),
        SizedBox(height: 2.h),
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const CustomIconWidget(iconName: 'upload', size: 20),
          label: Text(
            _selectedImage != null || _uploadedImageUrl != null
                ? AppLocalizations.of(context)!.changeImage
                : AppLocalizations.of(context)!.selectImage, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildLinkingStep(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.deepLinkDestination, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 1.h),
        DropdownButtonFormField<String>(
          initialValue: _selectedLinkType,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.linkType,
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(value: 'store', child: Text(AppLocalizations.of(context)!.store, maxLines: 1, overflow: TextOverflow.ellipsis)),
            DropdownMenuItem(value: 'product', child: Text(AppLocalizations.of(context)!.product, maxLines: 1, overflow: TextOverflow.ellipsis)),
            DropdownMenuItem(value: 'category', child: Text(AppLocalizations.of(context)!.category, maxLines: 1, overflow: TextOverflow.ellipsis)),
            DropdownMenuItem(value: 'collection', child: Text(AppLocalizations.of(context)!.collection, maxLines: 1, overflow: TextOverflow.ellipsis)),
            DropdownMenuItem(
              value: 'external_url',
              child: Text(AppLocalizations.of(context)!.externalUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
          onChanged: (value) {
            setState(() => _selectedLinkType = value!);
          },
        ),
        SizedBox(height: 2.h),
        if (_selectedLinkType == 'external_url')
          TextFormField(
            controller: _externalUrlController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.externalUrl,
              border: OutlineInputBorder(),
              hintText: 'https://example.com',
            ),
          )
        else if (_isLoadingOptions)
          const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(strokeWidth: 2),
          ))
        else
          _buildLinkTargetDropdown(),
      ],
    );
  }

  Widget _buildLinkTargetDropdown() {
    List<Map<String, dynamic>> options;
    String label;
    switch (_selectedLinkType) {
      case 'store':
        options = _stores;
        label = AppLocalizations.of(context)!.selectStore;
        break;
      case 'category':
        options = _categories;
        label = AppLocalizations.of(context)!.selectCategory;
        break;
      case 'product':
        options = _products;
        label = AppLocalizations.of(context)!.selectProduct;
        break;
      case 'collection':
        options = _categories;
        label = AppLocalizations.of(context)!.selectCollection;
        break;
      default:
        options = [];
        label = AppLocalizations.of(context)!.selectTarget;
    }
    if (options.isEmpty) {
      return Text(AppLocalizations.of(context)!.noItemsFound, style: TextStyle(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    return DropdownButtonFormField<String>(
      value: options.any((o) => o['id'].toString() == _linkTargetId) ? _linkTargetId : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      isExpanded: true,
      items: options.map((o) => DropdownMenuItem<String>(
        value: o['id'].toString(),
        child: Text(o['name'] ?? AppLocalizations.of(context)!.unknown, overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: (value) => setState(() => _linkTargetId = value),
    );
  }

  Widget _buildTargetingStep(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.targetingRules, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 1.h),
        DropdownButtonFormField<String>(
          initialValue: _selectedTargetType,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.targetType,
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(value: 'global_home', child: Text(AppLocalizations.of(context)!.globalHome, maxLines: 1, overflow: TextOverflow.ellipsis)),
            DropdownMenuItem(value: 'store', child: Text(AppLocalizations.of(context)!.specificStore, maxLines: 1, overflow: TextOverflow.ellipsis)),
            DropdownMenuItem(
              value: 'category',
              child: Text(AppLocalizations.of(context)!.specificCategory, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            DropdownMenuItem(value: 'product', child: Text(AppLocalizations.of(context)!.specificProduct, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (value) {
            setState(() => _selectedTargetType = value!);
          },
        ),
        if (_selectedTargetType != 'global_home') ...[
          SizedBox(height: 2.h),
          if (_isLoadingOptions)
            const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ))
          else
            _buildTargetDropdown(),
        ],
        SizedBox(height: 2.h),
        Text(AppLocalizations.of(context)!.scheduleOptional, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 1.h),
        ListTile(
          title: Text(AppLocalizations.of(context)!.startDate, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(_startDate?.toString().split(' ')[0] ?? AppLocalizations.of(context)!.notSet, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: const CustomIconWidget(
            iconName: 'calendar_today',
            size: 20,
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _startDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() => _startDate = date);
            }
          },
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.endDate, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(_endDate?.toString().split(' ')[0] ?? AppLocalizations.of(context)!.notSet, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: const CustomIconWidget(
            iconName: 'calendar_today',
            size: 20,
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate:
                  _endDate ?? DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() => _endDate = date);
            }
          },
        ),

        // Push notification toggle (only for new ads)
        if (widget.existingAd == null) ...[
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(26),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withAlpha(77)),
            ),
            child: SwitchListTile(
              title: Text(AppLocalizations.of(context)!.sendPushNotification, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(AppLocalizations.of(context)!.notifyAllCustomersAboutThisAd, maxLines: 1, overflow: TextOverflow.ellipsis),
              value: _sendNotification,
              activeColor: Colors.blue,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _sendNotification = v),
              secondary: const Icon(Icons.notifications_active, color: Colors.blue),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTargetDropdown() {
    List<Map<String, dynamic>> options;
    String label;
    switch (_selectedTargetType) {
      case 'store':
        options = _stores;
        label = AppLocalizations.of(context)!.selectStore;
        break;
      case 'category':
        options = _categories;
        label = AppLocalizations.of(context)!.selectCategory;
        break;
      case 'product':
        options = _products;
        label = AppLocalizations.of(context)!.selectProduct;
        break;
      default:
        options = [];
        label = AppLocalizations.of(context)!.selectTarget;
    }
    if (options.isEmpty) {
      return Text(AppLocalizations.of(context)!.noItemsFound, style: TextStyle(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    return DropdownButtonFormField<String>(
      value: options.any((o) => o['id'].toString() == _targetId) ? _targetId : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      isExpanded: true,
      items: options.map((o) => DropdownMenuItem<String>(
        value: o['id'].toString(),
        child: Text(o['name'] ?? AppLocalizations.of(context)!.unknown, overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: (value) => setState(() => _targetId = value),
    );
  }
}