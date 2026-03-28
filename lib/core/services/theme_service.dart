import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum DashboardTheme { green, tiles, tiles2 }

class ThemeService {
  static final ThemeService _instance = ThemeService._();
  factory ThemeService() => _instance;
  ThemeService._() {
    _init();
  }

  static const _key = 'dashboard_theme';

  final ValueNotifier<DashboardTheme> themeNotifier =
      ValueNotifier<DashboardTheme>(DashboardTheme.green);

  Future<void> _init() async {
    const storage = FlutterSecureStorage();
    final saved = await storage.read(key: _key);
    if (saved == 'tiles') {
      themeNotifier.value = DashboardTheme.tiles;
    } else if (saved == 'tiles2') {
      themeNotifier.value = DashboardTheme.tiles2;
    }
  }

  Future<void> setTheme(DashboardTheme theme) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: _key, value: theme.name);
    themeNotifier.value = theme;
  }

  DashboardTheme get current => themeNotifier.value;
}
