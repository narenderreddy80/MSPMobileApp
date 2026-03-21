import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../weather/screens/weather_screen.dart';
import '../../market/screens/market_prices_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
                children: const [
                  Text('MSP Farmers', style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('Good Morning, Farmer! 🌱',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
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
                // Weather quick card
                _WeatherQuickCard(onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const WeatherScreen()))),
                const SizedBox(height: 12),
                // Market ticker
                _MarketTickerCard(onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MarketPricesScreen()))),
                const SizedBox(height: 16),
                // Quick actions
                _SectionHeader('Quick Actions'),
                const SizedBox(height: 8),
                _QuickActionsGrid(),
                const SizedBox(height: 16),
                // Scheme updates
                _SectionHeader('Govt. Scheme Updates'),
                const SizedBox(height: 8),
                _SchemeUpdates(),
                const SizedBox(height: 16),
                // Season tip
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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Today\'s Weather',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                  SizedBox(height: 4),
                  Text('32°C  Partly Cloudy',
                    style: TextStyle(color: Colors.white,
                      fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Hyderabad · Humidity 68%',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Column(
                children: const [
                  Icon(Icons.wb_cloudy, color: Colors.white, size: 48),
                  SizedBox(height: 4),
                  Text('Tap for forecast',
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

class _MarketTickerCard extends StatelessWidget {
  final VoidCallback onTap;
  const _MarketTickerCard({required this.onTap});

  final _tickers = const [
    ('Paddy', '₹2,250', '+2.0%', true),
    ('Cotton', '₹7,100', '-2.0%', false),
    ('Maize', '₹1,780', '+1.2%', true),
    ('Soybean', '₹4,200', '+0.5%', true),
    ('Red Chilli', '₹9,200', '+4.0%', true),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.trending_up, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 6),
                  Text('Mandi Prices', style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('View All →',
                    style: const TextStyle(color: AppTheme.primary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _tickers.map((t) => Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (t.$4 ? Colors.green : Colors.red)
                        .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (t.$4 ? Colors.green : Colors.red)
                          .withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(t.$1,
                          style: const TextStyle(fontSize: 11,
                            fontWeight: FontWeight.bold)),
                        Text(t.$2,
                          style: const TextStyle(fontSize: 13,
                            fontWeight: FontWeight.bold)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t.$4 ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 10,
                              color: t.$4 ? Colors.green : Colors.red),
                            Text(t.$3,
                              style: TextStyle(fontSize: 10,
                                color: t.$4 ? Colors.green : Colors.red)),
                          ],
                        ),
                      ],
                    ),
                  )).toList(),
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
  final _actions = const [
    _Action(Icons.biotech, 'Analyze Crop', Colors.green, 0),
    _Action(Icons.history, 'My Reports', Colors.blue, 1),
    _Action(Icons.forum, 'Community', Colors.orange, 3),
    _Action(Icons.person, 'Profile', Colors.purple, 4),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: _actions.map((a) => GestureDetector(
        onTap: () {
          // Navigate to parent's tab by index via rootNavigator if needed
          // For simplicity, show a snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Go to ${a.label}'),
              duration: const Duration(seconds: 1)));
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: a.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(a.icon, color: a.color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(a.label, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      )).toList(),
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final Color color;
  final int tabIndex;
  const _Action(this.icon, this.label, this.color, this.tabIndex);
}

class _SchemeUpdates extends StatelessWidget {
  final _schemes = const [
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
      children: _schemes.map((s) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: s.color.withValues(alpha: 0.12),
            child: Icon(s.icon, color: s.color, size: 20),
          ),
          title: Text(s.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: Text(s.subtitle,
            style: const TextStyle(fontSize: 12),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () {},
        ),
      )).toList(),
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold)),
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
