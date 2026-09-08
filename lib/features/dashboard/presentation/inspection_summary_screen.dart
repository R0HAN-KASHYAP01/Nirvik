import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/assignment.dart';
import '../data/arrival_verification_repository.dart';
import '../data/assignments_repository.dart';
import '../data/inspection_checklist_repository.dart';
import '../data/inspection_evidence_repository.dart';
import '../data/inspection_findings_repository.dart';
import '../data/inspection_submission_repository.dart';

class InspectionSummaryScreen extends StatefulWidget {
  final AssignmentSummary assignment;

  const InspectionSummaryScreen({super.key, required this.assignment});

  @override
  State<InspectionSummaryScreen> createState() =>
      _InspectionSummaryScreenState();
}

class _InspectionSummaryScreenState extends State<InspectionSummaryScreen> {
  final ArrivalVerificationRepository _arrivalRepository =
      ArrivalVerificationRepository();

  final InspectionChecklistRepository _checklistRepository =
      InspectionChecklistRepository();

  final InspectionEvidenceRepository _evidenceRepository =
      InspectionEvidenceRepository();

  final InspectionFindingsRepository _findingsRepository =
      InspectionFindingsRepository();

  final InspectionSubmissionRepository _submissionRepository =
      InspectionSubmissionRepository();

  final AssignmentsRepository _assignmentsRepository = AssignmentsRepository();

  final TextEditingController _remarksController = TextEditingController();

  Map<String, dynamic>? _arrivalVerification;
  List<Map<String, dynamic>> _checklistResponses = [];
  List<Map<String, dynamic>> _evidence = [];
  List<Map<String, dynamic>> _findings = [];

  bool _isLoading = true;
  bool _isSubmitting = false;

  String _riskLevel = 'low';

  @override
  void initState() {
    super.initState();
    _loadSummaryData();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadSummaryData() async {
    try {
      final arrival = await _arrivalRepository.getVerificationByAssignmentId(
        widget.assignment.id,
      );

      final checklist = await _checklistRepository.getChecklistResponses(
        widget.assignment.id,
      );

      final evidence = await _evidenceRepository.getEvidence(
        widget.assignment.id,
      );

      final findings = await _findingsRepository.getFindings(
        widget.assignment.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _arrivalVerification = arrival;
        _checklistResponses = checklist;
        _evidence = evidence;
        _findings = findings;
        _riskLevel = _calculateRiskLevel(findings);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage('Unable to load inspection summary: $error', isError: true);
    }
  }

  String _calculateRiskLevel(List<Map<String, dynamic>> findings) {
    var hasHigh = false;
    var hasMedium = false;

    for (final finding in findings) {
      final severity =
          finding['severity']?.toString().toLowerCase() ?? 'medium';

      if (severity == 'high') {
        hasHigh = true;
      } else if (severity == 'medium') {
        hasMedium = true;
      }
    }

    if (hasHigh) {
      return 'high';
    }

    if (hasMedium) {
      return 'medium';
    }

    return 'low';
  }

  int get _yesCount {
    return _checklistResponses
        .where((response) => response['answer'] == true)
        .length;
  }

  int get _noCount {
    return _checklistResponses
        .where((response) => response['answer'] == false)
        .length;
  }

  int get _highFindingCount {
    return _findings.where((finding) {
      return finding['severity']?.toString().toLowerCase() == 'high';
    }).length;
  }

  int get _mediumFindingCount {
    return _findings.where((finding) {
      return finding['severity']?.toString().toLowerCase() == 'medium';
    }).length;
  }

  int get _lowFindingCount {
    return _findings.where((finding) {
      return finding['severity']?.toString().toLowerCase() == 'low';
    }).length;
  }

  Color _riskColor(String risk) {
    switch (risk.toLowerCase()) {
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

  String _formatDateTime(dynamic value) {
    if (value == null) {
      return 'Not available';
    }

    final parsed = DateTime.tryParse(value.toString());

    if (parsed == null) {
      return value.toString();
    }

    final local = parsed.toLocal();

    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final minute = local.minute.toString().padLeft(2, '0');

    return '${local.day}/${local.month}/${local.year} · '
        '$hour:$minute $period';
  }

  String _formatDistance(dynamic value) {
    if (value == null) {
      return 'Not available';
    }

    final distance = double.tryParse(value.toString());

    if (distance == null) {
      return value.toString();
    }

    return '${distance.toStringAsFixed(2)} km';
  }

  Future<void> _submitInspection() async {
    if (_isSubmitting) {
      return;
    }

    final inspectorProfileId = _submissionRepository.getCurrentUserId();

    if (inspectorProfileId == null) {
      _showMessage(
        'No authenticated inspector session was found.',
        isError: true,
      );
      return;
    }

    if (_arrivalVerification == null) {
      _showMessage(
        'Arrival verification is required before submission.',
        isError: true,
      );
      return;
    }

    if (_checklistResponses.isEmpty) {
      _showMessage(
        'Checklist responses are required before submission.',
        isError: true,
      );
      return;
    }

    if (_findings.isEmpty) {
      _showMessage(
        'Please add at least one finding before submission.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final remarks = _remarksController.text.trim();

      final summary =
          'Inspection completed for ${widget.assignment.projectName}. '
          'Checklist: $_yesCount Yes, $_noCount No. '
          'Evidence items: ${_evidence.length}. '
          'Findings: ${_findings.length}. '
          'Risk level: ${_riskLevel.toUpperCase()}.';

      // Step 1: Save the final inspection submission.
      await _submissionRepository.saveSubmission(
        assignmentId: widget.assignment.id,
        inspectorProfileId: inspectorProfileId,
        instituteProfileId: widget.assignment.instituteProfileId,
        overallStatus: 'submitted',
        riskLevel: _riskLevel,
        inspectorRemarks: remarks.isEmpty ? null : remarks,
        reportSummary: summary,
      );

      // Step 2: Mark the assignment as completed only
      // after the inspection submission has been saved.
      await _assignmentsRepository.markAssignmentCompleted(
        widget.assignment.id,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Inspection submitted and assignment completed successfully.',
      );

      await Future<void>.delayed(const Duration(milliseconds: 700));

      if (!mounted) {
        return;
      }

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('Inspection could not be completed: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
            'Inspection Assignment',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            widget.assignment.projectName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
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
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.schedule_outlined,
                size: 18,
                color: Colors.black54,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _formatDateTime(widget.assignment.scheduledDateTime),
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArrivalSection() {
    final verified = _arrivalVerification != null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.indigo),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Arrival Verification',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              StatusBadge(
                label: verified ? 'VERIFIED' : 'NOT VERIFIED',
                color: verified ? Colors.green : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (verified) ...[
            _buildSummaryRow(
              'Verified At',
              _formatDateTime(_arrivalVerification!['verified_at']),
            ),
            _buildSummaryRow(
              'Distance',
              _formatDistance(_arrivalVerification!['distance_km']),
            ),
          ] else
            const Text(
              'Arrival verification was not found.',
              style: TextStyle(color: Colors.black54),
            ),
        ],
      ),
    );
  }

  Widget _buildChecklistSection() {
    final total = _checklistResponses.length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.checklist_outlined, color: Colors.indigo),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Checklist Results',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildCountTile(
                  label: 'Total',
                  value: total,
                  icon: Icons.list_alt_outlined,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCountTile(
                  label: 'Yes',
                  value: _yesCount,
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCountTile(
                  label: 'No',
                  value: _noCount,
                  icon: Icons.cancel_outlined,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceSection() {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Evidence Uploaded',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${_evidence.length}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildFindingsSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_outlined, color: Colors.indigo),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Findings Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${_findings.length}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildCountTile(
                  label: 'High',
                  value: _highFindingCount,
                  icon: Icons.priority_high,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCountTile(
                  label: 'Medium',
                  value: _mediumFindingCount,
                  icon: Icons.remove_circle_outline,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCountTile(
                  label: 'Low',
                  value: _lowFindingCount,
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._findings.map(_buildFindingPreview),
        ],
      ),
    );
  }

  Widget _buildFindingPreview(Map<String, dynamic> finding) {
    final title = finding['title']?.toString() ?? 'Untitled Finding';

    final category = finding['category']?.toString() ?? 'Other';

    final severity = finding['severity']?.toString().toLowerCase() ?? 'medium';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            StatusBadge(
              label: severity.toUpperCase(),
              color: _riskColor(severity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskSection() {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _riskColor(_riskLevel).withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield_outlined, color: _riskColor(_riskLevel)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Risk Level',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                SizedBox(height: 4),
                Text(
                  'Calculated from inspection findings',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          StatusBadge(
            label: _riskLevel.toUpperCase(),
            color: _riskColor(_riskLevel),
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inspector Remarks',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _remarksController,
            enabled: !_isSubmitting,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Enter any final observations or remarks...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountTile({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inspection Summary')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                const Text(
                  'Review Inspection',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Review all inspection information before submitting the final report.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                _buildAssignmentCard(),
                const SizedBox(height: 12),
                _buildArrivalSection(),
                const SizedBox(height: 12),
                _buildChecklistSection(),
                const SizedBox(height: 12),
                _buildEvidenceSection(),
                const SizedBox(height: 12),
                _buildFindingsSection(),
                const SizedBox(height: 12),
                _buildRiskSection(),
                const SizedBox(height: 12),
                _buildRemarksSection(),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: _isSubmitting
                      ? 'Completing Inspection...'
                      : 'Submit Inspection',
                  onPressed: _isSubmitting ? () {} : _submitInspection,
                ),
              ],
            ),
    );
  }
}
