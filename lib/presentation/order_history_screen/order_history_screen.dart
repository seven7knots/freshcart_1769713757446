import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/database_service.dart';
import '../../services/order_service.dart';
import '../../widgets/main_layout_wrapper.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/order_card_widget.dart';
import './widgets/search_bar_widget.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _allOrders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  Map<String, dynamic> _currentFilters = {};
  bool _isLoading = true;
  bool _isSearching = false;
  String? _error;
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _loadOrders();
  }

  bool get _shouldShowBack =>
      Navigator.of(context).canPop() && MainLayoutWrapper.of(context) == null;

  void _goToTab(int index) {
    final wrapper = MainLayoutWrapper.of(context);
    if (wrapper != null) {
      wrapper.updateTabIndex(index);
      return;
    }
    Navigator.pushNamed(context, AppRoutes.getRouteForIndex(index));
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orderService = OrderService();
      final orders = await orderService.getUserOrders(limit: 50);

      if (mounted) {
        setState(() {
          _allOrders
            ..clear()
            ..addAll(orders);
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreOrders();
    }
  }

  void _onSearchChanged() {
    setState(() {
      _isSearching = _searchController.text.isNotEmpty;
    });

    if (_searchController.text.isNotEmpty) {
      _performSearch();
    } else {
      _applyFilters();
    }
  }

  Future<void> _performSearch() async => _applyFilters();

  void _loadMoreOrders() {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _currentPage++;
        _isLoading = false;
      });
    });
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allOrders);

    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((order) {
        final orderId = (order['orderId'] as String).toLowerCase();
        final orderDate = DateTime.parse(order['orderDate'] as String);
        final dateString =
            '${orderDate.day}/${orderDate.month}/${orderDate.year}';

        bool matchesOrder =
            orderId.contains(searchTerm) || dateString.contains(searchTerm);

        if (!matchesOrder) {
          final items = order['items'] as List<dynamic>;
          matchesOrder = items.any(
            (item) =>
                (item['name'] as String).toLowerCase().contains(searchTerm),
          );
        }

        return matchesOrder;
      }).toList();
    }

    if (_currentFilters['status'] != null) {
      filtered = filtered
          .where((order) => order['status'] == _currentFilters['status'])
          .toList();
    }

    if (_currentFilters['dateRange'] != null) {
      final dateRange = _currentFilters['dateRange'] as DateTimeRange;
      filtered = filtered.where((order) {
        final orderDate = DateTime.parse(order['orderDate'] as String);
        return orderDate.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
            orderDate.isBefore(dateRange.end.add(const Duration(days: 1)));
      }).toList();
    }

    if (_currentFilters['priceRange'] != null) {
      final priceRange = _currentFilters['priceRange'] as RangeValues;
      filtered = filtered.where((order) {
        final totalAmount = order['totalAmount'] as double;
        return totalAmount >= priceRange.start && totalAmount <= priceRange.end;
      }).toList();
    }

    if (_currentFilters['sortBy'] != null) {
      final sortBy = _currentFilters['sortBy'] as String;
      switch (sortBy) {
        case 'Recent First':
          filtered.sort(
            (a, b) => DateTime.parse(b['orderDate'] as String)
                .compareTo(DateTime.parse(a['orderDate'] as String)),
          );
          break;
        case 'Oldest First':
          filtered.sort(
            (a, b) => DateTime.parse(a['orderDate'] as String)
                .compareTo(DateTime.parse(b['orderDate'] as String)),
          );
          break;
        case 'Price: High to Low':
          filtered.sort(
            (a, b) =>
                (b['totalAmount'] as double).compareTo(a['totalAmount'] as double),
          );
          break;
        case 'Price: Low to High':
          filtered.sort(
            (a, b) =>
                (a['totalAmount'] as double).compareTo(b['totalAmount'] as double),
          );
          break;
      }
    }

    setState(() => _filteredOrders = filtered);
  }

  void _showFilterBottomSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: 80.h,
        child: FilterBottomSheetWidget(
          currentFilters: _currentFilters,
          onApplyFilters: (filters) {
            setState(() => _currentFilters = filters);
            _applyFilters();
          },
        ),
      ),
    );
  }

  void _handleReorderAll(Map<String, dynamic> order) {
    final cs = Theme.of(context).colorScheme;
    HapticFeedback.lightImpact();
    final items = order['items'] as List<dynamic>;
    final availableItems =
        items.where((item) => item['isAvailable'] == true).length;

    Fluttertoast.showToast(
      msg: '$availableItems items added to cart',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: cs.primary,
      textColor: cs.onPrimary,
    );
  }

  void _handleAddToCart(Map<String, dynamic> item) {
    final cs = Theme.of(context).colorScheme;
    HapticFeedback.lightImpact();
    Fluttertoast.showToast(
      msg: '${item['name']} added to cart',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: cs.secondary,
      textColor: cs.onSecondary,
    );
  }

  void _handleDownloadReceipt() {
    HapticFeedback.lightImpact();
    Fluttertoast.showToast(
      msg: 'Receipt downloaded successfully',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handleRateOrder() {
    HapticFeedback.lightImpact();
    _showRatingDialog();
  }

  void _handleReportIssue() {
    HapticFeedback.lightImpact();
    Fluttertoast.showToast(
      msg: 'Issue reported. We\'ll contact you soon.',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handleShareOrder() {
    HapticFeedback.lightImpact();
    Fluttertoast.showToast(
      msg: 'Order details shared',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handleVoiceSearch() {
    HapticFeedback.lightImpact();
    Fluttertoast.showToast(
      msg: 'Voice search activated',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handleBarcodeSearch() {
    HapticFeedback.lightImpact();
    Fluttertoast.showToast(
      msg: 'Barcode scanner opened',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handleExploreProducts() {
    HapticFeedback.lightImpact();
    _goToTab(0);
  }

  void _showRatingDialog() {
    int selectedRating = 5;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cs.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Rate Your Order',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How was your shopping experience?', style: theme.textTheme.bodyLarge),
              SizedBox(height: 3.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setDialogState(() => selectedRating = index + 1);
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 1.w),
                      child: Icon(
                        index < selectedRating ? Icons.star : Icons.star_border,
                        size: 32,
                        color: index < selectedRating ? cs.tertiary : cs.outline,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: theme.textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Fluttertoast.showToast(
                  msg: 'Thank you for your $selectedRating star rating!',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: cs.secondary,
                  textColor: cs.onSecondary,
                );
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshOrders() async {
    HapticFeedback.lightImpact();
    await _loadOrders();
    if (!mounted) return;

    Fluttertoast.showToast(
      msg: 'Orders refreshed',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Future<void> _reorderItems(String orderId) async {
    try {
      final order = await DatabaseService.instance.getOrderById(orderId);
      final orderItems = order['order_items'] as List<dynamic>;

      for (final item in orderItems) {
        await DatabaseService.instance.addToCart(
          productId: item['product_id'],
          quantity: item['quantity'],
          optionsSelected: item['options_selected'] != null
              ? List<Map<String, dynamic>>.from(item['options_selected'])
              : null,
          specialInstructions: item['special_instructions'],
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Items added to cart'),
            backgroundColor: Colors.green,
          ),
        );
        _goToTab(2);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reorder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: _shouldShowBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Order History',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: 2.h),
                  Text('Loading orders...', style: theme.textTheme.bodyMedium),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 15.w, color: cs.error),
                      SizedBox(height: 2.h),
                      Text(
                        'Error Loading Orders',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      ElevatedButton.icon(
                        onPressed: _loadOrders,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 1.5.h,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : _filteredOrders.isEmpty
                  ? EmptyStateWidget(onExploreProducts: _handleExploreProducts)
                  : RefreshIndicator(
                      onRefresh: _refreshOrders,
                      child: CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverToBoxAdapter(
                            child: SearchBarWidget(
                              controller: _searchController,
                              hintText: 'Search orders, products, or dates...',
                              onChanged: (value) => _applyFilters(),
                              onVoiceSearch: _handleVoiceSearch,
                              onBarcodeSearch: _handleBarcodeSearch,
                              onClear: () => _applyFilters(),
                            ),
                          ),
                          if (_isSearching || _currentFilters.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(horizontal: 4.w),
                                child: Text(
                                  '${_filteredOrders.length} order${_filteredOrders.length != 1 ? 's' : ''} found',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index == _filteredOrders.length) {
                                  return Container(
                                    padding: EdgeInsets.all(4.w),
                                    child: Center(
                                      child: CircularProgressIndicator(color: cs.primary),
                                    ),
                                  );
                                }

                                final order = _filteredOrders[index];
                                return OrderCardWidget(
                                  order: order,
                                  onReorderAll: () => _handleReorderAll(order),
                                  onAddToCart: _handleAddToCart,
                                  onDownloadReceipt: _handleDownloadReceipt,
                                  onRateOrder: _handleRateOrder,
                                  onReportIssue: _handleReportIssue,
                                  onShareOrder: _handleShareOrder,
                                );
                              },
                              childCount: _filteredOrders.length + (_isLoading ? 1 : 0),
                            ),
                          ),
                          SliverToBoxAdapter(child: SizedBox(height: 10.h)),
                        ],
                      ),
                    ),
    );
  }
}
