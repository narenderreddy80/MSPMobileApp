import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/crop_analysis_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import 'analysis_result_screen.dart';

class CropAnalysisScreen extends StatefulWidget {
  const CropAnalysisScreen({super.key});

  @override
  State<CropAnalysisScreen> createState() => _CropAnalysisScreenState();
}

class _CropAnalysisScreenState extends State<CropAnalysisScreen> {
  final _picker = ImagePicker();
  final _notesCtrl = TextEditingController();
  final List<XFile> _images = [];
  bool _loading = false;

  Future<void> _pickImages(ImageSource source) async {
    if (source == ImageSource.gallery) {
      final picked = await _picker.pickMultiImage(imageQuality: 85);
      final remaining = AppConstants.maxImages - _images.length;
      setState(() => _images.addAll(picked.take(remaining)));
    } else {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked != null && _images.length < AppConstants.maxImages) {
        setState(() => _images.add(picked));
      }
    }
  }

  void _removeImage(int index) => setState(() => _images.removeAt(index));

  Future<void> _analyze() async {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one crop image')));
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await CropAnalysisService().analyze(
        _images.map((x) => x.path).toList(),
        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AnalysisResultScreen(result: result)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: ${e.toString()}'),
            backgroundColor: AppTheme.error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crop Analyzer')),
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Crop Images',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold)),
                        Text('${_images.length}/${AppConstants.maxImages}',
                          style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_images.isNotEmpty) ...[
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(File(_images[i].path),
                                  width: 100, height: 100, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 2, right: 2,
                                child: GestureDetector(
                                  onTap: () => _removeImage(i),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.red, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_images.length < AppConstants.maxImages)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickImages(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Camera'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickImages(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Gallery'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Farmer Notes (Optional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Describe crop type, symptoms, location, growth stage',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Paddy crop, yellowing leaves at tillering stage, Andhra Pradesh...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _loading ? null : _analyze,
              icon: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.biotech),
              label: Text(_loading ? 'Analyzing...' : 'Analyze Crop',
                style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
