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
  ];

  final List<String> _cuisineOptions = [
    'Italian',
    'Mexican',
    'Asian',
    'American',
    'Mediterranean',
    'Indian',
    'Thai',
    'Japanese',
  ];

  Map<String, dynamic>? _generatedMealPlan;
  bool _isGenerating = false;
  bool _showGroceryList = false;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();

    // Track AI meal planning start
    AnalyticsService.logAIMealPlanningStart();
    AnalyticsService.logScreenView(screenName: 'ai_meal_planning_screen');
  }

  Future<void> _generateMealPlan() async {
    setState(() {
      _isGenerating = true;
      _generatedMealPlan = null;
      _showGroceryList = false;
    });

    try {
      final mealPlan = await _aiService.generateMealPlan(
        dietType: _selectedDiet,
        budget: _budget,
        householdSize: _householdSize,
        mealCount: _mealCount,
        cuisinePreferences: _selectedCuisines,
      );

      setState(() {
        _generatedMealPlan = mealPlan;
        _isGenerating = false;
      });

      // Track meal plan generated
      await AnalyticsService.logAIMealPlanGenerated(
        dietType: _selectedDiet,
        budget: _budget,
        householdSize: _householdSize,
      );
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate meal plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addAllToCart() async {
    if (_generatedMealPlan == null) return;

    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      _isAddingToCart = true;
    });

    try {
      final result = await _aiService.addMealPlanToCart(
        mealPlan: _generatedMealPlan!,
      );

      if (result['success'] == true) {
        final itemsAdded = result['items_added'] ?? 0;
        final errors = result['errors'] as List? ?? [];

        // Refresh cart
        ref.read(cartNotifierProvider.notifier).loadCart();

        if (errors.isEmpty) {
          _showError('Added $itemsAdded items to cart!');
        } else {
          _showError(
            'Added $itemsAdded items to cart. ${errors.length} items not found.',
          );
        }
      } else {
        _showError(result['error'] ?? 'Failed to add items to cart');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() {
        _isAddingToCart = false;
      });
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              'Add All to Cart?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'This will add all grocery items from your meal plan to the cart. Continue?',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12.sp,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                ),
                child: const Text('Add to Cart'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
          'AI Meal Planning',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan Your Meals',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Let AI create a personalized meal plan based on your preferences',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 3.h),
              DietPreferenceWidget(
                dietTypes: _dietTypes,
                selectedDiet: _selectedDiet,
                onDietChanged: (diet) {
                  setState(() {
                    _selectedDiet = diet;
                  });
                },
              ),
              SizedBox(height: 3.h),
              BudgetSliderWidget(
                budget: _budget,
                onBudgetChanged: (value) {
                  setState(() {
                    _budget = value;
                  });
                },
              ),
              SizedBox(height: 3.h),
              _buildHouseholdSelector(),
              SizedBox(height: 3.h),
              _buildMealCountSelector(),
              SizedBox(height: 3.h),
              _buildCuisineSelector(),
              SizedBox(height: 4.h),
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generateMealPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3.w),
                    ),
                  ),
                  child: _isGenerating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Generate Meal Plan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              if (_generatedMealPlan != null) ...[
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
          'Household Size',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: List.generate(6, (index) {
            final size = index + 1;
            final isSelected = _householdSize == size;
            return Padding(
              padding: EdgeInsets.only(right: 2.w),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _householdSize = size;
                  });
                },
                child: Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE50914)
                        : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(2.w),
                    border: Border.all(
                      color:
                          isSelected ? const Color(0xFFE50914) : Colors.white24,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$size',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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
          'Number of Meals',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [3, 5, 7, 14].map((count) {
            final isSelected = _mealCount == count;
            return Padding(
              padding: EdgeInsets.only(right: 2.w),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _mealCount = count;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE50914)
                        : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(2.w),
                    border: Border.all(
                      color:
                          isSelected ? const Color(0xFFE50914) : Colors.white24,
                    ),
                  ),
                  child: Text(
                    '$count meals',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
          'Cuisine Preferences',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
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
                padding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 1.h,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE50914)
                      : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(6.w),
                  border: Border.all(
                    color:
                        isSelected ? const Color(0xFFE50914) : Colors.white24,
                  ),
                ),
                child: Text(
                  cuisine,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMealPlanResults() {
    final meals = _generatedMealPlan?['meals'] as List? ?? [];
    final groceryList =
        _generatedMealPlan?['grocery_list'] as Map<String, dynamic>? ?? {};
    final totalCost = _generatedMealPlan?['total_estimated_cost'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Meal Plan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Est. \$${totalCost.toStringAsFixed(2)}',
              style: TextStyle(
                color: const Color(0xFFE50914),
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showGroceryList = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: !_showGroceryList
                      ? const Color(0xFFE50914)
                      : const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                ),
                child: Text(
                  'Meals',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showGroceryList = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _showGroceryList
                      ? const Color(0xFFE50914)
                      : const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                ),
                child: Text(
                  'Grocery List',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                  ),
                ),
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
            totalCost: totalCost,
          ),
      ],
    );
  }
}
