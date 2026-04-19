import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/ai_service.dart';
import '../services/analytics_service.dart';
import '../services/supabase_service.dart';
import '../models/ai_message_model.dart';
import 'package:uuid/uuid.dart';

final aiServiceProvider = Provider((ref) => AIService());

final aiConversationProvider =
    StateNotifierProvider<AIConversationNotifier, AIConversationState>(
  (ref) => AIConversationNotifier(ref.read(aiServiceProvider)),
);

class AIConversationState {
  final String conversationId;
  final List<AIMessageModel> messages;
  final bool isLoading;
  final bool isStreaming;
  final String? error;
  final Map<String, dynamic>? contextData;

  AIConversationState({
    required this.conversationId,
    this.messages = const [],
    this.isLoading = false,
    this.isStreaming = false,
    this.error,
    this.contextData,
  });

  AIConversationState copyWith({
    String? conversationId,
    List<AIMessageModel>? messages,
    bool? isLoading,
    bool? isStreaming,
    String? error,
    Map<String, dynamic>? contextData,
  }) {
    return AIConversationState(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      error: error,
      contextData: contextData ?? this.contextData,
    );
  }
}

class AIConversationNotifier extends StateNotifier<AIConversationState> {
  final AIService _aiService;
  final Uuid _uuid = const Uuid();

  AIConversationNotifier(this._aiService)
      : super(AIConversationState(conversationId: const Uuid().v4()));

  void updateContext(Map<String, dynamic> contextData) {
    state = state.copyWith(contextData: contextData);
  }

  /// Keywords that suggest the user is looking for products/stores
  static const _searchKeywords = [
    'find', 'search', 'look for', 'cheapest', 'cheap', 'buy',
    'order', 'get me', 'show me', 'where can i', 'price',
    'cost', 'deals', 'discount', 'offer', 'grocery', 'groceries',
    'food', 'milk', 'bread', 'rice', 'chicken', 'meat', 'fruits',
    'vegetables', 'snack', 'drink', 'water', 'juice', 'coffee',
    'near me', 'nearby', 'closest', 'open now', 'available',
    'store', 'restaurant', 'pharmacy', 'shop',
    'hungry', 'eat', 'dinner', 'lunch', 'breakfast', 'meal',
    'suggest', 'recommend', 'best', 'top rated',
    'what stores', 'which stores', 'list stores', 'all stores',
    'what products', 'which products', 'inside', 'in stock',
    'what do you have', 'what is available', 'open right now',
    // SESSION 19: Lebanese food + broader terms
    'bakery', 'butcher', 'supermarket', 'market', 'mini market',
    'coffee shop', 'cafe', 'pizza', 'burger', 'shawarma', 'manouche',
    'falafel', 'hummus', 'tabouleh', 'fattoush', 'labneh', 'cheese',
    'eggs', 'yogurt', 'chips', 'chocolate', 'ice cream', 'cake',
    'shampoo', 'soap', 'medicine', 'diapers', 'cleaning',
    'cheapest place', 'best price', 'compare prices', 'how much',
    'deliver', 'delivery fee', 'minimum order', 'free delivery',
    'what can i get', 'anything open',
    'i need', 'i want', 'looking for', 'do you have',
    'grilled', 'fresh', 'organic', 'frozen', 'canned',
  ];

  /// Keywords that indicate order tracking intent
  static const _trackingKeywords = [
    'track', 'tracking', 'my order', 'where is', 'status',
    'delivery', 'when will', 'shipped', 'delivered',
    'order status', 'how long', 'eta',
    'driver', 'rider', 'on the way',
  ];

  /// Keywords that specifically indicate store queries
  static const _storeKeywords = [
    'store', 'stores', 'shop', 'shops', 'restaurant', 'restaurants',
    'pharmacy', 'pharmacies', 'open', 'open now', 'what stores',
    'which stores', 'all stores', 'list stores', 'available stores',
    'near me', 'nearby', 'bakery', 'bakeries', 'cafe', 'cafes',
    'supermarket', 'supermarkets', 'butcher', 'mini market',
    'coffee shop', 'browse stores',
  ];

  bool _isProductSearchQuery(String message) {
    final lower = message.toLowerCase();
    return _searchKeywords.any((kw) => lower.contains(kw));
  }

  bool _isTrackingQuery(String message) {
    final lower = message.toLowerCase();
    return _trackingKeywords.any((kw) => lower.contains(kw));
  }

  bool _isStoreQuery(String message) {
    final lower = message.toLowerCase();
    return _storeKeywords.any((kw) => lower.contains(kw));
  }

  // ============================================================
  // SESSION 19: Fetch live user context for richer AI responses
  // ============================================================

  Future<Map<String, dynamic>> _getUserContext() async {
    final context = <String, dynamic>{};
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return context;

      // User name
      final metadata = user.userMetadata;
      final name = metadata?['full_name'] ??
          metadata?['name'] ??
          metadata?['display_name'];
      if (name != null && name.toString().isNotEmpty) {
        context['user_name'] = name;
      }

      // Cart item count
      try {
        final cartResult = await SupabaseService.client
            .from('cart_items')
            .select('id')
            .eq('user_id', user.id);
        final cartCount = (cartResult as List).length;
        if (cartCount > 0) {
          context['cart_items'] = '$cartCount items in cart';
        }
      } catch (e) { debugPrint('[AI_PROVIDER] Silent error: $e'); }

      // Active orders
      try {
        final ordersResult = await SupabaseService.client
            .from('orders')
            .select('id, status')
            .eq('customer_id', user.id)
            .inFilter('status', [
          'pending',
          'confirmed',
          'preparing',
          'ready',
          'picked_up',
          'on_the_way'
        ]);
        final activeOrders = (ordersResult as List);
        if (activeOrders.isNotEmpty) {
          context['active_orders'] = '${activeOrders.length} active order(s)';
        }
      } catch (e) { debugPrint('[AI_PROVIDER] Silent error: $e'); }
    } catch (e) {
      debugPrint('[AI] Error fetching user context: $e');
    }
    return context;
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final userMessage = AIMessageModel(
      id: _uuid.v4(),
      conversationId: state.conversationId,
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      final conversationHistory = state.messages
          .map((msg) => {'role': msg.role, 'content': msg.content})
          .toList();

      // Check if this is a product/store search query
      Map<String, dynamic>? richMetadata;

      if (_isProductSearchQuery(message)) {
        richMetadata = await _performSmartSearch(message);
      }

      // SESSION 19: Build enriched context
      final contextData = Map<String, dynamic>.from(state.contextData ?? {});

      // Fetch live user context (name, cart, orders)
      final userContext = await _getUserContext();
      contextData.addAll(userContext);
      contextData['current_screen'] = 'AI Mate Chat';

      // Fetch ALL products + stores for data-grounded AI responses
      try {
        final appData = await _aiService.fetchAppData();
        contextData['_app_data'] = appData;
      } catch (e) {
        debugPrint('[AI] Failed to fetch app data for context: $e');
      }

      if (richMetadata != null && richMetadata['results'] != null) {
        final results = richMetadata['results'] as List;
        if (results.isNotEmpty) {
          final storeResults =
              results.where((r) => r['item_type'] == 'store').toList();
          final productResults =
              results.where((r) => r['item_type'] != 'store').toList();

          if (productResults.isNotEmpty) {
            contextData['search_results'] = productResults
                .take(8)
                .map((r) {
                  final cat = r['category'] ?? '';
                  return '${r['name']} - ${r['currency'] ?? 'USD'} ${r['price']} ($cat)';
                })
                .join('\n');
          }

          // SESSION 20 FIX (Bug 1): min_order → minimum_order in context
          if (storeResults.isNotEmpty) {
            contextData['store_results'] = storeResults.take(10).map((r) {
              final rating =
                  r['rating'] != null ? ' | Rating: ${r['rating']}' : '';
              final category =
                  r['category'] != null ? ' | Type: ${r['category']}' : '';
              final deliveryFee = r['delivery_fee'] != null
                  ? ' | Delivery: \$${r['delivery_fee']}'
                  : '';
              final minOrder = r['min_order'] != null
                  ? ' | Min order: \$${r['min_order']}'
                  : '';
              return '${r['name']}$category$rating$deliveryFee$minOrder';
            }).join('\n');
          }

          contextData['search_query'] = message;
        }
      }

      // If store query and no stores found via unified search, fetch separately
      if (_isStoreQuery(message) &&
          !contextData.containsKey('store_results')) {
        try {
          final stores =
              await _aiService.searchStores(activeOnly: true, limit: 15);
          if (stores.isNotEmpty) {
            // SESSION 20 FIX (Bug 1): minimum_order (actual DB column name)
            contextData['store_results'] = stores.map((s) {
              final rating =
                  s['rating'] != null ? ' | Rating: ${s['rating']}' : '';
              final category =
                  s['category'] != null ? ' | Type: ${s['category']}' : '';
              final deliveryFee = s['delivery_fee'] != null
                  ? ' | Delivery: \$${s['delivery_fee']}'
                  : '';
              final minOrder = s['minimum_order'] != null
                  ? ' | Min order: \$${s['minimum_order']}'
                  : '';
              return '${s['name']}$category$rating$deliveryFee$minOrder';
            }).join('\n');
            contextData['search_query'] = message;
          }
        } catch (e) {
          debugPrint('[AI] Separate store search failed: $e');
        }
      }

      // Generate AI response
      final response = await _aiService.generateResponse(
        userMessage: message,
        conversationId: state.conversationId,
        conversationHistory: conversationHistory,
        contextData: contextData.isNotEmpty ? contextData : null,
      );

      // Build product card metadata
      Map<String, dynamic>? messageMetadata;

      if (richMetadata != null &&
          richMetadata['results'] != null &&
          (richMetadata['results'] as List).isNotEmpty) {
        final results = richMetadata['results'] as List;
        final productResults =
            results.where((r) => r['item_type'] != 'store').toList();
        if (productResults.isNotEmpty) {
          final productCards = productResults.take(5).map((r) {
            return {
              'product_id': r['item_id'],
              'name': r['name'],
              'price': r['price'],
              'currency': r['currency'] ?? 'USD',
              'image_url': r['image_url'],
              'store_name': r['merchant_id'] ?? '',
              'is_available': r['availability'] ?? true,
              'category': r['category'] ?? '',
            };
          }).toList();

          messageMetadata = {'products': productCards};
        }
      }

      final aiMessage = AIMessageModel(
        id: _uuid.v4(),
        conversationId: state.conversationId,
        role: 'assistant',
        content: response,
        timestamp: DateTime.now(),
        metadata: messageMetadata,
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );

      await AnalyticsService.logAIFeatureUsage(
        featureName:
            richMetadata != null ? 'smart_search_chat' : 'chat_assistant',
        additionalParams: {
          'conversation_id': state.conversationId,
          'message_count': state.messages.length,
          'has_products': (richMetadata != null).toString(),
        },
      );
    } catch (e) {
      debugPrint('AI sendMessage error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get AI response. Please try again.',
      );
    }
  }

  Future<Map<String, dynamic>?> _performSmartSearch(String query) async {
    try {
      final results = await _aiService.unifiedMarketplaceSearch(
        query: query,
        sortBy: 'relevance',
      );
      return results;
    } catch (e) {
      debugPrint('Smart search error: $e');
      return null;
    }
  }

  Stream<String> streamMessage(String message) async* {
    if (message.trim().isEmpty) return;

    final userMessage = AIMessageModel(
      id: _uuid.v4(),
      conversationId: state.conversationId,
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isStreaming: true,
      error: null,
    );

    try {
      final conversationHistory = state.messages
          .map((msg) => {'role': msg.role, 'content': msg.content})
          .toList();

      final fullResponse = StringBuffer();
      final aiMessageId = _uuid.v4();

      await for (var chunk in _aiService.streamResponse(
        userMessage: message,
        conversationId: state.conversationId,
        conversationHistory: conversationHistory,
        contextData: state.contextData,
      )) {
        fullResponse.write(chunk);
        yield chunk;
      }

      final aiMessage = AIMessageModel(
        id: aiMessageId,
        conversationId: state.conversationId,
        role: 'assistant',
        content: fullResponse.toString(),
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isStreaming: false,
      );
    } catch (e) {
      state = state.copyWith(
        isStreaming: false,
        error: 'Failed to stream AI response: $e',
      );
    }
  }

  void clearConversation() {
    state = AIConversationState(conversationId: _uuid.v4());
  }

  void addQuickMessage(String message) {
    sendMessage(message);
  }
}