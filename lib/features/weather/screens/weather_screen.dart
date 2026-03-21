import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weather Forecast')),
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current conditions
            _CurrentWeatherCard(),
            const SizedBox(height: 16),
            // Farming advisory
            _FarmingAdvisoryCard(),
            const SizedBox(height: 16),
            // 5-day forecast
            _ForecastSection(),
            const SizedBox(height: 16),
            // Soil moisture
            _SoilCard(),
          ],
        ),
      ),
    );
  }
}

class _CurrentWeatherCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text('Hyderabad, Telangana',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('32°C',
                      style: TextStyle(color: Colors.white, fontSize: 52,
                        fontWeight: FontWeight.bold)),
                    const Text('Partly Cloudy',
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('Feels like 35°C',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
                const Icon(Icons.wb_cloudy, color: Colors.white, size: 72),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _WeatherStat(icon: Icons.water_drop, label: 'Humidity', value: '68%'),
                _WeatherStat(icon: Icons.air, label: 'Wind', value: '12 km/h'),
                _WeatherStat(icon: Icons.visibility, label: 'Visibility', value: '8 km'),
                _WeatherStat(icon: Icons.umbrella, label: 'Rain', value: '20%'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _WeatherStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }
}

class _FarmingAdvisoryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final advisories = [
      ('Good conditions for paddy transplanting this week.', Icons.check_circle, Colors.green),
      ('Low rain probability — consider irrigation for kharif crops.', Icons.water_drop, Colors.blue),
      ('Mild wind speeds — suitable for pesticide spraying.', Icons.air, Colors.orange),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.agriculture, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text('Farming Advisory',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            ...advisories.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(a.$2, color: a.$3, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(a.$1,
                    style: const TextStyle(fontSize: 13))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _ForecastSection extends StatelessWidget {
  final _forecast = const [
    ('Mon', '☀️', '34°', '22°'),
    ('Tue', '⛅', '30°', '21°'),
    ('Wed', '🌧️', '27°', '20°'),
    ('Thu', '🌦️', '29°', '21°'),
    ('Fri', '☀️', '33°', '22°'),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('5-Day Forecast',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _forecast.map((f) => Column(
                children: [
                  Text(f.$1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(f.$2, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(f.$3, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(f.$4, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                ],
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoilCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Soil Conditions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _SoilRow('Soil Moisture', '65%', 0.65, Colors.blue),
            const SizedBox(height: 8),
            _SoilRow('Soil Temperature', '28°C', 0.56, Colors.orange),
          ],
        ),
      ),
    );
  }
}

class _SoilRow extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;
  const _SoilRow(this.label, this.value, this.progress, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 130,
          child: Text(label, style: const TextStyle(fontSize: 13))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold,
          color: color, fontSize: 13)),
      ],
    );
  }
}
