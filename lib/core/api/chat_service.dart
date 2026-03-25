import 'api_client.dart';

class ConversationDto {
  final int id;
  final int listingId;
  final String listingCropName;
  final String? listingThumbnailUrl;
  final String buyerUserId;
  final String buyerName;
  final String sellerUserId;
  final String sellerName;
  final DateTime createdAt;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ConversationDto({
    required this.id,
    required this.listingId,
    required this.listingCropName,
    this.listingThumbnailUrl,
    required this.buyerUserId,
    required this.buyerName,
    required this.sellerUserId,
    required this.sellerName,
    required this.createdAt,
    this.lastMessageText,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ConversationDto.fromJson(Map<String, dynamic> j) => ConversationDto(
    id:                   j['id'] as int,
    listingId:            j['listingId'] as int,
    listingCropName:      j['listingCropName'] as String,
    listingThumbnailUrl:  j['listingThumbnailUrl'] as String?,
    buyerUserId:          j['buyerUserId'] as String,
    buyerName:            j['buyerName'] as String,
    sellerUserId:         j['sellerUserId'] as String,
    sellerName:           j['sellerName'] as String,
    createdAt:            DateTime.parse(j['createdAt'] as String),
    lastMessageText:      j['lastMessageText'] as String?,
    lastMessageAt:        j['lastMessageAt'] == null ? null : DateTime.parse(j['lastMessageAt'] as String),
    unreadCount:          (j['unreadCount'] as int?) ?? 0,
  );
}

class MessageDto {
  final int id;
  final int conversationId;
  final String senderUserId;
  final String senderName;
  final String text;
  final DateTime sentAt;

  const MessageDto({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    required this.senderName,
    required this.text,
    required this.sentAt,
  });

  factory MessageDto.fromJson(Map<String, dynamic> j) => MessageDto(
    id:             j['id'] as int,
    conversationId: j['conversationId'] as int,
    senderUserId:   j['senderUserId'] as String,
    senderName:     j['senderName'] as String,
    text:           j['text'] as String,
    sentAt:         DateTime.parse(j['sentAt'] as String),
  );
}

class ChatService {
  final _client = ApiClient();

  Future<ConversationDto> getOrCreateConversation(int listingId) async {
    final res = await _client.dio.post('/api/Chat/conversations',
        data: {'listingId': listingId});
    return ConversationDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ConversationDto>> getMyConversations() async {
    final res = await _client.dio.get('/api/Chat/conversations');
    return (res.data as List<dynamic>)
        .map((e) => ConversationDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MessageDto>> getMessages(int conversationId, {int limit = 50, int? before}) async {
    final res = await _client.dio.get(
      '/api/Chat/conversations/$conversationId/messages',
      queryParameters: {
        'limit': limit,
        'before': before,
      }..removeWhere((k, v) => v == null),
    );
    return (res.data as List<dynamic>)
        .map((e) => MessageDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MessageDto> sendMessage(int conversationId, String text) async {
    final res = await _client.dio.post(
        '/api/Chat/conversations/$conversationId/messages',
        data: {'text': text});
    return MessageDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<int> getUnreadCount() async {
    final res = await _client.dio.get('/api/Chat/unread-count');
    return (res.data as Map<String, dynamic>)['count'] as int;
  }

  Future<void> markConversationRead(int conversationId) async {
    await _client.dio.post('/api/Chat/conversations/$conversationId/read');
  }

  Future<List<ConversationDto>> getListingConversations(int listingId) async {
    final res = await _client.dio.get('/api/Chat/conversations',
        queryParameters: {'listingId': listingId});
    return (res.data as List<dynamic>)
        .map((e) => ConversationDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
