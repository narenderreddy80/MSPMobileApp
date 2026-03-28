import 'package:flutter/material.dart';
import '../../../core/api/consultation_service.dart';
import '../../../core/theme/app_theme.dart';
import 'call_summary_screen.dart';

class ConsultationHistoryScreen extends StatefulWidget {
  const ConsultationHistoryScreen({super.key});

  @override
  State<ConsultationHistoryScreen> createState() => _ConsultationHistoryScreenState();
}

class _ConsultationHistoryScreenState extends State<ConsultationHistoryScreen> {
  final _service = ConsultationService();
  List<ConsultationDto> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _sessions = await _service.getMySessions();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Color _statusColor(String status) => switch (status) {
    'Completed'  => Colors.green,
    'InProgress' => Colors.blue,
    'Accepted'   => Colors.teal,
    'Requested'  => Colors.orange,
    'Cancelled'  => Colors.red,
    'Missed'     => Colors.grey,
    _            => Colors.grey,
  };

  IconData _statusIcon(String status) => switch (status) {
    'Completed'  => Icons.check_circle,
    'InProgress' => Icons.videocam,
    'Accepted'   => Icons.handshake,
    'Requested'  => Icons.schedule,
    'Cancelled'  => Icons.cancel,
    'Missed'     => Icons.phone_missed,
    _            => Icons.help,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Consultation History'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.video_call_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('No consultations yet', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _sessions.length,
                    itemBuilder: (_, i) {
                      final s = _sessions[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _statusColor(s.status).withValues(alpha: 0.12),
                            child: Icon(_statusIcon(s.status), color: _statusColor(s.status), size: 20),
                          ),
                          title: Text(s.expertName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${s.expertSpecialization} · ${s.cropType ?? "General"}',
                                  style: const TextStyle(fontSize: 11)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _statusColor(s.status).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(s.status,
                                        style: TextStyle(fontSize: 10, color: _statusColor(s.status), fontWeight: FontWeight.w500)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('${s.requestedAt.day}/${s.requestedAt.month}/${s.requestedAt.year}',
                                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  if (s.durationMinutes > 0) ...[
                                    const SizedBox(width: 8),
                                    Text('${s.durationMinutes} min',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                  if (s.farmerRating != null) ...[
                                    const Spacer(),
                                    Icon(Icons.star, size: 12, color: Colors.amber[700]),
                                    Text(' ${s.farmerRating}', style: const TextStyle(fontSize: 10)),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onTap: s.status == 'Completed'
                              ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CallSummaryScreen(
                                      session: s, notes: const [], duration: '${s.durationMinutes} min',
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
