class ConversationModel {
  final String id;
  final String buyerId;
  final String sellerId;
  final String listingId;
  final DateTime? lastMessageAt;
  final int buyerUnreadCount;
  final int sellerUnreadCount;
  final bool isArchivedByBuyer;
  final bool isArchivedBySeller;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Populated from joins
  final Map<String, dynamic>? buyerProfile;
  final Map<String, dynamic>? sellerProfile;
  final Map<String, dynamic>? listing;
  final String? lastMessageContent;

  ConversationModel({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.listingId,
    this.lastMessageAt,
    this.buyerUnreadCount = 0,
    this.sellerUnreadCount = 0,
    this.isArchivedByBuyer = false,
    this.isArchivedBySeller = false,
    this.createdAt,
    this.updatedAt,
    this.buyerProfile,
    this.sellerProfile,
    this.listing,
    this.lastMessageContent,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      listingId: json['listing_id'] as String,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      buyerUnreadCount: json['buyer_unread_count'] as int? ?? 0,
      sellerUnreadCount: json['seller_unread_count'] as int? ?? 0,
      isArchivedByBuyer: json['is_archived_by_buyer'] as bool? ?? false,
      isArchivedBySeller: json['is_archived_by_seller'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      buyerProfile: json['buyer'] as Map<String, dynamic>?,
      sellerProfile: json['seller'] as Map<String, dynamic>?,
      listing: json['listing'] as Map<String, dynamic>?,
      lastMessageContent: json['last_message_content'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'listing_id': listingId,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'buyer_unread_count': buyerUnreadCount,
      'seller_unread_count': sellerUnreadCount,
      'is_archived_by_buyer': isArchivedByBuyer,
      'is_archived_by_seller': isArchivedBySeller,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  int getUnreadCount(String currentUserId) {
    return currentUserId == buyerId ? buyerUnreadCount : sellerUnreadCount;
  }

  String getOtherParticipantId(String currentUserId) {
    return currentUserId == buyerId ? sellerId : buyerId;
  }

  Map<String, dynamic>? getOtherParticipantProfile(String currentUserId) {
    return currentUserId == buyerId ? sellerProfile : buyerProfile;
  }
}
