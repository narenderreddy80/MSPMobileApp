import 'api_client.dart';

class FieldDto {
  final int id;
  final String name;
  final String cropType;
  final DateTime? sowingDate;
  final double areaAcres;
  final String polygonGeoJson;
  final double centroidLat;
  final double centroidLon;
  final String? tileId;
  final DateTime createdAt;
  final FieldAnalysisDto? latestAnalysis;

  const FieldDto({
    required this.id,
    required this.name,
    required this.cropType,
    this.sowingDate,
    required this.areaAcres,
    required this.polygonGeoJson,
    required this.centroidLat,
    required this.centroidLon,
    this.tileId,
    required this.createdAt,
    this.latestAnalysis,
  });

  factory FieldDto.fromJson(Map<String, dynamic> j) => FieldDto(
    id: j['id'],
    name: j['name'] ?? '',
    cropType: j['cropType'] ?? '',
    sowingDate: j['sowingDate'] != null ? DateTime.parse(j['sowingDate']) : null,
    areaAcres: (j['areaAcres'] ?? 0).toDouble(),
    polygonGeoJson: j['polygonGeoJson'] ?? '',
    centroidLat: (j['centroidLat'] ?? 0).toDouble(),
    centroidLon: (j['centroidLon'] ?? 0).toDouble(),
    tileId: j['tileId'],
    createdAt: DateTime.parse(j['createdAt']),
    latestAnalysis: j['latestAnalysis'] != null
        ? FieldAnalysisDto.fromJson(j['latestAnalysis'])
        : null,
  );
}

class FieldAnalysisDto {
  final int id;
  final double ndviAvg;
  final double ndviMin;
  final double ndviMax;
  final double stressedAreaPct;
  final double healthyAreaPct;
  final double? ndwiAvg;
  final String? weakZoneLatLon;
  final String aiSuggestion;
  final String alertTitle;
  final String severity;
  final DateTime imageDate;
  final DateTime analysedAt;
  final String? ndviImageUrl;

  const FieldAnalysisDto({
    required this.id,
    required this.ndviAvg,
    required this.ndviMin,
    required this.ndviMax,
    required this.stressedAreaPct,
    required this.healthyAreaPct,
    this.ndwiAvg,
    this.weakZoneLatLon,
    required this.aiSuggestion,
    required this.alertTitle,
    required this.severity,
    required this.imageDate,
    required this.analysedAt,
    this.ndviImageUrl,
  });

  factory FieldAnalysisDto.fromJson(Map<String, dynamic> j) => FieldAnalysisDto(
    id: j['id'],
    ndviAvg: (j['ndviAvg'] ?? 0).toDouble(),
    ndviMin: (j['ndviMin'] ?? 0).toDouble(),
    ndviMax: (j['ndviMax'] ?? 0).toDouble(),
    stressedAreaPct: (j['stressedAreaPct'] ?? 0).toDouble(),
    healthyAreaPct: (j['healthyAreaPct'] ?? 0).toDouble(),
    ndwiAvg: j['ndwiAvg'] != null ? (j['ndwiAvg']).toDouble() : null,
    weakZoneLatLon: j['weakZoneLatLon'],
    aiSuggestion: j['aiSuggestion'] ?? '',
    alertTitle: j['alertTitle'] ?? '',
    severity: j['severity'] ?? 'Normal',
    imageDate: DateTime.parse(j['imageDate']),
    analysedAt: DateTime.parse(j['analysedAt']),
    ndviImageUrl: j['ndviImageUrl'],
  );

  bool get isCritical => severity == 'Critical';
  bool get isWarning  => severity == 'Warning';

  String get severityEmoji => switch (severity) {
    'Critical' => '🔴',
    'Warning'  => '🟠',
    'Watch'    => '🟡',
    _          => '🟢',
  };
}

class FieldService {
  final _client = ApiClient();

  Future<List<FieldDto>> getMyFields() async {
    final res = await _client.dio.get('/api/Field');
    return (res.data as List).map((e) => FieldDto.fromJson(e)).toList();
  }

  Future<FieldDto> createField({
    required String name,
    required String cropType,
    DateTime? sowingDate,
    required double areaAcres,
    required String polygonGeoJson,
    required double centroidLat,
    required double centroidLon,
  }) async {
    final res = await _client.dio.post('/api/Field', data: {
      'name': name,
      'cropType': cropType,
      'sowingDate': sowingDate?.toUtc().toIso8601String(),
      'areaAcres': areaAcres,
      'polygonGeoJson': polygonGeoJson,
      'centroidLat': centroidLat,
      'centroidLon': centroidLon,
    });
    return FieldDto.fromJson(res.data);
  }

  Future<FieldAnalysisDto> triggerAnalysis(int fieldId) async {
    final res = await _client.dio.post('/api/Field/$fieldId/analyse');
    return FieldAnalysisDto.fromJson(res.data);
  }

  Future<FieldAnalysisDto?> getLatestAnalysis(int fieldId) async {
    try {
      final res = await _client.dio.get('/api/Field/$fieldId/analysis');
      return FieldAnalysisDto.fromJson(res.data);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteField(int fieldId) async {
    await _client.dio.delete('/api/Field/$fieldId');
  }
}
