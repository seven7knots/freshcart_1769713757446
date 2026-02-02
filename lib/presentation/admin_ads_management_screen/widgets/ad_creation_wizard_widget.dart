import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/ads_service.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.existingAd != null) {
      _loadExistingAd();
    }
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
      }

      widget.onAdCreated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save ad: $e')));
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
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                widget.existingAd != null ? 'Edit Ad' : 'Create New Ad',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                              : Text(_currentStep == 3 ? 'Save' : 'Continue'),
                        ),
                        SizedBox(width: 2.w),
                        if (_currentStep > 0)
                          TextButton(
                            onPressed: details.onStepCancel,
                            child: const Text('Back'),
                          ),
                      ],
                    ),
                  );
                },
                steps: [
                  Step(
                    title: const Text('Format & Content'),
                    content: _buildFormatStep(context),
                    isActive: _currentStep >= 0,
                  ),
                  Step(
                    title: const Text('Image Upload'),
                    content: _buildImageStep(context),
                    isActive: _currentStep >= 1,
                  ),
                  Step(
                    title: const Text('Deep Linking'),
                    content: _buildLinkingStep(context),
                    isActive: _currentStep >= 2,
                  ),
                  Step(
                    title: const Text('Targeting & Schedule'),
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
          Text('Select Ad Format', style: theme.textTheme.titleSmall),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            children: [
              ChoiceChip(
                label: const Text('Carousel'),
                selected: _selectedFormat == 'carousel',
                onSelected: (selected) {
                  setState(() => _selectedFormat = 'carousel');
                },
              ),
              ChoiceChip(
                label: const Text('Rotating Banner'),
                selected: _selectedFormat == 'rotating_banner',
                onSelected: (selected) {
                  setState(() => _selectedFormat = 'rotating_banner');
                },
              ),
              ChoiceChip(
                label: const Text('Fixed Banner'),
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
            decoration: const InputDecoration(
              labelText: 'Ad Title',
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
        Text('Upload Ad Image', style: theme.textTheme.titleSmall),
        SizedBox(height: 2.h),
        if (_selectedImage != null || _uploadedImageUrl != null)
          Container(
            height: 20.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                  : CustomImageWidget(
                      imageUrl: _uploadedImageUrl!,
                      fit: BoxFit.cover,
                      semanticLabel: 'Ad preview image',
                    ),
            ),
          ),
        SizedBox(height: 2.h),
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const CustomIconWidget(iconName: 'upload', size: 20),
          label: Text(
            _selectedImage != null || _uploadedImageUrl != null
                ? 'Change Image'
                : 'Select Image',
          ),
        ),
      ],
    );
  }

  Widget _buildLinkingStep(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Deep Link Destination', style: theme.textTheme.titleSmall),
        SizedBox(height: 1.h),
        DropdownButtonFormField<String>(
          initialValue: _selectedLinkType,
          decoration: const InputDecoration(
            labelText: 'Link Type',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'store', child: Text('Store')),
            DropdownMenuItem(value: 'product', child: Text('Product')),
            DropdownMenuItem(value: 'category', child: Text('Category')),
            DropdownMenuItem(value: 'collection', child: Text('Collection')),
            DropdownMenuItem(
              value: 'external_url',
              child: Text('External URL'),
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
            decoration: const InputDecoration(
              labelText: 'External URL',
              border: OutlineInputBorder(),
              hintText: 'https://example.com',
            ),
          )
        else
          TextFormField(
            initialValue: _linkTargetId,
            decoration: InputDecoration(
              labelText: '${_selectedLinkType.toUpperCase()} ID',
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => _linkTargetId = value,
          ),
      ],
    );
  }

  Widget _buildTargetingStep(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Targeting Rules', style: theme.textTheme.titleSmall),
        SizedBox(height: 1.h),
        DropdownButtonFormField<String>(
          initialValue: _selectedTargetType,
          decoration: const InputDecoration(
            labelText: 'Target Type',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'global_home', child: Text('Global Home')),
            DropdownMenuItem(value: 'store', child: Text('Specific Store')),
            DropdownMenuItem(
              value: 'category',
              child: Text('Specific Category'),
            ),
            DropdownMenuItem(value: 'product', child: Text('Specific Product')),
          ],
          onChanged: (value) {
            setState(() => _selectedTargetType = value!);
          },
        ),
        if (_selectedTargetType != 'global_home') ...[
          SizedBox(height: 2.h),
          TextFormField(
            initialValue: _targetId,
            decoration: const InputDecoration(
              labelText: 'Target ID',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _targetId = value,
          ),
        ],
        SizedBox(height: 2.h),
        Text('Schedule (Optional)', style: theme.textTheme.titleSmall),
        SizedBox(height: 1.h),
        ListTile(
          title: const Text('Start Date'),
          subtitle: Text(_startDate?.toString().split(' ')[0] ?? 'Not set'),
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
          title: const Text('End Date'),
          subtitle: Text(_endDate?.toString().split(' ')[0] ?? 'Not set'),
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
      ],
    );
  }
}
