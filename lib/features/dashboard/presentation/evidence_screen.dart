import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/assignment.dart';
import '../data/inspection_evidence_repository.dart';
import 'inspection_findings_screen.dart';

class EvidenceScreen extends StatefulWidget {
  final AssignmentSummary assignment;

  const EvidenceScreen({super.key, required this.assignment});

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen> {
  final ImagePicker _picker = ImagePicker();
  final InspectionEvidenceRepository _repository =
      InspectionEvidenceRepository();

  final TextEditingController _descriptionController = TextEditingController();

  Uint8List? _selectedImageBytes;
  String? _selectedFileExtension;

  List<Map<String, dynamic>> _evidence = [];

  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadEvidence();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadEvidence() async {
    try {
      final evidence = await _repository.getEvidence(widget.assignment.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _evidence = evidence;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage('Unable to load existing evidence.', isError: true);

      debugPrint('Evidence loading error: $error');
    }
  }

  Future<void> _pickImage() async {
    if (_isUploading) {
      return;
    }

    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();

      if (!mounted) {
        return;
      }

      final fileName = image.name;
      final extension = _getFileExtension(fileName);

      setState(() {
        _selectedImageBytes = bytes;
        _selectedFileExtension = extension;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('Unable to select the image.', isError: true);

      debugPrint('Image selection error: $error');
    }
  }

  String _getFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');

    if (lastDot == -1 || lastDot == fileName.length - 1) {
      return 'jpg';
    }

    return fileName.substring(lastDot + 1);
  }

  Future<void> _uploadEvidence() async {
    if (_selectedImageBytes == null) {
      _showMessage('Please select an evidence photo first.', isError: true);
      return;
    }

    if (_isUploading) {
      return;
    }

    final inspectorProfileId = _repository.getCurrentUserId();

    if (inspectorProfileId == null) {
      _showMessage(
        'No authenticated inspector session was found.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final storagePath = await _repository.uploadEvidenceFile(
        assignmentId: widget.assignment.id,
        fileBytes: _selectedImageBytes!,
        fileExtension: _selectedFileExtension ?? 'jpg',
      );

      await _repository.saveEvidence(
        assignmentId: widget.assignment.id,
        inspectorProfileId: inspectorProfileId,
        instituteProfileId: widget.assignment.instituteProfileId,
        storagePath: storagePath,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      await _loadEvidence();

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedImageBytes = null;
        _selectedFileExtension = null;
        _descriptionController.clear();
      });

      _showMessage('Evidence uploaded successfully.');
    } on StorageException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('Storage upload failed: ${error.message}', isError: true);

      debugPrint('Storage upload error: $error');
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Evidence record could not be saved: ${error.message}',
        isError: true,
      );

      debugPrint('Evidence database error: $error');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to upload evidence. Please try again.',
        isError: true,
      );

      debugPrint('Evidence upload error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _continueToFindings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InspectionFindingsScreen(assignment: widget.assignment),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
        ),
      );
  }

  Widget _buildAssignmentCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assignment',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            widget.assignment.projectName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.black54,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.assignment.location,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImage() {
    if (_selectedImageBytes == null) {
      return const SizedBox.shrink();
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          _selectedImageBytes!,
          width: double.infinity,
          height: 240,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildEvidenceForm() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Evidence',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _isUploading ? null : _pickImage,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(
              _selectedImageBytes == null ? 'Select Photo' : 'Change Photo',
            ),
          ),
          if (_selectedImageBytes != null) ...[
            const SizedBox(height: 14),
            _buildSelectedImage(),
            const SizedBox(height: 14),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              enabled: !_isUploading,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe what this evidence shows',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: _isUploading ? 'Uploading Evidence...' : 'Upload Evidence',
              onPressed: _isUploading ? () {} : _uploadEvidence,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEvidenceList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_evidence.isEmpty) {
      return AppCard(
        child: Column(
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 42,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 10),
            const Text(
              'No evidence uploaded yet.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Uploaded Evidence',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        ..._evidence.map(_buildEvidenceItem),
      ],
    );
  }

  Widget _buildEvidenceItem(Map<String, dynamic> evidence) {
    final description = evidence['description']?.toString();
    final createdAt = evidence['created_at']?.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.photo_outlined, size: 32, color: Colors.indigo),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inspection Evidence',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                  if (createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      createdAt,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inspection Evidence')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAssignmentCard(),
          const SizedBox(height: 16),
          _buildEvidenceForm(),
          const SizedBox(height: 20),
          _buildEvidenceList(),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Continue to Findings',
            onPressed: _continueToFindings,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
