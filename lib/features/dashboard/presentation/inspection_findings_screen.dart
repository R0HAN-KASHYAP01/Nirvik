import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/assignment.dart';
import '../data/inspection_findings_repository.dart';
import 'inspection_summary_screen.dart';

class InspectionFindingsScreen extends StatefulWidget {
  final AssignmentSummary assignment;

  const InspectionFindingsScreen({super.key, required this.assignment});

  @override
  State<InspectionFindingsScreen> createState() =>
      _InspectionFindingsScreenState();
}

class _InspectionFindingsScreenState extends State<InspectionFindingsScreen> {
  final InspectionFindingsRepository _repository =
      InspectionFindingsRepository();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _recommendationController =
      TextEditingController();

  static const List<String> _categories = [
    'Infrastructure',
    'Attendance',
    'Documentation',
    'Financial',
    'Safety',
    'Staffing',
    'Beneficiary Services',
    'Other',
  ];

  static const List<String> _severities = ['low', 'medium', 'high'];

  String _selectedCategory = _categories.first;
  String _selectedSeverity = 'medium';

  List<Map<String, dynamic>> _findings = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadFindings();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _recommendationController.dispose();
    super.dispose();
  }

  Future<void> _loadFindings() async {
    try {
      final findings = await _repository.getFindings(widget.assignment.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _findings = findings;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load findings: $error')),
      );
    }
  }

  Future<void> _saveFinding() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final recommendation = _recommendationController.text.trim();

    if (title.isEmpty) {
      _showMessage('Please enter a finding title.');
      return;
    }

    final inspectorProfileId = _repository.getCurrentUserId();

    if (inspectorProfileId == null) {
      _showMessage('No authenticated inspector session was found.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _repository.saveFinding(
        assignmentId: widget.assignment.id,
        inspectorProfileId: inspectorProfileId,
        instituteProfileId: widget.assignment.instituteProfileId,
        title: title,
        category: _selectedCategory,
        severity: _selectedSeverity,
        description: description.isEmpty ? null : description,
        recommendation: recommendation.isEmpty ? null : recommendation,
      );

      _titleController.clear();
      _descriptionController.clear();
      _recommendationController.clear();

      setState(() {
        _selectedCategory = _categories.first;
        _selectedSeverity = 'medium';
      });

      await _loadFindings();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finding saved successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save finding: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _continueToSummary() {
    if (_findings.isEmpty) {
      _showMessage('Please add at least one finding before continuing.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InspectionSummaryScreen(assignment: widget.assignment),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildAssignmentCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.assignment.projectName,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.black54,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.assignment.location,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFindingForm() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Finding',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Finding Title',
              hintText: 'Enter a short title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: _categories.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _selectedCategory = value;
              });
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _selectedSeverity,
            decoration: const InputDecoration(
              labelText: 'Severity',
              border: OutlineInputBorder(),
            ),
            items: _severities.map((severity) {
              return DropdownMenuItem<String>(
                value: severity,
                child: Text(severity[0].toUpperCase() + severity.substring(1)),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _selectedSeverity = value;
              });
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _descriptionController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Describe the issue found during inspection',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _recommendationController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Recommendation',
              hintText: 'Enter the recommended corrective action',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: _isSaving ? 'Saving Finding...' : 'Save Finding',
            onPressed: _isSaving
                ? () {}
                : () {
                    _saveFinding();
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildFindingsList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_findings.isEmpty) {
      return AppCard(
        child: Column(
          children: [
            Icon(
              Icons.fact_check_outlined,
              size: 42,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 10),
            const Text(
              'No findings added yet.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add a finding using the form above.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Saved Findings',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ..._findings.map(_buildFindingCard),
      ],
    );
  }

  Widget _buildFindingCard(Map<String, dynamic> finding) {
    final title = finding['title']?.toString() ?? 'Untitled Finding';

    final category = finding['category']?.toString() ?? 'Other';

    final severity = finding['severity']?.toString() ?? 'medium';

    final description = finding['description']?.toString();

    final recommendation = finding['recommendation']?.toString();

    final status = finding['status']?.toString() ?? 'open';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                StatusBadge(
                  label: severity.toUpperCase(),
                  color: _severityColor(severity),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              category,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(description),
            ],
            if (recommendation != null && recommendation.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Recommendation',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                recommendation,
                style: const TextStyle(color: Colors.black87),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Status: ${status.toUpperCase()}',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inspection Findings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAssignmentCard(),
          const SizedBox(height: 16),
          _buildFindingForm(),
          const SizedBox(height: 20),
          _buildFindingsList(),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Continue to Summary',
            onPressed: _continueToSummary,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
