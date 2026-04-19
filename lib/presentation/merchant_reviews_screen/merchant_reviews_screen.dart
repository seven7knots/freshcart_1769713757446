import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/merchant_provider.dart';
import '../../services/supabase_service.dart';
import '../../l10n/generated/app_localizations.dart';

class MerchantReviewsScreen extends StatefulWidget {
  const MerchantReviewsScreen({super.key});

  @override
  State<MerchantReviewsScreen> createState() => _MerchantReviewsScreenState();
}

class _MerchantReviewsScreenState extends State<MerchantReviewsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0.0;
  Map<int, int> _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReviews());
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);

    try {
      final merchantProvider =
          Provider.of<MerchantProvider>(context, listen: false);

      if (merchantProvider.stores.isNotEmpty) {
        final storeId = merchantProvider.stores.first['id'] as String;

        // SESSION 34: Load from store_ratings with user join
        try {
          final response = await SupabaseService.client
              .from('store_ratings')
              .select('*, users!store_ratings_customer_id_fkey(full_name, email)')
              .eq('store_id', storeId)
              .order('created_at', ascending: false)
              .limit(100);

          _reviews = List<Map<String, dynamic>>.from(response);
          _calculateStats();
        } catch (e) {
          debugPrint('[MERCHANT_REVIEWS] Could not load ratings: $e');
          _reviews = [];
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('[MERCHANT_REVIEWS] Error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _calculateStats() {
    if (_reviews.isEmpty) {
      _averageRating = 0.0;
      _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      return;
    }

    double totalRating = 0;
    final distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    for (final review in _reviews) {
      final rating = (review['rating'] as num?)?.toInt() ?? 0;
      totalRating += rating;
      if (rating >= 1 && rating <= 5) {
        distribution[rating] = (distribution[rating] ?? 0) + 1;
      }
    }

    _averageRating = totalRating / _reviews.length;
    _ratingDistribution = distribution;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.reviews, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReviews,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReviews,
              child: _reviews.isEmpty
                  ? _buildEmptyState(theme)
                  : _buildReviewsList(theme),
            ),
    );
  }

  // ============================================================
  // EMPTY STATE — overflow-safe with LayoutBuilder
  // ============================================================

  Widget _buildEmptyState(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(4.w),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 4.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(5.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.reviews_outlined,
                      size: 12.w, color: theme.colorScheme.primary),
                ),
                SizedBox(height: 3.h),
                Text(AppLocalizations.of(context)!.noReviewsYet,
                    style: TextStyle(
                        fontSize: 20.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 1.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Text(
                    AppLocalizations.of(context)!.customerReviewsWillAppearHereOnce,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                SizedBox(height: 4.h),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: Colors.amber, size: 7.w),
                        SizedBox(height: 1.5.h),
                        Text(AppLocalizations.of(context)!.tipsToGetReviews,
                            style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        SizedBox(height: 1.5.h),
                        _buildTipItem(theme, Icons.speed,
                            'Deliver orders quickly and accurately'),
                        SizedBox(height: 1.h),
                        _buildTipItem(theme, Icons.high_quality,
                            'Maintain high quality products'),
                        SizedBox(height: 1.h),
                        _buildTipItem(theme, Icons.support_agent,
                            'Provide excellent customer service'),
                        SizedBox(height: 1.h),
                        _buildTipItem(theme, Icons.local_offer,
                            'Offer competitive prices and deals'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTipItem(ThemeData theme, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 5.w, color: theme.colorScheme.primary),
        SizedBox(width: 3.w),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 12.sp,
                  color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  // ============================================================
  // REVIEWS LIST (when reviews exist)
  // ============================================================

  Widget _buildReviewsList(ThemeData theme) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRatingOverview(theme),
          SizedBox(height: 3.h),
          Text('All Reviews (${_reviews.length})',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 2.h),
          ...List.generate(_reviews.length, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: _buildReviewCard(theme, _reviews[index]),
            );
          }),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  Widget _buildRatingOverview(ThemeData theme) {
    final totalReviews = _reviews.length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(_averageRating.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 32.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 0.5.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return Icon(
                        i < _averageRating.round()
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 4.w,
                      );
                    }),
                  ),
                  SizedBox(height: 0.5.h),
                  Text('$totalReviews reviews',
                      style: TextStyle(
                          fontSize: 11.sp,
                          color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              flex: 3,
              child: Column(
                children: [5, 4, 3, 2, 1].map((star) {
                  final count = _ratingDistribution[star] ?? 0;
                  final fraction =
                      totalReviews > 0 ? count / totalReviews : 0.0;

                  return Padding(
                    padding: EdgeInsets.only(bottom: 0.4.h),
                    child: Row(
                      children: [
                        Text('$star',
                            style: TextStyle(
                                fontSize: 10.sp, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                        SizedBox(width: 1.w),
                        Icon(Icons.star, size: 3.w, color: Colors.amber),
                        SizedBox(width: 1.5.w),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: fraction,
                              minHeight: 6,
                              backgroundColor:
                                  Colors.grey.shade200,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                        SizedBox(width: 1.5.w),
                        SizedBox(
                          width: 7.w,
                          child: Text('$count',
                              style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(ThemeData theme, Map<String, dynamic> review) {
    final user = review['users'] as Map<String, dynamic>?;
    final customerName = user?['full_name'] as String? ??
        user?['email'] as String? ??
        review['user_name'] as String? ??
        'Customer';
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final comment = review['comment'] as String? ??
        review['review_text'] as String? ??
        '';
    final createdAt =
        DateTime.tryParse(review['created_at'] as String? ?? '');

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 4.5.w,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    customerName.isNotEmpty
                        ? customerName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customerName,
                          style: TextStyle(
                              fontSize: 13.sp, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (createdAt != null)
                        Text(
                          '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                          style: TextStyle(
                              fontSize: 10.sp,
                              color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    return Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 3.5.w,
                    );
                  }),
                ),
              ],
            ),
            if (comment.isNotEmpty) ...[
              SizedBox(height: 1.5.h),
              Text(comment, style: TextStyle(fontSize: 12.sp, height: 1.4), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }
}