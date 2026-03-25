import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';

class ListingSummaryDto {
  final int id;
  final String sellerUserId;
  final String sellerName;
  final String cropName;
  final String variety;
  final double quantityValue;
  final String quantityUnit;
  final double pricePerUnit;
  final String state;
  final String district;
  final String status;
  final DateTime createdAt;
  final String? thumbnailUrl;

  const ListingSummaryDto({
    required this.id,
    required this.sellerUserId,
    required this.sellerName,
    required this.cropName,
    required this.variety,
    required this.quantityValue,
    required this.quantityUnit,
    required this.pricePerUnit,
    required this.state,
    required this.district,
    required this.status,
    required this.createdAt,
    this.thumbnailUrl,
  });

  factory ListingSummaryDto.fromJson(Map<String, dynamic> j) => ListingSummaryDto(
    id:            j['id'] as int,
    sellerUserId:  j['sellerUserId'] as String,
    sellerName:    j['sellerName'] as String,
    cropName:      j['cropName'] as String,
    variety:       j['variety'] as String? ?? '',
    quantityValue: (j['quantityValue'] as num).toDouble(),
    quantityUnit:  j['quantityUnit'] as String,
    pricePerUnit:  (j['pricePerUnit'] as num).toDouble(),
    state:         j['state'] as String,
    district:      j['district'] as String,
    status:        j['status'] as String,
    createdAt:     DateTime.parse(j['createdAt'] as String),
    thumbnailUrl:  j['thumbnailUrl'] as String?,
  );
}

class ListingDetailDto extends ListingSummaryDto {
  final String? notes;
  final List<String> imageUrls;

  const ListingDetailDto({
    required super.id,
    required super.sellerUserId,
    required super.sellerName,
    required super.cropName,
    required super.variety,
    required super.quantityValue,
    required super.quantityUnit,
    required super.pricePerUnit,
    required super.state,
    required super.district,
    required super.status,
    required super.createdAt,
    super.thumbnailUrl,
    this.notes,
    required this.imageUrls,
  });

  factory ListingDetailDto.fromJson(Map<String, dynamic> j) => ListingDetailDto(
    id:            j['id'] as int,
    sellerUserId:  j['sellerUserId'] as String,
    sellerName:    j['sellerName'] as String,
    cropName:      j['cropName'] as String,
    variety:       j['variety'] as String? ?? '',
    quantityValue: (j['quantityValue'] as num).toDouble(),
    quantityUnit:  j['quantityUnit'] as String,
    pricePerUnit:  (j['pricePerUnit'] as num).toDouble(),
    state:         j['state'] as String,
    district:      j['district'] as String,
    status:        j['status'] as String,
    createdAt:     DateTime.parse(j['createdAt'] as String),
    thumbnailUrl:  j['thumbnailUrl'] as String?,
    notes:         j['notes'] as String?,
    imageUrls:     (j['imageUrls'] as List<dynamic>).cast<String>(),
  );
}

class PagedListings {
  final int total;
  final List<ListingSummaryDto> items;
  const PagedListings(this.total, this.items);
}

class PagedDetailListings {
  final int total;
  final List<ListingDetailDto> items;
  const PagedDetailListings(this.total, this.items);
}

class ListingService {
  final _client = ApiClient();

  Future<PagedListings> browse({
    String? cropName,
    String? state,
    double? minPrice,
    double? maxPrice,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (cropName != null && cropName.isNotEmpty) queryParams['cropName'] = cropName;
    if (state != null && state.isNotEmpty) queryParams['state'] = state;
    if (minPrice != null) queryParams['minPrice'] = minPrice;
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice;
    final res = await _client.dio.get('/api/Listings', queryParameters: queryParams);
    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>)
        .map((e) => ListingSummaryDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return PagedListings(data['total'] as int, items);
  }

  Future<ListingDetailDto> getDetail(int id) async {
    final res = await _client.dio.get('/api/Listings/$id');
    return ListingDetailDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PagedDetailListings> getMyListings({
    String status = 'Active',
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await _client.dio.get('/api/Listings/mine', queryParameters: {
      'status': status,
      'limit': limit,
      'offset': offset,
    });
    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>)
        .map((e) => ListingDetailDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return PagedDetailListings(data['total'] as int, items);
  }

  Future<ListingDetailDto> createListing({
    required String cropName,
    String? variety,
    required double quantityValue,
    required String quantityUnit,
    required double pricePerUnit,
    required String state,
    required String district,
    String? notes,
    List<File> images = const [],
  }) async {
    final formData = FormData.fromMap({
      'cropName': cropName,
      if (variety != null && variety.isNotEmpty) 'variety': variety,
      'quantityValue': quantityValue,
      'quantityUnit': quantityUnit,
      'pricePerUnit': pricePerUnit,
      'state': state,
      'district': district,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (images.isNotEmpty)
        'images': await Future.wait(images.map((f) async =>
            MultipartFile.fromFile(f.path, filename: f.path.split('/').last))),
    });
    final res = await _client.dio.post('/api/Listings',
        data: formData,
        options: Options(contentType: 'multipart/form-data'));
    return ListingDetailDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> updateStatus(int id, String status) async {
    await _client.dio.patch('/api/Listings/$id/status',
        data: {'status': status});
  }
}
