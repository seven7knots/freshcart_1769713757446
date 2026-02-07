import 'package:flutter/material.dart' hide FilterChip;
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../providers/admin_provider.dart';
import '../../services/category_service.dart';
import '../../widgets/admin_layout_wrapper.dart';
import './widgets/category_form_modal_widget.dart';
import './widgets/category_list_item_widget.dart';
import './widgets/category_reorder_list_widget.dart';

class AdminCategoriesManagementScreen extends StatefulWidget {
  const AdminCategoriesManagementScreen({super.key});

  @override
  State<AdminCategoriesManagementScreen> createState() =>
      _AdminCategoriesManagementScreenState();
}

class _AdminCategoriesManagementScreenState
    extends State<AdminCategoriesManagementScreen> {
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  String _statusFilter = 'all';

  List<Map<String, dynamic>> _allCategories = [];
  List<Map<String, dynamic>> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final categories = await CategoryService.getAllCategories();
      _allCategories = List<Map<String, dynamic>>.from(categories);
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> list = List.from(_allCategories);

    if (_statusFilter == 'active') {
      list = list.where((c) => c['is_active'] == true).toList();
    } else if (_statusFilter == 'inactive') {
      list = list.where((c) => c['is_active'] == false).toList();
    }

    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) {
        final name = (c['name'] ?? '').toString().toLowerCase();
        return name.contains(q);
      }).toList();
    }

    setState(() => _filteredCategories = list);
  }

  void _openCreateModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryFormModalWidget(
        onCategoryCreated: () {
          Navigator.pop(context);
          _loadCategories();
        },
      ),
    );
  }

  void _openEditModal(Map<String, dynamic> category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryFormModalWidget(
        existingCategory: category,
        onCategoryCreated: () {
          Navigator.pop(context);
          _loadCategories();
        },
      ),
    );
  }

  Future<void> _toggleStatus(Map<String, dynamic> category) async {
    try {
      final isActive = category['is_active'] == true;
      await CategoryService.updateCategory(
          category['id'], {'is_active': !isActive});
      _loadCategories();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _deleteCategory(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category'),
        content:
            const Text('This will permanently remove the category. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await CategoryService.deleteCategory(id);
        _loadCategories();
      } catch (e) {
        _showError(e);
      }
    }
  }

  void _openReorder() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryReorderListWidget(
        categories: _allCategories,
        onReorderComplete: () {
          Navigator.pop(context);
          _loadCategories();
        },
      ),
    );
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final theme = Theme.of(context);

    if (!admin.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Access denied')),
      );
    }

    return AdminLayoutWrapper(
      currentRoute: '/admin-categories-management-screen',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Categories'),
          actions: [
            IconButton(
              icon: const Icon(Icons.swap_vert),
              onPressed: _openReorder,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadCategories,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => _applyFilters(),
                    decoration: InputDecoration(
                      hintText: 'Search categories',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _applyFilters();
                              },
                            )
                          : null,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      _filterChip('All', 'all'),
                      SizedBox(width: 2.w),
                      _filterChip('Active', 'active'),
                      SizedBox(width: 2.w),
                      _filterChip('Inactive', 'inactive'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _filteredCategories.isEmpty
                          ? const Center(child: Text('No categories found'))
                          : ListView.builder(
                              padding: EdgeInsets.all(3.w),
                              itemCount: _filteredCategories.length,
                              itemBuilder: (_, i) {
                                final c = _filteredCategories[i];
                                return CategoryListItemWidget(
                                  category: c,
                                  onEdit: () => _openEditModal(c),
                                  onDelete: () => _deleteCategory(c['id']),
                                  onStatusToggle: () => _toggleStatus(c),
                                );
                              },
                            ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreateModal,
          icon: const Icon(Icons.add),
          label: const Text('Add Category'),
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _statusFilter == value;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _statusFilter = value;
          _applyFilters();
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
