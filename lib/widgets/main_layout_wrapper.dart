import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../presentation/ai_chat_assistant_screen/ai_chat_assistant_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/search_screen/search_screen.dart';
import '../presentation/stores_screen/stores_screen.dart';
import '../presentation/global_admin_controls_overlay_screen/global_admin_controls_overlay_screen.dart';
import './custom_bottom_bar.dart';

/// Global layout wrapper that maintains persistent bottom navigation across main screens.
/// Uses IndexedStack to preserve state and prevent unnecessary rebuilds.
///
/// UPDATED:
/// - Removed FloatingAIChatbox (AI is only accessible via AI Mate tab)
/// - Replaced Cart at index 2 with AI Chat Assistant screen
/// - Tab order: Home(0), Search(1), AI Mate(2), Stores(3), Profile(4)
class MainLayoutWrapper extends StatefulWidget {
  final int initialIndex;

  const MainLayoutWrapper({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainLayoutWrapper> createState() => MainLayoutWrapperState();

  /// Access the current state from anywhere in the widget tree.
  static MainLayoutWrapperState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainLayoutWrapperState>();
  }
}

class MainLayoutWrapperState extends State<MainLayoutWrapper> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    HomeScreen(),               // Index 0 - Home
    SearchScreen(),             // Index 1 - Search
    AIChatAssistantScreen(),    // Index 2 - AI Mate (replaces Cart)
    StoresScreen(),             // Index 3 - Stores
    ProfileScreen(),            // Index 4 - Profile
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    HapticFeedback.lightImpact();
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  /// Public method to update the current tab index from child screens.
  void updateTabIndex(int index) {
    if (index < 0 || index >= _screens.length) return;
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  int get currentIndex => _currentIndex;

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        variant: BottomBarVariant.primary,
      ),
    );

    // Global overlay wrapper: admin-only FAB/edit mode hooks live here.
    return GlobalAdminControlsOverlayScreen(
      contentType: 'global',
      child: content,
    );
  }
}