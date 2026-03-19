import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../config/health_package.dart';

/// Expandable section showing recommended pre-gym health tests.
class _HealthPackageSection extends StatefulWidget {
  @override
  State<_HealthPackageSection> createState() => _HealthPackageSectionState();
}

class _HealthPackageSectionState extends State<_HealthPackageSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final package = preGymHealthPackage;

    return Card(
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.medical_services, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Recommended tests before joining a gym',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                Text(
                  package.description,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                ..._groupByCategory(package.tests).entries.map((e) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Text(
                          e.key,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      ...e.value.map((t) => Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• ${t.name}',
                                  style: theme.textTheme.bodySmall,
                                ),
                                if (t.required)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Text(
                                      '(required)',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )),
                    ],
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Map<String, List<HealthTest>> _groupByCategory(List<HealthTest> tests) {
    final map = <String, List<HealthTest>>{};
    for (final t in tests) {
      map.putIfAbsent(t.category, () => []).add(t);
    }
    return map;
  }
}

/// Health OCR - upload image or PDF to backend for OCR processing.
class HealthOcrScreen extends StatefulWidget {
  const HealthOcrScreen({super.key});

  @override
  State<HealthOcrScreen> createState() => _HealthOcrScreenState();
}

class _HealthOcrScreenState extends State<HealthOcrScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedFile;
  String? _selectedFileName;
  Map<String, dynamic>? _result;
  bool _uploading = false;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        setState(() {
          _selectedFile = image;
          _selectedFileName = image.name;
          _result = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf'],
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.single.bytes != null && mounted) {
        final f = result.files.single;
        final xfile = XFile.fromData(
          f.bytes!,
          name: f.name,
          mimeType: f.extension == 'pdf' ? 'application/pdf' : 'image/${f.extension ?? "jpeg"}',
        );
        setState(() {
          _selectedFile = xfile;
          _selectedFileName = f.name;
          _result = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo != null && mounted) {
        setState(() {
          _selectedFile = photo;
          _selectedFileName = photo.name;
          _result = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildFilePreview() {
    if (_selectedFile == null) return const SizedBox.shrink();
    final isPdf = (_selectedFileName ?? '').toLowerCase().endsWith('.pdf');
    if (isPdf) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.picture_as_pdf, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(_selectedFileName ?? 'PDF file'),
            ],
          ),
        ),
      );
    }
    return FutureBuilder(
      future: _selectedFile!.readAsBytes(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            snap.data!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  Future<void> _uploadAndProcess() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null || _selectedFile == null) return;
    setState(() => _uploading = true);
    final (data, err) = await ApiService().uploadHealthOcrWithError(auth.token!, _selectedFile!);
    setState(() {
      _uploading = false;
      _result = data;
    });
    if (mounted && data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err != null ? 'Upload failed: $err' : 'Upload failed'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _clear() {
    setState(() {
      _selectedFile = null;
      _selectedFileName = null;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HealthPackageSection(),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.document_scanner,
                      size: 64, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Health Report OCR',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload a photo or PDF of your health report for OCR extraction.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_selectedFile != null) ...[
            _buildFilePreview(),
            const SizedBox(height: 16),
            if (_result != null) ...[
              Card(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Extracted Values',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_result!['hba1c'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('HbA1c: ${_result!['hba1c']}'),
                        ),
                      if (_result!['cholesterol'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Cholesterol: ${_result!['cholesterol']}'),
                        ),
                      if (_result!['raw_text'] != null &&
                          (_result!['raw_text'] as String).isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Raw text (preview):',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (_result!['raw_text'] as String).length > 200
                              ? '${(_result!['raw_text'] as String).substring(0, 200)}...'
                              : _result!['raw_text'] as String,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else if (!_uploading) ...[
              FilledButton.icon(
                onPressed: _uploadAndProcess,
                icon: const Icon(Icons.upload),
                label: const Text('Upload & Process'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (_uploading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
            OutlinedButton(
              onPressed: _clear,
              child: const Text('Clear & Choose Another'),
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose from Gallery'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Pick Image or PDF'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
