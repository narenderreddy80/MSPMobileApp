import 'api_client.dart';

class ConsultationDto {
  final int id;
  final String farmerUserId;
  final String farmerName;
  final int expertId;
  final String expertName;
  final String expertSpecialization;
  final String status;
  final String? cropType;
  final String? problemDescription;
  final String? channelName;
  final String? agoraToken;
  final DateTime requestedAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int durationMinutes;
  final String? aiSummary;
  final String? aiRecommendations;
  final String? expertNotes;
  final int? farmerRating;
  final String? farmerFeedback;

  const ConsultationDto({
    required this.id,
    required this.farmerUserId,
    required this.farmerName,
    required this.expertId,
    required this.expertName,
    required this.expertSpecialization,
    required this.status,
    this.cropType,
    this.problemDescription,
    this.channelName,
    this.agoraToken,
    required this.requestedAt,
    this.startedAt,
    this.endedAt,
    required this.durationMinutes,
    this.aiSummary,
    this.aiRecommendations,
    this.expertNotes,
    this.farmerRating,
    this.farmerFeedback,
  });

  factory ConsultationDto.fromJson(Map<String, dynamic> j) => ConsultationDto(
        id: j['id'],
        farmerUserId: j['farmerUserId'] ?? '',
        farmerName: j['farmerName'] ?? 'Farmer',
        expertId: j['expertId'] ?? 0,
        expertName: j['expertName'] ?? 'Expert',
        expertSpecialization: j['expertSpecialization'] ?? '',
        status: j['status'] ?? 'Unknown',
        cropType: j['cropType'],
        problemDescription: j['problemDescription'],
        channelName: j['channelName'],
        agoraToken: j['agoraToken'],
        requestedAt: DateTime.tryParse(j['requestedAt'] ?? '') ?? DateTime.now(),
        startedAt: j['startedAt'] != null ? DateTime.tryParse(j['startedAt']) : null,
        endedAt: j['endedAt'] != null ? DateTime.tryParse(j['endedAt']) : null,
        durationMinutes: j['durationMinutes'] ?? 0,
        aiSummary: j['aiSummary'],
        aiRecommendations: j['aiRecommendations'],
        expertNotes: j['expertNotes'],
        farmerRating: j['farmerRating'],
        farmerFeedback: j['farmerFeedback'],
      );
}

class ConsultationNoteDto {
  final int id;
  final String authorUserId;
  final String authorRole;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;

  const ConsultationNoteDto({
    required this.id,
    required this.authorUserId,
    required this.authorRole,
    required this.content,
    this.imageUrl,
    required this.createdAt,
  });

  factory ConsultationNoteDto.fromJson(Map<String, dynamic> j) => ConsultationNoteDto(
        id: j['id'],
        authorUserId: j['authorUserId'] ?? '',
        authorRole: j['authorRole'] ?? '',
        content: j['content'] ?? '',
        imageUrl: j['imageUrl'],
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      );
}

class ConsultationService {
  final _dio = ApiClient().dio;

  Future<ConsultationDto> requestConsultation({
    required int expertId,
    String? cropType,
    String? problemDescription,
    int? fieldId,
  }) async {
    final res = await _dio.post('/api/Consultation/request', data: {
      'expertId': expertId,
      'cropType': cropType,
      'problemDescription': problemDescription,
      'fieldId': fieldId,
    });
    return ConsultationDto.fromJson(res.data);
  }

  Future<ConsultationDto> getSession(int id) async {
    final res = await _dio.get('/api/Consultation/$id');
    return ConsultationDto.fromJson(res.data);
  }

  Future<List<ConsultationDto>> getMySessions() async {
    final res = await _dio.get('/api/Consultation/my-sessions');
    return (res.data as List).map((e) => ConsultationDto.fromJson(e)).toList();
  }

  Future<ConsultationDto> startCall(int sessionId) async {
    final res = await _dio.post('/api/Consultation/$sessionId/start-call');
    return ConsultationDto.fromJson(res.data);
  }

  Future<ConsultationDto> endCall(int sessionId) async {
    final res = await _dio.post('/api/Consultation/$sessionId/end-call');
    return ConsultationDto.fromJson(res.data);
  }

  Future<ConsultationNoteDto> addNote(int sessionId, String content, {String? imageUrl}) async {
    final res = await _dio.post('/api/Consultation/$sessionId/notes', data: {
      'content': content,
      'imageUrl': imageUrl,
    });
    return ConsultationNoteDto.fromJson(res.data);
  }

  Future<List<ConsultationNoteDto>> getNotes(int sessionId) async {
    final res = await _dio.get('/api/Consultation/$sessionId/notes');
    return (res.data as List).map((e) => ConsultationNoteDto.fromJson(e)).toList();
  }

  Future<String> getAiSuggestion(int sessionId, String question) async {
    final res = await _dio.post('/api/Consultation/$sessionId/ai-suggest', data: {
      'question': question,
    });
    return res.data['suggestion'] ?? '';
  }

  Future<ConsultationDto> rateSession(int sessionId, int rating, {String? feedback}) async {
    final res = await _dio.post('/api/Consultation/$sessionId/rate', data: {
      'rating': rating,
      'feedback': feedback,
    });
    return ConsultationDto.fromJson(res.data);
  }

  Future<ConsultationDto> generateSummary(int sessionId) async {
    final res = await _dio.post('/api/Consultation/$sessionId/summary');
    return ConsultationDto.fromJson(res.data);
  }

  // Expert endpoints
  Future<List<ConsultationDto>> getExpertPending() async {
    final res = await _dio.get('/api/Consultation/expert/pending');
    return (res.data as List).map((e) => ConsultationDto.fromJson(e)).toList();
  }

  Future<List<ConsultationDto>> getExpertSessions() async {
    final res = await _dio.get('/api/Consultation/expert/sessions');
    return (res.data as List).map((e) => ConsultationDto.fromJson(e)).toList();
  }

  Future<ConsultationDto> acceptConsultation(int sessionId) async {
    final res = await _dio.post('/api/Consultation/$sessionId/accept');
    return ConsultationDto.fromJson(res.data);
  }
}
