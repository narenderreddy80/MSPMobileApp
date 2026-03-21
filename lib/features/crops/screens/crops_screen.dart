import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

class CropsScreen extends StatefulWidget {
  const CropsScreen({super.key});

  @override
  State<CropsScreen> createState() => _CropsScreenState();
}

class _CropsScreenState extends State<CropsScreen> {
  late Future<List<dynamic>> _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _future = _loadCrops();
  }

  Future<List<dynamic>> _loadCrops() async {
    final res = await ApiClient().dio.get('/api/Crops');
    return res.data as List<dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crop Directory')),
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search crops...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading crops'));
                }
                final crops = (snapshot.data ?? [])
                    .where((c) => _search.isEmpty ||
                        (c['name'] ?? '').toString().toLowerCase().contains(_search.toLowerCase()))
                    .toList();

                if (crops.isEmpty) {
                  return const Center(
                    child: Text('No crops found', style: TextStyle(color: Colors.grey)));
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() => _future = _loadCrops()),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: crops.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final c = crops[i] as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                            child: const Icon(Icons.grass, color: AppTheme.primary),
                          ),
                          title: Text(c['name'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(c['description'] ?? '',
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
