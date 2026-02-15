import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../models/user_address_model.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../map_location_picker/map_location_picker_screen.dart';

class MyAddressesScreen extends StatefulWidget {
  const MyAddressesScreen({super.key});

  @override
  State<MyAddressesScreen> createState() => _MyAddressesScreenState();
}

class _MyAddressesScreenState extends State<MyAddressesScreen> {
  final _locationService = LocationService();
  List<UserAddress> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    try {
      _addresses = await _locationService.loadSavedAddresses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load addresses: $e')),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveAddresses() async {
    try {
      await _locationService.saveAddresses(_addresses);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addAddress() async {
    final result = await Navigator.push<UserAddress>(
      context,
      MaterialPageRoute(
        builder: (_) => const UniversalMapPickerScreen(
          mode: MapPickerMode.delivery,
        ),
      ),
    );
    if (result == null || !mounted) return;

    final label = await _showLabelDialog(initialLabel: 'HOME');
    if (label == null) return;

    final detail = await _showDetailDialog();

    final newAddr = result.copyWith(
      label: label,
      detail: detail ?? '',
      isDefault: _addresses.isEmpty,
    );

    setState(() => _addresses.add(newAddr));
    await _saveAddresses();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address added'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _editAddress(int index) async {
    final addr = _addresses[index];

    final result = await Navigator.push<UserAddress>(
      context,
      MaterialPageRoute(
        builder: (_) => UniversalMapPickerScreen(
          mode: MapPickerMode.delivery,
          initialLat: addr.lat,
          initialLng: addr.lng,
        ),
      ),
    );
    if (result == null || !mounted) return;

    final label = await _showLabelDialog(initialLabel: addr.label);
    if (label == null) return;

    final detail = await _showDetailDialog(initialDetail: addr.detail);

    setState(() {
      _addresses[index] = result.copyWith(
        label: label,
        detail: detail ?? addr.detail,
        isDefault: addr.isDefault,
      );
    });
    await _saveAddresses();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address updated'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _deleteAddress(int index) async {
    final addr = _addresses[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address?'),
        content: Text('Remove "${addr.label}" at ${addr.address}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final wasDefault = addr.isDefault;
    setState(() => _addresses.removeAt(index));

    // If deleted address was default, make the first one default
    if (wasDefault && _addresses.isNotEmpty) {
      setState(() {
        _addresses[0] = _addresses[0].copyWith(isDefault: true);
      });
    }

    await _saveAddresses();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address deleted'), backgroundColor: Colors.orange),
      );
    }
  }

  Future<void> _setDefault(int index) async {
    setState(() {
      for (int i = 0; i < _addresses.length; i++) {
        _addresses[i] = _addresses[i].copyWith(isDefault: i == index);
      }
    });
    await _saveAddresses();
    await _locationService.cacheSelectedAddress(_addresses[index]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${_addresses[index].label}" set as default'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<String?> _showLabelDialog({String initialLabel = 'HOME'}) async {
    String selected = initialLabel;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Address Label'),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['HOME', 'WORK', 'GYM', 'FAMILY', 'OTHER'].map((label) {
              final isSelected = selected == label;
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                selectedColor: AppTheme.kjRed.withOpacity(0.2),
                onSelected: (_) => setDialogState(() => selected = label),
              );
            }).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, selected),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kjRed, foregroundColor: Colors.white),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showDetailDialog({String? initialDetail}) async {
    final controller = TextEditingController(text: initialDetail ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Address Details'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Building, floor, apartment (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, ''), child: const Text('Skip')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kjRed, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('My Addresses',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: _loadAddresses,
                  child: ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: _addresses.length,
                    itemBuilder: (context, index) => _buildAddressCard(theme, index),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAddress,
        backgroundColor: AppTheme.kjRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Add Address'),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_outlined, size: 20.w, color: theme.colorScheme.outline),
            SizedBox(height: 3.h),
            Text('No Saved Addresses', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 1.h),
            Text('Add your delivery addresses for faster checkout',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: theme.colorScheme.onSurfaceVariant)),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: _addAddress,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Add Your First Address'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kjRed,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(ThemeData theme, int index) {
    final addr = _addresses[index];
    final hasCoords = addr.hasCoordinates;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: addr.isDefault
              ? AppTheme.kjRed.withOpacity(0.5)
              : theme.colorScheme.outline.withOpacity(0.15),
          width: addr.isDefault ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: addr.isDefault
                        ? AppTheme.kjRed.withOpacity(0.1)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _labelIcon(addr.label),
                    color: addr.isDefault ? AppTheme.kjRed : theme.colorScheme.onSurfaceVariant,
                    size: 6.w,
                  ),
                ),
                SizedBox(width: 3.w),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                          decoration: BoxDecoration(
                            color: addr.isDefault
                                ? AppTheme.kjRed.withOpacity(0.1)
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            addr.label.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: addr.isDefault ? AppTheme.kjRed : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (addr.isDefault) ...[
                          SizedBox(width: 2.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('DEFAULT',
                                style: TextStyle(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green)),
                          ),
                        ],
                        if (hasCoords) ...[
                          SizedBox(width: 2.w),
                          Icon(Icons.gps_fixed, size: 3.5.w, color: Colors.green),
                        ],
                      ]),
                      SizedBox(height: 0.8.h),
                      Text(
                        addr.address,
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if ((addr.detail ?? '').isNotEmpty) ...[
                        SizedBox(height: 0.3.h),
                        Text(
                          addr.detail ?? '',
                          style: TextStyle(fontSize: 11.sp, color: theme.colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Popup menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 5.w, color: theme.colorScheme.onSurfaceVariant),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editAddress(index);
                        break;
                      case 'default':
                        _setDefault(index);
                        break;
                      case 'delete':
                        _deleteAddress(index);
                        break;
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [
                      Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit'),
                    ])),
                    if (!addr.isDefault)
                      const PopupMenuItem(value: 'default', child: Row(children: [
                        Icon(Icons.star, size: 18, color: Colors.amber), SizedBox(width: 8), Text('Set as Default'),
                      ])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [
                      Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ])),
                  ],
                ),
              ],
            ),
          ),
          // Set as default button (if not default)
          if (!addr.isDefault)
            InkWell(
              onTap: () => _setDefault(index),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 1.2.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                ),
                child: Center(
                  child: Text('Set as default',
                      style: TextStyle(
                          fontSize: 12.sp,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _labelIcon(String label) {
    switch (label.toUpperCase()) {
      case 'HOME':
        return Icons.home;
      case 'WORK':
        return Icons.work;
      case 'GYM':
        return Icons.fitness_center;
      case 'FAMILY':
        return Icons.family_restroom;
      default:
        return Icons.location_on;
    }
  }
}