import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import '../../services/ai_service.dart';
import '../../services/analytics_service.dart';
import '../../providers/cart_provider.dart';
import './widgets/diet_preference_widget.dart';
import './widgets/meal_calendar_widget.dart';
import './widgets/grocery_list_widget.dart';
import './widgets/budget_slider_widget.dart';
import '../../l10n/generated/app_localizations.dart';

class AIMealPlanningScreen extends ConsumerStatefulWidget {
  const AIMealPlanningScreen({super.key});

  @override
  ConsumerState<AIMealPlanningScreen> createState() =>
      _AIMealPlanningScreenState();
}

class _AIMealPlanningScreenState extends ConsumerState<AIMealPlanningScreen> {
  final AIService _aiService = AIService();

  String _selectedDiet = 'balanced';
  double _budget = 100.0;
  int _householdSize = 2;
  int _mealCount = 7;
  final List<String> _selectedCuisines = [];

  final List<String> _dietTypes = [
    'balanced',
    'low-carb',
    'keto',
    'vegetarian',
    'vegan',
    'paleo',
    'mediterranean',
    'high-protein',
  ];

  final List<String> _cuisineOptions = [
    'Lebanese',
    'Middle Eastern',
    'Arabic',
    'Turkish',
    'Mediterranean',
    'Italian',
    'Indian',
    'Asian',
    'Mexican',
    'American',
    'French',
    'Thai',
    'Japanese',
    'Korean',
    'Greek',
  ];

  Map<String, dynamic>? _mealPlanData;
  bool _isGenerating = false;
  bool _showGroceryList = false;
  bool _isAddingToCart = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logAIMealPlanningStart();
    AnalyticsService.logScreenView(screenName: 'ai_meal_planning_screen');
  }

  Future<void> _generateMealPlan() async {
    setState(() {
      _isGenerating = true;
      _mealPlanData = null;
      _showGroceryList = false;
      _errorMessage = null;
    });

    try {
      final result = await _aiService.generateMealPlan(
        dietType: _selectedDiet,
        budget: _budget,
        householdSize: _householdSize,
        mealCount: _mealCount,
        cuisinePreferences:
            _selectedCuisines.isEmpty ? null : _selectedCuisines,
      );

      if (!mounted) return;
      if (result['success'] == true) {
        // Handle no_compliant_items: show empty state with message
        if (result['no_compliant_items'] == true) {
          setState(() {
            _isGenerating = false;
            _mealPlanData = null;
            _errorMessage = result['message'] as String? ??
                'No items in the catalog match your diet requirements.';
          });
          return;
        }

        final mealPlan = result['meal_plan'] as Map<String, dynamic>?;
        if (mealPlan != null) {
          setState(() {
            _mealPlanData = mealPlan;
            _isGenerating = false;
          });

          await AnalyticsService.logAIMealPlanGenerated(
            dietType: _selectedDiet,
            budget: _budget,
            householdSize: _householdSize,
          );
        } else {
          if (!mounted) return;
          setState(() {
            _isGenerating = false;
            _errorMessage = AppLocalizations.of(context)?.mealPlanWasEmptyPleaseTry
                ?? 'Meal plan was empty. Please try again.';
          });
        }
      } else {
        setState(() {
          _isGenerating = false;
          _errorMessage = result['error']?.toString()
              ?? AppLocalizations.of(context)?.failedToGenerateMealPlan
              ?? 'Failed to generate meal plan.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Failed to generate meal plan: $e';
      });
    }

    if (_errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red),
      );
    }
  }

  // ============================================================
  // SESSION 29 FIX: Use getMatchedProductIds + CartNotifier.
  //
  // PREVIOUS BUG: Called _aiService.addMealPlanToCart() which used
  // _supabaseClient.from('cart_items').insert() directly, bypassing
  // CartNotifier. Also had a .catchError type mismatch crash.
  //
  // FIX: getMatchedProductIds() only returns product IDs.
  // We then call cartNotifierProvider.notifier.addToCart() for each
  // — proper RLS, deduplication, and state management.
  // ============================================================
  Future<void> _addAllToCart() async {
    if (_mealPlanData == null) return;

    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() => _isAddingToCart = true);

    try {
      final result = await _aiService.getMatchedProductIds(
        mealPlan: _mealPlanData!,
      );

      if (result['success'] != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? AppLocalizations.of(context)!.failedToMatchProducts, maxLines: 1, overflow: TextOverflow.ellipsis),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final productIds = List<String>.from(result['product_ids'] ?? []);
      final notFound = List<String>.from(result['not_found'] ?? []);

      int addedCount = 0;
      int failedCount = 0;

      for (final productId in productIds) {
        try {
          await ref
              .read(cartNotifierProvider.notifier)
              .addToCart(productId: productId, quantity: 1);
          addedCount++;
        } catch (e) {
          debugPrint('[MEAL_CART] Failed to add $productId: $e');
          failedCount++;
        }
      }

      if (mounted) {
        if (notFound.isEmpty && failedCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added $addedCount items to cart!', maxLines: 1, overflow: TextOverflow.ellipsis),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final notFoundMsg = notFound.isNotEmpty
              ? ' ${notFound.length} items not available in stores.'
              : '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Added $addedCount items.$notFoundMsg', maxLines: 1, overflow: TextOverflow.ellipsis),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(
              AppLocalizations.of(context)!.addAllToCart,
              style: TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
            content: Text(
              AppLocalizations.of(context)!.thisWillSearchForMatchingProducts,
              style: TextStyle(color: Colors.white70, fontSize: 12.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                ),
                child: Text(
                  AppLocalizations.of(context)!.addToCart,
                  style: TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.aiMealPlanning,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.planYourMeals,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 1.h),
              Text(
                AppLocalizations.of(context)!.aiCreatesAPersonalizedMealPlan,
                style: TextStyle(color: Colors.white70, fontSize: 13.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 3.h),
              DietPreferenceWidget(
                dietTypes: _dietTypes,
                selectedDiet: _selectedDiet,
                onDietChanged: (diet) => setState(() => _selectedDiet = diet),
              ),
              SizedBox(height: 3.h),
              BudgetSliderWidget(
                budget: _budget,
                onBudgetChanged: (value) => setState(() => _budget = value),
              ),
              SizedBox(height: 3.h),
              _buildHouseholdSelector(),
              SizedBox(height: 3.h),
              _buildMealCountSelector(),
              SizedBox(height: 3.h),
              _buildCuisineSelector(),
              SizedBox(height: 4.h),
              ElevatedButton(
                onPressed: _isGenerating ? null : _generateMealPlan,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isGenerating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.2,
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.generateMealPlan,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
              ),
              if (_mealPlanData != null) ...[
                SizedBox(height: 4.h),
                _buildMealPlanResults(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHouseholdSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.householdSize,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: List.generate(6, (index) {
            final size = index + 1;
            final isSelected = _householdSize == size;
            return GestureDetector(
              onTap: () => setState(() => _householdSize = size),
              child: Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE50914)
                      : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(2.w),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFE50914)
                        : Colors.white24,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$size',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMealCountSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.numberOfMeals,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: [3, 5, 7, 14].map((count) {
            final isSelected = _mealCount == count;
            return GestureDetector(
              onTap: () => setState(() => _mealCount = count),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE50914)
                      : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(2.w),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFE50914)
                        : Colors.white24,
                  ),
                ),
                child: Text(
                  '$count meals',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCuisineSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.cuisinePreferences,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _cuisineOptions.map((cuisine) {
            final isSelected = _selectedCuisines.contains(cuisine);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedCuisines.remove(cuisine);
                  } else {
                    _selectedCuisines.add(cuisine);
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE50914)
                      : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(6.w),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFE50914)
                        : Colors.white24,
                  ),
                ),
                child: Text(
                  cuisine,
                  style: TextStyle(color: Colors.white, fontSize: 12.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMealPlanResults() {
    final meals = _mealPlanData?['meals'] as List? ?? [];
    final groceryList =
        _mealPlanData?['grocery_list'] as Map<String, dynamic>? ?? {};
    final totalCost = _mealPlanData?['total_estimated_cost'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(
              AppLocalizations.of(context)!.yourMealPlan,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Flexible(child: Text(
              'Est. \$${(totalCost is num ? totalCost : 0.0).toStringAsFixed(2)}',
              style: TextStyle(
                color: const Color(0xFFE50914),
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => _showGroceryList = false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: !_showGroceryList
                      ? const Color(0xFFE50914)
                      : const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2.w)),
                ),
                child: Text(
                  AppLocalizations.of(context)!.meals,
                  style: TextStyle(color: Colors.white, fontSize: 13.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => _showGroceryList = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _showGroceryList
                      ? const Color(0xFFE50914)
                      : const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2.w)),
                ),
                child: Text(
                  AppLocalizations.of(context)!.groceryList,
                  style: TextStyle(color: Colors.white, fontSize: 13.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        if (!_showGroceryList)
          MealCalendarWidget(meals: meals)
        else
          GroceryListWidget(
            groceryList: groceryList,
            totalCost: totalCost is num ? totalCost.toDouble() : 0.0,
          ),
        SizedBox(height: 3.h),
        // Add to Cart bar — Container + InkWell so press feedback is a clean white overlay,
        // not a wash-out. minHeight 56 for proper tap target; Expanded label with ellipsis.
        Material(
          color: Colors.green.shade700,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _isAddingToCart ? null : _addAllToCart,
            splashColor: Colors.white.withOpacity(0.2),
            highlightColor: Colors.white.withOpacity(0.1),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isAddingToCart
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.shopping_cart, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isAddingToCart
                            ? AppLocalizations.of(context)!.addingToCart
                            : AppLocalizations.of(context)!.addGroceryListToCart,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 2.h),
        OutlinedButton.icon(
          onPressed: _isGenerating ? null : _generateMealPlan,
          icon: const Icon(Icons.refresh, color: Colors.white70),
          label: Text(
            AppLocalizations.of(context)!.regeneratePlan,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            side: const BorderSide(color: Colors.white24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        SizedBox(height: 4.h),
      ],
    );
  }
}