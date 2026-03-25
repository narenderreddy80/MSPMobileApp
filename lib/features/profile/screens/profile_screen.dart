import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/rating_widgets.dart';
import '../../marketplace/screens/conversations_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _email;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    const storage = FlutterSecureStorage();
    final email  = await storage.read(key: AppConstants.userEmailKey);
    final userId = await storage.read(key: AppConstants.userIdKey);
    setState(() { _email = email; _userId = userId; });
  }

  Future<void> _logout() async {
    await ApiClient().clearToken();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 48,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
              child: const Icon(Icons.person, size: 56, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            Text(_email ?? 'Farmer',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Farmer',
                style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 32),

            _menuItem(context, Icons.history, 'Analysis History', () =>
              Navigator.pushNamed(context, '/history')),
            _menuItem(context, Icons.eco, 'Crop Directory', () =>
              Navigator.pushNamed(context, '/crops')),
            _menuItem(context, Icons.smart_toy, 'AI Advisory', () =>
              Navigator.pushNamed(context, '/advisory')),
            _menuItem(context, Icons.chat_outlined, 'My Chats', () =>
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const ConversationsScreen()))),
            const Divider(height: 32),

            // ── My Reviews ────────────────────────────────────────
            if (_userId != null)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: UserReviewsSection(
                  userId: _userId!,
                  userName: _email ?? 'Me',
                  showRateButton: false,
                ),
              ),

            const Divider(height: 32),
            _menuItem(context, Icons.logout, 'Logout', _logout,
              color: AppTheme.error),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(BuildContext ctx, IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    final c = color ?? Colors.black87;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: color ?? AppTheme.primary),
        title: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w500)),
        trailing: color == null
            ? const Icon(Icons.chevron_right, color: Colors.grey)
            : null,
        onTap: onTap,
      ),
    );
  }
}
