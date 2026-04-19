import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/cart_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/store_rating_dialog.dart';
import '../../services/database_service.dart';
import '../../services/order_service.dart';
import '../../widgets/main_layout_wrapper.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/order_card_widget.dart';
import './widgets/search_bar_widget.dart';
import '../../widgets/shimmer_placeholder.dart';
import '../../l10n/generated/app_localizations.dart';

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
  bool _isLoadingMore = false;
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
        final normalized = orders.map((o) {
          final m = Map<String, dynamic>.from(o);
          m['orderId'] = o['order_number'] ?? o['id'] ?? '';
          m['orderDate'] = o['created_at'] ?? DateTime.now().toIso8601String();
          m['totalAmount'] = (o['total'] as num?)?.toDouble() ?? 0.0;
          m['items'] = o['order_items'] ?? [];
          m['storeName'] =
              (o['stores'] as Map<String, dynamic>?)?['name'] ?? AppLocalizations.of(context)!.unknownStore;
          m['storeId'] = o['store_id'] as String? ?? '';
          m['itemCount'] = (o['order_items'] as List?)?.length ?? 0;
          return m;
        }).toList();

        _allOrders
          ..clear()
          ..addAll(normalized);

        setState(() => _isLoading = false);
        _applyFilters();
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
    setState(() => _isSearching = _searchController.text.isNotEmpty);
    _applyFilters();
  }

  void _loadMoreOrders() {
    if (_isLoadingMore || _isLoading) return;
    setState(() => _isLoadingMore = true);
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _currentPage++;
        _isLoadingMore = false;
      });
    });
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allOrders);

    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((order) {
        final orderId = (order['orderId'] as String? ?? '').toLowerCase();
        final orderDate = DateTime.tryParse(
                order['orderDate'] as String? ?? '') ??
            DateTime.now();
        final dateString =
            '${orderDate.day}/${orderDate.month}/${orderDate.year}';

        bool matchesOrder =
            orderId.contains(searchTerm) || dateString.contains(searchTerm);

        if (!matchesOrder) {
          final items = (order['items'] as List<dynamic>?) ?? [];
          matchesOrder = items.any((raw) {
            final item = raw as Map<String, dynamic>;
            // FIX: check both 'name' and 'product_name' — real Supabase uses product_name
            final name = (item['name'] as String?
                    ?? item['product_name'] as String?
                    ?? '')
                .toLowerCase();
            return name.contains(searchTerm);
          });
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
        final orderDate = DateTime.tryParse(
                order['orderDate'] as String? ?? '') ??
            DateTime.now();
        return orderDate
                .isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
            orderDate.isBefore(dateRange.end.add(const Duration(days: 1)));
      }).toList();
    }

    if (_currentFilters['priceRange'] != null) {
      final priceRange = _currentFilters['priceRange'] as RangeValues;
      filtered = filtered.where((order) {
        final totalAmount =
            (order['totalAmount'] as num?)?.toDouble() ?? 0.0;
        return totalAmount >= priceRange.start &&
            totalAmount <= priceRange.end;
      }).toList();
    }

    if (_currentFilters['sortBy'] != null) {
      final sortBy = _currentFilters['sortBy'] as String;
      switch (sortBy) {
        case 'Recent First':
          filtered.sort((a, b) =>
              DateTime.parse(b['orderDate'] as String)
                  .compareTo(DateTime.parse(a['orderDate'] as String)));
          break;
        case 'Oldest First':
          filtered.sort((a, b) =>
              DateTime.parse(a['orderDate'] as String)
                  .compareTo(DateTime.parse(b['orderDate'] as String)));
          break;
        case 'Price: High to Low':
          filtered.sort((a, b) =>
              ((b['totalAmount'] as num?)?.toDouble() ?? 0.0)
                  .compareTo((a['totalAmount'] as num?)?.toDouble() ?? 0.0));
          break;
        case 'Price: Low to High':
          filtered.sort((a, b) =>
              ((a['totalAmount'] as num?)?.toDouble() ?? 0.0)
                  .compareTo((b['totalAmount'] as num?)?.toDouble() ?? 0.0));
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

  // FIX: actually add all items to cart via CartNotifier
  void _handleReorderAll(Map<String, dynamic> order) {
    HapticFeedback.lightImpact();
    final items = (order['items'] as List<dynamic>?) ?? [];

    int added = 0;
    for (final raw in items) {
      final item = raw as Map<String, dynamic>;
      final productId = item['product_id'] as String?;
      final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
      if (productId != null && productId.isNotEmpty) {
        ref
            .read(cartNotifierProvider.notifier)
            .addToCart(productId: productId, quantity: quantity);
        added++;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$added item${added != 1 ? 's' : ''} added to cart', maxLines: 1, overflow: TextOverflow.ellipsis),
      backgroundColor: added > 0 ? Colors.green.shade600 : Colors.orange,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));
  }

  // FIX: actually add single item to cart via CartNotifier
  void _handleAddToCart(Map<String, dynamic> item) {
    HapticFeedback.lightImpact();
    final productId = item['product_id'] as String?;
    // FIX: use product_name (real Supabase column) not name (mock field)
    final name = item['product_name'] as String?
        ?? item['name'] as String?
        ?? AppLocalizations.of(context)!.item;

    if (productId == null || productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.cannotAddItemProductNotFound, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.red,
      ));
      return;
    }

    ref
        .read(cartNotifierProvider.notifier)
        .addToCart(productId: productId, quantity: 1);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$name added to cart', maxLines: 1, overflow: TextOverflow.ellipsis),
      backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));
  }

  void _handleDownloadReceipt() {
    HapticFeedback.lightImpact();
    Fluttertoast.showToast(
      msg: AppLocalizations.of(context)!.receiptDownloadedSuccessfully,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handleRateOrder(Map<String, dynamic> order) {
    HapticFeedback.lightImpact();
    final status = order['status'] as String? ?? '';
    final storeId = order['storeId'] as String? ?? '';
    final orderId = order['id'] as String? ?? '';
    final storeName = order['storeName'] as String?;

    if (status != 'delivered') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.youCanOnlyRateDeliveredOrders, maxLines: 1, overflow: TextOverflow.ellipsis),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (storeId.isEmpty || orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.cannotIdentifyStoreForThisOrder, maxLines: 1, overflow: TextOverflow.ellipsis)),
      );
      return;
    }

    StoreRatingDialog.show(context,
        orderId: orderId, storeId: storeId, storeName: storeName);
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
      msg: AppLocalizations.of(context)!.orderDetailsShared,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handleVoiceSearch() {
    HapticFeedback.lightImpact();
    Fluttertoast.showToast(
      msg: AppLocalizations.of(context)!.voiceSearchActivated,
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

  Future<void> _refreshOrders() async {
    HapticFeedback.lightImpact();
    await _loadOrders();
    if (!mounted) return;
    Fluttertoast.showToast(
      msg: AppLocalizations.of(context)!.ordersRefreshed,
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.itemsAddedToCart, maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.green,
          ),
        );
        _goToTab(2);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reorder: $e', maxLines: 1, overflow: TextOverflow.ellipsis),
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
      // FIX: resize when keyboard opens — prevents 344px overflow on empty state
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        iconTheme: IconThemeData(color: cs.onSurface),
        actionsIconTheme: IconThemeData(color: cs.onSurface),
        elevation: 0,
        leading: _shouldShowBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          AppLocalizations.of(context)!.orderHistory,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const ShimmerFullPage()
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 15.w, color: cs.error),
                      SizedBox(height: 2.h),
                      Text(AppLocalizations.of(context)!.errorLoadingOrders,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 1.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      SizedBox(height: 3.h),
                      ElevatedButton.icon(
                        onPressed: _loadOrders,
                        icon: const Icon(Icons.refresh),
                        label: Text(AppLocalizations.of(context)!.retry, maxLines: 1, overflow: TextOverflow.ellipsis),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 1.5.h),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshOrders,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // Search bar always visible
                      SliverToBoxAdapter(
                        child: SearchBarWidget(
                          controller: _searchController,
                          hintText: AppLocalizations.of(context)!.searchOrdersProductsOrDates,
                          onChanged: (value) => _applyFilters(),
                          onVoiceSearch: _handleVoiceSearch,
                          onBarcodeSearch: _handleBarcodeSearch,
                          onClear: () => _applyFilters(),
                        ),
                      ),

                      if (_isSearching || _currentFilters.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: Text(
                              '${_filteredOrders.length} order${_filteredOrders.length != 1 ? 's' : ''} found',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: cs.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),

                      if (_filteredOrders.isEmpty)
                        SliverToBoxAdapter(
                          child: EmptyStateWidget(
                              onExploreProducts: _handleExploreProducts),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == _filteredOrders.length) {
                                return _isLoadingMore
                                    ? Container(
                                        padding: EdgeInsets.all(4.w),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                              color: cs.primary),
                                        ),
                                      )
                                    : const SizedBox.shrink();
                              }

                              final order = _filteredOrders[index];
                              return OrderCardWidget(
                                order: order,
                                onReorderAll: () => _handleReorderAll(order),
                                onAddToCart: _handleAddToCart,
                                onDownloadReceipt: _handleDownloadReceipt,
                                onRateOrder: () => _handleRateOrder(order),
                                onReportIssue: _handleReportIssue,
                                onShareOrder: _handleShareOrder,
                              );
                            },
                            childCount: _filteredOrders.length +
                                (_isLoadingMore ? 1 : 0),
                          ),
                        ),

                      SliverToBoxAdapter(child: SizedBox(height: 10.h)),
                    ],
                  ),
                ),
    );
  }
}