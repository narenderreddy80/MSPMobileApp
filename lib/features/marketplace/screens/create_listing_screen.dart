import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/listing_service.dart';
import '../../../core/theme/app_theme.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ListingService();
  final _picker   = ImagePicker();

  final _cropCtrl     = TextEditingController();
  final _varietyCtrl  = TextEditingController();
  final _qtyCtrl      = TextEditingController();
  final _priceCtrl    = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _notesCtrl    = TextEditingController();

  String _qtyUnit = 'quintal';
  String _state = 'Telangana';
  final List<File> _images = [];
  bool _submitting = false;

  final _states = ['Andhra Pradesh', 'Karnataka', 'Kerala', 'Maharashtra',
    'Madhya Pradesh', 'Punjab', 'Rajasthan', 'Tamil Nadu', 'Telangana',
    'Uttar Pradesh', 'West Bengal'];

  @override
  void dispose() {
    _cropCtrl.dispose(); _varietyCtrl.dispose(); _qtyCtrl.dispose();
    _priceCtrl.dispose(); _districtCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 images allowed')));
      return;
    }
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200);
    if (picked != null && mounted) {
      setState(() => _images.add(File(picked.path)));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await _service.createListing(
        cropName:      _cropCtrl.text.trim(),
        variety:       _varietyCtrl.text.trim().isEmpty ? null : _varietyCtrl.text.trim(),
        quantityValue: double.parse(_qtyCtrl.text.trim()),
        quantityUnit:  _qtyUnit,
        pricePerUnit:  double.parse(_priceCtrl.text.trim()),
        state:         _state,
        district:      _districtCtrl.text.trim(),
        notes:         _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        images:        _images,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing posted successfully!')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Crop Listing')),
      backgroundColor: AppTheme.background,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Crop Details'),
            _field(_cropCtrl, 'Crop Name *', required: true),
            const SizedBox(height: 12),
            _field(_varietyCtrl, 'Variety (optional)'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Quantity *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' :
                      double.tryParse(v.trim()) == null ? 'Invalid number' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _qtyUnit,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                  ),
                  items: ['kg', 'quintal', 'ton'].map((u) =>
                    DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) => setState(() => _qtyUnit = v ?? 'quintal'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Price per $_qtyUnit (\u20b9) *',
                border: const OutlineInputBorder(),
                prefixText: '\u20b9 ',
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' :
                  double.tryParse(v.trim()) == null ? 'Invalid number' : null,
            ),
            const SizedBox(height: 20),
            _section('Location'),
            DropdownButtonFormField<String>(
              initialValue: _state,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'State *', border: OutlineInputBorder()),
              items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _state = v ?? _state),
            ),
            const SizedBox(height: 12),
            _field(_districtCtrl, 'District *', required: true),
            const SizedBox(height: 20),
            _section('Additional Info'),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (quality, harvest date, delivery terms...)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            _section('Photos (up to 5)'),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                ..._images.asMap().entries.map((e) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(e.value,
                        width: 80, height: 80, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 2, right: 2,
                      child: GestureDetector(
                        onTap: () => setState(() => _images.removeAt(e.key)),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )),
                if (_images.length < 5)
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4),
                          style: BorderStyle.solid, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.primary.withValues(alpha: 0.05),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                            color: AppTheme.primary, size: 28),
                          Text('Add Photo',
                            style: TextStyle(color: AppTheme.primary, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.sell),
              label: Text(_submitting ? 'Posting...' : 'Post Listing'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold, color: AppTheme.primary)),
  );

  Widget _field(TextEditingController ctrl, String label, {bool required = false}) =>
    TextFormField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: required ? (v) => v == null || v.trim().isEmpty ? 'Required' : null : null,
    );
}
