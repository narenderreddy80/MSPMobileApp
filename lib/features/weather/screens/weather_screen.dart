import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/weather_service.dart';
import '../../../core/theme/app_theme.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _service    = WeatherService();
  final _searchCtrl = TextEditingController();
  final _nominatim  = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));
  WeatherData? _data;
  bool _loading  = true;
  bool _searching = false;
  String? _error;
  String? _savedLocationName;
  List<_PlaceSuggestion> _suggestions = [];
  bool _loadingSuggestions = false;
  Timer? _debounce;

  static const _prefName = 'weather_location_name';
  static const _prefLat  = 'weather_location_lat';
  static const _prefLon  = 'weather_location_lon';

  @override
  void initState() {
    super.initState();
    _loadSavedAndFetch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _nominatim.close();
    super.dispose();
  }

  Future<void> _loadSavedAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final name  = prefs.getString(_prefName);
    final lat   = prefs.getDouble(_prefLat);
    final lon   = prefs.getDouble(_prefLon);
    if (name != null && lat != null && lon != null) {
      _searchCtrl.text = name;
      if (mounted) setState(() => _savedLocationName = name);
      await _fetchByCoords(lat, lon);
    } else {
      await _fetch();
    }
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

  Future<void> _fetchByCoords(double lat, double lon) async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.fetchWeatherByCoords(lat, lon);
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  /// Called on every keystroke; triggers Nominatim after 5 chars with 400ms debounce.
  void _onSearchChanged(String text) {
    _debounce?.cancel();
    if (text.trim().length < 5) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400),
        () => _fetchSuggestions(text.trim()));
  }

  Future<void> _fetchSuggestions(String query) async {
    if (!mounted) return;
    setState(() => _loadingSuggestions = true);
    try {
      final res = await _nominatim.get<List<dynamic>>(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': '$query, India',
          'format': 'json',
          'countrycodes': 'in',
          'limit': 6,
          'addressdetails': 0,
        },
        options: Options(headers: {'User-Agent': 'MSP-Farmers-App/1.0'}),
      );
      final items = res.data ?? [];
      if (mounted) {
        setState(() {
          _suggestions = items.map((e) {
            final m = e as Map<String, dynamic>;
            return _PlaceSuggestion(
              displayName: m['display_name'] as String,
              lat: double.parse(m['lat'] as String),
              lon: double.parse(m['lon'] as String),
            );
          }).toList();
          _loadingSuggestions = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  Future<void> _selectSuggestion(_PlaceSuggestion s) async {
    _debounce?.cancel();
    // Use only the first part of the display name (city/village) as the label
    final label = s.displayName.split(',').first.trim();
    _searchCtrl.text = label;
    setState(() { _suggestions = []; _savedLocationName = label; });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefName, label);
    await prefs.setDouble(_prefLat, s.lat);
    await prefs.setDouble(_prefLon, s.lon);
    if (mounted) _fetchByCoords(s.lat, s.lon);
  }

  Future<void> _clearSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefName);
    await prefs.remove(_prefLat);
    await prefs.remove(_prefLon);
    _searchCtrl.clear();
    if (mounted) setState(() => _savedLocationName = null);
    await _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MSP Farmers',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Weather',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        actions: [
          if (_savedLocationName != null)
            IconButton(
              icon: const Icon(Icons.my_location, color: Colors.white),
              tooltip: 'Use my GPS location',
              onPressed: _loading || _searching ? null : _clearSavedLocation,
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loading || _searching ? null : _loadSavedAndFetch,
          ),
        ],
      ),
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          Column(
            children: [
              _WeatherSearchBar(
                controller: _searchCtrl,
                searching: _searching || _loadingSuggestions,
                onChanged: _onSearchChanged,
                onClear: _clearSavedLocation,
              ),
              Expanded(child: _buildBody()),
            ],
          ),
          if (_suggestions.isNotEmpty)
            Positioned(
              top: 58,
              left: 12,
              right: 12,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(10),
                child: _SuggestionsList(
                  suggestions: _suggestions,
                  onSelect: _selectSuggestion,
                ),
              ),
            ),
        ],
      ),
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

// ── Place suggestion model ────────────────────────────────────────────────────

class _PlaceSuggestion {
  final String displayName;
  final double lat;
  final double lon;
  const _PlaceSuggestion({required this.displayName, required this.lat, required this.lon});
}

// ── Weather Search Bar ────────────────────────────────────────────────────────

class _WeatherSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool searching;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _WeatherSearchBar({
    required this.controller,
    required this.searching,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search city or village in India...',
          prefixIcon: searching
              ? const SizedBox(
                  width: 20, height: 20,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ))
              : const Icon(Icons.search, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.primary),
          ),
          helperText: 'Type at least 5 letters to search',
          helperStyle: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        enabled: !searching,
      ),
    );
  }
}

// ── Suggestions dropdown ──────────────────────────────────────────────────────

class _SuggestionsList extends StatelessWidget {
  final List<_PlaceSuggestion> suggestions;
  final ValueChanged<_PlaceSuggestion> onSelect;
  const _SuggestionsList({required this.suggestions, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 280),
        color: Colors.white,
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 48),
          itemBuilder: (_, i) {
            final s = suggestions[i];
            final parts = s.displayName.split(',');
            final title = parts.first.trim();
            final subtitle = parts.length > 1
                ? parts.skip(1).take(3).map((e) => e.trim()).join(', ')
                : '';
            return ListTile(
              dense: true,
              leading: const Icon(Icons.location_on_outlined,
                  color: AppTheme.primary, size: 20),
              title: Text(title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: subtitle.isNotEmpty
                  ? Text(subtitle,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      maxLines: 1, overflow: TextOverflow.ellipsis)
                  : null,
              onTap: () => onSelect(s),
            );
          },
        ),
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
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => HourlyWeatherPage(day: day, date: date, hours: hours),
    ));
  }
}

// ── Hourly Weather Full Page ───────────────────────────────────────────────────

class HourlyWeatherPage extends StatelessWidget {
  final DailyForecast day;
  final DateTime date;
  final List<HourlyForecast> hours;
  const HourlyWeatherPage(
      {super.key, required this.day, required this.date, required this.hours});

  @override
  Widget build(BuildContext context) {
    final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month;
    final currentHour = DateTime.now().hour;
    final title = isToday ? 'Today' : DateFormat('EEEE, d MMM').format(date);

    // Compute stats from hourly data
    final totalRain = hours.fold(0.0, (sum, h) => sum + h.precipitation);
    final maxRainProb = hours.isEmpty ? 0
        : hours.map((h) => h.precipitationProbability).reduce(max);
    final avgHumidity = hours.isEmpty ? 0.0
        : hours.map((h) => h.humidity).reduce((a, b) => a + b) / hours.length;
    final maxWind = hours.isEmpty ? 0.0
        : hours.map((h) => h.windSpeed).reduce(max);
    final rainyHours = hours.where((h) => h.precipitationProbability >= 40).length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MSP Farmers',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Green banner ────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BannerStat(weatherEmoji(day.weatherCode),
                    '${day.tempMax.toStringAsFixed(0)}° / ${day.tempMin.toStringAsFixed(0)}°',
                    'High / Low'),
                _BannerStat('🌧', '${totalRain.toStringAsFixed(1)} mm',
                    'Total Rain'),
                _BannerStat('💧', '$maxRainProb%',
                    'Max Rain %'),
                _BannerStat('🌬', '${maxWind.toStringAsFixed(0)} km/h',
                    'Max Wind'),
              ],
            ),
          ),

          // ── Info chips row ──────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              _InfoChip(Icons.water_drop_outlined, '${avgHumidity.toStringAsFixed(0)}%',
                  'Avg Humidity', Colors.blue),
              const SizedBox(width: 8),
              _InfoChip(Icons.umbrella_outlined,
                  rainyHours == 0 ? 'None' : '$rainyHours hrs',
                  'Rainy Hours', rainyHours == 0 ? Colors.green : Colors.indigo),
              const SizedBox(width: 8),
              _InfoChip(Icons.touch_app_outlined, 'Drag', 'to explore', Colors.grey),
            ]),
          ),

          const Divider(height: 1),

          // ── Graph area (white background, blue fill below curve) ─
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: hours.isEmpty
                    ? const Center(child: Text('No hourly data',
                        style: TextStyle(color: Colors.white54)))
                    : _InteractiveGraph(
                        hours: hours,
                        isToday: isToday,
                        currentHour: currentHour),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  const _BannerStat(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(icon, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 3),
      Text(value,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      Text(label,
        style: const TextStyle(color: Colors.white60, fontSize: 10)),
    ]);
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _InfoChip(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                overflow: TextOverflow.ellipsis),
              Text(label,
                style: const TextStyle(fontSize: 9, color: Colors.black45),
                overflow: TextOverflow.ellipsis),
            ],
          )),
        ]),
      ),
    );
  }
}

// ── Interactive full-fit graph ─────────────────────────────────────────────────

class _InteractiveGraph extends StatefulWidget {
  final List<HourlyForecast> hours;
  final bool isToday;
  final int currentHour;
  const _InteractiveGraph(
      {required this.hours, required this.isToday, required this.currentHour});

  @override
  State<_InteractiveGraph> createState() => _InteractiveGraphState();
}

class _InteractiveGraphState extends State<_InteractiveGraph> {
  int? _selectedIndex;

  void _updateTouch(Offset pos, double slotW) {
    if (slotW <= 0) return;
    final idx = (pos.dx / slotW).floor().clamp(0, widget.hours.length - 1);
    setState(() => _selectedIndex = idx);
  }

  void _clearTouch() => setState(() => _selectedIndex = null);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final totalW = constraints.maxWidth;
      final totalH = constraints.maxHeight;
      final n = widget.hours.length;
      final slotW = n > 0 ? totalW / n : totalW;

      return Stack(children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart:  (d) => _updateTouch(d.localPosition, slotW),
          onPanUpdate: (d) => _updateTouch(d.localPosition, slotW),
          onPanEnd:    (_) => _clearTouch(),
          onTapDown:   (d) => _updateTouch(d.localPosition, slotW),
          onTapUp:     (_) => _clearTouch(),
          child: CustomPaint(
            size: Size(totalW, totalH),
            painter: _GraphPainter(
              hours: widget.hours,
              isToday: widget.isToday,
              currentHour: widget.currentHour,
              selectedIndex: _selectedIndex,
            ),
          ),
        ),
        // Hover detail card
        if (_selectedIndex != null)
          _HoverCard(
            entry: widget.hours[_selectedIndex!],
            xCenter: _selectedIndex! * slotW + slotW / 2,
            totalW: totalW,
          ),
      ]);
    });
  }
}

// ── Hover card (shown while finger is on graph) ────────────────────────────────

class _HoverCard extends StatelessWidget {
  final HourlyForecast entry;
  final double xCenter;
  final double totalW;
  const _HoverCard({required this.entry, required this.xCenter, required this.totalW});

  static String _timeLbl(int h) {
    if (h == 0)  return '12:00 AM';
    if (h < 12)  return '$h:00 AM';
    if (h == 12) return '12:00 PM';
    return '${h - 12}:00 PM';
  }

  @override
  Widget build(BuildContext context) {
    const cardW = 152.0;
    final rawLeft = xCenter - cardW / 2;
    final left = rawLeft.clamp(4.0, totalW - cardW - 4);
    final hourNum = int.tryParse(entry.time.split('T').last.split(':').first) ?? 0;

    return Positioned(
      top: 10,
      left: left,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: cardW,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1B4F72).withValues(alpha: 0.20)),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_timeLbl(hourNum),
                style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 12,
                  color: Color(0xFF1B4F72))),
              const SizedBox(height: 5),
              Row(children: [
                Text(weatherEmoji(entry.weatherCode),
                  style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 8),
                Text('${entry.temperature.toStringAsFixed(0)}°C',
                  style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold,
                    color: Colors.black87)),
              ]),
              const SizedBox(height: 3),
              Text(weatherDescription(entry.weatherCode),
                style: const TextStyle(fontSize: 10, color: Colors.black54)),
              const SizedBox(height: 7),
              Row(children: [
                const Icon(Icons.water_drop, size: 12, color: Colors.blue),
                const SizedBox(width: 3),
                Text('${entry.humidity.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 11, color: Colors.black87)),
                const SizedBox(width: 10),
                const Icon(Icons.air, size: 12, color: Colors.grey),
                const SizedBox(width: 3),
                Flexible(child: Text('${entry.windSpeed.toStringAsFixed(0)} km/h',
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                  overflow: TextOverflow.ellipsis)),
              ]),
              if (entry.precipitationProbability > 0) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.umbrella, size: 12, color: Colors.blueAccent),
                  const SizedBox(width: 3),
                  Text('Rain ${entry.precipitationProbability}%',
                    style: const TextStyle(fontSize: 11, color: Colors.blueAccent)),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Graph CustomPainter ────────────────────────────────────────────────────────

class _GraphPainter extends CustomPainter {
  final List<HourlyForecast> hours;
  final bool isToday;
  final int currentHour;
  final int? selectedIndex;

  static const _gridHours  = [0, 6, 12, 18];
  static const _gridLabels = ['12 AM', '6 AM', '12 PM', '6 PM'];

  const _GraphPainter({
    required this.hours,
    required this.isToday,
    required this.currentHour,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hours.isEmpty) return;
    final n     = hours.length;
    final w     = size.width;
    final h     = size.height;
    final slotW = w / n;

    // ── Layout zones (proportional to canvas height) ──────────────
    const timeLabelY  = 16.0;
    const emojiY      = 40.0;
    const curveTop    = 72.0;
    final curveBottom = h * 0.58;
    final rainTop     = curveBottom + 14;
    final rainBottom  = h * 0.80;
    final rainPctY    = h * 0.87;

    final temps = hours.map((e) => e.temperature).toList();
    final minT  = temps.reduce(min) - 2;
    final maxT  = temps.reduce(max) + 2;
    final tRange = (maxT - minT).clamp(1.0, double.infinity);

    final hrs = List.generate(n, (i) =>
        int.tryParse(hours[i].time.split('T').last.split(':').first) ?? i);

    double xOf(int i)     => i * slotW + slotW / 2;
    double yOfT(double t) => curveBottom - ((t - minT) / tRange) * (curveBottom - curveTop);

    // ── Vertical grid lines at 12am / 6am / 12pm / 6pm ───────────
    const gridColor = Color(0xFFCFD8DC);
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    for (int gi = 0; gi < _gridHours.length; gi++) {
      final gh  = _gridHours[gi];
      final idx = hrs.indexOf(gh);
      if (idx < 0) continue;
      final gx = xOf(idx);

      canvas.drawLine(Offset(gx, timeLabelY + 10), Offset(gx, rainBottom), gridPaint);

      // Time label (dark on white)
      _txt(canvas, _gridLabels[gi], Offset(gx, timeLabelY),
          sz: 10.5, color: const Color(0xFF37474F), bold: true, maxW: slotW * 4);

      // Weather emoji
      _txt(canvas, weatherEmoji(hours[idx].weatherCode),
          Offset(gx, emojiY), sz: 19, color: Colors.black, maxW: slotW * 4);
    }

    // ── Horizontal temp guide lines (faint) ───────────────────────
    const guideCount = 3;
    for (int g = 0; g <= guideCount; g++) {
      final gy = curveTop + (curveBottom - curveTop) * g / guideCount;
      canvas.drawLine(Offset(0, gy), Offset(w, gy),
          Paint()..color = const Color(0xFFECEFF1)..strokeWidth = 1.0);
    }

    // ── "Now" column soft highlight (light blue tint) ─────────────
    final nowIdx = isToday ? hrs.indexOf(currentHour) : -1;
    if (nowIdx >= 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(nowIdx * slotW + 1, curveTop - 10, slotW - 2, curveBottom - curveTop + 10),
          const Radius.circular(8),
        ),
        Paint()..color = const Color(0xFF1B4F72).withValues(alpha: 0.08),
      );
    }

    // ── Selected column highlight + vertical line ──────────────────
    if (selectedIndex != null) {
      canvas.drawRect(
        Rect.fromLTWH(selectedIndex! * slotW, 0, slotW, h),
        Paint()..color = const Color(0xFF1B4F72).withValues(alpha: 0.06),
      );
      canvas.drawLine(
        Offset(xOf(selectedIndex!), timeLabelY + 10),
        Offset(xOf(selectedIndex!), rainBottom + 4),
        Paint()
          ..color = const Color(0xFF1B4F72).withValues(alpha: 0.70)
          ..strokeWidth = 1.5,
      );
    }

    // ── Build smooth Catmull-Rom spline (no zigzag) ───────────────
    // Pre-compute all (x, y) points
    final pts = List.generate(n, (i) => Offset(xOf(i), yOfT(temps[i])));

    // Helper: Catmull-Rom control points for segment i → i+1
    // Uses neighbours i-1 and i+2 (clamped) for tangent calculation
    (Offset, Offset) crPts(int i) {
      final p0 = pts[(i - 1).clamp(0, n - 1)];
      final p1 = pts[i];
      final p2 = pts[(i + 1).clamp(0, n - 1)];
      final p3 = pts[(i + 2).clamp(0, n - 1)];
      final cp1 = Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
      final cp2 = Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
      return (cp1, cp2);
    }

    final curvePath = Path();
    final fillPath  = Path();

    curvePath.moveTo(pts[0].dx, pts[0].dy);
    fillPath..moveTo(0, curveBottom)..lineTo(pts[0].dx, pts[0].dy);

    for (int i = 0; i < n - 1; i++) {
      final (cp1, cp2) = crPts(i);
      curvePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i + 1].dx, pts[i + 1].dy);
      fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i + 1].dx, pts[i + 1].dy);
    }
    fillPath..lineTo(pts[n - 1].dx, curveBottom)..close();

    // ── Blue gradient fill BELOW the curve ────────────────────────
    canvas.drawPath(fillPath, Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, curveTop), Offset(0, curveBottom),
        [
          const Color(0xFF1B4F72).withValues(alpha: 0.85),
          const Color(0xFF1565C0).withValues(alpha: 0.50),
        ],
      ));

    // ── Curve stroke (dark blue border between white/blue) ─────────
    canvas.drawPath(curvePath, Paint()
      ..color = const Color(0xFF0D47A1)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);

    // ── Temperature labels at grid hours (above curve = white bg) ──
    for (int gi = 0; gi < _gridHours.length; gi++) {
      final idx = hrs.indexOf(_gridHours[gi]);
      if (idx < 0) continue;
      final x     = xOf(idx);
      final y     = yOfT(temps[idx]);
      final isNow = isToday && hrs[idx] == currentHour;
      _txt(canvas, '${temps[idx].toStringAsFixed(0)}°',
          Offset(x, y - 14),
          sz: 10.5,
          color: isNow ? const Color(0xFF0D47A1) : const Color(0xFF37474F),
          bold: isNow,
          maxW: slotW * 3);
      // Dot on curve (white dot with blue border)
      canvas.drawCircle(Offset(x, y), isNow ? 5.0 : 3.5,
          Paint()..color = Colors.white);
      canvas.drawCircle(Offset(x, y), isNow ? 5.0 : 3.5, Paint()
        ..color = const Color(0xFF0D47A1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isNow ? 2.5 : 1.5);
    }

    // ── "Now" dashed vertical line (orange/red highlight) ──────────
    if (nowIdx >= 0) {
      final nx     = xOf(nowIdx);
      final dashPt = Paint()
        ..color = Colors.orange.withValues(alpha: 0.80)
        ..strokeWidth = 1.5;
      double dy = curveTop - 8;
      while (dy < curveBottom) {
        canvas.drawLine(Offset(nx, dy), Offset(nx, min(dy + 4, curveBottom)), dashPt);
        dy += 7;
      }
      _txt(canvas, 'Now', Offset(nx, timeLabelY),
          sz: 10.5, color: Colors.orange.shade800, bold: true, maxW: slotW * 3);
    }

    // ── Selected hour: large dot ───────────────────────────────────
    if (selectedIndex != null) {
      final sx = xOf(selectedIndex!);
      final sy = yOfT(temps[selectedIndex!]);
      canvas.drawCircle(Offset(sx, sy), 6.5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(sx, sy), 6.5, Paint()
        ..color = const Color(0xFF0D47A1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5);
    }

    // ── Rain probability bars (blue shades) ───────────────────────
    for (int i = 0; i < n; i++) {
      final prob = hours[i].precipitationProbability;
      if (prob <= 0) continue;
      final bx   = xOf(i);
      final barH = (prob / 100) * (rainBottom - rainTop);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bx - slotW * 0.38, rainBottom - barH, slotW * 0.76, barH),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF1565C0)
            .withValues(alpha: 0.25 + (prob / 100) * 0.55),
      );
    }

    // Rain % labels at grid positions only
    for (int gi = 0; gi < _gridHours.length; gi++) {
      final idx = hrs.indexOf(_gridHours[gi]);
      if (idx < 0) continue;
      final prob = hours[idx].precipitationProbability;
      if (prob <= 0) continue;
      _txt(canvas, '$prob%', Offset(xOf(idx), rainPctY),
          sz: 9.5, color: const Color(0xFF1565C0), maxW: slotW * 3);
    }
  }

  void _txt(Canvas canvas, String text, Offset centre,
      {required double sz, required Color color, bool bold = false, required double maxW}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: sz, color: color,
          fontWeight: bold ? FontWeight.bold : FontWeight.w400)),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: maxW);
    tp.paint(canvas, Offset(centre.dx - tp.width / 2, centre.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _GraphPainter old) =>
      old.hours != hours ||
      old.selectedIndex != selectedIndex ||
      old.currentHour != currentHour;
}

// ── Soil Card ─────────────────────────────────────────────────────────────────

class _SoilCard extends StatelessWidget {
  final double temperature;
  final double moisture;
  const _SoilCard({required this.temperature, required this.moisture});

  @override
  Widget build(BuildContext context) {
    final moisturePct    = (moisture * 200).clamp(0.0, 100.0);
    final moistureProgress = moisturePct / 100;
    final tempProgress   = ((temperature - 10) / 40).clamp(0.0, 1.0);

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
            _SoilRow('Soil Moisture',     '${moisturePct.toStringAsFixed(0)}%',
                moistureProgress, Colors.blue),
            const SizedBox(height: 10),
            _SoilRow('Soil Temperature',  '${temperature.toStringAsFixed(1)}°C',
                tempProgress, Colors.orange),
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
