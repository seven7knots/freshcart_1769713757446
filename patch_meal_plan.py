"""Issue 4: Strict JSON schema for meal planning + authentic dishes + populated grocery list.

Changes:
  - ai_service.dart: rewrite _mealPlanSystemPrompt to the new schema, bump model to sonnet,
    rewrite generateMealPlan prompt construction, rewrite getMatchedProductIds for list shape.
  - meal_calendar_widget.dart: read new schema (name, prep_time_min, portion_size, description, ingredients, est_price_usd).
  - grocery_list_widget.dart: accept List + new fields (name, qty, est_price_usd).
  - ai_meal_planning_screen.dart: groceryList typed as List, totalCost ← total_est_price_usd, parse-failure error.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent


# ---------- ai_service.dart ----------
def patch_ai_service() -> None:
    path = ROOT / 'lib/services/ai_service.dart'
    s = path.read_text(encoding='utf-8')

    # 1) Add _mealPlanModel constant (kept separate from chat model).
    old_const = """  static const String _defaultModel = 'claude-haiku-4-5-20251001';
  static const int _maxHistoryMessages = 20;
  static const int _chatMaxTokens = 2048;
  static const int _mealPlanMaxTokens = 8192;"""
    new_const = """  static const String _defaultModel = 'claude-haiku-4-5-20251001';
  // Meal planning needs stronger structured output than haiku — use sonnet.
  static const String _mealPlanModel = 'claude-sonnet-4-5';
  static const int _maxHistoryMessages = 20;
  static const int _chatMaxTokens = 2048;
  static const int _mealPlanMaxTokens = 8192;"""
    if old_const not in s:
        raise SystemExit("ai_service: model constants block not found")
    s = s.replace(old_const, new_const)

    # 2) Replace the entire _mealPlanSystemPrompt block with the strict schema prompt.
    old_prompt_start = "  static const String _mealPlanSystemPrompt = '''"
    old_prompt_end_marker = "If status is `no_compliant_items`, `meals` should be an empty array, and `message` must clearly explain which rules disqualified the catalog.''';"

    start = s.find(old_prompt_start)
    end = s.find(old_prompt_end_marker)
    if start == -1 or end == -1:
        raise SystemExit("ai_service: old system prompt not found")
    end += len(old_prompt_end_marker)
    old_prompt_block = s[start:end]

    new_prompt_block = r"""  static const String _mealPlanSystemPrompt = '''
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
''';"""

    s = s.replace(old_prompt_block, new_prompt_block)

    # 3) Replace the generateMealPlan body (prompt construction + model call + error paths)
    old_generate = """  Future<Map<String, dynamic>> generateMealPlan({
    required String dietType,
    required double budget,
    required int householdSize,
    required int mealCount,
    List<String>? cuisinePreferences,
  }) async {
    try {
      List<Map<String, dynamic>> availableProducts = [];
      String productCatalogJson = '';

      try {
        final productsResult = await _supabaseClient
            .from('products')
            .select('id, name, description, price, category, stores(name)')
            .eq('is_available', true)
            .order('name')
            .limit(150);

        availableProducts =
            List<Map<String, dynamic>>.from(productsResult);

        if (availableProducts.isNotEmpty) {
          final catalogList = availableProducts
              .map((p) => {
                    'id': p['id'],
                    'name': p['name'],
                    'description': p['description'] ?? '',
                    'price': p['price'],
                    'category': p['category'] ?? 'general',
                    'store_name': p['stores']?['name'] ?? 'KJ Store',
                  })
              .toList();
          productCatalogJson = jsonEncode(catalogList);
        }
      } catch (e) {
        debugPrint('[AI] Failed to fetch products for meal planning: $e');
      }

      final bool hasRealProducts = availableProducts.isNotEmpty;

      final String catalogSection = hasRealProducts
          ? '''
ITEM CATALOG (the ONLY source you may use — do NOT invent items):
$productCatalogJson'''
          : '''
NOTE: No products are currently in the catalog. Return status: "no_compliant_items" with message: "No products are currently available in the store catalog."''';

      final prompt = '''
Generate a meal plan with these parameters:
- Diet: $dietType
- Budget: \\$$budget USD
- Household size: $householdSize people
- Number of meals: $mealCount
- Cuisine preferences: ${cuisinePreferences?.join(', ') ?? 'Lebanese / Mediterranean'}

$catalogSection''';

      final messages = [
        Message(role: 'system', content: _mealPlanSystemPrompt),
        Message(role: 'user', content: prompt),
      ];

      final completion = await _claudeClient.createChatCompletion(
        messages: messages,
        model: _defaultModel,
        options: {
          'max_output_tokens': _mealPlanMaxTokens,
          'temperature': 0.3,
        },
      );

      final jsonString = _stripJsonFences(completion.text);
      final mealPlan = _parseJson(jsonString);

      if (mealPlan == null) {
        return {
          'success': false,
          'error': 'Failed to parse meal plan. Please try again.',
        };
      }

      // Handle no_compliant_items status from the LLM
      final status = mealPlan['status'] as String?;
      if (status == 'no_compliant_items') {
        return {
          'success': true,
          'no_compliant_items': true,
          'message': mealPlan['message'] as String? ??
              'No items in the catalog match your diet requirements.',
          'meal_plan': mealPlan,
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
            'estimated_cost': mealPlan['total_estimated_cost'] ?? 0,
            'is_active': true,
          });
        } catch (e) {
          debugPrint('[AI] Failed to save meal plan to DB: $e');
        }
      }

      return {'success': true, 'meal_plan': mealPlan};
    } catch (e) {
      debugPrint('Meal plan generation error: $e');
      return {'success': false, 'error': 'Failed to generate meal plan: $e'};
    }
  }"""

    new_generate = r"""  Future<Map<String, dynamic>> generateMealPlan({
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
  }"""

    if old_generate not in s:
        raise SystemExit("ai_service: generateMealPlan old body not found")
    s = s.replace(old_generate, new_generate)

    # 4) Rewrite getMatchedProductIds for new list-shape grocery_list
    old_matcher = """  Future<Map<String, dynamic>> getMatchedProductIds({
    required Map<String, dynamic> mealPlan,
  }) async {
    try {
      final groceryList =
          mealPlan['grocery_list'] as Map<String, dynamic>?;
      if (groceryList == null) {
        return {
          'success': false,
          'error': 'No grocery list found',
          'product_ids': <String>[],
          'not_found': <String>[],
        };
      }

      final matchedIds = <String>[];
      final notFound = <String>[];

      for (var category in groceryList.keys) {
        final rawItems = groceryList[category];
        if (rawItems is! List) continue;

        for (var item in rawItems) {
          if (item is! Map) continue;
          final itemMap = Map<String, dynamic>.from(item);
          final itemName =
              (itemMap['item'] ?? itemMap['name'] ?? '').toString().trim();
          final productId = itemMap['product_id']?.toString();

          if (itemName.isEmpty) continue;

          // Priority 1: Use product_id from AI response (strict prompt path)
          if (productId != null &&
              productId != 'null' &&
              productId.isNotEmpty) {
            try {
              final check = await _supabaseClient
                  .from('products')
                  .select('id')
                  .eq('id', productId)
                  .eq('is_available', true)
                  .maybeSingle();
              if (check != null) {
                matchedIds.add(productId);
                debugPrint('[AI_CART] ID match: $itemName → $productId');
                continue;
              }
            } catch (e) { debugPrint('[AI_SERVICE] Silent error: $e'); }
          }

          // Priority 2: Fuzzy name search fallback
          // SESSION 29 FIX: Use try/catch instead of .catchError to avoid
          // Dart type mismatch crash.
          try {
            final products = await ProductService.searchProducts(
              itemName,
              storeId: null,
              availableOnly: true,
            );
            if (products.isNotEmpty) {
              matchedIds.add(products.first.id);
              debugPrint(
                  '[AI_CART] Name match: $itemName → ${products.first.name}');
            } else {
              notFound.add(itemName);
              debugPrint('[AI_CART] Not found: $itemName');
            }
          } catch (e) {
            notFound.add(itemName);
            debugPrint('[AI_CART] Search error for $itemName: $e');
          }
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
  }"""

    new_matcher = r"""  Future<Map<String, dynamic>> getMatchedProductIds({
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
  }"""

    if old_matcher not in s:
        raise SystemExit("ai_service: getMatchedProductIds old body not found")
    s = s.replace(old_matcher, new_matcher)

    path.write_text(s, encoding='utf-8')
    print(f"patched {path.relative_to(ROOT)}")


# ---------- meal_calendar_widget.dart ----------
MEAL_CALENDAR = r"""import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/generated/app_localizations.dart';

class MealCalendarWidget extends StatelessWidget {
  final List<dynamic> meals;

  const MealCalendarWidget({
    super.key,
    required this.meals,
  });

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  String _portionLabel(BuildContext context, dynamic v) {
    final raw = (v ?? '').toString().trim();
    if (raw.isEmpty) return AppLocalizations.of(context)!.medium;
    return _capitalize(raw);
  }

  String _ingredientsLabel(dynamic ingredients) {
    if (ingredients is! List || ingredients.isEmpty) return '';
    final parts = <String>[];
    for (final raw in ingredients) {
      if (raw is Map) {
        final name = (raw['name'] ?? '').toString().trim();
        final qty = (raw['qty'] ?? raw['quantity'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        parts.add(qty.isEmpty ? name : '$name ($qty)');
      } else if (raw is String) {
        parts.add(raw);
      }
    }
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: meals.map((meal) {
        final mealData = meal as Map<String, dynamic>;
        final name = (mealData['name'] ?? mealData['meal_name'] ?? '')
            .toString()
            .trim();
        final cuisine = (mealData['cuisine'] ?? '').toString().trim();
        final description = (mealData['description'] ?? '').toString().trim();
        final prepTime = mealData['prep_time_min'] ?? mealData['prep_time'] ?? 0;
        final price =
            mealData['est_price_usd'] ?? mealData['estimated_cost'] ?? 0;
        final ingredients = _ingredientsLabel(mealData['ingredients']);

        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(3.w),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty
                              ? AppLocalizations.of(context)!.meal
                              : name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        if (cuisine.isNotEmpty) ...[
                          SizedBox(height: 0.5.h),
                          Text(
                            cuisine,
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50913).withAlpha(51),
                      borderRadius: BorderRadius.circular(2.w),
                    ),
                    child: Text(
                      '\$${(price is num ? price : 0).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: const Color(0xFFE50913),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  Icon(Icons.timer_outlined, color: Colors.white70, size: 4.w),
                  SizedBox(width: 1.w),
                  Flexible(
                    child: Text(
                      '${prepTime is num ? prepTime.toInt() : 0} min',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 12.sp),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Icon(Icons.restaurant, color: Colors.white70, size: 4.w),
                  SizedBox(width: 1.w),
                  Flexible(
                    child: Text(
                      _portionLabel(context, mealData['portion_size']),
                      style: TextStyle(
                          color: Colors.white70, fontSize: 12.sp),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                SizedBox(height: 1.h),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.sp,
                    height: 1.35,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (ingredients.isNotEmpty) ...[
                SizedBox(height: 1.h),
                Text(
                  AppLocalizations.of(context)!.ingredients,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  ingredients,
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
"""


# ---------- grocery_list_widget.dart ----------
GROCERY_LIST = r"""import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class GroceryListWidget extends StatelessWidget {
  final List<dynamic> groceryList;
  final double totalCost;

  const GroceryListWidget({
    super.key,
    required this.groceryList,
    required this.totalCost,
  });

  @override
  Widget build(BuildContext context) {
    if (groceryList.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 3.h),
        child: Center(
          child: Text(
            'Grocery list is empty.',
            style: TextStyle(color: Colors.white60, fontSize: 13.sp),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...groceryList.map((raw) {
          if (raw is! Map) return const SizedBox.shrink();
          final item = Map<String, dynamic>.from(raw);
          final name = (item['name'] ?? item['item'] ?? '').toString().trim();
          final qty = (item['qty'] ?? item['quantity'] ?? '').toString().trim();
          final priceRaw = item['est_price_usd'] ?? item['price'] ?? 0;
          final price = priceRaw is num ? priceRaw.toDouble() : 0.0;
          if (name.isEmpty) return const SizedBox.shrink();

          return Container(
            margin: EdgeInsets.only(bottom: 1.h),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(2.w),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      if (qty.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 0.3.h),
                          child: Text(
                            qty,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: const Color(0xFFE50913),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: const Color(0xFFE50913).withAlpha(30),
            borderRadius: BorderRadius.circular(2.w),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '\$${totalCost.toStringAsFixed(2)}',
                style: TextStyle(
                  color: const Color(0xFFE50913),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
"""


# ---------- ai_meal_planning_screen.dart ----------
def patch_meal_screen() -> None:
    path = ROOT / 'lib/presentation/ai_meal_planning_screen/ai_meal_planning_screen.dart'
    s = path.read_text(encoding='utf-8')

    # 1) Change groceryList type + totalCost source + display section.
    old_block = """  Widget _buildMealPlanResults() {
    final meals = _mealPlanData?['meals'] as List? ?? [];
    final groceryList =
        _mealPlanData?['grocery_list'] as Map<String, dynamic>? ?? {};
    final totalCost = _mealPlanData?['total_estimated_cost'] ?? 0.0;"""

    new_block = """  Widget _buildMealPlanResults() {
    final meals = _mealPlanData?['meals'] as List? ?? const [];
    final groceryList =
        (_mealPlanData?['grocery_list'] as List?) ?? const [];
    final totalCost = _mealPlanData?['total_est_price_usd']
        ?? _mealPlanData?['total_estimated_cost']
        ?? 0.0;"""

    if old_block not in s:
        raise SystemExit("meal screen: results header not found")
    s = s.replace(old_block, new_block)

    # 2) GroceryListWidget now takes List (already replaced widget above).
    # No signature change needed on the call site — argument type changed from Map to List.

    path.write_text(s, encoding='utf-8')
    print(f"patched {path.relative_to(ROOT)}")


def write_widget(rel: str, content: str) -> None:
    p = ROOT / rel
    p.write_text(content, encoding='utf-8', newline='\n')
    print(f"wrote {rel}")


patch_ai_service()
write_widget('lib/presentation/ai_meal_planning_screen/widgets/meal_calendar_widget.dart', MEAL_CALENDAR)
write_widget('lib/presentation/ai_meal_planning_screen/widgets/grocery_list_widget.dart', GROCERY_LIST)
patch_meal_screen()
print("done")
