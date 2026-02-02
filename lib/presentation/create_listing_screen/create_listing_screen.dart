import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/marketplace_service.dart';
import '../../theme/app_theme.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final List<File> _selectedImages = [];
  String _selectedCategory = 'electronics';
  String _selectedCondition = 'good';
  bool _isNegotiable = true;
  bool _isUploading = false;

  final categories = [
    'electronics',
    'furniture',
    'clothing',
    'home',
    'vehicles',
    'sports',
    'books',
    'other'
  ];
  final conditions = ['new', 'like_new', 'good', 'fair', 'poor'];

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.length + _selectedImages.length > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 5 images allowed')));
      return;
    }
    setState(() {
      _selectedImages.addAll(images.map((img) => File(img.path)));
    });
  }

  Future<void> _createListing() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one image')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final service = MarketplaceService();
      final imageUrls = await service.uploadImages(_selectedImages);
      await service.createListing(
        title: _titleController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        category: _selectedCategory,
        condition: _selectedCondition,
        imageUrls: imageUrls,
        locationText: _locationController.text.isNotEmpty
            ? _locationController.text
            : null,
        isNegotiable: _isNegotiable,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Listing created successfully')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Create Listing',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(4.w),
          children: [
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 20.h,
                decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.grey[400]!)),
                child: _selectedImages.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Icon(Icons.add_photo_alternate,
                                size: 40, color: Colors.grey[600]),
                            SizedBox(height: 1.h),
                            Text('Add Images (Max 5)',
                                style: TextStyle(
                                    fontSize: 13.sp, color: Colors.grey[600]))
                          ])
                    : GridView.builder(
                        padding: EdgeInsets.all(2.w),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8),
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) => Stack(
                          children: [
                            ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.file(_selectedImages[index],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity)),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _selectedImages.removeAt(index)),
                                child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.close,
                                        size: 16, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            SizedBox(height: 2.h),
            TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                    labelText: 'Title', border: OutlineInputBorder()),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
            SizedBox(height: 2.h),
            TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 4,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
            SizedBox(height: 2.h),
            DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                    labelText: 'Category', border: OutlineInputBorder()),
                items: categories
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c[0].toUpperCase() + c.substring(1))))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!)),
            SizedBox(height: 2.h),
            DropdownButtonFormField<String>(
                initialValue: _selectedCondition,
                decoration: const InputDecoration(
                    labelText: 'Condition', border: OutlineInputBorder()),
                items: conditions
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.replaceAll('_', ' ').toUpperCase())))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCondition = v!)),
            SizedBox(height: 2.h),
            TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                    labelText: 'Price (USD)',
                    border: OutlineInputBorder(),
                    prefixText: '\$'),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
            SizedBox(height: 2.h),
            TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                    labelText: 'Location (Optional)',
                    border: OutlineInputBorder())),
            SizedBox(height: 2.h),
            SwitchListTile(
                title: const Text('Price Negotiable'),
                value: _isNegotiable,
                onChanged: (v) => setState(() => _isNegotiable = v)),
            SizedBox(height: 3.h),
            ElevatedButton(
              onPressed: _isUploading ? null : _createListing,
              style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 6.h)),
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Post Listing'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
