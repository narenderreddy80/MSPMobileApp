import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/api/expert_service.dart';
import '../../../core/api/mandi_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/themed_icon.dart';
import '../../advisory/screens/advisory_screen.dart';
import '../../crop_analysis/screens/crop_analysis_screen.dart';
import '../../expert_connect/screens/expert_connect_screen.dart';
import '../../expert_connect/screens/expert_dashboard_screen.dart';
import '../../fields/screens/my_fields_screen.dart';
import '../../market/screens/market_prices_screen.dart';
import '../../marketplace/screens/marketplace_screen.dart';
import '../../schemes/screens/govt_schemes_screen.dart';
import '../../videos/screens/farming_videos_screen.dart';
import '../../weather/screens/weather_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = 'Farmer';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    const storage = FlutterSecureStorage();
    final name = await storage.read(key: 'user_full_name');
    if (name != null && name.isNotEmpty && mounted) {
      setState(() => _userName = name.split(' ').first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DashboardTheme>(
      valueListenable: ThemeService().themeNotifier,
      builder: (context, theme, _) {
        if (theme == DashboardTheme.tiles) {
          return _TilesDashboard(userName: _userName);
        }
        if (theme == DashboardTheme.tiles2) {
          return _Tiles2Dashboard(userName: _userName);
        }
        return _GreenDashboard(userName: _userName);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GREEN THEME (default)
// ═══════════════════════════════════════════════════════════════════════════
class _GreenDashboard extends StatelessWidget {
  final String userName;
  const _GreenDashboard({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            snap: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MSP Farmers', style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('Good Morning, $userName! 🌱',
                      style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _WeatherQuickCard(onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const WeatherScreen()))),
                const SizedBox(height: 12),
                _MandiTickerCard(onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MarketPricesScreen()))),
                const SizedBox(height: 12),
                _ExpertConnectBanner(onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ExpertConnectScreen()))),
                const SizedBox(height: 16),
                _SectionHeader('Quick Actions'),
                const SizedBox(height: 8),
                _QuickActionsGrid(),
                const SizedBox(height: 16),
                _SectionHeader('Govt. Scheme Updates'),
                const SizedBox(height: 8),
                _SchemeUpdates(),
                const SizedBox(height: 16),
                _SeasonTipCard(),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TILES THEME
// ═══════════════════════════════════════════════════════════════════════════
class _TilesDashboard extends StatelessWidget {
  final String userName;
  const _TilesDashboard({required this.userName});

  // Exact Slack brand colours – pastel tints  (light bg / dark fg)
  // Slack Blue   #36C5F0
  static const _blue   = (Color(0xFFD4F1FB), Color(0xFF036B8F));
  // Slack Green  #2EB67D
  static const _green  = (Color(0xFFCBF0E3), Color(0xFF0D5E40));
  // Slack Pink   #E01E5A
  static const _pink   = (Color(0xFFF9C8D8), Color(0xFF8B0A30));
  // Slack Yellow #ECB22E
  static const _yellow = (Color(0xFFFCEBB8), Color(0xFF7A5600));

  // Tile assignments (rotate through the 4 Slack colours)
  static const _doctor     = _blue;    // Doctor      – blue
  static const _mandi      = _yellow;  // Mandi       – yellow
  static const _weather    = _blue;    // Weather     – blue
  static const _govt       = _pink;    // Govt.       – pink
  static const _expert     = _green;   // Expert      – green
  static const _fieldWatch = _green;   // Field Watch – green
  static const _buySell    = _pink;    // Buy & Sell  – pink
  static const _videos     = _yellow;  // Videos      – yellow

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome heading
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 22,
                            fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
                        children: [
                          const TextSpan(
                            text: 'Welcome, ',
                            style: TextStyle(color: Color(0xFFE65100)),
                          ),
                          TextSpan(
                            text: userName,
                            style: const TextStyle(color: Color(0xFF4CAF50)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Row 1
                    Row(children: [
                      Expanded(child: _Tile(
                          color: _doctor.$1, textColor: _doctor.$2,
                          icon: Icons.medical_services, label: 'Doctor',
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const CropAnalysisScreen())))),
                      const SizedBox(width: 12),
                      Expanded(child: _Tile(
                          color: _mandi.$1, textColor: _mandi.$2,
                          icon: Icons.currency_rupee, label: 'Mandi Prices',
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const MarketPricesScreen())))),
                    ]),
                    const SizedBox(height: 12),
                    // Row 2 – Weather full width
                    _FullWidthTile(
                      color: _weather.$1, textColor: _weather.$2,
                      icon: Icons.wb_cloudy, label: 'Weather',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const WeatherScreen())),
                    ),
                    const SizedBox(height: 12),
                    // Row 3
                    Row(children: [
                      Expanded(child: _Tile(
                          color: _govt.$1, textColor: _govt.$2,
                          icon: Icons.account_balance, label: 'Govt. Schemes',
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const GovtSchemesScreen())))),
                      const SizedBox(width: 12),
                      Expanded(child: _Tile(
                          color: _expert.$1, textColor: _expert.$2,
                          icon: Icons.record_voice_over, label: 'Expert Connect',
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const ExpertConnectScreen())))),
                    ]),
                    const SizedBox(height: 12),
                    // Row 4
                    Row(children: [
                      Expanded(child: _Tile(
                          color: _fieldWatch.$1, textColor: _fieldWatch.$2,
                          icon: Icons.visibility, label: 'Field Watch',
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const MyFieldsScreen())))),
                      const SizedBox(width: 12),
                      Expanded(child: _Tile(
                          color: _buySell.$1, textColor: _buySell.$2,
                          icon: Icons.shopping_bag, label: 'Buy & Sell',
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const MarketplaceScreen())))),
                    ]),
                    const SizedBox(height: 12),
                    // Row 5
                    Row(children: [
                      Expanded(child: _Tile(
                          color: _videos.$1, textColor: _videos.$2,
                          icon: Icons.video_library, label: 'Videos',
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const FarmingVideosScreen())))),
                      const SizedBox(width: 12),
                      Expanded(child: _Tile(
                          color: _blue.$1, textColor: _blue.$2,
                          icon: Icons.smart_toy, label: 'AI Advisory',
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const AdvisoryScreen())))),
                    ]),
                    const SizedBox(height: 16),
                    _SeasonTipCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 3D decoration helper ─────────────────────────────────────────────────────
BoxDecoration _tile3d(Color color) => BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.lerp(color, Colors.white, 0.35)!,
      color,
      Color.lerp(color, Colors.black, 0.18)!,
    ],
    stops: const [0.0, 0.40, 1.0],
  ),
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
  boxShadow: [
    BoxShadow(
      color: Color.lerp(color, Colors.black, 0.4)!.withValues(alpha: 0.5),
      blurRadius: 10, offset: const Offset(4, 6),
    ),
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.18),
      blurRadius: 4, offset: const Offset(-2, -2),
    ),
  ],
);

class _Tile extends StatefulWidget {
  final Color color;
  final Color textColor;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Tile({required this.color, required this.textColor,
      required this.icon, required this.label, required this.onTap});

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        height: 130,
        width: double.infinity,
        transform: _pressed
            ? (Matrix4.identity()..translate(3.0, 4.0))
            : Matrix4.identity(),
        decoration: _pressed
            ? _tile3d(widget.color).copyWith(boxShadow: [
                BoxShadow(
                  color: Color.lerp(widget.color, Colors.black, 0.4)!
                      .withValues(alpha: 0.3),
                  blurRadius: 4, offset: const Offset(2, 3),
                ),
              ])
            : _tile3d(widget.color),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: widget.textColor, size: 48),
            const SizedBox(height: 10),
            Text(widget.label,
                style: TextStyle(
                    color: widget.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _FullWidthTile extends StatelessWidget {
  final Color color;
  final Color textColor;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FullWidthTile({required this.color, required this.textColor,
      required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72, width: double.infinity,
        decoration: _tile3d(color),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 30),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TILES 2 THEME  — Premium Smart Dashboard
// ═══════════════════════════════════════════════════════════════════════════
class _Tiles2Dashboard extends StatelessWidget {
  final String userName;
  const _Tiles2Dashboard({required this.userName});

  // 3-column — ALL 9 screens accessible from dashboard
  static const _tiles = [
    _SmTile(Color(0xFF43A047), Color(0xFF2E7D32), Icons.medical_services, 'Doctor',       'Crop scan'),
    _SmTile(Color(0xFF42A5F5), Color(0xFF1E88E5), Icons.currency_rupee,   'Mandi',        'Live rates'),
    _SmTile(Color(0xFF26A69A), Color(0xFF00796B), Icons.wb_cloudy,        'Weather',      'Forecast'),
    _SmTile(Color(0xFFEF5350), Color(0xFFE53935), Icons.record_voice_over,    'Expert',       'Get advice'),
    _SmTile(Color(0xFF66BB6A), Color(0xFF388E3C), Icons.satellite_alt,    'My Fields',    'Field map'),
    _SmTile(Color(0xFFAB47BC), Color(0xFF7B1FA2), Icons.shopping_bag,     'Buy & Sell',   'Marketplace'),
    _SmTile(Color(0xFFFFCA28), Color(0xFFF57C00), Icons.account_balance,  'Govt Schemes', 'Benefits'),
    _SmTile(Color(0xFFEC407A), Color(0xFFC2185B), Icons.video_library,    'Videos',       'Farming tips'),
    _SmTile(Color(0xFF5C6BC0), Color(0xFF283593), Icons.smart_toy,        'AI Advisory',  'Ask anything'),
  ];

  static const _screens = [
    CropAnalysisScreen(),
    MarketPricesScreen(),
    WeatherScreen(),
    ExpertConnectScreen(),
    MyFieldsScreen(),
    MarketplaceScreen(),
    GovtSchemesScreen(),
    FarmingVideosScreen(),
    AdvisoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),
      body: Column(
        children: [
          _SmHeader(userName: userName),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _SmAlertBanner(),
                  const SizedBox(height: 16),
                  // 3-column grid (matching reference)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _tiles.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.88,
                    ),
                    itemBuilder: (context, i) {
                      return _SmTileCard(
                        tile: _tiles[i],
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => _screens[i])),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _SmVideosSection(onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const FarmingVideosScreen()))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmTile {
  final Color colorStart;
  final Color colorEnd;
  final IconData icon;
  final String title;
  final String subtitle;
  const _SmTile(this.colorStart, this.colorEnd, this.icon, this.title, this.subtitle);
}

// ── Premium green gradient header ────────────────────────────────────────────
class _SmHeader extends StatelessWidget {
  final String userName;
  const _SmHeader({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text('My Location',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const WeatherScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(children: [
                        Icon(Icons.wb_sunny, color: Colors.white, size: 15),
                        SizedBox(width: 5),
                        Text('32°C  Today',
                            style: TextStyle(color: Colors.white,
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('Good Morning, $userName! 🌱',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              const Text('Check your farm updates today',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Alert banner ──────────────────────────────────────────────────────────────
class _SmAlertBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFF3CD)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCA28), width: 1),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFFCA28).withValues(alpha: 0.2),
              blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFCA28).withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFF57C00), size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pest Alert!',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 13, color: Color(0xFF7B4F00))),
                Text('Check your crops for early signs',
                    style: TextStyle(fontSize: 11, color: Color(0xFF9E6B00))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF57C00),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('View',
                style: TextStyle(color: Colors.white,
                    fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Gradient tile card ────────────────────────────────────────────────────────
class _SmTileCard extends StatefulWidget {
  final _SmTile tile;
  final VoidCallback onTap;
  const _SmTileCard({required this.tile, required this.onTap});

  @override
  State<_SmTileCard> createState() => _SmTileCardState();
}

class _SmTileCardState extends State<_SmTileCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.tile;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: _pressed
            ? (Matrix4.identity()..scale(0.96))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [t.colorStart, t.colorEnd],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: t.colorEnd.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon — 70% of tile (large, centred with subtle circle bg)
            Expanded(
              flex: 7,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Icon(t.icon, color: Colors.white, size: 42),
                ),
              ),
            ),
            // Title + subtitle — bottom 30%
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(t.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            height: 1.2)),
                    const SizedBox(height: 2),
                    Text(t.subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 9)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// Latest Videos section (Smart theme)
class _SmVideosSection extends StatelessWidget {
  final VoidCallback onTap;
  const _SmVideosSection({required this.onTap});

  static const _videos = [
    (title: 'Organic Farming',   gradient: [Color(0xFF43A047), Color(0xFF2E7D32)]),
    (title: 'Pest Control',      gradient: [Color(0xFFEF5350), Color(0xFFE53935)]),
    (title: 'Irrigation Tips',   gradient: [Color(0xFF42A5F5), Color(0xFF1E88E5)]),
    (title: 'Soil Preparation',  gradient: [Color(0xFFFFCA28), Color(0xFFF57C00)]),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Latest Videos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            GestureDetector(
              onTap: onTap,
              child: const Row(children: [
                Text('View All', style: TextStyle(color: Color(0xFF43A047), fontSize: 12)),
                Icon(Icons.chevron_right, color: Color(0xFF43A047), size: 16),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            itemCount: _videos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final v = _videos[i];
              return GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Container(
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: v.gradient,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(right: -15, top: -15,
                                child: Container(width: 60, height: 60,
                                  decoration: BoxDecoration(shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.1)))),
                              const Center(
                                child: Icon(Icons.play_circle_fill,
                                    color: Colors.white, size: 40)),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        child: Text(v.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS (used by both themes)
// ═══════════════════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold));
  }
}

class _WeatherQuickCard extends StatelessWidget {
  final VoidCallback onTap;
  const _WeatherQuickCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.75)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Today\'s Weather',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    SizedBox(height: 4),
                    Text('32°C  Partly Cloudy',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white,
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Hyderabad · Humidity 68%',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset('assets/icons/weather.jpeg',
                        width: 52, height: 52, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 4),
                  const Text('Tap for forecast',
                      style: TextStyle(color: Colors.white60, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MandiTickerCard extends StatefulWidget {
  final VoidCallback onTap;
  const _MandiTickerCard({required this.onTap});

  @override
  State<_MandiTickerCard> createState() => _MandiTickerCardState();
}

class _MandiTickerCardState extends State<_MandiTickerCard> {
  final _service = MandiService();
  List<MandiPriceDto> _prices = [];
  bool _loading = true;
  String? _detectedState;
  bool _isNational = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String?> _getNearestState() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return null;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 10)),
      );
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isEmpty) return null;
      return placemarks.first.administrativeArea;
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    try {
      final state = await _getNearestState();
      var data = await _service.getPrices(state: state, limit: 15);
      bool national = false;
      if (data.isEmpty && state != null) {
        data = await _service.getPrices(limit: 15);
        national = data.isNotEmpty;
      }
      if (mounted) {
        setState(() {
          _detectedState = state;
          _prices = data;
          _isNational = national;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset('assets/icons/marketplace.jpeg',
                        width: 24, height: 24, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mandi Prices',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        if (_detectedState != null && !_isNational)
                          Row(children: [
                            const Icon(Icons.location_on,
                                size: 11, color: AppTheme.primary),
                            const SizedBox(width: 2),
                            Text('Near you · $_detectedState',
                                style: const TextStyle(
                                    fontSize: 10, color: AppTheme.primary)),
                          ])
                        else if (_isNational)
                          Row(children: [
                            const Icon(Icons.public,
                                size: 11, color: Colors.grey),
                            const SizedBox(width: 2),
                            const Text('National prices (no local data)',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey)),
                          ]),
                      ],
                    ),
                  ),
                  const Text('View All →',
                      style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              if (_loading)
                const SizedBox(
                    height: 50,
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)))
              else if (_prices.isEmpty)
                const Text('No prices available near you',
                    style: TextStyle(color: Colors.grey, fontSize: 12))
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _prices
                        .map((p) => Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.commodity,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                  Text('₹${p.modalPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary)),
                                  Text(p.market,
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey[600])),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  static const _actions = [
    _ActionItem('assets/icons/crop_analysis.jpeg', 'Analyze Crop', Icons.biotech),
    _ActionItem(null, 'My Reports', Icons.history),
    _ActionItem('assets/icons/marketplace.jpeg', 'Buy / Sell', Icons.storefront),
    _ActionItem('assets/icons/home.jpeg', 'Profile', Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: _actions
          .map((a) => Tooltip(
                message: a.label,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Go to ${a.label}'),
                        duration: const Duration(seconds: 1)));
                  },
                  child: a.assetPath != null
                      ? ThemedAssetIcon(assetPath: a.assetPath!, size: 56)
                      : ThemedIcon(icon: a.fallbackIcon, size: 56),
                ),
              ))
          .toList(),
    );
  }
}

class _ActionItem {
  final String? assetPath;
  final String label;
  final IconData fallbackIcon;
  const _ActionItem(this.assetPath, this.label, this.fallbackIcon);
}

class _SchemeUpdates extends StatelessWidget {
  final _schemes = const [
    _Scheme('Buy & Sell on Marketplace',
        'List your produce or equipment for sale. Browse local buyer listings near you.',
        Colors.teal, Icons.storefront),
    _Scheme('PM-KISAN Instalment 17',
        'Next instalment expected by Apr 2026. Check beneficiary status on portal.',
        Colors.blue, Icons.account_balance),
    _Scheme('PMFBY Kharif Registration',
        'Pradhan Mantri Fasal Bima Yojana: last date to register is 31 July.',
        Colors.green, Icons.shield),
    _Scheme('Soil Health Card 2.0',
        'New soil health cards being issued. Visit nearest KVK for testing.',
        Colors.orange, Icons.science),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _schemes
          .map((s) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: s.color.withValues(alpha: 0.12),
                    child: Icon(s.icon, color: s.color, size: 20),
                  ),
                  title: Text(s.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(s.subtitle,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {},
                ),
              ))
          .toList(),
    );
  }
}

class _Scheme {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  const _Scheme(this.title, this.subtitle, this.color, this.icon);
}

class _SeasonTipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb, color: Colors.amber, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Season Tip — Kharif 2026',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                    'Pre-sow paddy seeds with Trichoderma viride to suppress '
                    'soil-borne fungal diseases like sheath blight and bakanae. '
                    'Apply 4g per kg of seed.',
                    style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpertConnectBanner extends StatefulWidget {
  final VoidCallback onTap;
  const _ExpertConnectBanner({required this.onTap});

  @override
  State<_ExpertConnectBanner> createState() => _ExpertConnectBannerState();
}

class _ExpertConnectBannerState extends State<_ExpertConnectBanner> {
  bool _isExpert = false;

  @override
  void initState() {
    super.initState();
    _checkExpert();
  }

  Future<void> _checkExpert() async {
    try {
      final profile = await ExpertService().getMyExpertProfile();
      if (mounted && profile != null) setState(() => _isExpert = true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isExpert = _isExpert;
    return GestureDetector(
      onTap: isExpert
          ? () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ExpertDashboardScreen()))
          : widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isExpert
                ? [Colors.green[700]!, Colors.green[500]!]
                : [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (isExpert ? Colors.green : AppTheme.primary)
                  .withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                isExpert
                    ? 'assets/icons/expert_consultation.jpeg'
                    : 'assets/icons/expert_connect.jpeg',
                width: 52, height: 52, fit: BoxFit.cover),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isExpert ? 'Expert Dashboard' : 'Expert Connect',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    isExpert
                        ? 'View incoming requests and manage your consultations.'
                        : 'Video call with agri scientists. Show your crop, get instant advice.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }
}
