import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/api/consultation_service.dart';
import '../../../core/theme/app_theme.dart';

class CallSummaryScreen extends StatefulWidget {
  final ConsultationDto session;
  final List<ConsultationNoteDto> notes;
  final String duration;
  const CallSummaryScreen({
    super.key,
    required this.session,
    required this.notes,
    required this.duration,
  });

  @override
  State<CallSummaryScreen> createState() => _CallSummaryScreenState();
}

class _CallSummaryScreenState extends State<CallSummaryScreen> {
  final _consultationService = ConsultationService();
  ConsultationDto? _updatedSession;
  bool _loadingSummary = true;
  int _rating = 0;
  final _feedbackController = TextEditingController();
  bool _rated = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      // Poll for AI summary (generated in background after call end)
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(seconds: 3));
        final session = await _consultationService.getSession(widget.session.id);
        if (session.aiSummary != null && session.aiSummary!.isNotEmpty) {
          if (mounted) setState(() { _updatedSession = session; _loadingSummary = false; });
          return;
        }
      }
      // If still no summary, try to generate it
      final session = await _consultationService.generateSummary(widget.session.id);
      if (mounted) setState(() { _updatedSession = session; _loadingSummary = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingSummary = false);
    }
  }

  Future<void> _submitRating() async {
    if (_rating == 0) return;
    try {
      await _consultationService.rateSession(
        widget.session.id, _rating,
        feedback: _feedbackController.text.trim().isNotEmpty ? _feedbackController.text.trim() : null,
      );
      if (mounted) setState(() => _rated = true);
    } catch (_) {
      if (mounted) setState(() => _rated = true); // Demo mode
    }
  }

  String _buildShareText() {
    final s = _updatedSession ?? widget.session;
    final buf = StringBuffer();
    buf.writeln('Consultation Summary');
    buf.writeln('${'=' * 30}');
    buf.writeln('Expert: ${s.expertName} (${s.expertSpecialization})');
    buf.writeln('Crop: ${s.cropType ?? "N/A"}');
    buf.writeln('Duration: ${widget.duration}');
    buf.writeln('Date: ${s.requestedAt.day}/${s.requestedAt.month}/${s.requestedAt.year}');
    buf.writeln();
    if (s.aiSummary != null) {
      buf.writeln('Summary:');
      buf.writeln(s.aiSummary);
      buf.writeln();
    }
    if (s.aiRecommendations != null) {
      buf.writeln('Recommendations:');
      buf.writeln(s.aiRecommendations);
      buf.writeln();
    }
    if (widget.notes.isNotEmpty) {
      buf.writeln('Session Notes:');
      for (final n in widget.notes) {
        buf.writeln('[${n.authorRole}] ${n.content}');
      }
    }
    buf.writeln();
    buf.writeln('— MSP Farming App');
    return buf.toString();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _updatedSession ?? widget.session;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Consultation Summary'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _buildShareText()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Summary copied to clipboard'), backgroundColor: Colors.green));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Call completed banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 48),
                  const SizedBox(height: 8),
                  const Text('Consultation Completed',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 4),
                  Text('Duration: ${widget.duration}',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Expert info
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                  child: const Icon(Icons.person, color: AppTheme.primary),
                ),
                title: Text(s.expertName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(s.expertSpecialization),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.grass, color: Colors.green, size: 18),
                    Text(s.cropType ?? 'N/A', style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // AI Summary
            _SectionTitle('AI Summary'),
            const SizedBox(height: 8),
            Card(
              color: Colors.amber[50],
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: _loadingSummary
                    ? const Row(
                        children: [
                          SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text('AI is generating your consultation summary...',
                              style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      )
                    : s.aiSummary != null
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.smart_toy, color: AppTheme.primary, size: 22),
                              const SizedBox(width: 10),
                              Expanded(child: Text(s.aiSummary!,
                                  style: const TextStyle(fontSize: 13, height: 1.5))),
                            ],
                          )
                        : const Text('Summary not available yet. It will appear shortly.',
                            style: TextStyle(fontSize: 13, color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 16),

            // AI Recommendations
            if (s.aiRecommendations != null) ...[
              _SectionTitle('Recommendations'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.checklist, color: Colors.green, size: 22),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s.aiRecommendations!,
                          style: const TextStyle(fontSize: 13, height: 1.5))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Session Notes
            if (widget.notes.isNotEmpty) ...[
              _SectionTitle('Session Notes (${widget.notes.length})'),
              const SizedBox(height: 8),
              ...widget.notes.map((n) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    n.authorRole == 'AI' ? Icons.smart_toy : Icons.person,
                    color: n.authorRole == 'AI' ? Colors.amber[700]
                         : n.authorRole == 'Expert' ? AppTheme.primary : Colors.green,
                    size: 20,
                  ),
                  title: Text(n.content, style: const TextStyle(fontSize: 12, height: 1.4)),
                  subtitle: Text('${n.authorRole} · ${n.createdAt.hour}:${n.createdAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 10)),
                ),
              )),
              const SizedBox(height: 16),
            ],

            // Rating
            _SectionTitle('Rate this Consultation'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: _rated
                    ? const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Thank you for your feedback!',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (i) => IconButton(
                              icon: Icon(
                                i < _rating ? Icons.star : Icons.star_border,
                                color: Colors.amber, size: 36,
                              ),
                              onPressed: () => setState(() => _rating = i + 1),
                            )),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _feedbackController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Optional feedback for the expert...',
                              hintStyle: const TextStyle(fontSize: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _rating > 0 ? _submitRating : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Submit Rating'),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // Share button
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
              Clipboard.setData(ClipboardData(text: _buildShareText()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Summary copied to clipboard'), backgroundColor: Colors.green));
            },
                icon: const Icon(Icons.share),
                label: const Text('Share Summary & Notes'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Text(title,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold));
}
