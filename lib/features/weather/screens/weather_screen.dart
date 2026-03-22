import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/api/weather_service.dart';
import '../../../core/theme/app_theme.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _service = WeatherService();
  WeatherData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.fetchWeather();
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _fetch,
          ),
        ],
      ),
      backgroundColor: AppTheme.background,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Fetching weather data...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Could not load weather',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetch,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final d = _data!;
    final advisories = farmingAdvisories(d);

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CurrentWeatherCard(data: d),
          const SizedBox(height: 16),
          _FarmingAdvisoryCard(advisories: advisories),
          const SizedBox(height: 16),
          _ForecastCard(daily: d.daily, weatherData: d),
          const SizedBox(height: 16),
          _SoilCard(temperature: d.soilTemperature, moisture: d.soilMoisture),
          const SizedBox(height: 8),
          Center(
            child: Text('Data: Open-Meteo.com (free, no API key)',
              style: TextStyle(fontSize: 10, color: Colors.grey[400])),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Current Weather Card ───────────────────────────────────────────────────────

class _CurrentWeatherCard extends StatelessWidget {
  final WeatherData data;
  const _CurrentWeatherCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final c = data.current;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryDark, AppTheme.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(data.locationName,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                ),
                Text(DateFormat('EEE, d MMM').format(DateTime.now()),
                  style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            // Temp + emoji
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${c.temperature.toStringAsFixed(0)}°C',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 56,
                        fontWeight: FontWeight.bold, height: 1)),
                    Text(weatherDescription(c.weatherCode),
                      style: const TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Feels like ${c.feelsLike.toStringAsFixed(0)}°C',
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                Text(weatherEmoji(c.weatherCode),
                  style: const TextStyle(fontSize: 72)),
              ],
            ),
            const SizedBox(height: 20),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(Icons.water_drop, 'Humidity', '${c.humidity.toStringAsFixed(0)}%'),
                _Stat(Icons.air, 'Wind', '${c.windSpeed.toStringAsFixed(0)} km/h'),
                _Stat(Icons.umbrella, 'Rain', '${c.precipitation.toStringAsFixed(1)} mm'),
                _Stat(Icons.wb_sunny, 'UV', c.uvIndex.toStringAsFixed(1)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Stat(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: Colors.white70, size: 18),
      const SizedBox(height: 4),
      Text(value,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      Text(label,
        style: const TextStyle(color: Colors.white60, fontSize: 10)),
    ]);
  }
}

// ── Farming Advisory ──────────────────────────────────────────────────────────

class _FarmingAdvisoryCard extends StatelessWidget {
  final List<(String, bool)> advisories;
  const _FarmingAdvisoryCard({required this.advisories});

  @override
  Widget build(BuildContext context) {
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
                  Icon(
                    a.$2 ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: a.$2 ? Colors.green : AppTheme.secondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(a.$1, style: const TextStyle(fontSize: 13))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ── 7-Day Forecast ────────────────────────────────────────────────────────────

class _ForecastCard extends StatelessWidget {
  final List<DailyForecast> daily;
  final WeatherData weatherData;
  const _ForecastCard({required this.daily, required this.weatherData});

  @override
  Widget build(BuildContext context) {
    final days = daily.take(7).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('7-Day Forecast',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Text('· tap a day for hourly',
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ]),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: days.map((f) {
                final date = DateTime.parse(f.date);
                final isToday = date.day == DateTime.now().day &&
                                date.month == DateTime.now().month;
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _showHourly(context, f, weatherData.hourlyForDate(f.date)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                      decoration: isToday ? BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                      ) : null,
                      child: Column(children: [
                        Text(
                          isToday ? 'Today' : DateFormat('EEE').format(date),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: isToday ? AppTheme.primary : null),
                        ),
                        const SizedBox(height: 4),
                        Text(weatherEmoji(f.weatherCode),
                          style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 2),
                        Text('${f.tempMax.toStringAsFixed(0)}°',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('${f.tempMin.toStringAsFixed(0)}°',
                          style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                        if (f.precipitationProbability > 0)
                          Text('${f.precipitationProbability}%',
                            style: const TextStyle(fontSize: 10, color: Colors.blueAccent)),
                      ]),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showHourly(BuildContext context, DailyForecast day, List<HourlyForecast> hours) {
    final date = DateTime.parse(day.date);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _HourlySheet(day: day, date: date, hours: hours),
    );
  }
}

// ── Hourly Bottom Sheet ────────────────────────────────────────────────────────

class _HourlySheet extends StatelessWidget {
  final DailyForecast day;
  final DateTime date;
  final List<HourlyForecast> hours;
  const _HourlySheet({required this.day, required this.date, required this.hours});

  @override
  Widget build(BuildContext context) {
    final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month;
    final currentHour = DateTime.now().hour;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // Handle + header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(children: [
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Text(weatherEmoji(day.weatherCode),
                  style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    isToday ? 'Today — Hourly Forecast' : '${DateFormat("EEEE, d MMM").format(date)} — Hourly',
                    style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('${day.tempMin.toStringAsFixed(0)}° – ${day.tempMax.toStringAsFixed(0)}°  ·  '
                      '${day.precipitationProbability}% rain',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ]),
            ]),
          ),
          // Hourly list
          Expanded(
            child: hours.isEmpty
              ? const Center(child: Text('No hourly data available'))
              : ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: hours.length,
                  itemBuilder: (_, i) {
                    final h = hours[i];
                    final hourNum = int.tryParse(h.time.split('T').last.split(':').first) ?? 0;
                    final isCurrent = isToday && hourNum == currentHour;
                    return _HourlyRow(entry: h, isCurrent: isCurrent);
                  },
                ),
          ),
        ],
      ),
    );
  }
}

class _HourlyRow extends StatelessWidget {
  final HourlyForecast entry;
  final bool isCurrent;
  const _HourlyRow({required this.entry, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final hourNum = int.tryParse(entry.time.split('T').last.split(':').first) ?? 0;
    final timeLabel = DateFormat('h a').format(
      DateTime(2000, 1, 1, hourNum));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: isCurrent ? BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          // Time
          SizedBox(width: 48,
            child: Text(timeLabel,
              style: TextStyle(
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCurrent ? AppTheme.primary : null,
                fontSize: 13))),
          // Emoji
          Text(weatherEmoji(entry.weatherCode),
            style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          // Temp
          SizedBox(width: 44,
            child: Text('${entry.temperature.toStringAsFixed(0)}°C',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
          const Spacer(),
          // Rain chance
          if (entry.precipitationProbability > 0) ...[
            const Icon(Icons.umbrella, size: 13, color: Colors.blueAccent),
            const SizedBox(width: 2),
            SizedBox(width: 32,
              child: Text('${entry.precipitationProbability}%',
                style: const TextStyle(fontSize: 12, color: Colors.blueAccent))),
          ] else
            const SizedBox(width: 46),
          // Wind
          const Icon(Icons.air, size: 13, color: Colors.grey),
          const SizedBox(width: 2),
          SizedBox(width: 52,
            child: Text('${entry.windSpeed.toStringAsFixed(0)} km/h',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
          // Humidity
          const Icon(Icons.water_drop, size: 13, color: Colors.lightBlue),
          const SizedBox(width: 2),
          Text('${entry.humidity.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 12, color: Colors.lightBlue)),
        ]),
      ),
    );
  }
}

// ── Soil Card ─────────────────────────────────────────────────────────────────

class _SoilCard extends StatelessWidget {
  final double temperature;
  final double moisture;
  const _SoilCard({required this.temperature, required this.moisture});

  @override
  Widget build(BuildContext context) {
    // soil moisture range 0–0.5 m³/m³; normalize to 0–1 for display
    final moisturePct = (moisture * 200).clamp(0.0, 100.0);
    final moistureProgress = moisturePct / 100;
    // temp range 10–50°C for display
    final tempProgress = ((temperature - 10) / 40).clamp(0.0, 1.0);

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
            _SoilRow(
              'Soil Moisture',
              '${moisturePct.toStringAsFixed(0)}%',
              moistureProgress,
              Colors.blue,
            ),
            const SizedBox(height: 10),
            _SoilRow(
              'Soil Temperature',
              '${temperature.toStringAsFixed(1)}°C',
              tempProgress,
              Colors.orange,
            ),
            const SizedBox(height: 10),
            _MoistureLabel(moisturePct),
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
    return Row(children: [
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
      Text(value,
        style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
    ]);
  }
}

class _MoistureLabel extends StatelessWidget {
  final double pct;
  const _MoistureLabel(this.pct);

  @override
  Widget build(BuildContext context) {
    final String status;
    final Color color;
    if (pct < 20) {
      status = 'Very Dry — irrigation urgently needed';
      color = Colors.red;
    } else if (pct < 35) {
      status = 'Dry — consider irrigation';
      color = Colors.orange;
    } else if (pct < 65) {
      status = 'Adequate — suitable for most crops';
      color = Colors.green;
    } else {
      status = 'Wet — check drainage';
      color = Colors.blue;
    }
    return Row(children: [
      Icon(Icons.circle, size: 10, color: color),
      const SizedBox(width: 6),
      Text(status, style: TextStyle(fontSize: 12, color: color)),
    ]);
  }
}
