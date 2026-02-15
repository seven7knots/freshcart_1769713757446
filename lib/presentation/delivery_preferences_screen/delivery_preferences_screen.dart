// ============================================================
// FILE: lib/presentation/delivery_preferences_screen/delivery_preferences_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

class DeliveryPreferencesScreen extends StatefulWidget {
  const DeliveryPreferencesScreen({super.key});

  @override
  State<DeliveryPreferencesScreen> createState() => _DeliveryPreferencesScreenState();
}

class _DeliveryPreferencesScreenState extends State<DeliveryPreferencesScreen> {
  bool _isLoading = true;

  String _preferredTimeSlot = 'anytime';
  bool _leaveAtDoor = false;
  bool _ringDoorbell = true;
  bool _callOnArrival = true;
  bool _contactlessDel = false;

  final _instructionsController = TextEditingController();
  final _handlingController = TextEditingController();

  final _timeSlots = const [
    {'value': 'anytime', 'label': 'Anytime', 'icon': Icons.access_time},
    {'value': 'morning', 'label': 'Morning (8-12)', 'icon': Icons.wb_sunny},
    {'value': 'afternoon', 'label': 'Afternoon (12-5)', 'icon': Icons.wb_cloudy},
    {'value': 'evening', 'label': 'Evening (5-9)', 'icon': Icons.nights_stay},
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    _handlingController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final result = await Supabase.instance.client
          .from('user_delivery_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (result != null && mounted) {
        setState(() {
          _preferredTimeSlot = result['preferred_time_slot'] ?? 'anytime';
          _leaveAtDoor = result['leave_at_door'] ?? false;
          _ringDoorbell = result['ring_doorbell'] ?? true;
          _callOnArrival = result['call_on_arrival'] ?? true;
          _contactlessDel = result['contactless_delivery'] ?? false;
          _instructionsController.text = result['delivery_instructions'] ?? '';
          _handlingController.text = result['special_handling'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('[DELIVERY_PREFS] Error loading: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('user_delivery_preferences').upsert({
        'user_id': userId,
        'preferred_time_slot': _preferredTimeSlot,
        'delivery_instructions': _instructionsController.text.trim(),
        'leave_at_door': _leaveAtDoor,
        'ring_doorbell': _ringDoorbell,
        'call_on_arrival': _callOnArrival,
        'contactless_delivery': _contactlessDel,
        'special_handling': _handlingController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery preferences saved!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Preferences'),
        actions: [
          TextButton(
            onPressed: _savePreferences,
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(4.w),
              children: [
                _buildSection(theme: theme, title: 'Preferred Delivery Time', icon: Icons.schedule, children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Wrap(
                      spacing: 2.w,
                      runSpacing: 1.h,
                      children: _timeSlots.map((slot) {
                        final isSelected = _preferredTimeSlot == slot['value'];
                        return ChoiceChip(
                          label: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(slot['icon'] as IconData, size: 16, color: isSelected ? Colors.white : theme.colorScheme.onSurface),
                            SizedBox(width: 1.w),
                            Text(slot['label'] as String),
                          ]),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _preferredTimeSlot = slot['value'] as String);
                          },
                          selectedColor: AppTheme.kjRed,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : theme.colorScheme.onSurface, fontSize: 13),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 2.h),
                ]),
                SizedBox(height: 2.h),

                _buildSection(theme: theme, title: 'Delivery Options', icon: Icons.local_shipping, children: [
                  _buildToggle(theme, 'Leave at Door', 'Driver leaves order at your door', _leaveAtDoor, (v) => setState(() => _leaveAtDoor = v)),
                  _buildToggle(theme, 'Ring Doorbell', 'Driver rings doorbell on arrival', _ringDoorbell, (v) => setState(() => _ringDoorbell = v)),
                  _buildToggle(theme, 'Call on Arrival', 'Driver calls when arriving', _callOnArrival, (v) => setState(() => _callOnArrival = v)),
                  _buildToggle(theme, 'Contactless Delivery', 'No face-to-face interaction', _contactlessDel, (v) => setState(() => _contactlessDel = v)),
                ]),
                SizedBox(height: 2.h),

                _buildSection(theme: theme, title: 'Special Instructions', icon: Icons.edit_note, children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    child: TextField(
                      controller: _instructionsController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'e.g., Gate code: 1234, Second floor...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    child: TextField(
                      controller: _handlingController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Special Handling',
                        hintText: 'e.g., Fragile items, keep upright',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(height: 1.h),
                ]),
                SizedBox(height: 3.h),

                SizedBox(
                  width: double.infinity,
                  height: 6.h,
                  child: ElevatedButton(
                    onPressed: _savePreferences,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kjRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Preferences', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ),
                SizedBox(height: 4.h),
              ],
            ),
    );
  }

  Widget _buildSection({required ThemeData theme, required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 1.h),
          child: Row(children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            SizedBox(width: 2.w),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ]),
        ),
        ...children,
      ]),
    );
  }

  Widget _buildToggle(ThemeData theme, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.kjRed,
    );
  }
}