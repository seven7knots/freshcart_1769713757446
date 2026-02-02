class MealPlanModel {
  final String id;
  final String userId;
  final String dietType;
  final double budget;
  final int householdSize;
  final int mealCount;
  final List<String>? cuisinePreferences;
  final List<MealItem> meals;
  final Map<String, List<GroceryItem>> groceryList;
  final double estimatedCost;
  final DateTime createdAt;

  MealPlanModel({
    required this.id,
    required this.userId,
    required this.dietType,
    required this.budget,
    required this.householdSize,
    required this.mealCount,
    this.cuisinePreferences,
    required this.meals,
    required this.groceryList,
    required this.estimatedCost,
    required this.createdAt,
  });

  factory MealPlanModel.fromJson(Map<String, dynamic> json) {
    return MealPlanModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      dietType: json['diet_type'] ?? '',
      budget: (json['budget'] ?? 0).toDouble(),
      householdSize: json['household_size'] ?? 1,
      mealCount: json['meal_count'] ?? 0,
      cuisinePreferences: json['cuisine_preferences'] != null
          ? List<String>.from(json['cuisine_preferences'])
          : null,
      meals: json['meals'] != null
          ? (json['meals'] as List).map((m) => MealItem.fromJson(m)).toList()
          : [],
      groceryList: json['grocery_list'] != null
          ? (json['grocery_list'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key,
                (value as List)
                    .map((item) => GroceryItem.fromJson(item))
                    .toList(),
              ),
            )
          : {},
      estimatedCost: (json['estimated_cost'] ?? 0).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'diet_type': dietType,
      'budget': budget,
      'household_size': householdSize,
      'meal_count': mealCount,
      'cuisine_preferences': cuisinePreferences,
      'meals': meals.map((m) => m.toJson()).toList(),
      'grocery_list': groceryList.map(
        (key, value) => MapEntry(
          key,
          value.map((item) => item.toJson()).toList(),
        ),
      ),
      'estimated_cost': estimatedCost,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class MealItem {
  final String name;
  final List<String> ingredients;
  final int prepTime;
  final String difficulty;
  final double estimatedCost;

  MealItem({
    required this.name,
    required this.ingredients,
    required this.prepTime,
    required this.difficulty,
    required this.estimatedCost,
  });

  factory MealItem.fromJson(Map<String, dynamic> json) {
    return MealItem(
      name: json['name'] ?? '',
      ingredients: json['ingredients'] != null
          ? List<String>.from(json['ingredients'])
          : [],
      prepTime: json['prep_time'] ?? 0,
      difficulty: json['difficulty'] ?? 'medium',
      estimatedCost: (json['estimated_cost'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'ingredients': ingredients,
      'prep_time': prepTime,
      'difficulty': difficulty,
      'estimated_cost': estimatedCost,
    };
  }
}

class GroceryItem {
  final String name;
  final String quantity;
  final double estimatedPrice;
  final bool available;

  GroceryItem({
    required this.name,
    required this.quantity,
    required this.estimatedPrice,
    this.available = true,
  });

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? '',
      estimatedPrice: (json['estimated_price'] ?? 0).toDouble(),
      available: json['available'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'estimated_price': estimatedPrice,
      'available': available,
    };
  }
}
