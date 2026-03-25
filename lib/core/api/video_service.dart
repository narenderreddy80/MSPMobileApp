import 'api_client.dart';

class VideoItemDto {
  final String videoId;
  final String title;
  final String channelTitle;
  final String thumbnailUrl;
  final String publishedAt;

  const VideoItemDto({
    required this.videoId,
    required this.title,
    required this.channelTitle,
    required this.thumbnailUrl,
    required this.publishedAt,
  });

  factory VideoItemDto.fromJson(Map<String, dynamic> j) => VideoItemDto(
        videoId:      j['videoId'] ?? '',
        title:        j['title'] ?? '',
        channelTitle: j['channelTitle'] ?? '',
        thumbnailUrl: j['thumbnailUrl'] ?? '',
        publishedAt:  j['publishedAt'] ?? '',
      );

  String get youtubeUrl => 'https://www.youtube.com/watch?v=$videoId';
  String get thumbnailFallback =>
      'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
}

class VideoSearchResult {
  final List<VideoItemDto> items;
  final String? nextPageToken;

  const VideoSearchResult({required this.items, this.nextPageToken});

  factory VideoSearchResult.fromJson(Map<String, dynamic> j) =>
      VideoSearchResult(
        items: (j['items'] as List? ?? [])
            .map((e) => VideoItemDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextPageToken: j['nextPageToken'],
      );
}

class VideoService {
  final _client = ApiClient();

  Future<VideoSearchResult> getFarmingVideos({
    String crop = 'farming',
    String? topic,
    String language = 'hi',
    String? pageToken,
  }) async {
    final res = await _client.dio.get('/api/Videos/farming', queryParameters: {
      'crop': crop,
      if (topic != null) 'topic': topic,
      'language': language,
      if (pageToken != null) 'pageToken': pageToken,
    });
    return VideoSearchResult.fromJson(res.data as Map<String, dynamic>);
  }

  /// Personalized feed based on user's fields, crop health, and market activity.
  Future<VideoSearchResult> getPersonalizedFeed({
    String language = 'hi',
    String? pageToken,
  }) async {
    final res = await _client.dio.get('/api/Videos/feed', queryParameters: {
      'language': language,
      if (pageToken != null) 'pageToken': pageToken,
    });
    return VideoSearchResult.fromJson(res.data as Map<String, dynamic>);
  }
}
