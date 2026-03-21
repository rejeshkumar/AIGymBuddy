import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

/// Body Scan - capture/upload image, analyze (NOT stored), get suggestions.
class BodyScanScreen extends StatefulWidget {
  const BodyScanScreen({super.key});

  @override
  State<BodyScanScreen> createState() => _BodyScanScreenState();
}

class _BodyScanScreenState extends State<BodyScanScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  bool _loading = false;
  bool _analyzing = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _pickImage({bool fromCamera = false}) async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        if (result != null && result.files.single.bytes != null && mounted) {
          setState(() {
            _imageBytes = result.files.single.bytes;
            _loading = false;
          });
        } else {
          setState(() => _loading = false);
        }
        return;
      }
      final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
      final photo = await _picker.pickImage(source: source, imageQuality: 85);
      if (photo != null && mounted) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to pick image: $e';
        });
      }
    }
  }

  Future<void> _analyze() async {
    if (_imageBytes == null) return;
    final auth = context.read<AuthProvider>();
    if (auth.token == null) {
      setState(() => _error = 'Please sign in to analyze.');
      return;
    }
    setState(() {
      _analyzing = true;
      _error = null;
      _result = null;
    });
    try {
      final (data, err) = await ApiService().bodyScan(
        auth.token!,
        _imageBytes!,
        filename: 'body_scan.jpg',
      );
      if (mounted) {
        setState(() {
          _analyzing = false;
          _result = data;
          _error = err;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analyzing = false;
          _error = 'Analysis failed: $e';
        });
      }
    }
  }

  void _clear() {
    setState(() {
      _imageBytes = null;
      _result = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Body Scan'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.photo_camera, size: 48, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Upload or take a photo',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Image is analyzed only – never stored. Get personalized areas of improvement, exercises, and nutrition tips.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_imageBytes == null) ...[
              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else
                Column(
                  children: [
                    FilledButton.icon(
                      onPressed: () => _pickImage(fromCamera: true),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 52),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _pickImage(fromCamera: false),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload from Device'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 52),
                      ),
                    ),
                  ],
                ),
            ] else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _imageBytes!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error, size: 24),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_error!, style: TextStyle(color: theme.colorScheme.onErrorContainer))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_result != null) _buildResults(theme),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _analyzing ? null : _clear,
                      icon: const Icon(Icons.refresh),
                      label: const Text('New Photo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _analyzing ? null : _analyze,
                      icon: _analyzing
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.analytics),
                      label: Text(_analyzing ? 'Analyzing...' : 'Analyze'),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    final areas = _result!['areas_of_improvement'] as List<dynamic>? ?? [];
    final exercises = _result!['suggested_exercises'] as List<dynamic>? ?? [];
    final nutrition = _result!['suggested_nutrition'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _SectionCard(
          theme: theme,
          title: 'Areas of Improvement',
          icon: Icons.trending_up,
          items: areas.map((e) => e.toString()).toList(),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          theme: theme,
          title: 'Suggested Exercises',
          icon: Icons.fitness_center,
          items: exercises.map((e) => e.toString()).toList(),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          theme: theme,
          title: 'Nutrition Tips',
          icon: Icons.restaurant,
          items: nutrition.map((e) => e.toString()).toList(),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final IconData icon;
  final List<String> items;

  const _SectionCard({
    required this.theme,
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.key + 1}.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.value,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
