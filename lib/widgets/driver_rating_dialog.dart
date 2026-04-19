// ============================================================
// FILE: lib/widgets/driver_rating_dialog.dart
// ============================================================
// SESSION 20 — Issue 1: Driver Rating System
//
// A bottom sheet dialog that lets customers rate their driver
// after an order is delivered. Shows 1-5 stars + optional comment.
// Saves to driver_ratings table and auto-updates driver average.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../services/supabase_service.dart';
import '../l10n/generated/app_localizations.dart';

class DriverRatingDialog extends StatefulWidget {
  final String orderId;
  final String driverId;
  final String? driverName;

  const DriverRatingDialog({
    super.key,
    required this.orderId,
    required this.driverId,
    this.driverName,
  });

  /// Show the rating dialog as a bottom sheet
  static Future<bool?> show(
    BuildContext context, {
    required String orderId,
    required String driverId,
    String? driverName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (_) => DriverRatingDialog(
        orderId: orderId,
        driverId: driverId,
        driverName: driverName,
      ),
    );
  }

  @override
  State<DriverRatingDialog> createState() => _DriverRatingDialogState();
}

class _DriverRatingDialogState extends State<DriverRatingDialog> {
  int _selectedRating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  final _ratingLabels = {
    1: 'Poor',
    2: 'Fair',
    3: 'Good',
    4: 'Great',
    5: 'Excellent',
  };

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) return;
    setState(() => _isSubmitting = true);

    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      // Check if already rated this order
      final existing = await SupabaseService.client
          .from('driver_ratings')
          .select('id')
          .eq('order_id', widget.orderId)
          .eq('customer_id', userId)
          .maybeSingle();

      if (existing != null) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.youAlreadyRatedThisDelivery),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Insert rating
      await SupabaseService.client.from('driver_ratings').insert({
        'order_id': widget.orderId,
        'driver_id': widget.driverId,
        'customer_id': userId,
        'rating': _selectedRating,
        'comment': _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update driver's average rating
      final ratings = await SupabaseService.client
          .from('driver_ratings')
          .select('rating')
          .eq('driver_id', widget.driverId);

      if (ratings.isNotEmpty) {
        double sum = 0;
        for (var r in ratings) {
          sum += (r['rating'] as num).toDouble();
        }
        final average = sum / ratings.length;

        await SupabaseService.client.from('drivers').update({
          'rating': double.parse(average.toStringAsFixed(2)),
          'total_ratings': ratings.length,
        }).eq('id', widget.driverId);
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thanks for rating! You gave $_selectedRating stars', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('[RATING] Error submitting rating: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: $e', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 6.w,
        right: 6.w,
        top: 2.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 3.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 12.w,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(height: 3.h),

          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star_rounded, color: Colors.amber, size: 40),
          ),
          SizedBox(height: 2.h),

          // Title
          Text(
            AppLocalizations.of(context)!.rateYourDriver,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 0.5.h),
          Text(
            widget.driverName != null
                ? 'How was your delivery with ${widget.driverName}?'
                : 'How was your delivery experience?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 3.h),

          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starIndex = i + 1;
              final isSelected = starIndex <= _selectedRating;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedRating = starIndex);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isSelected ? Colors.amber : theme.colorScheme.outline,
                    size: isSelected ? 44 : 40,
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 1.h),

          // Rating label
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _selectedRating > 0
                ? Text(
                    _ratingLabels[_selectedRating] ?? '',
                    key: ValueKey(_selectedRating),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.amber[700],
                      fontWeight: FontWeight.w600,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis)
                : Text(
                    AppLocalizations.of(context)!.tapAStarToRate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          SizedBox(height: 2.5.h),

          // Comment field
          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'Add a comment (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
              fillColor: Colors.grey.shade200.withOpacity(0.5),
              contentPadding: EdgeInsets.all(3.w),
            ),
          ),
          SizedBox(height: 2.h),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedRating == 0 || _isSubmitting
                  ? null
                  : _submitRating,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: Colors.grey.shade400.withOpacity(0.2),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _selectedRating > 0
                          ? 'Submit Rating ($_selectedRating/5)'
                          : 'Select a Rating',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          SizedBox(height: 1.h),

          // Skip button
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.maybeLater,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}