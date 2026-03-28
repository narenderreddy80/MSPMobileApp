import 'package:flutter/material.dart';
import '../../../core/api/expert_service.dart';
import '../../../core/api/consultation_service.dart';
import '../../../core/theme/app_theme.dart';
import 'video_call_screen.dart';
import 'consultation_history_screen.dart';
import 'expert_register_screen.dart';

class ExpertConnectScreen extends StatefulWidget {
  final String? cropType;
  final String? problemDescription;
  final int? fieldId;
  const ExpertConnectScreen({super.key, this.cropType, this.problemDescription, this.fieldId});

  @override
  State<ExpertConnectScreen> createState() => _ExpertConnectScreenState();
}

class _ExpertConnectScreenState extends State<ExpertConnectScreen> {
  final _expertService = ExpertService();
  final _consultationService = ConsultationService();
  List<ExpertDto> _experts = [];
  bool _loading = true;
  String? _selectedSpecialization;
  int? _connectingExpertId;

  static const _specializations = [
    'All',
    'Plant Pathology',
    'Soil Science',
    'Entomology',
    'Agronomy',
    'Horticulture',
    'Irrigation',
    'Organic Farming',
  ];

  @override
  void initState() {
    super.initState();
    _loadExperts();
  }

  Future<void> _loadExperts() async {
    setState(() => _loading = true);
    try {
      final experts = await _expertService.getAvailableExperts(
        specialization: _selectedSpecialization,
      );
      if (mounted) setState(() { _experts = experts; _loading = false; });
    } catch (e) {
      debugPrint('ExpertConnect: API error: $e');
      if (mounted) setState(() { _experts = []; _loading = false; });
    }
  }

  Future<void> _connectToExpert(ExpertDto expert) async {
    setState(() => _connectingExpertId = expert.id);
    try {
      final session = await _consultationService.requestConsultation(
        expertId: expert.id,
        cropType: widget.cropType,
        problemDescription: widget.problemDescription,
        fieldId: widget.fieldId,
      );
      if (mounted) {
        setState(() => _connectingExpertId = null);
        Navigator.push(context,
          MaterialPageRoute(builder: (_) => VideoCallScreen(session: session, expertName: expert.name)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _connectingExpertId = null);
        Navigator.push(context,
          MaterialPageRoute(builder: (_) => VideoCallScreen(
            session: ConsultationDto(
              id: 0, farmerUserId: '', farmerName: 'You',
              expertId: expert.id, expertName: expert.name,
              expertSpecialization: expert.specialization,
              status: 'Accepted', cropType: widget.cropType,
              problemDescription: widget.problemDescription,
              channelName: 'demo_channel',
              requestedAt: DateTime.now(), durationMinutes: 0,
            ),
            expertName: expert.name,
          )));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Expert Connect'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Become an Expert',
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ExpertRegisterScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ConsultationHistoryScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          // Problem context banner
          if (widget.cropType != null || widget.problemDescription != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppTheme.primary.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.cropType ?? "Crop"} — ${widget.problemDescription ?? "General consultation"}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.primary),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Specialization filter chips
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _specializations.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final spec = _specializations[i];
                final selected = (_selectedSpecialization == null && spec == 'All') ||
                    _selectedSpecialization == spec;
                return ChoiceChip(
                  label: Text(spec, style: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : AppTheme.primary,
                  )),
                  selected: selected,
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                  side: BorderSide.none,
                  onSelected: (_) {
                    setState(() => _selectedSpecialization = spec == 'All' ? null : spec);
                    _loadExperts();
                  },
                );
              },
            ),
          ),

          // Expert list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _experts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_search, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text('No experts available right now',
                                style: TextStyle(color: Colors.grey[500])),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _loadExperts,
                              child: const Text('Refresh'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _experts.length,
                        itemBuilder: (_, i) => _ExpertCard(
                          expert: _experts[i],
                          connecting: _connectingExpertId == _experts[i].id,
                          onConnect: () => _connectToExpert(_experts[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ExpertCard extends StatelessWidget {
  final ExpertDto expert;
  final bool connecting;
  final VoidCallback onConnect;
  const _ExpertCard({required this.expert, required this.connecting, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    final initials = expert.name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: avatar + name + online badge
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                  child: Text(initials,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expert.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(expert.specialization,
                        style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w500)),
                      if (expert.organization != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(expert.organization!,
                            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: expert.isAvailable ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(expert.isAvailable ? 'Online' : 'Offline',
                      style: TextStyle(fontSize: 9,
                        color: expert.isAvailable ? Colors.green : Colors.grey)),
                  ],
                ),
              ],
            ),
            // Qualification
            if (expert.qualification != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.school_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(child: Text(expert.qualification!,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]))),
                ],
              ),
            ],
            // Bio
            if (expert.bio != null) ...[
              const SizedBox(height: 8),
              Text(expert.bio!, style: const TextStyle(fontSize: 12, height: 1.4),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            // Stats row
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _stat(Icons.star, expert.rating.toStringAsFixed(1), Colors.amber),
                _stat(Icons.video_call, '${expert.totalConsultations}', Colors.blue),
                _stat(Icons.work_history, '${expert.experienceYears}yr', Colors.teal),
                if (expert.languages != null)
                  _stat(Icons.language, expert.languages!.split(',').first, Colors.purple),
              ],
            ),
            const SizedBox(height: 12),
            // Connect button - full width
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: expert.isAvailable && !connecting ? onConnect : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                icon: connecting
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.video_call, size: 20),
                label: Text(connecting ? 'Connecting...' : 'Connect with Expert',
                  style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(value, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
