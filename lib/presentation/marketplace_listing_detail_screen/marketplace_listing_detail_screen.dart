import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../models/marketplace_listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/marketplace_service.dart';
import '../../services/messaging_service.dart';
import '../../widgets/admin_action_button.dart';
import './widgets/listing_image_carousel_widget.dart';
import './widgets/listing_info_section_widget.dart';
import './widgets/quick_inquiry_buttons_widget.dart';
import './widgets/seller_profile_card_widget.dart';

class MarketplaceListingDetailScreen extends StatefulWidget {
  const MarketplaceListingDetailScreen({super.key});

  @override
  State<MarketplaceListingDetailScreen> createState() =>
      _MarketplaceListingDetailScreenState();
}

class _MarketplaceListingDetailScreenState
    extends State<MarketplaceListingDetailScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final MessagingService _messagingService = MessagingService();

  MarketplaceListingModel? _listing;
  Map<String, dynamic>? _sellerProfile;
  bool _isLoading = true;
  bool _isSendingMessage = false;

  @override
  void initState() {
    super.initState();
    _loadListingDetails();
  }

  Future<void> _loadListingDetails() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final listingId =
          ModalRoute.of(context)?.settings.arguments as String? ?? '';

      if (listingId.isEmpty) {
        throw Exception('Listing ID not provided');
      }

      print('🔍 Loading listing details for: $listingId');

      // Fetch listing with seller profile
      final response =
          await Supabase.instance.client.from('marketplace_listings').select('''
            *,
            seller:users!marketplace_listings_user_id_fkey(
              id,
              full_name,
              profile_image_url,
              created_at
            )
          ''').eq('id', listingId).single();

      setState(() {
        _listing = MarketplaceListingModel.fromJson(response);
        _sellerProfile = response['seller'] as Map<String, dynamic>?;
        _isLoading = false;
      });

      print('✅ Listing loaded: ${_listing?.title}');
    } catch (e) {
      print('❌ Error loading listing: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load listing: $e')),
        );
      }
    }
  }

  Future<void> _contactSeller({String? prefilledMessage}) async {
    if (_listing == null) return;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to contact seller')),
      );
      return;
    }

    if (currentUserId == _listing!.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot message your own listing')),
      );
      return;
    }

    try {
      setState(() {
        _isSendingMessage = true;
      });

      print('📤 Creating/getting conversation with seller');

      // Get or create conversation
      final conversation = await _messagingService.getOrCreateConversation(
        listingId: _listing!.id,
        sellerId: _listing!.userId,
      );

      // If prefilled message provided, send it
      if (prefilledMessage != null && prefilledMessage.isNotEmpty) {
        await _messagingService.sendMessage(
          conversationId: conversation.id,
          content: prefilledMessage,
          messageType: 'inquiry',
        );
      }

      setState(() {
        _isSendingMessage = false;
      });

      // Navigate to chat screen
      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.marketplaceChatScreen,
          arguments: {'conversationId': conversation.id},
        );
      }
    } catch (e) {
      print('❌ Error contacting seller: $e');
      setState(() {
        _isSendingMessage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to contact seller: $e')),
        );
      }
    }
  }

  void _showMessageComposer() {
    final TextEditingController messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Message Seller',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: messageController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSendingMessage
                      ? null
                      : () {
                          final message = messageController.text.trim();
                          if (message.isNotEmpty) {
                            Navigator.pop(context);
                            _contactSeller(prefilledMessage: message);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: _isSendingMessage
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Send Message',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Admin Controls (visible only to admin)
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (!authProvider.isAdmin) return const SizedBox.shrink();
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  color: Colors.orange.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings,
                          color: Colors.orange, size: 20),
                      SizedBox(width: 2.w),
                      Text(
                        'Admin Mode - Manage Listing',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const Spacer(),
                      AdminActionButton(
                        icon: Icons.check_circle,
                        label: 'Approve',
                        isCompact: true,
                        color: Colors.green,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Listing approved')),
                          );
                        },
                      ),
                      AdminActionButton(
                        icon: Icons.edit,
                        label: 'Edit',
                        isCompact: true,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Edit listing')),
                          );
                        },
                      ),
                      AdminActionButton(
                        icon: Icons.delete,
                        label: 'Delete',
                        isCompact: true,
                        color: Colors.red,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Delete listing')),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _listing == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 60, color: Colors.grey[400]),
                              SizedBox(height: 2.h),
                              Text(
                                'Listing not found',
                                style: TextStyle(
                                    fontSize: 16.sp, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image Carousel
                              ListingImageCarouselWidget(
                                  images: _listing!.images),

                              // Listing Info
                              ListingInfoSectionWidget(listing: _listing!),

                              // Seller Profile Card
                              if (_sellerProfile != null)
                                SellerProfileCardWidget(
                                  sellerProfile: _sellerProfile!,
                                  listingUserId: _listing!.userId,
                                ),

                              // Quick Inquiry Buttons (only for non-owners)
                              if (Supabase
                                      .instance.client.auth.currentUser?.id !=
                                  _listing!.userId)
                                QuickInquiryButtonsWidget(
                                  onInquirySelected: (inquiry) {
                                    _contactSeller(prefilledMessage: inquiry);
                                  },
                                ),

                              SizedBox(height: 10.h),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
