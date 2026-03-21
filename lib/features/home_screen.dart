import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'dashboard/screens/dashboard_screen.dart';
import 'crop_analysis/screens/crop_analysis_screen.dart';
import 'market/screens/market_prices_screen.dart';
import 'community/screens/community_screen.dart';
import 'profile/screens/profile_screen.dart';
import 'voice_assistant/voice_assistant_fab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _screens = const [
    DashboardScreen(),
    CropAnalysisScreen(),
    MarketPricesScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _index, children: _screens),
          const Positioned(
            right: 0,
            bottom: 80,
            child: VoiceAssistantFab(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primary.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppTheme.primary),
            label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.biotech_outlined),
            selectedIcon: Icon(Icons.biotech, color: AppTheme.primary),
            label: 'Analyze'),
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store, color: AppTheme.primary),
            label: 'Mandi'),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum, color: AppTheme.primary),
            label: 'Community'),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person, color: AppTheme.primary),
            label: 'Profile'),
        ],
      ),
    );
  }
}
