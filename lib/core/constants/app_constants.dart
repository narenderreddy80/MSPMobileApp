class AppConstants {
  // API base URL — change to your deployed server URL for production
  static const String baseUrl = 'http://10.0.2.2:5198'; // Android emulator
  // static const String baseUrl = 'http://localhost:5198'; // iOS simulator

  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userRoleKey = 'user_role';

  static const int maxImages = 5;
  static const int maxImageSizeMb = 5;
}
