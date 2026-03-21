import 'api_client.dart';

class AuthService {
  final _client = ApiClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _client.dio.post('/api/Auth/login', data: {
      'email': email,
      'password': password,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<void> register(
      String email, String password, String role, String fullName) async {
    await _client.dio.post('/api/Auth/register', data: {
      'email': email,
      'password': password,
      'role': role,
      'fullName': fullName,
    });
  }
}
