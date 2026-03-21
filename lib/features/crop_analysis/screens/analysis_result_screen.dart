import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';

class AnalysisResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  const AnalysisResultScreen({super.key, required this.result});

  Color _healthColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy': return Colors.green;
      case 'diseased': return Colors.red;
      case 'stressed': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Color _severityColor(String s) {
    switch (s.toLowerCase()) {
      case 'critical': return Colors.red[900]!;
      case 'high': return Colors.red;
      case 'moderate': return Colors.orange;
      default: return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final diseases = (result['diseases'] as List? ?? []);
    final fixes = (result['fixes'] as List? ?? []);
    final youtubeLinks = (result['youTubeLinks'] as List? ?? []);
    final healthStatus = result['healthStatus'] ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Result')),
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.eco, color: AppTheme.primary, size: 28),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(result['cropName'] ?? 'Unknown',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _healthColor(healthStatus).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _healthColor(healthStatus)),
                          ),
                          child: Text(healthStatus,
                            style: TextStyle(
                              color: _healthColor(healthStatus),
                              fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    if ((result['cropDetails'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(result['cropDetails'],
                        style: TextStyle(color: Colors.grey[700])),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Diseases
            if (diseases.isNotEmpty) ...[
              _sectionTitle(context, 'Detected Diseases', Icons.warning_amber),
              ...diseases.map((d) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(d['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _severityColor(d['severity'] ?? '').withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(d['severity'] ?? '',
                              style: TextStyle(
                                color: _severityColor(d['severity'] ?? ''),
                                fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      if ((d['description'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(d['description'], style: TextStyle(color: Colors.grey[700])),
                      ],
                      if ((d['symptoms'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('Symptoms: ${d['symptoms']}',
                          style: const TextStyle(fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 4),
            ],

            // Fixes
            if (fixes.isNotEmpty) ...[
              _sectionTitle(context, 'Recommended Fixes', Icons.healing),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: fixes.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12, backgroundColor: AppTheme.primary,
                            child: Text('${e.key + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 11))),
                          const SizedBox(width: 10),
                          Expanded(child: Text(e.value.toString())),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],

            // YouTube links
            if (youtubeLinks.isNotEmpty) ...[
              _sectionTitle(context, 'Learn More', Icons.play_circle_outline),
              ...youtubeLinks.map((link) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.play_circle_filled, color: Colors.red, size: 32),
                  title: Text(link['title'] ?? '', style: const TextStyle(fontSize: 13)),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () async {
                    final url = Uri.parse(link['url'] ?? '');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              )),
            ],

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Analyze Another'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext ctx, String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(icon, color: AppTheme.primary, size: 20),
      const SizedBox(width: 6),
      Text(title, style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold)),
    ]),
  );
}
