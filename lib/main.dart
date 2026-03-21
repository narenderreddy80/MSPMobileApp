import 'package:flutter/material.dart';
import 'core/api/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final token = await ApiClient().token;
  runApp(MSPFarmersApp(isLoggedIn: token != null));
}

class MSPFarmersApp extends StatelessWidget {
  final bool isLoggedIn;
  const MSPFarmersApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MSP Farmers',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login':    (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home':     (_) => const HomeScreen(),
      },
    );
  }
}
