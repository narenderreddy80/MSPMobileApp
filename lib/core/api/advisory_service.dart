import 'api_client.dart';

class AdvisoryService {
  final _client = ApiClient();

  Future<String> ask(String question) async {
    final res = await _client.dio.post('/api/Advisory/ask', data: {
      'question': question,
    });
    return res.data['answer'] as String? ?? res.data.toString();
  }
}
