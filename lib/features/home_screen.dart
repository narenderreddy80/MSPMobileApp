import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'crop_analysis/screens/crop_analysis_screen.dart';
import 'history/screens/history_screen.dart';
import 'advisory/screens/advisory_screen.dart';
import 'crops/screens/crops_screen.dart';
import 'profile/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _screens = const [
    CropAnalysisScreen(),
    HistoryScreen(),
    AdvisoryScreen(),
    CropsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primary.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.biotech_outlined),
            selectedIcon: Icon(Icons.biotech, color: AppTheme.primary),
            label: 'Analyze'),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: AppTheme.primary),
            label: 'History'),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy, color: AppTheme.primary),
            label: 'Advisory'),
          NavigationDestination(
            icon: Icon(Icons.grass_outlined),
            selectedIcon: Icon(Icons.grass, color: AppTheme.primary),
            label: 'Crops'),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person, color: AppTheme.primary),
            label: 'Profile'),
        ],
      ),
    );
  }
}
