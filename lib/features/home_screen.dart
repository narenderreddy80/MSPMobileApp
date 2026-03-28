import 'package:flutter/material.dart';
import '../core/services/notification_service.dart';
import '../core/theme/app_theme.dart';
import 'dashboard/screens/dashboard_screen.dart';
import 'crop_analysis/screens/crop_analysis_screen.dart';
import 'fields/screens/my_fields_screen.dart';
import 'marketplace/screens/marketplace_screen.dart';
import 'profile/screens/profile_screen.dart';
import 'voice_assistant/voice_assistant_fab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  // 5 screens — centre (index 2) is Crop Analyzer
  final _screens = const [
    DashboardScreen(),    // 0 Home
    MyFieldsScreen(),     // 1 My Fields
    CropAnalysisScreen(), // 2 Crop Analyzer (centre FAB)
    MarketplaceScreen(),  // 3 Buy/Sell
    ProfileScreen(),      // 4 Profile
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
      bottomNavigationBar: _BottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

// ── Custom bottom nav with large centre FAB ───────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(Icons.home_rounded,       'Home'),
    _NavItem(Icons.satellite_alt,      'My Fields'),
    null, // placeholder for centre FAB
    _NavItem(Icons.shopping_bag,       'Buy / Sell'),
    _NavItem(Icons.person_rounded,     'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── 4 regular items (2 left + 2 right, centre is spacer) ──
              Row(
                children: List.generate(_items.length, (i) {
                  if (i == 2) return const Expanded(child: SizedBox());

                  final item = _items[i]!;
                  final selected = currentIndex == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (i == 4)
                            ValueListenableBuilder<int>(
                              valueListenable: NotificationService().unreadCountNotifier,
                              builder: (context, count, _) => Badge(
                                isLabelVisible: count > 0,
                                label: Text('$count'),
                                child: Icon(item.icon, size: 26,
                                    color: selected ? AppTheme.primary : Colors.grey[400]),
                              ),
                            )
                          else
                            Icon(item.icon, size: 26,
                                color: selected ? AppTheme.primary : Colors.grey[400]),
                          const SizedBox(height: 3),
                          Text(item.label,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                  color: selected ? AppTheme.primary : Colors.grey[500])),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: selected ? 5 : 0,
                            height: selected ? 5 : 0,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: AppTheme.primary),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),

              // ── Centre FAB — floats above the bar ──
              Positioned(
                top: -12,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => onTap(2),
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF43A047).withValues(alpha: 0.5),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle, color: Colors.white, size: 22),
                          const SizedBox(height: 2),
                          const Text('Scan',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
