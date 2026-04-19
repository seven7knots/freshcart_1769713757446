// ============================================================
// FILE: lib/presentation/marketplace_listing_detail_screen/marketplace_listing_detail_screen.dart
// ============================================================
// SESSION 28 FIXES:
// - Quick Inquiries no longer crash: message_type now always 'text'
//   (DB constraint messages_message_type_check rejects 'inquiry')
// - Seller phone fetched from users table (added phone to SELECT)
// - Contact section rebuilt: In-app Chat + WhatsApp deep link + Phone call
//   WhatsApp button only shows if seller has a phone number stored
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../models/marketplace_listing_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/marketplace_service.dart';
import '../../services/messaging_service.dart';
import '../../widgets/admin_action_button.dart';
import './widgets/listing_image_carousel_widget.dart';
import './widgets/listing_info_section_widget.dart';
import './widgets/quick_inquiry_buttons_widget.dart';
import './widgets/seller_profile_card_widget.dart';
import '../../l10n/generated/app_localizations.dart';

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
  bool _hasLoadedDetails = false;

  // SESSION 28: seller's phone number for WhatsApp + call
  String? _sellerPhone;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedDetails) {
      _hasLoadedDetails = true;
      _loadListingDetails();
    }
  }

  Future<void> _loadListingDetails() async {
    try {
      setState(() => _isLoading = true);

      final listingId =
          ModalRoute.of(context)?.settings.arguments as String? ?? '';

      if (listingId.isEmpty) throw Exception('Listing ID not provided');

      final response =
          await Supabase.instance.client.from('marketplace_listings').select('''
            *,
            seller:users!marketplace_listings_user_id_fkey(
              id,
              full_name,
              profile_image_url,
              created_at,
              phone
            )
          ''').eq('id', listingId).single();

      if (!mounted) return;

      final sellerData = response['seller'] as Map<String, dynamic>?;

      setState(() {
        _listing = MarketplaceListingModel.fromJson(response);
        _sellerProfile = sellerData;
        // SESSION 28: extract phone for WhatsApp / call buttons
        _sellerPhone = sellerData?['phone'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load listing: $e', maxLines: 1, overflow: TextOverflow.ellipsis)),
      );
    }
  }

  // ============================================================
  // SESSION 28: In-app chat contact
  // SESSION 28 FIX: All messages sent as messageType: 'text'
  // (DB constraint does not accept 'inquiry' as a valid type)
  // ============================================================
  Future<void> _contactSeller({String? prefilledMessage}) async {
    if (_listing == null) return;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseLoginToContactSeller, maxLines: 1, overflow: TextOverflow.ellipsis)),
      );
      return;
    }

    if (currentUserId == _listing!.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.youCannotMessageYourOwnListing, maxLines: 1, overflow: TextOverflow.ellipsis)),
      );
      return;
    }

    try {
      setState(() => _isSendingMessage = true);

      final conversation = await _messagingService.getOrCreateConversation(
        listingId: _listing!.id,
        sellerId: _listing!.userId,
      );

      if (prefilledMessage != null && prefilledMessage.isNotEmpty) {
        // SESSION 28 FIX: always 'text' — 'inquiry' violates DB constraint
        await _messagingService.sendMessage(
          conversationId: conversation.id,
          content: prefilledMessage,
          messageType: 'text',
        );
      }

      setState(() => _isSendingMessage = false);

      Navigator.pushNamed(
        context,
        AppRoutes.marketplaceChatScreen,
        arguments: {'conversationId': conversation.id},
      );
    } catch (e) {
      setState(() => _isSendingMessage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to contact seller: $e', maxLines: 1, overflow: TextOverflow.ellipsis)),
      );
    }
  }

  // ============================================================
  // SESSION 28: WhatsApp deep link
  // Opens wa.me with the seller's phone number pre-filled.
  // Phone is stored as +961XXXXXXX in the users table.
  // Strip the '+' for the wa.me URL format.
  // ============================================================
  Future<void> _openWhatsApp() async {
    if (_sellerPhone == null || _sellerPhone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.sellerHasNoWhatsappNumberOn, maxLines: 1, overflow: TextOverflow.ellipsis)),
      );
      return;
    }

    // Strip non-digits (e.g. '+' and spaces) for wa.me
    final digits = _sellerPhone!.replaceAll(RegExp(r'[^\d]'), '');
    final listingTitle = Uri.encodeComponent(
      'Hi, I\'m interested in your listing: ${_listing?.title ?? ''}',
    );
    final uri = Uri.parse('https://wa.me/$digits?text=$listingTitle');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenWhatsapp, maxLines: 1, overflow: TextOverflow.ellipsis)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open WhatsApp: $e', maxLines: 1, overflow: TextOverflow.ellipsis)),
        );
      }
    }
  }

  // ============================================================
  // SESSION 28: Phone call
  // ============================================================
  Future<void> _callSeller() async {
    if (_sellerPhone == null || _sellerPhone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.sellerHasNoPhoneNumberOn, maxLines: 1, overflow: TextOverflow.ellipsis)),
      );
      return;
    }

    final uri = Uri.parse('tel:$_sellerPhone');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.couldNotLaunchPhoneDialer, maxLines: 1, overflow: TextOverflow.ellipsis)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open dialer: $e', maxLines: 1, overflow: TextOverflow.ellipsis)),
        );
      }
    }
  }

  void _showMessageComposer() {
    final TextEditingController messageController = TextEditingController();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
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
                  Flexible(child: Text(
                    AppLocalizations.of(context)!.messageSeller,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
                  hintText: AppLocalizations.of(context)!.typeYourMessage,
                  hintStyle: TextStyle(color: theme.colorScheme.outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
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
                    backgroundColor: theme.colorScheme.primary,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: _isSendingMessage
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context)!.sendMessage,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.surface,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
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
    final theme = Theme.of(context);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwnListing = currentUserId != null &&
        _listing != null &&
        currentUserId == _listing!.userId;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Admin controls bar
            Consumer2<AuthProvider, AdminProvider>(
              builder: (context, authProvider, adminProvider, child) {
                if (!adminProvider.isAdmin) return const SizedBox.shrink();
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  color: Colors.orange.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings,
                          color: Colors.orange, size: 20),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AdminActionButton(
                        icon: Icons.check_circle,
                        label: AppLocalizations.of(context)!.approve,
                        isCompact: true,
                        color: Colors.green,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context)!.listingApproved, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          );
                        },
                      ),
                      AdminActionButton(
                        icon: Icons.edit,
                        label: AppLocalizations.of(context)!.edit,
                        isCompact: true,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context)!.editListing, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          );
                        },
                      ),
                      AdminActionButton(
                        icon: Icons.delete,
                        label: AppLocalizations.of(context)!.delete,
                        isCompact: true,
                        color: Colors.red,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context)!.deleteListing, maxLines: 1, overflow: TextOverflow.ellipsis)),
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
                                  size: 60, color: theme.colorScheme.outline),
                              SizedBox(height: 2.h),
                              Text(
                                AppLocalizations.of(context)!.listingNotFound,
                                style: TextStyle(
                                    fontSize: 16.sp, color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Back button overlay on image
                              Stack(
                                children: [
                                  ListingImageCarouselWidget(
                                      images: _listing!.images),
                                  Positioned(
                                    top: 1.h,
                                    left: 3.w,
                                    child: CircleAvatar(
                                      backgroundColor:
                                          Colors.black.withOpacity(0.45),
                                      child: IconButton(
                                        icon: const Icon(Icons.arrow_back,
                                            color: Colors.white),
                                        onPressed: () =>
                                            Navigator.pop(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              ListingInfoSectionWidget(listing: _listing!),

                              if (_sellerProfile != null)
                                SellerProfileCardWidget(
                                  sellerProfile: _sellerProfile!,
                                  listingUserId: _listing!.userId,
                                ),

                              // ================================================
                              // SESSION 28: Contact section
                              // Only shown to non-owners
                              // ================================================
                              if (!isOwnListing) ...[
                                // Quick Inquiries (fixed — now sends as 'text')
                                QuickInquiryButtonsWidget(
                                  onInquirySelected: (inquiry) {
                                    HapticFeedback.lightImpact();
                                    _contactSeller(prefilledMessage: inquiry);
                                  },
                                ),

                                // Contact action bar
                                _buildContactActionBar(theme),
                              ],

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

  // ============================================================
  // SESSION 28: Contact action bar — Chat / WhatsApp / Call
  // ============================================================
  Widget _buildContactActionBar(ThemeData theme) {
    final hasPhone =
        _sellerPhone != null && _sellerPhone!.isNotEmpty;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.contactSeller,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 2.h),
          Row(
            children: [
              // In-app Chat
              Expanded(
                child: _buildContactButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: AppLocalizations.of(context)!.chat,
                  color: AppTheme.kjRed,
                  isLoading: _isSendingMessage,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showMessageComposer();
                  },
                  theme: theme,
                ),
              ),

              // WhatsApp — only if seller has a phone number
              if (hasPhone) ...[
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildContactButton(
                    icon: Icons.message, // WhatsApp-style icon
                    label: AppLocalizations.of(context)!.whatsapp,
                    color: const Color(0xFF25D366), // WhatsApp green
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _openWhatsApp();
                    },
                    theme: theme,
                  ),
                ),
              ],

              // Phone call — only if seller has a phone number
              if (hasPhone) ...[
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildContactButton(
                    icon: Icons.phone_outlined,
                    label: AppLocalizations.of(context)!.call,
                    color: Colors.blue,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _callSeller();
                    },
                    theme: theme,
                  ),
                ),
              ],
            ],
          ),

          // Note if seller has no phone
          if (!hasPhone) ...[
            SizedBox(height: 1.h),
            Text(
              AppLocalizations.of(context)!.whatsappCallUnavailableSellerHasNo,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              )
            : Column(
                children: [
                  Icon(icon, color: color, size: 22),
                  SizedBox(height: 0.5.h),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
      ),
    );
  }
}