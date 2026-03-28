import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/theme_service.dart';
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
  String? _fullName;
  String _role = 'Farmer';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    const storage = FlutterSecureStorage();
    final email  = await storage.read(key: AppConstants.userEmailKey);
    final userId = await storage.read(key: AppConstants.userIdKey);
    final fullName = await storage.read(key: 'user_full_name');
    final role = await storage.read(key: AppConstants.userRoleKey);
    setState(() {
      _email = email;
      _userId = userId;
      _fullName = fullName;
      _role = role ?? 'Farmer';
    });
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
              backgroundColor: _role == 'Scientist'
                  ? Colors.green.withValues(alpha: 0.15)
                  : AppTheme.primary.withValues(alpha: 0.15),
              child: Icon(
                _role == 'Scientist' ? Icons.science : Icons.person,
                size: 56,
                color: _role == 'Scientist' ? Colors.green : AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(_fullName ?? _email ?? 'User',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold)),
            if (_email != null && _fullName != null) ...[
              const SizedBox(height: 4),
              Text(_email!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _role == 'Scientist'
                    ? Colors.green.withValues(alpha: 0.1)
                    : AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_role,
                style: TextStyle(
                  color: _role == 'Scientist' ? Colors.green : AppTheme.primary,
                  fontWeight: FontWeight.w500,
                )),
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

            // ── Theme Setting ──────────────────────────────────────
            _ThemeSelector(),
            const SizedBox(height: 8),

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

// ─── Theme Selector ───────────────────────────────────────────────────────────
class _ThemeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette_outlined, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Home Screen Theme',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<DashboardTheme>(
              valueListenable: ThemeService().themeNotifier,
              builder: (context, current, _) {
                return Row(
                  children: [
                    Expanded(
                      child: _ThemeOption(
                        label: 'Green',
                        subtitle: 'Classic',
                        icon: Icons.eco,
                        color: AppTheme.primary,
                        selected: current == DashboardTheme.green,
                        onTap: () => ThemeService().setTheme(DashboardTheme.green),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ThemeOption(
                        label: 'Tiles',
                        subtitle: 'Modern',
                        icon: Icons.grid_view,
                        color: const Color(0xFF1565C0),
                        selected: current == DashboardTheme.tiles,
                        onTap: () => ThemeService().setTheme(DashboardTheme.tiles),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ThemeOption(
                        label: 'Cards',
                        subtitle: 'Smart',
                        icon: Icons.dashboard_customize,
                        color: const Color(0xFF6A1B9A),
                        selected: current == DashboardTheme.tiles2,
                        onTap: () => ThemeService().setTheme(DashboardTheme.tiles2),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selected ? color : Colors.grey[700],
                    fontSize: 13)),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 10,
                    color: selected ? color.withValues(alpha: 0.8) : Colors.grey)),
            if (selected) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Active',
                    style: TextStyle(color: Colors.white, fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
