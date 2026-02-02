import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../presentation/home_screen/home_screen.dart';
import '../presentation/order_history_screen/order_history_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/search_screen/search_screen.dart';
import '../presentation/shopping_cart_screen/shopping_cart_screen.dart';
import './custom_bottom_bar.dart';
import './floating_ai_chatbox.dart';

/// Global layout wrapper that maintains persistent bottom navigation across main screens
/// Uses IndexedStack to preserve state and prevent unnecessary rebuilds
class MainLayoutWrapper extends StatefulWidget {
  final int initialIndex;

  const MainLayoutWrapper({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainLayoutWrapper> createState() => MainLayoutWrapperState();

  /// Static method to access the current state from anywhere in the widget tree
  static MainLayoutWrapperState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainLayoutWrapperState>();
  }
}

class MainLayoutWrapperState extends State<MainLayoutWrapper> {
  late int _currentIndex;

  // Main navigation screens - state is preserved with IndexedStack
  final List<Widget> _screens = [
    HomeScreen(),
    SearchScreen(),
    ShoppingCartScreen(),
    OrderHistoryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    // Haptic feedback for tab switch
    HapticFeedback.lightImpact();

    // Update the current index to show the selected screen
    setState(() {
      _currentIndex = index;
    });
  }

  /// Public method to update the current tab index from child screens
  void updateTabIndex(int index) {
    if (index != _currentIndex && index >= 0 && index < _screens.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  /// Get the current active tab index
  int get currentIndex => _currentIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          const FloatingAIChatbox(),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        variant: BottomBarVariant.primary,
      ),
    );
  }
}
