import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/admin_action_button.dart';
import './widgets/marketplace_ad_box_widget.dart';
import './widgets/marketplace_bottom_nav_widget.dart';
import './widgets/marketplace_category_icons_widget.dart';
import './widgets/marketplace_listings_feed_widget.dart';
import './widgets/marketplace_search_bar_widget.dart';
import './widgets/marketplace_top_bar_widget.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  String _selectedLocation = 'Lebanon';
  String _searchQuery = '';
  String? _selectedCategory;
  int _currentNavIndex = 0;

  // Demo listings data
  final List<Map<String, dynamic>> _demoListings = [
    {
      'id': 'demo-1',
      'title': '2020 Toyota Camry - Excellent Condition',
      'price': 18500.0,
      'category': 'vehicles',
      'image': 'https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb',
      'location': 'Beirut',
      'postedDate': '2 days ago',
      'isFavorite': false,
    },
    {
      'id': 'demo-2',
      'title': 'Modern 2BR Apartment in Achrafieh',
      'price': 250000.0,
      'category': 'properties',
      'image': 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00',
      'location': 'Achrafieh',
      'postedDate': '1 week ago',
      'isFavorite': false,
    },
    {
      'id': 'demo-3',
      'title': 'iPhone 14 Pro Max 256GB',
      'price': 1200.0,
      'category': 'mobiles',
      'image': 'https://images.unsplash.com/photo-1678652197950-91e93a944f8d',
      'location': 'Jounieh',
      'postedDate': '3 days ago',
      'isFavorite': false,
    },
    {
      'id': 'demo-4',
      'title': 'Samsung 65" 4K Smart TV',
      'price': 850.0,
      'category': 'electronics',
      'image': 'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1',
      'location': 'Tripoli',
      'postedDate': '5 days ago',
      'isFavorite': false,
    },
    {
      'id': 'demo-5',
      'title': 'Modern L-Shaped Sofa Set',
      'price': 650.0,
      'category': 'furniture',
      'image': 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc',
      'location': 'Saida',
      'postedDate': '1 day ago',
      'isFavorite': false,
    },
    {
      'id': 'demo-6',
      'title': 'MacBook Pro 16" M2 Max',
      'price': 2800.0,
      'category': 'electronics',
      'image': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8',
      'location': 'Beirut',
      'postedDate': '4 days ago',
      'isFavorite': false,
    },
  ];

  List<Map<String, dynamic>> get _filteredListings {
    var listings = _demoListings;

    if (_searchQuery.isNotEmpty) {
      listings = listings.where((listing) {
        return listing['title'].toString().toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
      }).toList();
    }

    if (_selectedCategory != null) {
      listings = listings.where((listing) {
        return listing['category'] == _selectedCategory;
      }).toList();
    }

    return listings;
  }

  void _onLocationChanged(String location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _onNavIndexChanged(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.chatListScreen);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.createListingScreen);
        break;
      case 3:
        Navigator.pushNamed(context, '/my-ads-screen');
        break;
      case 4:
        Navigator.pushNamed(context, '/marketplace-account-screen');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            MarketplaceTopBarWidget(
              selectedLocation: _selectedLocation,
              onLocationChanged: _onLocationChanged,
            ),
            MarketplaceSearchBarWidget(onSearchChanged: _onSearchChanged),
            const MarketplaceAdBoxWidget(),
            // Admin Controls Section
            provider.Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.isAdmin) {
                  return Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    color: Colors.orange.withValues(alpha: 0.1),
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings,
                            color: Colors.orange, size: 20),
                        SizedBox(width: 2.w),
                        Text(
                          'Admin Mode',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const Spacer(),
                        AdminActionButton(
                          icon: Icons.add,
                          label: 'Create',
                          onPressed: () {
                            Navigator.pushNamed(
                                context, AppRoutes.createListingScreen);
                          },
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All categories',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/all-categories-screen');
                    },
                    child: Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            MarketplaceCategoryIconsWidget(
              selectedCategory: _selectedCategory,
              onCategorySelected: _onCategorySelected,
            ),
            Expanded(
              child: MarketplaceListingsFeedWidget(listings: _filteredListings),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MarketplaceBottomNavWidget(
        currentIndex: _currentNavIndex,
        onIndexChanged: _onNavIndexChanged,
      ),
    );
  }
}
