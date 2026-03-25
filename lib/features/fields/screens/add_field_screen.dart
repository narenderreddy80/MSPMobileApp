import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/api/field_service.dart';
import '../../../core/theme/app_theme.dart';

class AddFieldScreen extends StatefulWidget {
  const AddFieldScreen({super.key});

  @override
  State<AddFieldScreen> createState() => _AddFieldScreenState();
}

class _AddFieldScreenState extends State<AddFieldScreen> {
  GoogleMapController? _mapCtrl;
  final List<LatLng> _points = [];
  final _nameCtrl    = TextEditingController();
  final _cropCtrl    = TextEditingController();
  final _searchCtrl  = TextEditingController();
  final _nominatim   = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));
  DateTime? _sowingDate;
  bool _saving = false;
  List<_FieldPlaceSuggestion> _suggestions = [];
  bool _loadingSuggestions = false;
  Timer? _debounce;

  // Default center: India centroid
  static const _initialPos = CameraPosition(
    target: LatLng(17.385, 78.486), // Hyderabad
    zoom: 15,
    tilt: 0,
  );

  @override
  void dispose() {
    _debounce?.cancel();
    _nameCtrl.dispose();
    _cropCtrl.dispose();
    _searchCtrl.dispose();
    _nominatim.close();
    super.dispose();
  }

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
            return _FieldPlaceSuggestion(
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

  void _selectSuggestion(_FieldPlaceSuggestion s) {
    _debounce?.cancel();
    _searchCtrl.text = s.displayName.split(',').first.trim();
    setState(() => _suggestions = []);
    _mapCtrl?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(s.lat, s.lon), 15),
    );
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
  }

  void _onMapTap(LatLng pt) {
    setState(() => _points.add(pt));
  }

  void _undoLastPoint() {
    if (_points.isNotEmpty) setState(() => _points.removeLast());
  }

  void _clearAll() => setState(() => _points.clear());

  Set<Polygon> get _polygons {
    if (_points.length < 3) return {};
    return {
      Polygon(
        polygonId: const PolygonId('field'),
        points: _points,
        strokeColor: AppTheme.primary,
        strokeWidth: 2,
        fillColor: AppTheme.primary.withValues(alpha: 0.25),
      ),
    };
  }

  Set<Marker> get _markers => _points
      .asMap()
      .entries
      .map((e) => Marker(
            markerId: MarkerId('pt_${e.key}'),
            position: e.value,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              e.key == 0
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueCyan,
            ),
            infoWindow: InfoWindow(title: e.key == 0 ? 'Start' : 'Point ${e.key + 1}'),
          ))
      .toSet();

  /// Shoelace formula — area in acres
  double _calcArea() {
    if (_points.length < 3) return 0;
    double sum = 0;
    for (int i = 0; i < _points.length; i++) {
      final j = (i + 1) % _points.length;
      sum += _points[i].longitude * _points[j].latitude;
      sum -= _points[j].longitude * _points[i].latitude;
    }
    final sqDeg = sum.abs() / 2;
    // 1 degree² ≈ 111319² m² at equator — approximate for India
    final sqMeters = sqDeg * 111319 * 111319 * cos(_points.first.latitude * pi / 180);
    return sqMeters / 4046.86; // m² to acres
  }

  LatLng get _centroid {
    if (_points.isEmpty) return const LatLng(0, 0);
    double lat = 0, lon = 0;
    for (final p in _points) {
      lat += p.latitude;
      lon += p.longitude;
    }
    return LatLng(lat / _points.length, lon / _points.length);
  }

  String _buildGeoJson() {
    final coords = _points.map((p) => [p.longitude, p.latitude]).toList();
    coords.add(coords.first); // close ring
    return jsonEncode({
      'type': 'Polygon',
      'coordinates': [coords],
    });
  }

  Future<void> _pickSowingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _sowingDate = picked);
  }

  Future<void> _save() async {
    if (_points.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap at least 3 points to draw your field boundary')));
      return;
    }
    if (_nameCtrl.text.trim().isEmpty || _cropCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter field name and crop type')));
      return;
    }

    setState(() => _saving = true);
    try {
      final centroid = _centroid;
      final area = _calcArea();
      await FieldService().createField(
        name: _nameCtrl.text.trim(),
        cropType: _cropCtrl.text.trim(),
        sowingDate: _sowingDate,
        areaAcres: area,
        polygonGeoJson: _buildGeoJson(),
        centroidLat: centroid.latitude,
        centroidLon: centroid.longitude,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('=== SAVE FIELD ERROR ===');
      debugPrint('Type: ${e.runtimeType}');
      debugPrint('Error: $e');
      if (e is DioException) {
        debugPrint('Status: ${e.response?.statusCode}');
        debugPrint('Response: ${e.response?.data}');
        debugPrint('Message: ${e.message}');
        debugPrint('Type: ${e.type}');
      }
      if (mounted) {
        String msg = 'Failed to save field';
        if (e is DioException) {
          if (e.response != null) {
            msg = 'Server error ${e.response?.statusCode}: ${e.response?.data}';
          } else {
            msg = 'Network error (${e.type.name}): ${e.message}';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 8)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final area = _calcArea();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text('Draw Your Field',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_points.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo, color: Colors.white),
              tooltip: 'Undo last point',
              onPressed: _undoLastPoint,
            ),
          if (_points.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              tooltip: 'Clear all',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: Column(
        children: [
          // Info bar
          Container(
            color: AppTheme.primary.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.touch_app, size: 16, color: AppTheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _points.isEmpty
                        ? 'Tap on the map to mark your field corners'
                        : _points.length < 3
                            ? 'Add ${3 - _points.length} more point(s) to close the field'
                            : '${_points.length} points · ${area.toStringAsFixed(2)} acres',
                    style: const TextStyle(fontSize: 12, color: AppTheme.primary),
                  ),
                ),
                if (_points.length >= 3)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${area.toStringAsFixed(1)} ac',
                      style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ),
              ],
            ),
          ),

          // Map + floating search bar
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _initialPos,
                  onMapCreated: (c) => _mapCtrl = c,
                  onTap: (pt) {
                    setState(() => _suggestions = []);
                    FocusScope.of(context).unfocus();
                    _onMapTap(pt);
                  },
                  mapType: MapType.satellite,
                  markers: _markers,
                  polygons: _polygons,
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                  zoomControlsEnabled: true,
                ),
                // Search bar
                Positioned(
                  top: 10,
                  left: 12,
                  right: 56, // leave room for my-location button
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(10),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search village, city...',
                        prefixIcon: _loadingSuggestions
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ))
                            : const Icon(Icons.search, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _suggestions = []);
                                },
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ),
                // Suggestions dropdown
                if (_suggestions.isNotEmpty)
                  Positioned(
                    top: 58,
                    left: 12,
                    right: 56,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 240),
                          color: Colors.white,
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _suggestions.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, indent: 48),
                            itemBuilder: (_, i) {
                              final s = _suggestions[i];
                              final parts = s.displayName.split(',');
                              final title = parts.first.trim();
                              final sub = parts.length > 1
                                  ? parts.skip(1).take(3).map((e) => e.trim()).join(', ')
                                  : '';
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.location_on_outlined,
                                    color: AppTheme.primary, size: 20),
                                title: Text(title,
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w600)),
                                subtitle: sub.isNotEmpty
                                    ? Text(sub,
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.grey),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis)
                                    : null,
                                onTap: () => _selectSuggestion(s),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Form below map
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Field Name',
                            hintText: 'e.g. North Paddy Field',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.label_outline),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _cropCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Crop Type',
                            hintText: 'e.g. Paddy, Wheat',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.grass),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickSowingDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Sowing Date (optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                        isDense: true,
                      ),
                      child: Text(
                        _sowingDate != null
                            ? '${_sowingDate!.day}/${_sowingDate!.month}/${_sowingDate!.year}'
                            : 'Tap to select',
                        style: TextStyle(
                          color: _sowingDate != null ? Colors.black87 : Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label: Text(_saving ? 'Saving...' : 'Save Field'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldPlaceSuggestion {
  final String displayName;
  final double lat;
  final double lon;
  const _FieldPlaceSuggestion({
    required this.displayName,
    required this.lat,
    required this.lon,
  });
}
