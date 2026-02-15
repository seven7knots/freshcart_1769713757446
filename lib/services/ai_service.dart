import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import './marketplace_service.dart';
import './gemini_service.dart';
import './order_service.dart';
import './product_service.dart';
import './supabase_service.dart';

class AIService {
  final GeminiClient _geminiClient;
  final ProductService _productService;
  final OrderService _orderService;
  final MarketplaceService _marketplaceService;
  final SupabaseClient _supabaseClient;
  final Uuid _uuid = const Uuid();

  AIService()
      : _geminiClient = GeminiClient(),
        _productService = ProductService(),
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

      // System prompt with context awareness
      final systemPrompt = _buildSystemPrompt(contextData);
      messages.add(Message(role: 'system', content: systemPrompt));

      // Add conversation history
      if (conversationHistory != null) {
        for (var msg in conversationHistory) {
          messages.add(Message(
            role: msg['role'] ?? 'user',
            content: msg['content'] ?? '',
          ));
        }
      }

      // Add current user message
      messages.add(Message(role: 'user', content: userMessage));

      // Log user message
      await _logConversation(
        conversationId: conversationId,
        messageType: 'user',
        content: userMessage,
        contextData: contextData,
      );

      // Generate AI response via Gemini
      final completion = await _geminiClient.createChatCompletion(
        messages: messages,
        model: 'gemini-2.5-flash',
        options: {'max_output_tokens': 500},
      );

      final aiResponse = completion.text;

      // Log AI response
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
        for (var msg in conversationHistory) {
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
        contextData: contextData,
      );

      final fullResponse = StringBuffer();

      await for (var chunk in _geminiClient.streamContentOnly(
        messages: messages,
        model: 'gemini-2.5-flash',
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

      // Search products
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
          });
        }
      }

      // Search services
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
              'image_url': service.images.isNotEmpty ? service.images[0] : null,
              'availability': service.isActive,
              'category': service.type,
              'merchant_id': service.providerId,
            });
          }
        }
      }

      // Sort results
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

  /// Generate meal plan with AI
  Future<Map<String, dynamic>> generateMealPlan({
    required String dietType,
    required double budget,
    required int householdSize,
    required int mealCount,
    List<String>? cuisinePreferences,
  }) async {
    try {
      final prompt = '''
Generate a meal plan with the following requirements:
- Diet type: $dietType
- Budget: \$$budget
- Household size: $householdSize people
- Number of meals: $mealCount
- Cuisine preferences: ${cuisinePreferences?.join(', ') ?? 'Any'}

Provide a JSON response with:
1. meals: Array of meal objects with name, ingredients (with quantities), prep_time, difficulty, estimated_cost
2. grocery_list: Organized by category (produce, dairy, pantry, etc.) with items and quantities
3. total_estimated_cost: Total cost for all ingredients
4. shopping_tips: Array of tips for efficient shopping

Format as valid JSON only, no additional text.''';

      final messages = [
        Message(
          role: 'system',
          content:
              'You are a meal planning assistant. Respond only with valid JSON.',
        ),
        Message(role: 'user', content: prompt),
      ];

      final completion = await _geminiClient.createChatCompletion(
        messages: messages,
        model: 'gemini-2.5-flash',
        options: {'max_output_tokens': 2000},
      );

      // Parse JSON response
      final jsonString = completion.text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final mealPlan = _parseJson(jsonString);

      if (mealPlan == null) {
        return {
          'success': false,
          'error': 'Failed to parse meal plan',
        };
      }

      // Save to database
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId != null) {
        await _supabaseClient.from('meal_plans').insert({
          'user_id': userId,
          'diet_type': dietType,
          'budget': budget,
          'household_size': householdSize,
          'meal_count': mealCount,
          'cuisine_preferences': cuisinePreferences,
          'meals': mealPlan['meals'],
          'grocery_list': mealPlan['grocery_list'],
          'estimated_cost': mealPlan['total_estimated_cost'],
        });
      }

      return {
        'success': true,
        'meal_plan': mealPlan,
      };
    } catch (e) {
      debugPrint('Meal plan generation error: $e');
      return {
        'success': false,
        'error': 'Failed to generate meal plan: $e',
      };
    }
  }

  /// Add all meal plan items to cart
  Future<Map<String, dynamic>> addMealPlanToCart({
    required Map<String, dynamic> mealPlan,
  }) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }

      final groceryList = mealPlan['grocery_list'] as Map<String, dynamic>?;
      if (groceryList == null) {
        return {
          'success': false,
          'error': 'No grocery list found',
        };
      }

      int itemsAdded = 0;
      final errors = <String>[];

      // Iterate through grocery categories
      for (var category in groceryList.keys) {
        final items = groceryList[category] as List?;
        if (items == null) continue;

        for (var item in items) {
          try {
            final itemName = item['item'] ?? item['name'] ?? '';
            final quantity = item['quantity'] ?? 1;

            // Search for product in database
            final products = await ProductService.searchProducts(
              itemName,
              storeId: null,
              availableOnly: true,
            );

            if (products.isNotEmpty) {
              final product = products.first;

              // Add to cart
              await _supabaseClient.from('cart_items').insert({
                'user_id': userId,
                'product_id': product.id,
                'quantity': quantity is int ? quantity : 1,
                'options_selected': [],
              });

              itemsAdded++;
            } else {
              errors.add('Product not found: $itemName');
            }
          } catch (e) {
            debugPrint('Error adding item to cart: $e');
            errors.add('Failed to add item');
          }
        }
      }

      return {
        'success': true,
        'items_added': itemsAdded,
        'errors': errors,
      };
    } catch (e) {
      debugPrint('Add meal plan to cart error: $e');
      return {
        'success': false,
        'error': 'Failed to add items to cart: $e',
      };
    }
  }

  /// Get order status for customer support
  Future<Map<String, dynamic>> getOrderStatus(String orderId) async {
    try {
      final orderData = await _orderService.getOrderById(orderId);
      return {
        'success': true,
        'order': orderData,
      };
    } catch (e) {
      debugPrint('Get order status error: $e');
      return {
        'success': false,
        'error': 'Order not found',
      };
    }
  }

  /// Build system prompt with context awareness
  String _buildSystemPrompt(Map<String, dynamic>? contextData) {
    final buffer = StringBuffer();
    buffer.writeln(
      'You are an AI assistant for KJ Delivery, a comprehensive marketplace app for food, groceries, pharmacy, retail, and services (mechanics, cleaners, technicians).',
    );
    buffer.writeln(
      'You help users with: general assistance, customer support (FAQs, order tracking, refunds, navigation), meal planning, smart search, and personalized recommendations.',
    );
    buffer.writeln(
      'PLATFORM COVERAGE:',
    );
    buffer.writeln(
      '- STORES: Browse stores, filter by category/location/rating, view store details, check operating hours',
    );
    buffer.writeln(
      '- PRODUCTS: Search products, compare prices, check availability, view reviews, recommend alternatives',
    );
    buffer.writeln(
      '- OFFERS & DEALS: Find active promotions, apply discount codes, suggest best deals based on cart',
    );
    buffer.writeln(
      '- ADS & PROMOTIONS: Show featured items, seasonal campaigns, personalized offers',
    );
    buffer.writeln(
      '- MARKETPLACE: User-to-user product listings, service providers (taxi, towing, water, diesel, chef, trainer, driver, cleaning, handyman)',
    );
    buffer.writeln(
      '- SERVICES: Book services, check provider availability, track service requests, view service history',
    );
    buffer.writeln(
      '- ORDERING FLOWS: Guide through cart → checkout → payment → tracking, handle order modifications, cancellations, refunds',
    );
    buffer.writeln(
      'CRITICAL RULES:',
    );
    buffer.writeln(
      '- NEVER guess prices, availability, services, or order status',
    );
    buffer.writeln(
      '- All data must come from backend tools (you cannot access database or web directly)',
    );
    buffer.writeln(
      '- Always propose actions and require user confirmation',
    );
    buffer.writeln(
      '- For complex issues, escalate to human support',
    );
    buffer.writeln(
      '- Be helpful, concise, and accurate',
    );
    buffer.writeln(
      '- Support both English and Arabic (Lebanese dialect)',
    );

    if (contextData != null) {
      buffer.writeln('\nCURRENT CONTEXT:');
      if (contextData['current_screen'] != null) {
        buffer.writeln('- Screen: ${contextData['current_screen']}');
      }
      if (contextData['cart_items'] != null) {
        buffer.writeln('- Cart items: ${contextData['cart_items']}');
      }
      if (contextData['user_location'] != null) {
        buffer.writeln('- User location: ${contextData['user_location']}');
      }
      if (contextData['search_results'] != null) {
        buffer.writeln('\nREAL SEARCH RESULTS FROM DATABASE:');
        buffer.writeln(contextData['search_results']);
        buffer.writeln(
          '\nIMPORTANT: The above are REAL products/services from our database. '
          'Reference them by name and price in your response. '
          'Help the user choose the best option. '
          'Users can add items to cart directly from the product cards shown below your message.',
        );
      }
      if (contextData['search_query'] != null) {
        buffer.writeln(
          '- User search query: ${contextData['search_query']}',
        );
      }
    }

    return buffer.toString();
  }

  /// Log conversation to database
  Future<void> _logConversation({
    required String conversationId,
    required String messageType,
    required String content,
    Map<String, dynamic>? contextData,
    Map<String, dynamic>? toolCalls,
  }) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) return;

      await _supabaseClient.from('ai_logs').insert({
        'user_id': userId,
        'conversation_id': conversationId,
        'message_type': messageType,
        'content': content,
        'context_data': contextData,
        'tool_calls': toolCalls,
      });
    } catch (e) {
      debugPrint('Failed to log conversation: $e');
    }
  }

  /// Helper: Check if price matches range
  bool _matchesPriceRange(double price, double? minPrice, double? maxPrice) {
    if (minPrice != null && price < minPrice) return false;
    if (maxPrice != null && price > maxPrice) return false;
    return true;
  }

  /// Helper: Sort results
  void _sortResults(List<Map<String, dynamic>> results, String sortBy) {
    switch (sortBy) {
      case 'price_low':
        results.sort(
            (a, b) => (a['price'] as double).compareTo(b['price'] as double));
        break;
      case 'price_high':
        results.sort(
            (a, b) => (b['price'] as double).compareTo(a['price'] as double));
        break;
      case 'relevance':
      default:
        // Keep original order (relevance from search)
        break;
    }
  }

  /// Helper: Parse JSON safely
  Map<String, dynamic>? _parseJson(String jsonString) {
    try {
      return Map<String, dynamic>.from(
        jsonDecode(jsonString),
      );
    } catch (e) {
      debugPrint('JSON parse error: $e');
      return null;
    }
  }
}