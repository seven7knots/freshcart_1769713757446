import 'package:flutter/material.dart' hide FilterChip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../providers/marketplace_provider.dart';
import '../../services/marketplace_service.dart';
import '../../l10n/generated/app_localizations.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingsAsync = ref.watch(myBookingsProvider(_selectedStatus));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.myBookings,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 6.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              children: [
                _buildFilterChip(AppLocalizations.of(context)!.all2, null),
                _buildFilterChip(AppLocalizations.of(context)!.requested, 'requested'),
                _buildFilterChip('Confirmed', 'confirmed'),
                _buildFilterChip(AppLocalizations.of(context)!.inProgress, 'in_progress'),
                _buildFilterChip(AppLocalizations.of(context)!.completed, 'completed'),
                _buildFilterChip('Cancelled', 'cancelled'),
              ],
            ),
          ),
          Expanded(
            child: bookingsAsync.when(
              data: (bookings) {
                if (bookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 60,
                          color: theme.colorScheme.outline,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          AppLocalizations.of(context)!.noBookingsFound,
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: theme.colorScheme.onSurfaceVariant,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 2.h),
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(child: Text(
                                'Booking #${booking.bookingNumber ?? booking.id.substring(0, 8)}',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              _buildStatusBadge(booking.status),
                            ],
                          ),
                          SizedBox(height: 1.h),
                          if (booking.scheduledTime != null)
                            Text(
                              'Scheduled: ${booking.scheduledTime!.toString().substring(0, 16)}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: theme.colorScheme.onSurfaceVariant,
                              ), maxLines: 1, overflow: TextOverflow.ellipsis),
                          SizedBox(height: 0.5.h),
                          Text(
                            'Total: \$${booking.total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ), maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (booking.status == 'requested' ||
                              booking.status == 'confirmed') ...[
                            SizedBox(height: 1.h),
                            ElevatedButton(
                              onPressed: () => _cancelBooking(booking.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                minimumSize: Size(double.infinity, 4.h),
                              ),
                              child: Text(AppLocalizations.of(context)!.cancelBooking, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                          if (booking.status == 'completed' &&
                              booking.customerRating == null) ...[
                            SizedBox(height: 1.h),
                            ElevatedButton(
                              onPressed: () => _showRatingDialog(booking.id),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 4.h),
                              ),
                              child: Text(AppLocalizations.of(context)!.rateService, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Error: ${error.toString()}',
                  style: TextStyle(color: Colors.red, fontSize: 12.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _selectedStatus == status;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(right: 2.w),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
        selected: isSelected,
        onSelected: (selected) =>
            setState(() => _selectedStatus = selected ? status : null),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        selectedColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'requested':
        color = Colors.orange;
        break;
      case 'confirmed':
      case 'in_progress':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10.sp,
          color: color,
          fontWeight: FontWeight.w600,
        ), maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }

  Future<void> _cancelBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.cancelBooking, maxLines: 1, overflow: TextOverflow.ellipsis),
        content: Text(AppLocalizations.of(context)!.areYouSureYouWantTo, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.no2, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.yes, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await MarketplaceService().cancelBooking(
          bookingId,
          'Cancelled by customer',
        );
        ref.invalidate(myBookingsProvider);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.bookingCancelled, maxLines: 1, overflow: TextOverflow.ellipsis)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}', maxLines: 1, overflow: TextOverflow.ellipsis)));
        }
      }
    }
  }

  Future<void> _showRatingDialog(String bookingId) async {
    int rating = 5;
    final reviewController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.rateService, maxLines: 1, overflow: TextOverflow.ellipsis),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => setState(() => rating = index + 1),
                  ),
                ),
              ),
              TextField(
                controller: reviewController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.reviewOptional,
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.submit, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await MarketplaceService().rateService(
          bookingId,
          rating,
          reviewController.text.isNotEmpty ? reviewController.text : null,
        );
        ref.invalidate(myBookingsProvider);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.ratingSubmitted, maxLines: 1, overflow: TextOverflow.ellipsis)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}', maxLines: 1, overflow: TextOverflow.ellipsis)));
        }
      }
    }
  }
}
