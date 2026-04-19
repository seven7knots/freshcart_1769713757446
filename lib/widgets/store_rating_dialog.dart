// ============================================================
// FILE: lib/widgets/store_rating_dialog.dart
// SESSION 34 — Store rating after order delivered
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../services/supabase_service.dart';
import '../l10n/generated/app_localizations.dart';

class StoreRatingDialog extends StatefulWidget {
  final String orderId;
  final String storeId;
  final String? storeName;

  const StoreRatingDialog({
    super.key,
    required this.orderId,
    required this.storeId,
    this.storeName,
  });

  /// Show as bottom sheet. Returns true if submitted, false/null if skipped.
  static Future<bool?> show(
    BuildContext context, {
    required String orderId,
    required String storeId,
    String? storeName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StoreRatingDialog(
        orderId: orderId,
        storeId: storeId,
        storeName: storeName,
      ),
    );
  }

  @override
  State<StoreRatingDialog> createState() => _StoreRatingDialogState();
}

class _StoreRatingDialogState extends State<StoreRatingDialog> {
  int _selectedRating = 0;
  bool _isSubmitting = false;
  final _commentController = TextEditingController();

  static const _labels = {
    1: 'Poor \u{1F61E}',
    2: 'Fair \u{1F610}',
    3: 'Good \u{1F642}',
    4: 'Very Good \u{1F60A}',
    5: 'Excellent \u{1F31F}',
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

      // Guard: check if already rated this order
      final existing = await SupabaseService.client
          .from('store_ratings')
          .select('id')
          .eq('order_id', widget.orderId)
          .eq('customer_id', userId)
          .maybeSingle();

      if (existing != null) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.youAlreadyRatedThisStore, maxLines: 1, overflow: TextOverflow.ellipsis)),
          );
        }
        return;
      }

      final comment = _commentController.text.trim();
      await SupabaseService.client.from('store_ratings').insert({
        'store_id': widget.storeId,
        'customer_id': userId,
        'order_id': widget.orderId,
        'rating': _selectedRating,
        if (comment.isNotEmpty) 'comment': comment,
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thanks for rating! $_selectedRating stars \u2B50', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 5.w,
        right: 5.w,
        top: 2.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 3.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 10.w,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outline.withOpacity(0.4),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          SizedBox(height: 2.h),

          // Icon
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.store_rounded, color: Colors.amber, size: 30),
          ),
          SizedBox(height: 1.5.h),

          Text(
            'Rate ${widget.storeName ?? AppLocalizations.of(context)!.theStore}',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 0.5.h),
          Text(
            AppLocalizations.of(context)!.howWasYourExperience,
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 3.h),

          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              final active = star <= _selectedRating;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedRating = star);
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: Icon(
                    active ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: active ? Colors.amber : cs.outline,
                    size: 11.w,
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 1.h),

          // Label
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _selectedRating > 0
                  ? (_labels[_selectedRating] ?? '')
                  : AppLocalizations.of(context)!.tapAStarToRate,
              key: ValueKey(_selectedRating),
              style: _selectedRating > 0
                  ? theme.textTheme.titleSmall?.copyWith(
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.w600,
                    )
                  : theme.textTheme.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          SizedBox(height: 2.h),

          // Comment field
          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 300,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.leaveACommentOptional,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: EdgeInsets.all(3.w),
            ),
          ),
          SizedBox(height: 2.h),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(AppLocalizations.of(context)!.skip, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed:
                      (_selectedRating == 0 || _isSubmitting) ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _selectedRating > 0
                              ? 'Submit ($_selectedRating\u2605)'
                              : AppLocalizations.of(context)!.selectARating, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
