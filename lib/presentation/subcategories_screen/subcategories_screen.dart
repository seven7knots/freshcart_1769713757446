import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';
import '../../services/category_service.dart';
import './widgets/subcategory_card_widget.dart';
import './widgets/subcategory_filter_widget.dart';

class SubcategoriesScreen extends StatefulWidget {
  final dynamic parentCategoryId;
  final String parentCategoryName;

  const SubcategoriesScreen({
    super.key,
    required this.parentCategoryId,
    required this.parentCategoryName,
  });

  @override
  State<SubcategoriesScreen> createState() => _SubcategoriesScreenState();
}

class _SubcategoriesScreenState extends State<SubcategoriesScreen> {
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];

  // If you decide to use types later (product/service/marketplace)
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    _loadSubcategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSubcategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rows = await _categoryService.getSubcategories(
        widget.parentCategoryId.toString(),
      );

      setState(() {
        _all = rows;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    var list = List<Map<String, dynamic>>.from(_all);

    // Type filter (optional)
    if (_typeFilter != null && _typeFilter!.trim().isNotEmpty) {
      list = list.where((c) => (c['type']?.toString() ?? '') == _typeFilter).toList();
    }

    // Search filter
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) {
        final name = (c['name'] as String? ?? '').toLowerCase();
        final desc = (c['description'] as String? ?? '').toLowerCase();
        return name.contains(q) || desc.contains(q);
      }).toList();
    }

    _filtered = list;
  }

  Future<void> _onSubcategoryTap(Map<String, dynamic> sub) async {
    final id = sub['id'];
    final name = (sub['name'] as String?) ?? 'Category';

    // If it has children -> go deeper
    final hasChildren =
        (sub['has_children'] == true) || ((sub['children_count'] ?? 0) as int > 0);

    if (hasChildren) {
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.subcategoriesScreen,
        arguments: {
          'parentCategoryId': id,
          'parentCategoryName': name,
        },
      );
      return;
    }

    // Otherwise -> open listings
    if (!mounted) return;
    Navigator.pushNamed(
      context,
      AppRoutes.categoryListingsScreen,
      arguments: {
        'categoryId': id,
        'fromTab': true,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.parentCategoryName),
        actions: [
          IconButton(
            onPressed: _loadSubcategories,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search + Filter row
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() => _applyFilters()),
                  decoration: InputDecoration(
                    hintText: 'Search subcategories...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _applyFilters());
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.5.h,
                    ),
                  ),
                ),
                SizedBox(height: 1.2.h),
                SubcategoryFilterWidget(
                  selectedType: _typeFilter,
                  onTypeChanged: (val) {
                    setState(() {
                      _typeFilter = val;
                      _applyFilters();
                    });
                  },
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(4.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48, color: theme.colorScheme.error),
                              SizedBox(height: 2.h),
                              Text(
                                'Failed to load subcategories',
                                style: theme.textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                _error!,
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 2.h),
                              ElevatedButton(
                                onPressed: _loadSubcategories,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(4.w),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.category_outlined,
                                      size: 64,
                                      color: theme.colorScheme.outline),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'No subcategories found',
                                    style: theme.textTheme.titleMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 1.h),
                                  Text(
                                    'Create subcategories under "${widget.parentCategoryName}" in Admin → Categories.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadSubcategories,
                            child: GridView.builder(
                              padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 3.h),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 3.w,
                                mainAxisSpacing: 2.h,
                                childAspectRatio: 1.25,
                              ),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final sub = _filtered[index];
                                return SubcategoryCardWidget(
                                  subcategory: sub,
                                  onTap: () => _onSubcategoryTap(sub),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
