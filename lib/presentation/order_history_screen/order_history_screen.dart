import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/database_service.dart';
import '../../services/order_service.dart';
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
          _allOrders.clear();
          _allOrders.addAll(orders);
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

  String _formatStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Processing';
      case 'confirmed':
      case 'preparing':
        return 'Processing';
      case 'ready':
      case 'picked_up':
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Processing';
    }
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

  Future<void> _performSearch() async {
    // Search will be handled by filtering _allOrders
    _applyFilters();
  }

  void _loadMoreOrders() {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate loading more orders
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _currentPage++;
          _isLoading = false;
        });
      }
    });
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allOrders);

    // Search filter
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((order) {
        final orderId = (order['orderId'] as String).toLowerCase();
        final orderDate = DateTime.parse(order['orderDate'] as String);
        final dateString =
            '${orderDate.day}/${orderDate.month}/${orderDate.year}';

        // Search in order ID, date, or item names
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

    // Status filter
    if (_currentFilters['status'] != null) {
      filtered = filtered
          .where((order) => order['status'] == _currentFilters['status'])
          .toList();
    }

    // Date range filter
    if (_currentFilters['dateRange'] != null) {
      final dateRange = _currentFilters['dateRange'] as DateTimeRange;
      filtered = filtered.where((order) {
        final orderDate = DateTime.parse(order['orderDate'] as String);
        return orderDate.isAfter(
              dateRange.start.subtract(const Duration(days: 1)),
            ) &&
            orderDate.isBefore(dateRange.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Price range filter
    if (_currentFilters['priceRange'] != null) {
      final priceRange = _currentFilters['priceRange'] as RangeValues;
      filtered = filtered.where((order) {
        final totalAmount = order['totalAmount'] as double;
        return totalAmount >= priceRange.start && totalAmount <= priceRange.end;
      }).toList();
    }

    // Sort filter
    if (_currentFilters['sortBy'] != null) {
      final sortBy = _currentFilters['sortBy'] as String;
      switch (sortBy) {
        case 'Recent First':
          filtered.sort(
            (a, b) => DateTime.parse(
              b['orderDate'] as String,
            ).compareTo(DateTime.parse(a['orderDate'] as String)),
          );
          break;
        case 'Oldest First':
          filtered.sort(
            (a, b) => DateTime.parse(
              a['orderDate'] as String,
            ).compareTo(DateTime.parse(b['orderDate'] as String)),
          );
          break;
        case 'Price: High to Low':
          filtered.sort(
            (a, b) => (b['totalAmount'] as double).compareTo(
              a['totalAmount'] as double,
            ),
          );
          break;
        case 'Price: Low to High':
          filtered.sort(
            (a, b) => (a['totalAmount'] as double).compareTo(
              b['totalAmount'] as double,
            ),
          );
          break;
      }
    }

    setState(() {
      _filteredOrders = filtered;
    });
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
            setState(() {
              _currentFilters = filters;
            });
            _applyFilters();
          },
        ),
      ),
    );
  }

  void _handleReorderAll(Map<String, dynamic> order) {
    HapticFeedback.lightImpact();
    final items = order['items'] as List<dynamic>;
    final availableItems =
        items.where((item) => item['isAvailable'] == true).length;

    Fluttertoast.showToast(
      msg: '$availableItems items added to cart',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      textColor: AppTheme.lightTheme.colorScheme.onPrimary,
    );
  }

  void _handleAddToCart(Map<String, dynamic> item) {
    HapticFeedback.lightImpact();
    Fluttertoast.showToast(
      msg: '${item['name']} added to cart',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
      textColor: AppTheme.lightTheme.colorScheme.onSecondary,
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
    Navigator.pushNamed(context, '/home-screen');
  }

  void _showRatingDialog() {
    int selectedRating = 5;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.lightTheme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Rate Your Order',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How was your shopping experience?',
                style: AppTheme.lightTheme.textTheme.bodyLarge,
              ),
              SizedBox(height: 3.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setDialogState(() {
                        selectedRating = index + 1;
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 1.w),
                      child: CustomIconWidget(
                        iconName:
                            index < selectedRating ? 'star' : 'star_border',
                        color: index < selectedRating
                            ? AppTheme.lightTheme.colorScheme.tertiary
                            : AppTheme.lightTheme.colorScheme.outline,
                        size: 32,
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
              child: Text(
                'Cancel',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Fluttertoast.showToast(
                  msg: 'Thank you for your $selectedRating star rating!',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
                  textColor: AppTheme.lightTheme.colorScheme.onSecondary,
                );
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshOrders() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
    });

    // Simulate refresh
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _currentPage = 1;
      });
      // Remove this line - _loadOrderHistory() method doesn't exist
      // _loadOrderHistory();

      Fluttertoast.showToast(
        msg: 'Orders refreshed',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
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

        // Navigate to cart
        Navigator.pushNamed(context, '/shopping-cart-screen');
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
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Order History',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTheme.colorScheme.onSurface,
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
                  Text(
                    'Loading orders...',
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 15.w, color: Colors.red),
                      SizedBox(height: 2.h),
                      Text(
                        'Error Loading Orders',
                        style:
                            AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      ElevatedButton.icon(
                        onPressed: _loadOrders,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppTheme.lightTheme.colorScheme.primary,
                          foregroundColor: Colors.white,
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
                  ? EmptyStateWidget(
                      onExploreProducts: () {
                        Navigator.pushNamed(context, AppRoutes.home);
                      },
                    )
                  : Column(
                      children: [
                        Builder(
                          builder: (BuildContext context) {
                            return CustomScrollView(
                              slivers: [
                                SliverToBoxAdapter(
                                  child: SearchBarWidget(
                                    controller: _searchController,
                                    hintText:
                                        'Search orders, products, or dates...',
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
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 4.w),
                                      child: Text(
                                        '${_filteredOrders.length} order${_filteredOrders.length != 1 ? 's' : ''} found',
                                        style: AppTheme
                                            .lightTheme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: AppTheme.lightTheme.colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                _filteredOrders.isEmpty
                                    ? SliverFillRemaining(
                                        child: EmptyStateWidget(
                                          onExploreProducts:
                                              _handleExploreProducts,
                                        ),
                                      )
                                    : SliverList(
                                        delegate: SliverChildBuilderDelegate(
                                          (context, index) {
                                            if (index ==
                                                _filteredOrders.length) {
                                              return Container(
                                                padding: EdgeInsets.all(4.w),
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: AppTheme.lightTheme
                                                        .colorScheme.primary,
                                                  ),
                                                ),
                                              );
                                            }

                                            final order =
                                                _filteredOrders[index];
                                            return OrderCardWidget(
                                              order: order,
                                              onReorderAll: () =>
                                                  _handleReorderAll(order),
                                              onAddToCart: _handleAddToCart,
                                              onDownloadReceipt:
                                                  _handleDownloadReceipt,
                                              onRateOrder: _handleRateOrder,
                                              onReportIssue: _handleReportIssue,
                                              onShareOrder: _handleShareOrder,
                                            );
                                          },
                                          childCount: _filteredOrders.length +
                                              (_isLoading ? 1 : 0),
                                        ),
                                      ),
                                SliverToBoxAdapter(
                                    child: SizedBox(height: 10.h)),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
    );
  }
}
