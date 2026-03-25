import 'package:flutter/material.dart';
import '../../../core/api/field_service.dart';
import '../../../core/theme/app_theme.dart';
import 'add_field_screen.dart';
import 'field_detail_screen.dart';

class MyFieldsScreen extends StatefulWidget {
  const MyFieldsScreen({super.key});

  @override
  State<MyFieldsScreen> createState() => _MyFieldsScreenState();
}

class _MyFieldsScreenState extends State<MyFieldsScreen> {
  final _service = FieldService();
  List<FieldDto> _fields = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final fields = await _service.getMyFields();
      if (mounted) setState(() { _fields = fields; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _goAdd() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddFieldScreen()),
    );
    if (added == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MSP Farmers',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('My Fields',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _fields.isEmpty
              ? _EmptyState(onAdd: _goAdd)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _fields.length,
                    itemBuilder: (_, i) => _FieldCard(
                      field: _fields[i],
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FieldDetailScreen(field: _fields[i]),
                          ),
                        );
                        _load();
                      },
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_field_fab',
        onPressed: _goAdd,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: const Text('Add Field', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final FieldDto field;
  final VoidCallback onTap;
  const _FieldCard({required this.field, required this.onTap});

  Color get _severityColor {
    final s = field.latestAnalysis?.severity ?? 'Normal';
    return switch (s) {
      'Critical' => Colors.red,
      'Warning'  => Colors.orange,
      'Watch'    => Colors.amber,
      _          => AppTheme.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final analysis = field.latestAnalysis;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            // Colour strip showing NDVI health
            Container(
              height: 4,
              color: analysis != null ? _severityColor : Colors.grey[300],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // NDVI circle badge
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: _severityColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: analysis != null
                          ? Text((analysis.ndviAvg * 100).toStringAsFixed(0),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _severityColor,
                                fontSize: 15))
                          : const Icon(Icons.satellite_alt,
                              color: Colors.grey, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(field.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text('${field.cropType}  ·  ${field.areaAcres.toStringAsFixed(1)} acres',  // ignore: unnecessary_string_interpolations
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        if (analysis != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${analysis.severityEmoji} ${analysis.alertTitle}',
                            style: TextStyle(
                              fontSize: 11, color: _severityColor,
                              fontWeight: FontWeight.w500),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ] else
                          const Text('No analysis yet — tap to analyse',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const Icon(Icons.chevron_right, color: Colors.grey),
                      if (analysis != null)
                        Text(
                          _daysAgo(analysis.analysedAt),
                          style: const TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // NDVI bar
            if (analysis != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: _NdviBar(
                  healthy: analysis.healthyAreaPct,
                  stressed: analysis.stressedAreaPct,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _daysAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return '1d ago';
    return '${diff}d ago';
  }
}

class _NdviBar extends StatelessWidget {
  final double healthy;
  final double stressed;
  const _NdviBar({required this.healthy, required this.stressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                Flexible(
                  flex: stressed.clamp(0, 100).toInt(),
                  child: Container(color: Colors.red[300]),
                ),
                Flexible(
                  flex: (100 - stressed - healthy).clamp(0, 100).toInt(),
                  child: Container(color: Colors.amber[300]),
                ),
                Flexible(
                  flex: healthy.clamp(0, 100).toInt(),
                  child: Container(color: Colors.green[400]),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _Legend(color: Colors.red, label: 'Stressed ${stressed.toStringAsFixed(0)}%'),
            const SizedBox(width: 12),
            _Legend(color: Colors.green, label: 'Healthy ${healthy.toStringAsFixed(0)}%'),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.satellite_alt, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No fields yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Draw your field on the satellite map to start receiving NDVI crop health analysis',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Add My First Field'),
            ),
          ],
        ),
      ),
    );
  }
}
