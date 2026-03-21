import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/api/crop_analysis_service.dart';
import '../../../core/theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = CropAnalysisService().getHistory();
  }

  Color _healthColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy': return Colors.green;
      case 'diseased': return Colors.red;
      case 'stressed': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis History')),
      backgroundColor: AppTheme.background,
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No analyses yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                setState(() => _future = CropAnalysisService().getHistory()),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final r = records[i] as Map<String, dynamic>;
                final date = DateTime.tryParse(r['createdAt'] ?? '');
                final status = r['healthStatus'] ?? 'Unknown';
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: CircleAvatar(
                      backgroundColor: _healthColor(status).withValues(alpha: 0.15),
                      child: Icon(Icons.eco, color: _healthColor(status)),
                    ),
                    title: Text(r['cropName'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(r['notes'] ?? 'No notes',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        const SizedBox(height: 4),
                        if (date != null)
                          Text(DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal()),
                            style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _healthColor(status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(status,
                        style: TextStyle(
                          color: _healthColor(status),
                          fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
