import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/ai_service.dart';
import '../../services/claude_service.dart';
import '../../services/analytics_service.dart';
import './widgets/ai_search_bar_widget.dart';
import './widgets/category_tabs_widget.dart';
import './widgets/interpreted_filters_widget.dart';
import './widgets/smart_suggestions_widget.dart';
import './widgets/unified_results_widget.dart';
import '../../l10n/generated/app_localizations.dart';

class AIPoweredSearchScreen extends ConsumerStatefulWidget {
  const AIPoweredSearchScreen({super.key});

  @override
  ConsumerState<AIPoweredSearchScreen> createState() =>
      _AIPoweredSearchScreenState();
}

class _AIPoweredSearchScreenState extends ConsumerState<AIPoweredSearchScreen>
    with SingleTickerProviderStateMixin {
  final AIService _aiService = AIService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  bool _isSearching = false;
  bool _isProcessingQuery = false;
  bool _isInterpretingQuery = false;
  String _selectedCategory = 'all';
  Map<String, dynamic>? _interpretedFilters;
  List<Map<String, dynamic>> _searchResults = [];
  String? _errorMessage;
  String? _aiInterpretation;
  List<String> _recentSearches = [];

  // Filter parameters
  double? _minPrice;
  double? _maxPrice;
  bool _openNow = false;
  String _sortBy = 'relevance';

  // Animation
  late AnimationController _pulseController;

  final List<String> _categories = [
    'all',
    'groceries',
    'restaurants',
    'pharmacy',
    'retail',
    'services',
  ];

  static const String _recentSearchesKey = 'ai_recent_searches';
  static const int _maxRecentSearches = 10;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _loadRecentSearches();
    AnalyticsService.logScreenView(screenName: 'ai_powered_search_screen');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Recent Searches
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList(_recentSearchesKey) ?? [];
      if (mounted) {
        setState(() => _recentSearches = searches);
      }
    } catch (e) {
      debugPrint('Failed to load recent searches: $e');
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    try {
      _recentSearches.remove(query); // Remove duplicate if exists
      _recentSearches.insert(0, query);
      if (_recentSearches.length > _maxRecentSearches) {
        _recentSearches = _recentSearches.sublist(0, _maxRecentSearches);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesKey, _recentSearches);
    } catch (e) {
      debugPrint('Failed to save recent search: $e');
    }
  }

  Future<void> _clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSearchesKey);
      if (mounted) {
        setState(() => _recentSearches = []);
      }
    } catch (e) {
      debugPrint('Failed to clear recent searches: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // AI Query Interpretation (extracts filters from natural language)
  // ─────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _interpretQuery(String query) async {
    try {
      setState(() => _isInterpretingQuery = true);

      final prompt = '''
Interpret this search query for a delivery/marketplace app in Lebanon and extract filters:
"$query"

Return JSON only:
{
  "cleaned_query": "simplified search terms without filter words",
  "category": AppLocalizations.of(context)!.groceriesRestaurantsPharmacyRetailServicesNull,
  "min_price": number or null,
  "max_price": number or null,
  "open_now": true/false,
  "sort_by": "relevance|price_low|price_high|rating",
  "interpretation": "one-line human-readable summary of what you understood"
}

Examples:
- "cheap shawarma open now" → {"cleaned_query": "shawarma", "category": "restaurants", "max_price": 10, "open_now": true, "sort_by": "price_low", "interpretation": "Affordable shawarma from restaurants open now"}
- "fresh fruits under 5 dollars" → {"cleaned_query": "fresh fruits", "category": "groceries", "max_price": 5, "open_now": false, "sort_by": "relevance", "interpretation": "Fresh fruits under \$5 from grocery stores"}
- "best rated pharmacy" → {"cleaned_query": "pharmacy", "category": "pharmacy", "open_now": false, "sort_by": "rating", "interpretation": "Top-rated pharmacies"}

Respond with JSON only, no markdown fences.''';

      final messages = [
        Message(
          role: 'system',
          content:
              'You are a search query interpreter for a Lebanese delivery app. '
              'Extract user intent into structured filters. '
              'Respond with valid JSON only — no markdown fences, no explanation.',
        ),
        Message(role: 'user', content: prompt),
      ];

      final completion = await ClaudeClient().createChatCompletion(
        messages: messages,
        model: 'claude-haiku-4-5-20251001',
        options: {'max_output_tokens': 500},
      );

      // Strip any markdown fences the AI might add
      String jsonString = completion.text
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      // Try to extract JSON object if there's extra text
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(jsonString);
      if (jsonMatch != null) {
        jsonString = jsonMatch.group(0)!;
      }

      final parsed = Map<String, dynamic>.from(jsonDecode(jsonString));

      if (mounted) {
        setState(() => _isInterpretingQuery = false);
      }
      return parsed;
    } catch (e) {
      debugPrint('Query interpretation error: $e');
      if (mounted) {
        setState(() => _isInterpretingQuery = false);
      }
      return {'cleaned_query': query, 'interpretation': null};
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Search with AI interpretation pipeline
  // ─────────────────────────────────────────────────────────────────────

  void _onSearchSubmitted(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) return;
    _performSmartSearch(query);
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _interpretedFilters = null;
        _aiInterpretation = null;
        _errorMessage = null;
      });
      return;
    }
    // Debounce: wait 800ms after user stops typing before searching
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _performSmartSearch(query);
    });
  }

  Future<void> _performSmartSearch(String query) async {
    if (query.trim().isEmpty) return;

    HapticFeedback.lightImpact();

    setState(() {
      _isSearching = true;
      _isProcessingQuery = true;
      _errorMessage = null;
      _aiInterpretation = null;
    });

    // Save to recent searches
    await _saveRecentSearch(query);

    try {
      // Step 1: AI interprets the natural language query
      final interpretation = await _interpretQuery(query);

      final cleanedQuery =
          (interpretation['cleaned_query'] as String?) ?? query;
      final interpretedCategory =
          interpretation['category'] as String?;
      final interpretedMinPrice =
          (interpretation['min_price'] as num?)?.toDouble();
      final interpretedMaxPrice =
          (interpretation['max_price'] as num?)?.toDouble();
      final interpretedOpenNow =
          (interpretation['open_now'] as bool?) ?? false;
      final interpretedSortBy =
          (interpretation['sort_by'] as String?) ?? 'relevance';
      final humanInterpretation =
          interpretation['interpretation'] as String?;

      if (mounted) {
        setState(() {
          _aiInterpretation = humanInterpretation;
          _interpretedFilters = interpretation;
          // Apply interpreted filters (user manual filters take priority)
          if (_minPrice == null && interpretedMinPrice != null) {
            _minPrice = interpretedMinPrice;
          }
          if (_maxPrice == null && interpretedMaxPrice != null) {
            _maxPrice = interpretedMaxPrice;
          }
          if (interpretedCategory != null &&
              _selectedCategory == 'all' &&
              _categories.contains(interpretedCategory)) {
            _selectedCategory = interpretedCategory;
          }
        });
      }

      // Step 2: Perform the actual marketplace search
      final results = await _aiService.unifiedMarketplaceSearch(
        query: cleanedQuery,
        category: _selectedCategory != 'all' ? _selectedCategory : null,
        minPrice: _minPrice ?? interpretedMinPrice,
        maxPrice: _maxPrice ?? interpretedMaxPrice,
        openNow: _openNow || interpretedOpenNow,
        sortBy: _sortBy != 'relevance' ? _sortBy : interpretedSortBy,
      );

      if (mounted) {
        setState(() {
          _searchResults = results['results'] ?? [];
          _isProcessingQuery = false;
          _isSearching = false;
        });
      }

      // Track usage
      await AnalyticsService.logAISmartSearchUsed(
        query: query,
        resultsCount: _searchResults.length,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.searchFailedPleaseTryAgain;
          _isProcessingQuery = false;
          _isSearching = false;
        });
      }
      debugPrint('AI Search error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Filter management
  // ─────────────────────────────────────────────────────────────────────

  void _updateFilters({
    double? minPrice,
    double? maxPrice,
    bool? openNow,
    String? sortBy,
  }) {
    setState(() {
      _minPrice = minPrice;
      _maxPrice = maxPrice;
      if (openNow != null) _openNow = openNow;
      if (sortBy != null) _sortBy = sortBy;
    });

    if (_searchController.text.isNotEmpty) {
      _performSmartSearch(_searchController.text);
    }
  }

  void _clearFilters() {
    setState(() {
      _minPrice = null;
      _maxPrice = null;
      _openNow = false;
      _sortBy = 'relevance';
      _interpretedFilters = null;
      _aiInterpretation = null;
      _selectedCategory = 'all';
    });
  }

  // ─────────────────────────────────────────────────────────────────────
  // UI Build
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            SizedBox(width: 2.w),
            Flexible(child: Text(
              AppLocalizations.of(context)!.aiSearch,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: (_minPrice != null || _maxPrice != null || _openNow)
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          AISearchBarWidget(
            controller: _searchController,
            onSearch: _onSearchSubmitted,
            isProcessing: _isProcessingQuery,
          ),

          // AI Interpretation banner
          if (_aiInterpretation != null && !_isSearching)
            _buildInterpretationBanner(theme),

          if (_interpretedFilters != null && !_isSearching)
            InterpretedFiltersWidget(
              filters: _interpretedFilters!,
              onClear: _clearFilters,
            ),

          CategoryTabsWidget(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onCategorySelected: (category) {
              setState(() => _selectedCategory = category);
              if (_searchController.text.isNotEmpty) {
                _performSmartSearch(_searchController.text);
              }
            },
          ),

          Expanded(child: _buildContent(theme)),
        ],
      ),
    );
  }

  Widget _buildInterpretationBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              _aiInterpretation!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _aiInterpretation = null),
            child: Icon(
              Icons.close,
              size: 16,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    // Loading state with animated indicator
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.15),
                  child: Icon(
                    _isInterpretingQuery
                        ? Icons.psychology
                        : Icons.search,
                    size: 12.w,
                    color: theme.colorScheme.primary.withValues(
                      alpha: 0.5 + (_pulseController.value * 0.5),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 2.h),
            Text(
              _isInterpretingQuery
                  ? AppLocalizations.of(context)!.understandingYourQuery
                  : AppLocalizations.of(context)!.searchingMarketplace,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      );
    }

    // Error state
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
              size: 15.w,
            ),
            SizedBox(height: 2.h),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 2.h),
            ElevatedButton.icon(
              onPressed: () {
                if (_searchController.text.isNotEmpty) {
                  _performSmartSearch(_searchController.text);
                }
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(AppLocalizations.of(context)!.retry, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
    }

    // Empty state — show recent searches + suggestions
    if (_searchResults.isEmpty && _searchController.text.isEmpty) {
      return _buildEmptyState(theme);
    }

    // No results state
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              size: 15.w,
            ),
            SizedBox(height: 2.h),
            Text(
              AppLocalizations.of(context)!.noResultsFound,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 1.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Text(
                AppLocalizations.of(context)!.tryRephrasingYourSearchOrAdjusting,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            SizedBox(height: 3.h),
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_list_off, size: 18),
              label: Text(AppLocalizations.of(context)!.clearFilters, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
    }

    // Results
    return UnifiedResultsWidget(
      results: _searchResults,
      selectedCategory: _selectedCategory,
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches
          if (_recentSearches.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(
                  AppLocalizations.of(context)!.recentSearches,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                GestureDetector(
                  onTap: _clearRecentSearches,
                  child: Text(
                    AppLocalizations.of(context)!.clearAll,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: _recentSearches.map((search) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = search;
                    _performSmartSearch(search);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 0.8.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history,
                          size: 14,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 1.5.w),
                        Flexible(child: Text(
                          search,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 3.h),
          ],

          // AI search tips
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: 2.w),
                    Flexible(child: Text(
                      AppLocalizations.of(context)!.smartSearchTips,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                SizedBox(height: 1.5.h),
                _buildTipRow(theme, '"cheap shawarma open now"',
                    'Finds affordable shawarma from open restaurants'),
                SizedBox(height: 1.h),
                _buildTipRow(theme, '"fresh fruits under \$5"',
                    'Auto-applies price filter to grocery results'),
                SizedBox(height: 1.h),
                _buildTipRow(theme, '"headache medicine"',
                    'Searches pharmacies automatically'),
                SizedBox(height: 1.h),
                _buildTipRow(theme, '"best rated bakery"',
                    'Sorts by rating, filters to bakeries'),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Smart suggestions
          SmartSuggestionsWidget(
            onSuggestionTap: (suggestion) {
              _searchController.text = suggestion;
              _performSmartSearch(suggestion);
            },
          ),

          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildTipRow(ThemeData theme, String example, String explanation) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.arrow_right,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: 1.w),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: example,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                TextSpan(
                  text: ' — $explanation',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Filter Bottom Sheet
  // ─────────────────────────────────────────────────────────────────────

  void _showFilterSheet() {
    final theme = Theme.of(context);

    // Local copies for the modal
    double? localMinPrice = _minPrice;
    double? localMaxPrice = _maxPrice;
    bool localOpenNow = _openNow;
    String localSortBy = _sortBy;

    final minController = TextEditingController(
      text: _minPrice?.toStringAsFixed(0) ?? '',
    );
    final maxController = TextEditingController(
      text: _maxPrice?.toStringAsFixed(0) ?? '',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(5.w)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 2.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(
                        AppLocalizations.of(context)!.filters,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            localMinPrice = null;
                            localMaxPrice = null;
                            localOpenNow = false;
                            localSortBy = 'relevance';
                            minController.clear();
                            maxController.clear();
                          });
                        },
                        child: Text(
                          AppLocalizations.of(context)!.clearAll,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),

                  SizedBox(height: 2.h),

                  // Open Now toggle
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SwitchListTile(
                      title: Text(AppLocalizations.of(context)!.openNow,
                          style: theme.textTheme.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                      value: localOpenNow,
                      activeColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
                        setModalState(() => localOpenNow = value);
                      },
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // Price Range
                  Text(
                    AppLocalizations.of(context)!.priceRange,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minController,
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.min,
                            labelStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                            prefixText: '\$ ',
                            prefixStyle: theme.textTheme.bodyLarge,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 1.5.h,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setModalState(() {
                              localMinPrice = double.tryParse(value);
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        child: Text('—',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.grey,
                            ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Expanded(
                        child: TextField(
                          controller: maxController,
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.max,
                            labelStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                            prefixText: '\$ ',
                            prefixStyle: theme.textTheme.bodyLarge,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 1.5.h,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setModalState(() {
                              localMaxPrice = double.tryParse(value);
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 2.h),

                  // Sort By
                  Text(
                    AppLocalizations.of(context)!.sortBy,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 1.h),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: [
                      _buildSortChip(theme, AppLocalizations.of(context)!.relevance, 'relevance',
                          localSortBy, (v) {
                        setModalState(() => localSortBy = v);
                      }),
                      _buildSortChip(theme, AppLocalizations.of(context)!.price4, 'price_low',
                          localSortBy, (v) {
                        setModalState(() => localSortBy = v);
                      }),
                      _buildSortChip(theme, AppLocalizations.of(context)!.price5, 'price_high',
                          localSortBy, (v) {
                        setModalState(() => localSortBy = v);
                      }),
                      _buildSortChip(theme, AppLocalizations.of(context)!.rating, 'rating',
                          localSortBy, (v) {
                        setModalState(() => localSortBy = v);
                      }),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _updateFilters(
                          minPrice: localMinPrice,
                          maxPrice: localMaxPrice,
                          openNow: localOpenNow,
                          sortBy: localSortBy,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.applyFilters,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),

                  SizedBox(height: 1.h),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortChip(
    ThemeData theme,
    String label,
    String value,
    String currentValue,
    Function(String) onSelected,
  ) {
    final isSelected = currentValue == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onSelected(value);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}