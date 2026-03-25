import 'api_client.dart';

class RatingDto {
  final int id;
  final String raterUserId;
  final String raterName;
  final int score;
  final String? comment;
  final DateTime createdAt;

  const RatingDto({
    required this.id,
    required this.raterUserId,
    required this.raterName,
    required this.score,
    this.comment,
    required this.createdAt,
  });

  factory RatingDto.fromJson(Map<String, dynamic> j) => RatingDto(
        id: j['id'] as int,
        raterUserId: j['raterUserId'] as String,
        raterName: j['raterName'] as String,
        score: j['score'] as int,
        comment: j['comment'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

class UserRatingSummary {
  final double averageScore;
  final int totalCount;
  final List<RatingDto> reviews;

  const UserRatingSummary({
    required this.averageScore,
    required this.totalCount,
    required this.reviews,
  });

  factory UserRatingSummary.fromJson(Map<String, dynamic> j) => UserRatingSummary(
        averageScore: (j['averageScore'] as num).toDouble(),
        totalCount: j['totalCount'] as int,
        reviews: (j['reviews'] as List)
            .map((e) => RatingDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class RatingService {
  final _dio = ApiClient().dio;

  Future<UserRatingSummary> getUserRatings(String userId) async {
    final res = await _dio.get('/api/Rating/user/$userId');
    return UserRatingSummary.fromJson(res.data as Map<String, dynamic>);
  }

  Future<RatingDto?> getMyRatingForUser(String rateeUserId) async {
    final res = await _dio.get('/api/Rating/my-rating/$rateeUserId');
    if (res.data == null) return null;
    return RatingDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<RatingDto> submitRating({
    required String rateeUserId,
    required int score,
    String? comment,
  }) async {
    final res = await _dio.post('/api/Rating', data: {
      'rateeUserId': rateeUserId,
      'score': score,
      'comment': comment,
    });
    return RatingDto.fromJson(res.data as Map<String, dynamic>);
  }
}
