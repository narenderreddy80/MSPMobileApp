import 'api_client.dart';

class ExpertDto {
  final int id;
  final String userId;
  final String name;
  final String specialization;
  final String? qualification;
  final String? organization;
  final String? bio;
  final String? languages;
  final int experienceYears;
  final double rating;
  final int totalConsultations;
  final bool isAvailable;

  const ExpertDto({
    required this.id,
    required this.userId,
    required this.name,
    required this.specialization,
    this.qualification,
    this.organization,
    this.bio,
    this.languages,
    required this.experienceYears,
    required this.rating,
    required this.totalConsultations,
    required this.isAvailable,
  });

  factory ExpertDto.fromJson(Map<String, dynamic> j) => ExpertDto(
        id: j['id'],
        userId: j['userId'] ?? '',
        name: j['name'] ?? 'Expert',
        specialization: j['specialization'] ?? '',
        qualification: j['qualification'],
        organization: j['organization'],
        bio: j['bio'],
        languages: j['languages'],
        experienceYears: j['experienceYears'] ?? 0,
        rating: (j['rating'] ?? 0).toDouble(),
        totalConsultations: j['totalConsultations'] ?? 0,
        isAvailable: j['isAvailable'] ?? false,
      );
}

class ExpertService {
  final _dio = ApiClient().dio;

  Future<List<ExpertDto>> getAvailableExperts({String? specialization}) async {
    final params = <String, dynamic>{};
    if (specialization != null) params['specialization'] = specialization;
    final res = await _dio.get('/api/Expert/available', queryParameters: params);
    return (res.data as List).map((e) => ExpertDto.fromJson(e)).toList();
  }

  Future<ExpertDto> getExpertById(int id) async {
    final res = await _dio.get('/api/Expert/$id');
    return ExpertDto.fromJson(res.data);
  }

  Future<List<ExpertDto>> searchExperts(String query) async {
    final res = await _dio.get('/api/Expert/search', queryParameters: {'q': query});
    return (res.data as List).map((e) => ExpertDto.fromJson(e)).toList();
  }

  Future<void> setAvailability(bool available) async {
    await _dio.put('/api/Expert/availability', queryParameters: {'available': available});
  }

  /// Returns the expert profile if logged-in user is an expert, null otherwise.
  Future<ExpertDto?> getMyExpertProfile() async {
    final res = await _dio.get('/api/Expert/me');
    if (res.data['isExpert'] == true && res.data['profile'] != null) {
      return ExpertDto.fromJson(res.data['profile']);
    }
    return null;
  }

  /// Register the current user as an expert.
  Future<ExpertDto> registerAsExpert({
    required String specialization,
    String? qualification,
    String? organization,
    String? bio,
    String? languages,
    required int experienceYears,
  }) async {
    final res = await _dio.post('/api/Expert/register', data: {
      'specialization': specialization,
      'qualification': qualification,
      'organization': organization,
      'bio': bio,
      'languages': languages,
      'experienceYears': experienceYears,
    });
    return ExpertDto.fromJson(res.data);
  }
}
