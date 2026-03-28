import 'package:flutter/material.dart';
import '../../../core/api/expert_service.dart';
import '../../../core/api/consultation_service.dart';
import '../../../core/theme/app_theme.dart';
import 'video_call_screen.dart';
import 'consultation_history_screen.dart';

class ExpertDashboardScreen extends StatefulWidget {
  const ExpertDashboardScreen({super.key});

  @override
  State<ExpertDashboardScreen> createState() => _ExpertDashboardScreenState();
}

class _ExpertDashboardScreenState extends State<ExpertDashboardScreen> {
  final _expertService = ExpertService();
  final _consultationService = ConsultationService();
  List<ConsultationDto> _pending = [];
  List<ConsultationDto> _recent = [];
  bool _loading = true;
  bool _available = true;
  bool _togglingAvailability = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Fetch actual availability from backend
      final profile = await _expertService.getMyExpertProfile();
      final pending = await _consultationService.getExpertPending();
      final recent = await _consultationService.getExpertSessions();
      if (mounted) {
        setState(() {
          if (profile != null) _available = profile.isAvailable;
          _pending = pending;
          _recent = recent.take(10).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleAvailability() async {
    setState(() => _togglingAvailability = true);
    try {
      _available = !_available;
      await _expertService.setAvailability(_available);
    } catch (_) {
      _available = !_available;
    }
    if (mounted) setState(() => _togglingAvailability = false);
  }

  Future<void> _acceptRequest(ConsultationDto session) async {
    try {
      final accepted = await _consultationService.acceptConsultation(session.id);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoCallScreen(
              session: accepted,
              expertName: 'You',
            ),
          ),
        );
        _load(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Expert Dashboard'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConsultationHistoryScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Availability toggle
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _available ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _available ? 'You are Online' : 'You are Offline',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _available ? Colors.green : Colors.grey,
                              ),
                            ),
                            Text(
                              _available
                                  ? 'Farmers can see you and request consultations'
                                  : 'You are hidden from farmers',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      _togglingAvailability
                          ? const SizedBox(width: 24, height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Switch(
                              value: _available,
                              activeColor: Colors.green,
                              onChanged: (_) => _toggleAvailability(),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Pending requests
              Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.orange, size: 20),
                  const SizedBox(width: 6),
                  Text('Incoming Requests (${_pending.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),

              if (_loading)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (_pending.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 8),
                          Text('No pending requests',
                              style: TextStyle(color: Colors.grey[500])),
                          const SizedBox(height: 4),
                          const Text('Pull down to refresh',
                              style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...(_pending.map((s) => _RequestCard(
                  session: s,
                  onAccept: () => _acceptRequest(s),
                ))),

              const SizedBox(height: 20),

              // Recent sessions
              if (_recent.isNotEmpty) ...[
                const Text('Recent Consultations',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ..._recent.map((s) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: s.status == 'Completed'
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.orange.withValues(alpha: 0.12),
                      child: Icon(
                        s.status == 'Completed' ? Icons.check : Icons.schedule,
                        size: 18,
                        color: s.status == 'Completed' ? Colors.green : Colors.orange,
                      ),
                    ),
                    title: Text(s.farmerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(
                      '${s.cropType ?? "General"} · ${s.status} · ${s.durationMinutes}min',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Text(
                      '${s.requestedAt.day}/${s.requestedAt.month}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                )),
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ConsultationDto session;
  final VoidCallback onAccept;
  const _RequestCard({required this.session, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.orange.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    session.farmerName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session.farmerName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        'Requested ${_timeAgo(session.requestedAt)}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.videocam, color: Colors.orange),
              ],
            ),
            const SizedBox(height: 10),
            if (session.cropType != null)
              Row(
                children: [
                  const Icon(Icons.grass, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text('Crop: ${session.cropType}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            if (session.problemDescription != null) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.report_problem_outlined, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(session.problemDescription!,
                        style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context), // Decline = just ignore
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.grey),
                    child: const Text('Later'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.video_call, size: 18),
                    label: const Text('Accept & Call'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
