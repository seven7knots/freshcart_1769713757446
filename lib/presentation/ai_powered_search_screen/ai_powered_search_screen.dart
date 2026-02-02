import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'dart:convert';

import '../../services/ai_service.dart';
import '../../services/openai_service.dart';
import '../../services/analytics_service.dart';
import './widgets/ai_search_bar_widget.dart';
import './widgets/category_tabs_widget.dart';
import './widgets/interpreted_filters_widget.dart';
import './widgets/smart_suggestions_widget.dart';
import './widgets/unified_results_widget.dart';

class AIPoweredSearchScreen extends ConsumerStatefulWidget {
  const AIPoweredSearchScreen({super.key});

  @override
  ConsumerState<AIPoweredSearchScreen> createState() =>
      _AIPoweredSearchScreenState();
}

class _AIPoweredSearchScreenState extends ConsumerState<AIPoweredSearchScreen> {
  final AIService _aiService = AIService();
  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;
  bool _isProcessingQuery = false;
  String _selectedCategory = 'all';
  Map<String, dynamic>? _interpretedFilters;
  List<Map<String, dynamic>> _searchResults = [];
  String? _errorMessage;

  // Filter parameters
  double? _minPrice;
  double? _maxPrice;
  bool _openNow = false;
  String _sortBy = 'relevance';

  final List<String> _categories = [
    'all',
    'groceries',
    'restaurants',
    'pharmacy',
    'retail',
    'services',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // Track AI search screen view
    AnalyticsService.logScreenView(screenName: 'ai_powered_search_screen');
  }

  Future<void> _performAISearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _isProcessingQuery = true;
      _errorMessage = null;
    });

    try {
      final results = await _aiService.unifiedMarketplaceSearch(
        query: query,
        category: _selectedCategory != 'all' ? _selectedCategory : null,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        openNow: _openNow,
        sortBy: _sortBy,
      );

      setState(() {
        _searchResults = results['results'] ?? [];
        _interpretedFilters = results['filters'];
        _isProcessingQuery = false;
        _isSearching = false;
      });

      // Track AI smart search usage
      await AnalyticsService.logAISmartSearchUsed(
        query: query,
        resultsCount: _searchResults.length,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Search failed: $e';
        _isProcessingQuery = false;
        _isSearching = false;
      });
    }
  }

  Future<Map<String, dynamic>> _interpretQuery(String query) async {
    try {
      final prompt = '''
Interpret this search query and extract filters:
"$query"

Return JSON with:
{
  "query": "cleaned search terms",
  "category": "groceries|restaurants|pharmacy|retail|services|null",
  "min_price": number or null,
  "max_price": number or null,
  "open_now": boolean,
  "sort_by": "relevance|price_low|price_high"
}

Examples:
- "cheap Italian food open now" → {"query": "Italian food", "category": "restaurants", "max_price": 20, "open_now": true}
- "mechanics near me under \$100" → {"query": "mechanics", "category": "services", "max_price": 100}

Respond with JSON only.''';

      final messages = [
        Message(
          role: 'system',
          content:
              'You are a search query interpreter. Respond only with valid JSON.',
        ),
        Message(role: 'user', content: prompt),
      ];

      final completion =
          await OpenAIClient(OpenAIService().dio).createChatCompletion(
        messages: messages,
        model: 'gpt-5-mini',
        reasoningEffort: 'minimal',
        options: {'max_completion_tokens': 200},
      );

      final jsonString = completion.text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return Map<String, dynamic>.from(
        jsonDecode(jsonString),
      );
    } catch (e) {
      debugPrint('Query interpretation error: $e');
      return {'query': query};
    }
  }

  void _updateFilters({
    double? minPrice,
    double? maxPrice,
    bool? openNow,
    String? sortBy,
  }) {
    setState(() {
      if (minPrice != null) _minPrice = minPrice;
      if (maxPrice != null) _maxPrice = maxPrice;
      if (openNow != null) _openNow = openNow;
      if (sortBy != null) _sortBy = sortBy;
    });

    if (_searchController.text.isNotEmpty) {
      _performAISearch(_searchController.text);
    }
  }

  void _clearFilters() {
    setState(() {
      _minPrice = null;
      _maxPrice = null;
      _openNow = false;
      _sortBy = 'relevance';
      _interpretedFilters = null;
    });
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
          'AI-Powered Search',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: (_minPrice != null || _maxPrice != null || _openNow)
                  ? const Color(0xFFE50914)
                  : Colors.white70,
            ),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          AISearchBarWidget(
            controller: _searchController,
            onSearch: _performAISearch,
            isProcessing: _isProcessingQuery,
          ),
          if (_interpretedFilters != null)
            InterpretedFiltersWidget(
              filters: _interpretedFilters!,
              onClear: _clearFilters,
            ),
          CategoryTabsWidget(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onCategorySelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
              if (_searchController.text.isNotEmpty) {
                _performAISearch(_searchController.text);
              }
            },
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFFE50914),
            ),
            SizedBox(height: 2.h),
            Text(
              _isProcessingQuery
                  ? 'Processing your query...'
                  : 'Searching marketplace...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 15.w,
            ),
            SizedBox(height: 2.h),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: () {
                if (_searchController.text.isNotEmpty) {
                  _performAISearch(_searchController.text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isEmpty) {
      return SmartSuggestionsWidget(
        onSuggestionTap: (suggestion) {
          _searchController.text = suggestion;
          _performAISearch(suggestion);
        },
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: Colors.white30,
              size: 15.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'No results found',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Try different keywords or filters',
              style: TextStyle(
                color: Colors.white.withAlpha(128),
                fontSize: 11.sp,
              ),
            ),
          ],
        ),
      );
    }

    return UnifiedResultsWidget(
      results: _searchResults,
      selectedCategory: _selectedCategory,
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(5.w)),
      ),
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _clearFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              SwitchListTile(
                title: const Text(
                  'Open Now',
                  style: TextStyle(color: Colors.white),
                ),
                value: _openNow,
                activeThumbColor: const Color(0xFFE50914),
                onChanged: (value) {
                  setModalState(() {
                    _openNow = value;
                  });
                },
              ),
              SizedBox(height: 2.h),
              Text(
                'Price Range',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Min',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixText: '\$',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(2.w),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setModalState(() {
                          _minPrice = double.tryParse(value);
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Max',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixText: '\$',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(2.w),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setModalState(() {
                          _maxPrice = double.tryParse(value);
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                'Sort By',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Wrap(
                spacing: 2.w,
                children: [
                  ChoiceChip(
                    label: const Text('Relevance'),
                    selected: _sortBy == 'relevance',
                    onSelected: (selected) {
                      setModalState(() {
                        _sortBy = 'relevance';
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Price: Low to High'),
                    selected: _sortBy == 'price_low',
                    onSelected: (selected) {
                      setModalState(() {
                        _sortBy = 'price_low';
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Price: High to Low'),
                    selected: _sortBy == 'price_high',
                    onSelected: (selected) {
                      setModalState(() {
                        _sortBy = 'price_high';
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _updateFilters(
                      minPrice: _minPrice,
                      maxPrice: _maxPrice,
                      openNow: _openNow,
                      sortBy: _sortBy,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914),
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2.w),
                    ),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
