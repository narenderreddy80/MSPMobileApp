import 'package:dio/dio.dart';
import 'api_client.dart';

class CropAnalysisService {
  final _client = ApiClient();

  Future<Map<String, dynamic>> analyze(
      List<String> imagePaths, String? notes) async {
    final formData = FormData();

    for (final path in imagePaths) {
      formData.files.add(MapEntry(
        'images',
        await MultipartFile.fromFile(path),
      ));
    }
    if (notes != null && notes.isNotEmpty) {
      formData.fields.add(MapEntry('notes', notes));
    }

    final res = await _client.dio.post(
      '/api/CropImageAnalysis/analyze',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getHistory() async {
    final res = await _client.dio.get('/api/CropImageAnalysis/history');
    return res.data as List<dynamic>;
  }
}
