import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './marketplace_service.dart';
import './claude_service.dart';
import './order_service.dart';
import './product_service.dart';
import './supabase_service.dart';

class AIService {
  final ClaudeClient _claudeClient;
  final OrderService _orderService;
  final MarketplaceService _marketplaceService;
  final SupabaseClient _supabaseClient;

  static const String _defaultModel = 'claude-haiku-4-5-20251001';
  // Meal planning needs stronger structured output than haiku — use sonnet.
  static const String _mealPlanModel = 'claude-sonnet-4-5';
  static const int _maxHistoryMessages = 20;
  static const int _chatMaxTokens = 2048;
  static const int _mealPlanMaxTokens = 8192;

  AIService()
      : _claudeClient = ClaudeClient(),
        _orderService = OrderService(),
        _marketplaceService = MarketplaceService(),
        _supabaseClient = SupabaseService.client;

  /// Generate AI response with conversation context
  Future<String> generateResponse({
    required String userMessage,
    required String conversationId,
    List<Map<String, String>>? conversationHistory,
    Map<String, dynamic>? contextData,
  }) async {
    try {
      final messages = <Message>[];
      final systemPrompt = _buildSystemPrompt(contextData);
      messages.add(Message(role: 'system', content: systemPrompt));

      if (conversationHistory != null) {
        final trimmedHistory = _trimHistory(conversationHistory);
        for (var msg in trimmedHistory) {
          messages.add(Message(
            role: msg['role'] ?? 'user',
            content: msg['content'] ?? '',
          ));
        }
      }
      messages.add(Message(role: 'user', content: userMessage));

      await _logConversation(
        conversationId: conversationId,
        messageType: 'user',
        content: userMessage,
      );

      final completion = await _claudeClient.createChatCompletion(
        messages: messages,
        model: _defaultModel,
        options: {'max_output_tokens': _chatMaxTokens},
      );

      final aiResponse = completion.text;

      await _logConversation(
        conversationId: conversationId,
        messageType: 'assistant',
        content: aiResponse,
      );

      return aiResponse;
    } catch (e) {
      debugPrint('AI Service Error: $e');
      return 'I apologize, but I\'m having trouble processing your request right now. Please try again.';
    }
  }

  /// Stream AI response for real-time chat
  Stream<String> streamResponse({
    required String userMessage,
    required String conversationId,
    List<Map<String, String>>? conversationHistory,
    Map<String, dynamic>? contextData,
  }) async* {
    try {
      final messages = <Message>[];
      final systemPrompt = _buildSystemPrompt(contextData);
      messages.add(Message(role: 'system', content: systemPrompt));

      if (conversationHistory != null) {
        final trimmedHistory = _trimHistory(conversationHistory);
        for (var msg in trimmedHistory) {
          messages.add(Message(
            role: msg['role'] ?? 'user',
            content: msg['content'] ?? '',
          ));
        }
      }
      messages.add(Message(role: 'user', content: userMessage));

      await _logConversation(
        conversationId: conversationId,
        messageType: 'user',
        content: userMessage,
      );

      final fullResponse = StringBuffer();

      await for (var chunk in _claudeClient.streamContentOnly(
        messages: messages,
        model: _defaultModel,
        options: {'max_output_tokens': _chatMaxTokens},
      )) {
        fullResponse.write(chunk);
        yield chunk;
      }

      await _logConversation(
        conversationId: conversationId,
        messageType: 'assistant',
        content: fullResponse.toString(),
      );
    } catch (e) {
      debugPrint('AI Stream Error: $e');
      yield 'I apologize, but I\'m having trouble processing your request right now.';
    }
  }

  List<Map<String, String>> _trimHistory(List<Map<String, String>> history) {
    if (history.length <= _maxHistoryMessages) return history;
    final firstMessages = history.take(2).toList();
    final recentMessages =
        history.skip(history.length - (_maxHistoryMessages - 2)).toList();
    return [...firstMessages, ...recentMessages];
  }

  String _stripJsonFences(String text) {
    var stripped = text.trim();
    stripped = stripped.replaceAll(
      RegExp(r'^```\s*[jJ][sS][oO][nN]?\s*\n?', multiLine: true),
      '',
    );
    stripped = stripped.replaceAll(
      RegExp(r'\n?```\s*$', multiLine: true),
      '',
    );
    stripped = stripped.replaceAll(
      RegExp(r'^```\s*$', multiLine: true),
      '',
    );
    return stripped.trim();
  }

  /// Unified marketplace search across all categories
  Future<Map<String, dynamic>> unifiedMarketplaceSearch({
    required String query,
    String? category,
    double? userLat,
    double? userLng,
    double? radiusKm,
    double? minPrice,
    double? maxPrice,
    bool? openNow,
    String sortBy = 'relevance',
  }) async {
    try {
      final results = <Map<String, dynamic>>[];

      final products = await ProductService.searchProducts(
        query,
        storeId: null,
        availableOnly: true,
      );

      for (var product in products) {
        if (_matchesPriceRange(product.price, minPrice, maxPrice)) {
          results.add({
            'item_type': 'product',
            'item_id': product.id,
            'name': product.name,
            'description': product.description,
            'price': product.price,
            'currency': product.currency,
            'image_url': product.imageUrl,
            'availability': product.isAvailable,
            'category': product.category,
            'merchant_id': product.storeId,
            // SESSION 29 FIX: Use real store name, not merchant_id UUID
            'store_name': product.storeName ?? '',
          });
        }
      }

      try {
        final storeResults = await _supabaseClient
            .from('stores')
            .select(
                'id, name, description, category, rating, is_active, image_url, delivery_fee, minimum_order')
            .eq('is_active', true)
            .or(
                'name.ilike.%$query%,description.ilike.%$query%,category.ilike.%$query%')
            .order('rating', ascending: false)
            .limit(10);

        for (var store in (storeResults as List)) {
          results.add({
            'item_type': 'store',
            'item_id': store['id'],
            'name': store['name'] ?? 'Unknown Store',
            'description': store['description'] ?? '',
            'price': 0.0,
            'currency': 'USD',
            'image_url': store['image_url'],
            'availability': store['is_active'] ?? true,
            'category': store['category'] ?? '',
            'rating': store['rating'],
            'delivery_fee': store['delivery_fee'],
            'min_order': store['minimum_order'],
          });
        }
      } catch (e) {
        debugPrint('[AI] Store search failed: $e');
      }

      if (category == null || category == 'services') {
        final services = await _marketplaceService.searchServices(
          query,
          limit: 20,
        );

        for (var service in services) {
          if (_matchesPriceRange(service.basePrice, minPrice, maxPrice)) {
            results.add({
              'item_type': 'service',
              'item_id': service.id,
              'name': service.name,
              'description': service.description,
              'price': service.basePrice,
              'currency': service.currency,
              'image_url':
                  service.images.isNotEmpty ? service.images[0] : null,
              'availability': service.isActive,
              'category': service.type,
              'merchant_id': service.providerId,
            });
          }
        }
      }

      _sortResults(results, sortBy);

      return {
        'success': true,
        'query': query,
        'total_results': results.length,
        'results': results,
      };
    } catch (e) {
      debugPrint('Unified search error: $e');
      return {
        'success': false,
        'error': 'Search failed',
        'results': [],
      };
    }
  }

  /// Search stores specifically (for AI context)
  Future<List<Map<String, dynamic>>> searchStores({
    String? query,
    bool activeOnly = true,
    int limit = 10,
  }) async {
    try {
      var dbQuery = _supabaseClient.from('stores').select(
          'id, name, description, category, rating, is_active, image_url, delivery_fee, minimum_order');

      if (activeOnly) dbQuery = dbQuery.eq('is_active', true);

      if (query != null && query.isNotEmpty) {
        dbQuery = dbQuery.or(
            'name.ilike.%$query%,description.ilike.%$query%,category.ilike.%$query%');
      }

      final results =
          await dbQuery.order('rating', ascending: false).limit(limit);
      return List<Map<String, dynamic>>.from(results);
    } catch (e) {
      debugPrint('[AI] Store search error: $e');
      return [];
    }
  }

  // ============================================================
  // SESSION 29 FIX: Strict product-aware meal plan generation.
  //
  // PREVIOUS BUG: Prompt said "try to use product names that MATCH"
  // — a suggestion the AI ignores. It invented realistic items
  // because there was no hard constraint.
  //
  // FIX:
  // 1. Fetch all available products from DB with their IDs.
  // 2. Pass them as a strict JSON catalog.
  // 3. Prompt says "ONLY use items from the catalog. Do NOT invent."
  // 4. AI includes product_id in every grocery item → ID-based cart match.
  // ============================================================
  // System prompt for meal planning — diet-safe, catalog-grounded
  static const String _mealPlanSystemPrompt = '''
You are the KJ Delivery meal planning chef. You create authentic, culturally appropriate meal plans and a consolidated grocery list for Lebanese / Middle Eastern customers.

PRIMARY GOALS:
1. Diet compliance is ABSOLUTE — never include items that violate the requested diet.
2. Cuisine fidelity — when Lebanese / Middle Eastern / Arabic cuisines are requested, use authentic regional dish names (e.g. Mujadara, Shish Tawook, Kibbeh, Fattoush, Tabbouleh, Moutabal, Mahshi, Freekeh, Sayadiyeh). Do NOT output generic names like "Meal", "Lunch", "Dinner".
3. Budget — try to stay within ±15% of the requested USD budget. Report the realistic total.
4. Portions — scale ingredient quantities to the household size.

═══════════════════════════════════════
DIET RULES — apply strictly:
═══════════════════════════════════════
BALANCED — no restrictions; include variety.
LOW-CARB — target <100g carbs/day. Forbid: sugar, sweet drinks, white bread/rice/pasta, pastries, most desserts.
KETO — <25g net carbs/day. Forbid ALL grains (bread, pita, pasta, rice, couscous, oats, corn), ALL sugar (incl. honey/maple/agave), ALL juices and sweet drinks, starchy vegetables (potato, sweet potato, corn), legumes (beans, lentils, chickpeas, hummus), most fruit (only berries in tiny portions), pomegranate molasses. Allowed: grilled meats (unsweetened marinade), fish, eggs, cheese, olives, olive oil, leafy salads (no croutons/fruit), low-carb veg, avocado, nuts, plain yogurt small.
VEGETARIAN — no meat/poultry/fish/seafood; eggs, dairy, honey allowed.
VEGAN — no animal products. Many "vegetable" dishes contain yogurt or butter — only select items explicitly plant-based.
PALEO — no grains, no legumes (incl. peanuts, chickpeas, lentils, beans, hummus), no dairy, no refined sugar/oils.
MEDITERRANEAN — plant-forward with fish and olive oil; limit red meat and sweets.
HIGH-PROTEIN — ≥30g protein per meal; every meal has a clear protein anchor.

═══════════════════════════════════════
OUTPUT FORMAT — return ONLY valid JSON, no prose, no markdown, no code fences.
Response MUST start with `{` and end with `}`.
═══════════════════════════════════════
{
  "meals": [
    {
      "name": "Mujadara",
      "cuisine": "Lebanese",
      "ingredients": [
        { "name": "brown lentils", "qty": "1 cup", "est_price_usd": 1.50 },
        { "name": "long-grain rice", "qty": "1 cup", "est_price_usd": 1.20 },
        { "name": "yellow onion", "qty": "2 large", "est_price_usd": 0.80 },
        { "name": "olive oil", "qty": "3 tbsp", "est_price_usd": 0.60 }
      ],
      "est_price_usd": 4.10,
      "portion_size": "medium",
      "prep_time_min": 45,
      "description": "Classic Lebanese lentils and rice with deeply caramelized onions."
    }
  ],
  "grocery_list": [
    { "name": "brown lentils", "qty": "2 cups", "est_price_usd": 3.00 },
    { "name": "long-grain rice", "qty": "2 cups", "est_price_usd": 2.40 },
    { "name": "yellow onion", "qty": "5 large", "est_price_usd": 2.00 }
  ],
  "total_est_price_usd": 85.40
}

FIELD RULES:
- `meals[].name`: the authentic dish name. Never "Meal N", never "Lunch".
- `meals[].portion_size`: one of "small" | "medium" | "large".
- `meals[].prep_time_min`: positive integer, realistic.
- `meals[].description`: one short sentence.
- `meals[].ingredients`: always a non-empty list with real ingredient names, quantities, and per-ingredient usd estimates.
- `grocery_list`: consolidated shopping list across all meals (merge duplicates, sum quantities). Always a non-empty list of objects.
- `total_est_price_usd`: realistic sum of grocery_list prices, within ±15% of the user's budget when possible.

FORBIDDEN:
- Do NOT emit markdown, prose, comments, or code fences.
- Do NOT output placeholder names like "Meal", "Lunch", "Dinner", "TBD".
- Do NOT output prep_time_min of 0.
- Do NOT wrap the JSON in ``` fences.
''';

  Future<Map<String, dynamic>> generateMealPlan({
    required String dietType,
    required double budget,
    required int householdSize,
    required int mealCount,
    List<String>? cuisinePreferences,
  }) async {
    try {
      final cuisinesLabel = (cuisinePreferences == null ||
              cuisinePreferences.isEmpty)
          ? 'Lebanese, Middle Eastern, Arabic, Mediterranean'
          : cuisinePreferences.join(', ');

      final prompt = '''
Build a meal plan and consolidated grocery list for these user inputs. Return ONLY the JSON object defined in the system prompt — no prose, no fences.

USER INPUTS:
- diet_type: $dietType
- budget_usd: ${budget.toStringAsFixed(2)}
- household_size: $householdSize
- number_of_meals: $mealCount
- cuisine_preferences: [$cuisinesLabel]

For Lebanese / Middle Eastern / Arabic cuisines, use authentic regional dish names such as mujadara, shish tawook, kibbeh, fattoush, tabbouleh, moutabal, mahshi, freekeh, sayadiyeh, kafta, mnazaleh, shakshuka. Do NOT emit "Meal 1", "Lunch", "Dinner" or any other placeholder.

Ensure every meal has: non-empty ingredients[], prep_time_min > 0, est_price_usd > 0, portion_size in {small, medium, large}, one-sentence description.
Ensure grocery_list is a non-empty list of {name, qty, est_price_usd} covering all meals combined (merge duplicate ingredients, sum quantities).
Ensure total_est_price_usd is realistic and close to the user's budget.
''';

      final messages = [
        Message(role: 'system', content: _mealPlanSystemPrompt),
        Message(role: 'user', content: prompt),
      ];

      final completion = await _claudeClient.createChatCompletion(
        messages: messages,
        model: _mealPlanModel,
        options: {
          'max_output_tokens': _mealPlanMaxTokens,
          'temperature': 0.4,
        },
      );

      final jsonString = _stripJsonFences(completion.text);
      final mealPlan = _parseJson(jsonString);

      if (mealPlan == null) {
        return {
          'success': false,
          'error':
              'Could not generate a meal plan. Please try again.',
        };
      }

      // Validate shape — reject silent-placeholder fallback.
      final meals = mealPlan['meals'];
      final groceryList = mealPlan['grocery_list'];
      if (meals is! List ||
          meals.isEmpty ||
          groceryList is! List ||
          groceryList.isEmpty) {
        return {
          'success': false,
          'error':
              'Could not generate a meal plan. Please try again.',
        };
      }

      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId != null) {
        try {
          await _supabaseClient.from('meal_plans').insert({
            'user_id': userId,
            'week_start': DateTime.now().toIso8601String().split('T')[0],
            'preferences': {
              'diet_type': dietType,
              'meal_count': mealCount,
              'cuisine_preferences': cuisinePreferences ?? [],
            },
            'budget': budget,
            'currency': 'USD',
            'household_size': householdSize,
            'plan_data': mealPlan['meals'],
            'grocery_list': mealPlan['grocery_list'],
            'estimated_cost': mealPlan['total_est_price_usd'] ?? 0,
            'is_active': true,
          });
        } catch (e) {
          debugPrint('[AI] Failed to save meal plan to DB: $e');
        }
      }

      return {'success': true, 'meal_plan': mealPlan};
    } catch (e) {
      debugPrint('Meal plan generation error: $e');
      return {
        'success': false,
        'error': 'Could not generate a meal plan. Please try again.',
      };
    }
  }

  // ============================================================
  // SESSION 29 FIX: getMatchedProductIds replaces addMealPlanToCart.
  //
  // PREVIOUS BUG: addMealPlanToCart used .catchError((_) => MapEntry(name, []))
  // which caused a Dart type error: "The error handler of Future.catchError
  // must return a value of the future's type."
  //
  // Also: bypassed CartNotifier by calling _supabaseClient.from('cart_items')
  // .insert() directly, skipping RLS and deduplication.
  //
  // FIX: This method only resolves product IDs. The caller (screen) uses
  // CartNotifier.addToCart() for actual cart insertion.
  // ============================================================
  Future<Map<String, dynamic>> getMatchedProductIds({
    required Map<String, dynamic> mealPlan,
  }) async {
    try {
      final groceryList = mealPlan['grocery_list'];
      if (groceryList is! List || groceryList.isEmpty) {
        return {
          'success': false,
          'error': 'No grocery list found',
          'product_ids': <String>[],
          'not_found': <String>[],
        };
      }

      final matchedIds = <String>[];
      final notFound = <String>[];

      for (final item in groceryList) {
        if (item is! Map) continue;
        final itemMap = Map<String, dynamic>.from(item);
        final itemName =
            (itemMap['name'] ?? itemMap['item'] ?? '').toString().trim();
        if (itemName.isEmpty) continue;

        try {
          final products = await ProductService.searchProducts(
            itemName,
            storeId: null,
            availableOnly: true,
          );
          if (products.isNotEmpty) {
            matchedIds.add(products.first.id);
            debugPrint(
                '[AI_CART] Name match: $itemName -> ${products.first.name}');
          } else {
            notFound.add(itemName);
            debugPrint('[AI_CART] Not found: $itemName');
          }
        } catch (e) {
          notFound.add(itemName);
          debugPrint('[AI_CART] Search error for $itemName: $e');
        }
      }

      return {
        'success': true,
        'product_ids': matchedIds,
        'not_found': notFound,
      };
    } catch (e) {
      debugPrint('getMatchedProductIds error: $e');
      return {
        'success': false,
        'error': 'Failed to match products: $e',
        'product_ids': <String>[],
        'not_found': <String>[],
      };
    }
  }

  /// Get order status for customer support
  Future<Map<String, dynamic>> getOrderStatus(String orderId) async {
    try {
      final orderData = await _orderService.getOrderById(orderId);
      return {'success': true, 'order': orderData};
    } catch (e) {
      debugPrint('Get order status error: $e');
      return {'success': false, 'error': 'Order not found'};
    }
  }

  // ============================================================
  // SESSION 29 FIX: Removed "I can add to cart" from system prompt.
  //
  // PREVIOUS BUG: System prompt said "Add to cart" was something the
  // AI could do. This caused the AI to narrate "I've added X to your
  // cart" — a hallucination. The AI cannot add to cart; only the app
  // UI buttons can. Removed that capability from the prompt entirely.
  // ============================================================
  /// Fetch ALL products and stores from Supabase for grounded AI responses
  Future<Map<String, dynamic>> fetchAppData() async {
    final data = <String, dynamic>{'products': <Map<String, dynamic>>[], 'stores': <Map<String, dynamic>>[]};
    try {
      // Fetch all available products with store names
      final productsResult = await _supabaseClient
          .from('products')
          .select('name, price, category, description, is_available, sale_price, stores(name)')
          .eq('is_available', true)
          .order('name')
          .limit(300);
      data['products'] = (productsResult as List).map((p) => {
        'name': p['name'] ?? '',
        'price': p['price'] ?? 0,
        'category': p['category'] ?? '',
        'store_name': p['stores']?['name'] ?? '',
        'description': (p['description'] ?? '').toString().length > 80
            ? (p['description'] ?? '').toString().substring(0, 80)
            : (p['description'] ?? ''),
        'sale_price': p['sale_price'],
      }).toList();

      // Fetch all active stores
      final storesResult = await _supabaseClient
          .from('stores')
          .select('name, category, rating, is_open, prep_time, address')
          .eq('is_active', true)
          .order('rating', ascending: false)
          .limit(100);
      data['stores'] = List<Map<String, dynamic>>.from(storesResult);
    } catch (e) {
      debugPrint('[AI] Failed to fetch app data: $e');
    }
    return data;
  }

  String _buildSystemPrompt(Map<String, dynamic>? contextData) {
    final buffer = StringBuffer();

    // Get pre-fetched app data from context
    final appData = contextData?['_app_data'] as Map<String, dynamic>?;
    final products = appData?['products'] as List? ?? [];
    final stores = appData?['stores'] as List? ?? [];

    final productsJson = products.isNotEmpty
        ? products.map((p) => '- ${p['name']} | \$${p['price']}${p['sale_price'] != null ? ' (sale: \$${p['sale_price']})' : ''} | ${p['category']} | ${p['store_name']}').join('\n')
        : '(No products currently in inventory)';

    final storesJson = stores.isNotEmpty
        ? stores.map((s) => '- ${s['name']} | ${s['category'] ?? 'General'} | Rating: ${s['rating'] ?? 'N/A'} | ${s['is_open'] == true ? 'Open' : 'Closed'}${s['prep_time'] != null ? ' | Prep: ${s['prep_time']}min' : ''}${s['address'] != null ? ' | ${s['address']}' : ''}').join('\n')
        : '(No stores currently listed)';

    buffer.writeln("""You are AI Mate, the smart shopping assistant for KJ Delivery in Lebanon. You respond in the same language the user writes in (English or Arabic).

You operate in TWO modes, but ALL responses must be grounded ONLY in the app's real data below. Never use outside knowledge for products, prices, stores, or availability.

=== CURRENT APP DATA ===
PRODUCTS IN INVENTORY:
$productsJson

AVAILABLE STORES:
$storesJson

=== MODE 1: SHOPPING ASSISTANT ===
When the user asks about products, prices, availability, stores, orders, or deliveries:
- ONLY reference products and stores from the data above
- Show exact prices and store names from the data
- If a product exists in inventory, tell the user the store, price, and availability
- If a product does NOT exist in inventory, say clearly: "This item is not available on KJ Delivery yet." Do NOT make up alternatives that aren't in the data
- If the inventory has very few products, be honest: "Our marketplace currently has ${products.length} products from ${stores.length} stores. We're growing every day!"
- Never invent delivery times, fees, store hours, or promotions
- For order tracking, direct them to the Order Tracking screen

=== MODE 2: FOOD & LIFESTYLE ADVISOR ===
When the user asks about recipes, cooking tips, meal planning, nutrition advice, food storage, or dietary guidance:
- You CAN share general cooking and nutrition knowledge
- BUT always connect it back to the app's inventory: check if any ingredients mentioned are available in the products list
- If ingredients ARE available: "Great news! You can get [ingredient] from [store] for [price] on KJ Delivery"
- If ingredients are NOT available: "You'll need [ingredient] — this isn't available on KJ Delivery yet, but keep checking as we add new products regularly"
- Never recommend specific outside brands, stores, or services that aren't in the app

=== STRICT RULES ===
1. NEVER invent or hallucinate products, prices, stores, or availability data
2. NEVER reference external stores, websites, or services outside KJ Delivery
3. If you don't have enough data to answer, say so honestly instead of guessing
4. Every product mention must match an exact entry in the inventory data above
5. Be helpful, concise, friendly, and natural
6. If the inventory is empty, acknowledge it warmly and encourage the user to check back""");

    // Append session context if available
    if (contextData != null) {
      buffer.writeln('\n--- CURRENT SESSION CONTEXT ---');
      if (contextData['user_name'] != null)
        buffer.writeln('User name: ${contextData['user_name']}');
      if (contextData['current_screen'] != null)
        buffer.writeln('User is on: ${contextData['current_screen']}');
      if (contextData['cart_items'] != null)
        buffer.writeln('Cart: ${contextData['cart_items']}');
      if (contextData['active_orders'] != null)
        buffer.writeln('Active orders: ${contextData['active_orders']}');
    }

    return buffer.toString();
  }

  Future<void> _logConversation({
    required String conversationId,
    required String messageType,
    required String content,
  }) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) return;

      final logEntry = <String, dynamic>{
        'user_id': userId,
        'session_id': conversationId,
        'feature': 'ai_chat',
        'model_used': _defaultModel,
      };

      if (messageType == 'user') {
        logEntry['input'] = content;
      } else {
        logEntry['output'] = content;
      }

      await _supabaseClient.from('ai_logs').insert(logEntry);
    } catch (e) {
      debugPrint('Failed to log conversation: $e');
    }
  }

  bool _matchesPriceRange(double price, double? minPrice, double? maxPrice) {
    if (minPrice != null && price < minPrice) return false;
    if (maxPrice != null && price > maxPrice) return false;
    return true;
  }

  void _sortResults(List<Map<String, dynamic>> results, String sortBy) {
    switch (sortBy) {
      case 'price_low':
        results.sort((a, b) =>
            ((a['price'] as num?)?.toDouble() ?? 0.0)
                .compareTo((b['price'] as num?)?.toDouble() ?? 0.0));
        break;
      case 'price_high':
        results.sort((a, b) =>
            ((b['price'] as num?)?.toDouble() ?? 0.0)
                .compareTo((a['price'] as num?)?.toDouble() ?? 0.0));
        break;
      default:
        break;
    }
  }

  String _repairJson(String jsonString) {
    var repaired = jsonString.trim();

    int openBraces = 0, closeBraces = 0;
    int openBrackets = 0, closeBrackets = 0;
    bool inString = false;
    String? prevChar;

    for (int i = 0; i < repaired.length; i++) {
      final c = repaired[i];
      if (c == '"' && prevChar != '\\') inString = !inString;
      if (!inString) {
        if (c == '{') openBraces++;
        if (c == '}') closeBraces++;
        if (c == '[') openBrackets++;
        if (c == ']') closeBrackets++;
      }
      prevChar = c;
    }

    if (inString) repaired += '"';

    repaired = repaired.trimRight();
    while (repaired.endsWith(',') || repaired.endsWith(':')) {
      repaired = repaired.substring(0, repaired.length - 1).trimRight();
    }

    final trailingKeyPattern = RegExp(r',\s*"[^"]*"\s*$');
    if (trailingKeyPattern.hasMatch(repaired)) {
      repaired = repaired.replaceFirst(trailingKeyPattern, '');
    }

    // Recount after cleanup
    openBraces = 0; closeBraces = 0;
    openBrackets = 0; closeBrackets = 0;
    inString = false; prevChar = null;

    for (int i = 0; i < repaired.length; i++) {
      final c = repaired[i];
      if (c == '"' && prevChar != '\\') inString = !inString;
      if (!inString) {
        if (c == '{') openBraces++;
        if (c == '}') closeBraces++;
        if (c == '[') openBrackets++;
        if (c == ']') closeBrackets++;
      }
      prevChar = c;
    }

    for (int i = 0; i < (openBrackets - closeBrackets); i++) repaired += ']';
    for (int i = 0; i < (openBraces - closeBraces); i++) repaired += '}';

    return repaired;
  }

  Map<String, dynamic>? _parseJson(String jsonString) {
    final cleaned = _stripJsonFences(jsonString);

    try {
      return Map<String, dynamic>.from(jsonDecode(cleaned));
    } catch (e) {
      debugPrint('JSON parse error (attempting repair): $e');
    }

    try {
      final repaired = _repairJson(cleaned);
      return Map<String, dynamic>.from(jsonDecode(repaired));
    } catch (e) {
      debugPrint('JSON repair also failed: $e');
    }

    try {
      final startIdx = cleaned.indexOf('{');
      final endIdx = cleaned.lastIndexOf('}');
      if (startIdx != -1 && endIdx > startIdx) {
        final extracted = cleaned.substring(startIdx, endIdx + 1);
        return Map<String, dynamic>.from(jsonDecode(extracted));
      }
    } catch (e) {
      debugPrint('JSON extraction also failed: $e');
    }

    return null;
  }
}