import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/services/notification_service.dart';
import 'dashboard/screens/dashboard_screen.dart';
import 'crop_analysis/screens/crop_analysis_screen.dart';
import 'fields/screens/my_fields_screen.dart';
import 'market/screens/market_prices_screen.dart';
import 'marketplace/screens/marketplace_screen.dart';
import 'profile/screens/profile_screen.dart';
import 'videos/screens/farming_videos_screen.dart';
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
    MyFieldsScreen(),
    FarmingVideosScreen(),
    MarketPricesScreen(),
    MarketplaceScreen(),
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
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppTheme.primary),
            label: 'Home'),
          const NavigationDestination(
            icon: Icon(Icons.biotech_outlined),
            selectedIcon: Icon(Icons.biotech, color: AppTheme.primary),
            label: 'Analyze'),
          const NavigationDestination(
            icon: Icon(Icons.satellite_alt_outlined),
            selectedIcon: Icon(Icons.satellite_alt, color: AppTheme.primary),
            label: 'My Fields'),
          const NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            selectedIcon: Icon(Icons.play_circle, color: AppTheme.primary),
            label: 'Videos'),
          const NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store, color: AppTheme.primary),
            label: 'Mandi'),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront, color: AppTheme.primary),
            label: 'Market'),
          NavigationDestination(
            icon: ValueListenableBuilder<int>(
              valueListenable: NotificationService().unreadCountNotifier,
              builder: (context, count, child) => Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                child: const Icon(Icons.person_outlined),
              ),
            ),
            selectedIcon: const Icon(Icons.person, color: AppTheme.primary),
            label: 'Profile'),
        ],
      ),
    );
  }
}
