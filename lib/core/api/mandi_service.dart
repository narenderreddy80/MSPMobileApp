import 'api_client.dart';

class MandiPriceDto {
  final String state;
  final String district;
  final String market;
  final String commodity;
  final String variety;
  final String grade;
  final String arrivalDate;
  final double minPrice;
  final double maxPrice;
  final double modalPrice;

  const MandiPriceDto({
    required this.state,
    required this.district,
    required this.market,
    required this.commodity,
    required this.variety,
    required this.grade,
    required this.arrivalDate,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
  });

  factory MandiPriceDto.fromJson(Map<String, dynamic> j) => MandiPriceDto(
    state:       j['state'] ?? '',
    district:    j['district'] ?? '',
    market:      j['market'] ?? '',
    commodity:   j['commodity'] ?? '',
    variety:     j['variety'] ?? '',
    grade:       j['grade'] ?? '',
    arrivalDate: j['arrivalDate'] ?? '',
    minPrice:    (j['minPrice'] ?? 0).toDouble(),
    maxPrice:    (j['maxPrice'] ?? 0).toDouble(),
    modalPrice:  (j['modalPrice'] ?? 0).toDouble(),
  );
}

class MandiHistoryDto {
  final String arrivalDate;
  final double minPrice;
  final double maxPrice;
  final double modalPrice;

  const MandiHistoryDto({
    required this.arrivalDate,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
  });

  factory MandiHistoryDto.fromJson(Map<String, dynamic> j) => MandiHistoryDto(
    arrivalDate: j['arrivalDate'] ?? '',
    minPrice:    (j['minPrice']   ?? 0).toDouble(),
    maxPrice:    (j['maxPrice']   ?? 0).toDouble(),
    modalPrice:  (j['modalPrice'] ?? 0).toDouble(),
  );
}

class MandiService {
  final _client = ApiClient();

  Future<List<MandiPriceDto>> getPrices({
    String? state,
    String? commodity,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      if (state != null && state.isNotEmpty) 'state': state,
      if (commodity != null && commodity.isNotEmpty) 'commodity': commodity,
    };

    final res = await _client.dio.get(
      '/api/Mandi/prices',
      queryParameters: params,
    );

    final list = res.data as List<dynamic>;
    return list.map((e) => MandiPriceDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MandiHistoryDto>> getHistory({
    required String commodity,
    required String market,
    String? variety,
    int days = 30,
  }) async {
    final params = <String, dynamic>{
      'commodity': commodity,
      'market': market,
      'days': days,
      if (variety != null && variety.isNotEmpty) 'variety': variety,
    };

    final res = await _client.dio.get(
      '/api/Mandi/history',
      queryParameters: params,
    );

    final list = res.data as List<dynamic>;
    return list.map((e) => MandiHistoryDto.fromJson(e as Map<String, dynamic>)).toList();
  }
}
