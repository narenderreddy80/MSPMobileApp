import 'package:flutter/material.dart';
import '../../../core/api/expert_service.dart';
import '../../../core/theme/app_theme.dart';
import 'expert_dashboard_screen.dart';

class ExpertRegisterScreen extends StatefulWidget {
  const ExpertRegisterScreen({super.key});

  @override
  State<ExpertRegisterScreen> createState() => _ExpertRegisterScreenState();
}

class _ExpertRegisterScreenState extends State<ExpertRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _expertService = ExpertService();
  bool _submitting = false;

  String _specialization = 'Plant Pathology';
  final _qualificationCtrl = TextEditingController();
  final _organizationCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _languagesCtrl = TextEditingController();
  int _experienceYears = 1;

  static const _specializations = [
    'Plant Pathology',
    'Soil Science',
    'Entomology',
    'Agronomy',
    'Horticulture',
    'Irrigation',
    'Organic Farming',
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await _expertService.registerAsExpert(
        specialization: _specialization,
        qualification: _qualificationCtrl.text.trim().isEmpty ? null : _qualificationCtrl.text.trim(),
        organization: _organizationCtrl.text.trim().isEmpty ? null : _organizationCtrl.text.trim(),
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        languages: _languagesCtrl.text.trim().isEmpty ? null : _languagesCtrl.text.trim(),
        experienceYears: _experienceYears,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registered as expert!'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ExpertDashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _qualificationCtrl.dispose();
    _organizationCtrl.dispose();
    _bioCtrl.dispose();
    _languagesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Register as Expert'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Join as an agricultural expert and help farmers with video consultations.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _specialization,
              decoration: const InputDecoration(
                labelText: 'Specialization *',
                border: OutlineInputBorder(),
              ),
              items: _specializations.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _specialization = v!),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _qualificationCtrl,
              decoration: const InputDecoration(
                labelText: 'Qualification',
                hintText: 'e.g. PhD Plant Sciences, IARI',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _organizationCtrl,
              decoration: const InputDecoration(
                labelText: 'Organization',
                hintText: 'e.g. KVK Hyderabad',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _bioCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell farmers about your expertise...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _languagesCtrl,
              decoration: const InputDecoration(
                labelText: 'Languages',
                hintText: 'e.g. Hindi,Telugu,English',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text('Experience (years): ', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _experienceYears,
                  items: List.generate(30, (i) => i + 1)
                      .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                      .toList(),
                  onChanged: (v) => setState(() => _experienceYears = v!),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Register as Expert', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
