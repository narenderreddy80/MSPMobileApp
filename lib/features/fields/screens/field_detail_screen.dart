import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/api/crop_analysis_service.dart';
import '../../../core/api/field_service.dart';
import '../../../core/api/weather_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../crop_analysis/screens/analysis_result_screen.dart';
import '../../videos/screens/farming_videos_screen.dart';

class FieldDetailScreen extends StatefulWidget {
  final FieldDto field;
  const FieldDetailScreen({super.key, required this.field});

  @override
  State<FieldDetailScreen> createState() => _FieldDetailScreenState();
}

class _FieldDetailScreenState extends State<FieldDetailScreen> {
  late FieldDto _field;
  bool _analysing = false;
  GoogleMapController? _mapCtrl;
  WeatherData? _weather;
  bool _weatherLoading = true;
  final _picker = ImagePicker();
  final List<XFile> _photos = [];
  bool _analyzingPhoto = false;

  @override
  void initState() {
    super.initState();
    _field = widget.field;
    _loadFieldWeather();
  }

  @override
  void dispose() {
    _mapCtrl?.dispose();
    super.dispose();
  }

  Future<void> _loadFieldWeather() async {
    try {
      final data = await WeatherService()
          .fetchWeatherByCoords(_field.centroidLat, _field.centroidLon);
      if (mounted) setState(() { _weather = data; _weatherLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _weatherLoading = false);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (source == ImageSource.gallery) {
      final picked = await _picker.pickMultiImage(imageQuality: 85);
      final remaining = 4 - _photos.length;
      if (picked.isNotEmpty && remaining > 0) {
        setState(() => _photos.addAll(picked.take(remaining)));
      }
    } else {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked != null && _photos.length < 4) {
        setState(() => _photos.add(picked));
      }
    }
  }

  Future<void> _analyzePhotos() async {
    if (_photos.isEmpty) return;
    setState(() => _analyzingPhoto = true);
    try {
      final sowingInfo = _field.sowingDate != null
          ? ' | Day ${DateTime.now().difference(_field.sowingDate!).inDays} after sowing'
          : '';
      final notes =
          'Field: ${_field.name} | Crop: ${_field.cropType}$sowingInfo';
      final result = await CropAnalysisService()
          .analyze(_photos.map((x) => x.path).toList(), notes);
      if (mounted) {
        setState(() => _analyzingPhoto = false);
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AnalysisResultScreen(result: result)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _analyzingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Photo analysis failed: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _onMapCreated(GoogleMapController ctrl) {
    _mapCtrl = ctrl;
    // After map initialises, fit the polygon bounds so the whole field is visible
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      try {
        final geo = jsonDecode(_field.polygonGeoJson);
        final coords = (geo['coordinates'][0] as List)
            .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();
        if (coords.isEmpty) return;

        double minLat = coords.first.latitude,  maxLat = coords.first.latitude;
        double minLon = coords.first.longitude, maxLon = coords.first.longitude;
        for (final p in coords) {
          if (p.latitude  < minLat) minLat = p.latitude;
          if (p.latitude  > maxLat) maxLat = p.latitude;
          if (p.longitude < minLon) minLon = p.longitude;
          if (p.longitude > maxLon) maxLon = p.longitude;
        }

        _mapCtrl?.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(minLat, minLon),
              northeast: LatLng(maxLat, maxLon),
            ),
            60, // padding in pixels
          ),
        );
      } catch (_) {
        // Fallback to centroid zoom if polygon parse fails
        _mapCtrl?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_field.centroidLat, _field.centroidLon), 16,
          ),
        );
      }
    });
  }

  Future<void> _triggerAnalysis() async {
    setState(() => _analysing = true);
    try {
      final analysis = await FieldService().triggerAnalysis(_field.id);
      if (mounted) {
        setState(() {
          _field = FieldDto(
            id: _field.id,
            name: _field.name,
            cropType: _field.cropType,
            sowingDate: _field.sowingDate,
            areaAcres: _field.areaAcres,
            polygonGeoJson: _field.polygonGeoJson,
            centroidLat: _field.centroidLat,
            centroidLon: _field.centroidLon,
            tileId: _field.tileId,
            createdAt: _field.createdAt,
            latestAnalysis: analysis,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analysis complete'),
            backgroundColor: AppTheme.primary));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _analysing = false);
    }
  }

  Set<Polygon> _buildPolygon() {
    try {
      final geo = jsonDecode(_field.polygonGeoJson);
      final coords = (geo['coordinates'][0] as List)
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
      return {
        Polygon(
          polygonId: const PolygonId('field'),
          points: coords,
          strokeColor: AppTheme.primary,
          strokeWidth: 2,
          fillColor: AppTheme.primary.withValues(alpha: 0.3),
        ),
      };
    } catch (_) {
      return {};
    }
  }

  Color get _severityColor {
    final s = _field.latestAnalysis?.severity ?? 'Normal';
    return switch (s) {
      'Critical' => Colors.red,
      'Warning'  => Colors.orange,
      'Watch'    => Colors.amber,
      _          => AppTheme.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final analysis = _field.latestAnalysis;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── App bar with map ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppTheme.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(_field.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            flexibleSpace: FlexibleSpaceBar(
              background: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(_field.centroidLat, _field.centroidLon),
                  zoom: 15,
                ),
                onMapCreated: _onMapCreated,
                mapType: MapType.satellite,
                polygons: _buildPolygon(),
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Field info row ─────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        _InfoChip(Icons.grass, _field.cropType, Colors.green),
                        const SizedBox(width: 12),
                        _InfoChip(Icons.square_foot, '${_field.areaAcres.toStringAsFixed(1)} ac',
                            Colors.blue),
                        if (_field.sowingDate != null) ...[
                          const SizedBox(width: 12),
                          _InfoChip(Icons.calendar_today,
                            '${_field.sowingDate!.day}/${_field.sowingDate!.month}/${_field.sowingDate!.year}',
                            Colors.orange),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Analyse button ─────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _analysing ? null : _triggerAnalysis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _severityColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: _analysing
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.satellite_alt),
                    label: Text(_analysing
                        ? 'Fetching satellite data...'
                        : analysis != null ? 'Re-analyse Field' : 'Analyse Field'),
                  ),
                ),

                if (analysis == null && !_analysing) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Tap "Analyse Field" to fetch Sentinel-2 satellite data\nand get AI-powered crop health insights.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ),
                ],

                if (analysis != null) ...[
                  const SizedBox(height: 16),

                  // ── Alert banner ───────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _severityColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _severityColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Text(analysis.severityEmoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(analysis.alertTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _severityColor, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── NDVI stats grid ────────────────────────
                  _SectionTitle('Satellite Analysis'),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.1,
                    children: [
                      _StatCard('NDVI Avg', analysis.ndviAvg.toStringAsFixed(2),
                          Icons.bar_chart, AppTheme.primary),
                      _StatCard('Stressed', '${analysis.stressedAreaPct.toStringAsFixed(0)}%',
                          Icons.warning_amber, Colors.red),
                      _StatCard('Healthy', '${analysis.healthyAreaPct.toStringAsFixed(0)}%',
                          Icons.check_circle, Colors.green),
                      _StatCard('Min NDVI', analysis.ndviMin.toStringAsFixed(2),
                          Icons.arrow_downward, Colors.orange),
                      _StatCard('Max NDVI', analysis.ndviMax.toStringAsFixed(2),
                          Icons.arrow_upward, Colors.teal),
                      if (analysis.ndwiAvg != null)
                        _StatCard('Water Index',
                            analysis.ndwiAvg!.toStringAsFixed(2),
                            Icons.water_drop, Colors.blue)
                      else
                        _StatCard('Image Date',
                            '${analysis.imageDate.day}/${analysis.imageDate.month}',
                            Icons.calendar_today, Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // NDVI health bar
                  _NdviHealthBar(
                    stressed: analysis.stressedAreaPct,
                    healthy: analysis.healthyAreaPct,
                  ),
                  const SizedBox(height: 16),

                  // ── NDVI heatmap image ─────────────────────
                  if (analysis.ndviImageUrl != null) ...[
                    _SectionTitle('NDVI Heatmap'),
                    const SizedBox(height: 8),
                    _NdviLegend(),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        analysis.ndviImageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context2, err, stack) => Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text('Heatmap loading...',
                              style: TextStyle(color: Colors.grey))),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── AI Suggestion ──────────────────────────
                  _SectionTitle('AI Advisory'),
                  const SizedBox(height: 8),
                  Card(
                    color: Colors.amber[50],
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.smart_toy, color: AppTheme.primary, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(analysis.aiSuggestion,
                              style: const TextStyle(fontSize: 13, height: 1.5)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (analysis.weakZoneLatLon != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.location_on, color: Colors.red),
                        title: const Text('Weak Zone Detected',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: const Text(
                          'A stressed area was detected. Walk to this location and inspect closely.',
                          style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),
                  Text(
                    'Analysed: ${_formatDate(analysis.analysedAt)} · '
                    'Image: ${_formatDate(analysis.imageDate)}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],

                // ── Field Photo Analysis ────────────────────────
                const SizedBox(height: 12),
                _SectionTitle('Field Photos · AI Analysis'),
                const SizedBox(height: 8),
                _FieldPhotoCard(
                  photos: _photos,
                  analysing: _analyzingPhoto,
                  onCamera:  () => _pickPhoto(ImageSource.camera),
                  onGallery: () => _pickPhoto(ImageSource.gallery),
                  onRemove:  (i) => setState(() => _photos.removeAt(i)),
                  onAnalyze: _analyzePhotos,
                ),

                // ── Field Weather ───────────────────────────────
                const SizedBox(height: 12),
                _SectionTitle('Field Weather'),
                const SizedBox(height: 8),
                if (_weatherLoading)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 10),
                            Text('Loading field weather...',
                              style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (_weather != null) ...[
                  _SmartAdvisoryCard(field: _field, w: _weather!),
                  const SizedBox(height: 8),
                  _FieldForecastStrip(daily: _weather!.daily),
                  const SizedBox(height: 8),
                  _FieldSoilAndGdd(field: _field, w: _weather!),
                ],
                // ── Farming Videos ────────────────────────────
                const SizedBox(height: 12),
                _SectionTitle('Farming Videos'),
                const SizedBox(height: 8),
                _WatchVideosCard(field: _field),

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Text(title,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold));
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
          Text(label,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
            textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _NdviHealthBar extends StatelessWidget {
  final double stressed;
  final double healthy;
  const _NdviHealthBar({required this.stressed, required this.healthy});

  @override
  Widget build(BuildContext context) {
    final moderate = (100 - stressed - healthy).clamp(0.0, 100.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Field Health Distribution',
          style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 16,
            child: Row(
              children: [
                if (stressed > 0)
                  Flexible(
                    flex: stressed.toInt(),
                    child: Container(
                      color: Colors.red[400],
                      child: Center(
                        child: stressed > 10
                            ? Text('${stressed.toStringAsFixed(0)}%',
                                style: const TextStyle(color: Colors.white, fontSize: 8))
                            : null,
                      ),
                    ),
                  ),
                if (moderate > 0)
                  Flexible(
                    flex: moderate.toInt(),
                    child: Container(color: Colors.amber[400]),
                  ),
                if (healthy > 0)
                  Flexible(
                    flex: healthy.toInt(),
                    child: Container(
                      color: Colors.green[400],
                      child: Center(
                        child: healthy > 10
                            ? Text('${healthy.toStringAsFixed(0)}%',
                                style: const TextStyle(color: Colors.white, fontSize: 8))
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _Dot(Colors.red, 'Stressed'),
            const SizedBox(width: 12),
            _Dot(Colors.amber, 'Moderate'),
            const SizedBox(width: 12),
            _Dot(Colors.green, 'Healthy'),
          ],
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot(this.color, this.label);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
    ],
  );
}

class _NdviLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LegendItem(Colors.red[400]!, 'Critical'),
        _LegendItem(Colors.orange[400]!, 'Stress'),
        _LegendItem(Colors.amber[400]!, 'Mild'),
        _LegendItem(Colors.lightGreen[400]!, 'OK'),
        _LegendItem(Colors.green[600]!, 'Healthy'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem(this.color, this.label);
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(height: 10, color: color),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey),
            textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Smart Advisory Card ───────────────────────────────────────────────────────

class _SmartAdvisoryCard extends StatelessWidget {
  final FieldDto field;
  final WeatherData w;
  const _SmartAdvisoryCard({required this.field, required this.w});

  (String, Color, IconData) get _irrigation {
    final rain3d = w.daily.take(3).fold(0.0, (s, d) => s + d.precipitationSum);
    final soilPct = (w.soilMoisture * 200).clamp(0.0, 100.0);
    if (rain3d >= 15) {
      return ('Skip irrigation — ${rain3d.toStringAsFixed(0)}mm rain expected in 3 days',
              Colors.blue, Icons.umbrella_outlined);
    }
    if (soilPct < 20) {
      return ('Irrigate now — soil moisture critically low (${soilPct.toStringAsFixed(0)}%)',
              Colors.red, Icons.water_drop);
    }
    if (soilPct < 35) {
      return ('Consider irrigation — soil at ${soilPct.toStringAsFixed(0)}% moisture',
              Colors.orange, Icons.water_drop_outlined);
    }
    return ('Soil moisture adequate (${soilPct.toStringAsFixed(0)}%) — monitor daily',
            Colors.green, Icons.check_circle_outline);
  }

  (String, Color, IconData) get _rain {
    final now = DateTime.now();
    for (int i = 0; i < w.daily.length; i++) {
      final d = w.daily[i];
      if (d.precipitationSum >= 1 && d.precipitationProbability >= 30) {
        final date = DateTime.parse(d.date);
        final daysAway = date.difference(DateTime(now.year, now.month, now.day)).inDays;
        final dayLabel = daysAway == 0
            ? 'Today'
            : daysAway == 1
                ? 'Tomorrow'
                : 'In $daysAway days (${DateFormat('EEE').format(date)})';
        final mm = d.precipitationSum.toStringAsFixed(1);
        final prob = d.precipitationProbability;
        final intensity = d.precipitationSum >= 20
            ? 'heavy'
            : d.precipitationSum >= 8
                ? 'moderate'
                : 'light';
        final color = daysAway <= 1 ? Colors.blue : Colors.teal;
        return ('$dayLabel — ${mm}mm $intensity rain ($prob% chance)',
                color, Icons.grain);
      }
    }
    return ('No significant rain in next 7 days — plan irrigation accordingly',
            Colors.orange, Icons.wb_sunny_outlined);
  }

  (String, Color, IconData) get _spray {
    final now = DateTime.now();
    final next48 = w.hourly.where((h) {
      try {
        final dt = DateTime.parse(h.time);
        return dt.isAfter(now) && dt.isBefore(now.add(const Duration(hours: 48)));
      } catch (_) { return false; }
    }).toList();
    final good = next48.where(
        (h) => h.windSpeed < 10 && h.precipitationProbability < 30).toList();
    if (good.isEmpty) {
      return ('No spray window in next 48h — high wind or rain expected',
              Colors.red, Icons.air);
    }
    final first = DateTime.parse(good.first.time);
    final dayLabel = first.day == now.day ? 'Today' : 'Tomorrow';
    final timeLabel = DateFormat('ha').format(first);
    return ('Best spray: $dayLabel $timeLabel · ${good.first.windSpeed.toStringAsFixed(0)} km/h wind, ${good.first.precipitationProbability}% rain',
            Colors.green, Icons.air);
  }

  @override
  Widget build(BuildContext context) {
    final irr   = _irrigation;
    final rain  = _rain;
    final spray = _spray;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.tips_and_updates_outlined,
                  color: AppTheme.primary, size: 18),
              const SizedBox(width: 6),
              Text('Smart Advisories',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            _AdvisoryRow(irr.$3,   irr.$1,   irr.$2),
            const Divider(height: 16),
            _AdvisoryRow(rain.$3,  rain.$1,  rain.$2),
            const Divider(height: 16),
            _AdvisoryRow(spray.$3, spray.$1, spray.$2),
          ],
        ),
      ),
    );
  }
}

class _AdvisoryRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _AdvisoryRow(this.icon, this.text, this.color);
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(text,
          style: const TextStyle(fontSize: 13, height: 1.4))),
    ],
  );
}

// ── 7-Day Forecast Strip ──────────────────────────────────────────────────────

class _FieldForecastStrip extends StatelessWidget {
  final List<DailyForecast> daily;
  const _FieldForecastStrip({required this.daily});

  @override
  Widget build(BuildContext context) {
    final days = daily.take(7).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('7-Day Forecast',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: days.asMap().entries.map((e) {
                  final i = e.key;
                  final d = e.value;
                  final date = DateTime.parse(d.date);
                  final label = i == 0
                      ? 'Today'
                      : i == 1 ? 'Tomorrow' : DateFormat('EEE').format(date);
                  final isToday = i == 0;
                  return Container(
                    width: 72,
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppTheme.primary.withValues(alpha: 0.08) : null,
                      borderRadius: BorderRadius.circular(10),
                      border: isToday
                          ? Border.all(color: AppTheme.primary.withValues(alpha: 0.3))
                          : null,
                    ),
                    child: Column(children: [
                      Text(label, style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold,
                        color: isToday ? AppTheme.primary : Colors.black87)),
                      const SizedBox(height: 4),
                      Text(weatherEmoji(d.weatherCode),
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 2),
                      Text('${d.tempMax.toStringAsFixed(0)}°',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                      Text('${d.tempMin.toStringAsFixed(0)}°',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[500])),
                      if (d.precipitationProbability > 0) ...[
                        const SizedBox(height: 2),
                        Text('${d.precipitationProbability}%',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.blueAccent)),
                      ],
                    ]),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Soil Conditions + Growing Degree Days ─────────────────────────────────────

class _FieldSoilAndGdd extends StatelessWidget {
  final FieldDto field;
  final WeatherData w;
  const _FieldSoilAndGdd({required this.field, required this.w});

  static double _baseTemp(String crop) => switch (crop.toLowerCase()) {
    'paddy' || 'rice'    => 10.0,
    'wheat'              => 0.0,
    'maize' || 'corn'    => 10.0,
    'cotton'             => 15.0,
    'sugarcane'          => 16.0,
    'soybean'            => 10.0,
    _                    => 10.0,
  };

  @override
  Widget build(BuildContext context) {
    final soilPct = (w.soilMoisture * 200).clamp(0.0, 100.0);
    final soilTempProgress = ((w.soilTemperature - 10) / 40).clamp(0.0, 1.0);
    final base = _baseTemp(field.cropType);
    final gdd7 = w.daily.take(7).fold(0.0, (sum, d) =>
        sum + max(0.0, (d.tempMax + d.tempMin) / 2 - base));
    final daysSinceSowing = field.sowingDate != null
        ? DateTime.now().difference(field.sowingDate!).inDays
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Soil Conditions',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _SoilBar('Moisture', '${soilPct.toStringAsFixed(0)}%',
                      soilPct / 100, Colors.blue),
                  const SizedBox(height: 8),
                  _SoilBar('Soil Temp', '${w.soilTemperature.toStringAsFixed(1)}°C',
                      soilTempProgress, Colors.orange),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Growing Degree Days',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${gdd7.toStringAsFixed(0)} GDD',
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold,
                        color: AppTheme.primary)),
                  Text('projected next 7 days',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  if (daysSinceSowing != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Day $daysSinceSowing after sowing',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.primary,
                            fontWeight: FontWeight.w500)),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text('Base ${base.toStringAsFixed(0)}°C · ${field.cropType}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Field Photo Card ──────────────────────────────────────────────────────────

class _FieldPhotoCard extends StatelessWidget {
  final List<XFile> photos;
  final bool analysing;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final ValueChanged<int> onRemove;
  final VoidCallback onAnalyze;

  const _FieldPhotoCard({
    required this.photos,
    required this.analysing,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.camera_alt_outlined,
                    color: AppTheme.primary, size: 18),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Capture photos of your crop for AI disease & stress analysis',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                if (photos.length < 4)
                  Text('${photos.length}/4',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),

            // Photo thumbnails
            if (photos.isNotEmpty) ...[
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(photos[i].path),
                          width: 90, height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -6, right: -6,
                        child: GestureDetector(
                          onTap: () => onRemove(i),
                          child: Container(
                            width: 20, height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 13, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Capture buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: photos.length >= 4 ? null : onCamera,
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: photos.length >= 4 ? null : onGallery,
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                    ),
                  ),
                ),
              ],
            ),

            // Analyse button — only shown when photos selected
            if (photos.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: analysing ? null : onAnalyze,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: analysing
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.biotech, size: 18),
                  label: Text(analysing
                      ? 'Analysing ${photos.length} photo${photos.length > 1 ? "s" : ""}...'
                      : 'Analyse ${photos.length} Photo${photos.length > 1 ? "s" : ""} with AI'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SoilBar extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;
  const _SoilBar(this.label, this.value, this.progress, this.color);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress,
          color: color,
          backgroundColor: color.withValues(alpha: 0.15),
          minHeight: 6,
        ),
      ),
    ],
  );
}

// ── Watch Videos card ─────────────────────────────────────────────────────────

class _WatchVideosCard extends StatelessWidget {
  final FieldDto field;
  const _WatchVideosCard({required this.field});

  static const _quickTopics = [
    ('Pest Control', 'pestcontrol', Icons.bug_report_outlined),
    ('Irrigation',   'irrigation',  Icons.water_drop_outlined),
    ('Fertilizer',   'fertilizer',  Icons.science_outlined),
    ('Harvest',      'harvest',     Icons.agriculture_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.play_circle_outline,
                    color: AppTheme.primary, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Watch ${field.cropType} farming videos & tips',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Quick topic buttons
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _quickTopics.map((t) {
                final (label, topic, icon) = t;
                return ActionChip(
                  avatar: Icon(icon, size: 14, color: AppTheme.primary),
                  label: Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.primary)),
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FarmingVideosScreen(
                        initialCrop: field.cropType,
                        fieldName: '${field.name} · $label',
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FarmingVideosScreen(
                      initialCrop: field.cropType,
                      fieldName: field.name,
                    ),
                  ),
                ),
                icon: const Icon(Icons.video_library_outlined, size: 18),
                label: Text('All ${field.cropType} Videos'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
