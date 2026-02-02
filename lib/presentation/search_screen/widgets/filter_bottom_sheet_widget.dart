import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FilterBottomSheetWidget extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>)? onFiltersApplied;
  final VoidCallback? onClearAll;

  const FilterBottomSheetWidget({
    super.key,
    required this.currentFilters,
    this.onFiltersApplied,
    this.onClearAll,
  });

  @override
  State<FilterBottomSheetWidget> createState() =>
      _FilterBottomSheetWidgetState();
}

class _FilterBottomSheetWidgetState extends State<FilterBottomSheetWidget> {
  late Map<String, dynamic> _filters;
  RangeValues _priceRange = const RangeValues(0, 100);

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.currentFilters);
    _priceRange = RangeValues(
      (_filters['minPrice'] as double?) ?? 0,
      (_filters['maxPrice'] as double?) ?? 100,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoriesSection(),
                  _buildPriceRangeSection(),
                  _buildBrandsSection(),
                  _buildDietarySection(),
                  _buildRatingsSection(),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Filters',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _filters.clear();
                    _priceRange = const RangeValues(0, 100);
                  });
                  widget.onClearAll?.call();
                },
                child: Text('Clear All'),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                icon: CustomIconWidget(
                  iconName: 'close',
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final categories = [
      'Fruits & Vegetables',
      'Dairy & Eggs',
      'Meat & Seafood',
      'Bakery',
      'Snacks',
      'Beverages',
      'Frozen Foods',
      'Pantry Staples',
    ];

    return _buildFilterSection(
      'Categories',
      Column(
        children: categories.map((category) {
          final isSelected =
              (_filters['categories'] as List<String>?)?.contains(category) ??
                  false;
          return CheckboxListTile(
            title: Text(category),
            value: isSelected,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              setState(() {
                final selectedCategories =
                    (_filters['categories'] as List<String>?) ?? <String>[];
                if (value == true) {
                  selectedCategories.add(category);
                } else {
                  selectedCategories.remove(category);
                }
                _filters['categories'] = selectedCategories;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceRangeSection() {
    return _buildFilterSection(
      'Price Range',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${_priceRange.start.round()}',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '\$${_priceRange.end.round()}',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: (values) {
              HapticFeedback.lightImpact();
              setState(() {
                _priceRange = values;
                _filters['minPrice'] = values.start;
                _filters['maxPrice'] = values.end;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBrandsSection() {
    final brands = [
      'Organic Valley',
      'Fresh Market',
      'Nature\'s Best',
      'Farm Fresh',
      'Green Choice',
      'Pure & Simple',
    ];

    return _buildFilterSection(
      'Brands',
      Column(
        children: brands.map((brand) {
          final isSelected =
              (_filters['brands'] as List<String>?)?.contains(brand) ?? false;
          return CheckboxListTile(
            title: Text(brand),
            value: isSelected,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              setState(() {
                final selectedBrands =
                    (_filters['brands'] as List<String>?) ?? <String>[];
                if (value == true) {
                  selectedBrands.add(brand);
                } else {
                  selectedBrands.remove(brand);
                }
                _filters['brands'] = selectedBrands;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDietarySection() {
    final dietary = [
      'Organic',
      'Gluten-Free',
      'Vegan',
      'Vegetarian',
      'Keto-Friendly',
      'Low-Sodium',
      'Sugar-Free',
    ];

    return _buildFilterSection(
      'Dietary Preferences',
      Column(
        children: dietary.map((diet) {
          final isSelected =
              (_filters['dietary'] as List<String>?)?.contains(diet) ?? false;
          return CheckboxListTile(
            title: Text(diet),
            value: isSelected,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              setState(() {
                final selectedDietary =
                    (_filters['dietary'] as List<String>?) ?? <String>[];
                if (value == true) {
                  selectedDietary.add(diet);
                } else {
                  selectedDietary.remove(diet);
                }
                _filters['dietary'] = selectedDietary;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRatingsSection() {
    return _buildFilterSection(
      'Customer Rating',
      Column(
        children: List.generate(5, (index) {
          final rating = 5 - index;
          final isSelected = (_filters['minRating'] as int?) == rating;
          return RadioListTile<int>(
            title: Row(
              children: [
                ...List.generate(
                    rating,
                    (i) => CustomIconWidget(
                          iconName: 'star',
                          color: AppTheme.lightTheme.colorScheme.tertiary,
                          size: 16,
                        )),
                ...List.generate(
                    5 - rating,
                    (i) => CustomIconWidget(
                          iconName: 'star_border',
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 16,
                        )),
                SizedBox(width: 2.w),
                Text('& up'),
              ],
            ),
            value: rating,
            groupValue: _filters['minRating'] as int?,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              setState(() {
                _filters['minRating'] = value;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          );
        }),
      ),
    );
  }

  Widget _buildFilterSection(String title, Widget content) {
    return ExpansionTile(
      title: Text(
        title,
        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      initiallyExpanded: true,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: content,
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    final activeFiltersCount = _getActiveFiltersCount();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onFiltersApplied?.call(_filters);
                  Navigator.pop(context);
                },
                child: Text(
                  activeFiltersCount > 0
                      ? 'Apply ($activeFiltersCount)'
                      : 'Apply Filters',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getActiveFiltersCount() {
    int count = 0;

    if ((_filters['categories'] as List<String>?)?.isNotEmpty == true) count++;
    if (_filters['minPrice'] != null || _filters['maxPrice'] != null) count++;
    if ((_filters['brands'] as List<String>?)?.isNotEmpty == true) count++;
    if ((_filters['dietary'] as List<String>?)?.isNotEmpty == true) count++;
    if (_filters['minRating'] != null) count++;

    return count;
  }
}
