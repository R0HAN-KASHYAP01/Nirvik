import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/assignment.dart';
import '../data/inspection_checklist_repository.dart';
import 'evidence_screen.dart';

class InspectionChecklistScreen extends StatefulWidget {
  final AssignmentSummary assignment;

  const InspectionChecklistScreen({super.key, required this.assignment});

  @override
  State<InspectionChecklistScreen> createState() =>
      _InspectionChecklistScreenState();
}

class _InspectionChecklistScreenState extends State<InspectionChecklistScreen> {
  final InspectionChecklistRepository _repository =
      InspectionChecklistRepository();

  final Map<int, bool?> _answers = {};

  bool _isSaving = false;

  final List<_ChecklistItem> _checklistItems = const [
    _ChecklistItem(
      id: 1,
      title: 'Institute is operational',
      description: 'Verify that the institute is functioning and activities are being conducted as expected.',
    ),
    _ChecklistItem(
      id: 2,
      title: 'Staff are present',
      description:
          'Verify the presence of required staff members at the institute.',
    ),
    _ChecklistItem(
      id: 3,
      title: 'Beneficiaries are present',
      description: 'Verify that beneficiaries are present and participating in the programme.',
    ),
    _ChecklistItem(
      id: 4,
      title: 'Required facilities are available',
      description: 'Check whether the required infrastructure and facilities are available and usable.',
    ),
    _ChecklistItem(
      id: 5,
      title: 'Records and registers are maintained',
      description: 'Verify that required records, registers and documentation are properly maintained.',
    ),
    _ChecklistItem(
      id: 6,
      title: 'Programme activities are being conducted',
      description: 'Verify that activities are being conducted according to the approved programme.',
    ),
    _ChecklistItem(
      id: 7,
      title: 'Safety and hygiene standards are maintained',
      description: 'Check the general safety, cleanliness and hygiene conditions of the institute.',
    ),
    _ChecklistItem(
      id: 8,
      title: 'No major irregularity observed',
      description: 'Confirm whether there are no major irregularities requiring immediate attention.',
    ),
  ];

  int get _answeredCount {
    return _answers.values.where((answer) => answer != null).length;
  }

  bool get _isComplete {
    return _answeredCount == _checklistItems.length;
  }

  void _setAnswer(int id, bool value) {
    if (_isSaving) {
      return;
    }

    setState(() {
      _answers[id] = value;
    });
  }

  Future<void> _continueToEvidence() async {
    if (_isSaving) {
      return;
    }

    if (!_isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all checklist items before continuing.'),
        ),
      );
      return;
    }

    final inspectorProfileId = _repository.getCurrentUserId();

    if (inspectorProfileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No authenticated inspector was found. Please sign in again.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final responses = _checklistItems.map((item) {
        return {
          'checklist_item_id': item.id,
          'checklist_item_title': item.title,
          'answer': _answers[item.id],
        };
      }).toList();

      await _repository.saveChecklistResponses(
        assignmentId: widget.assignment.id,
        inspectorProfileId: inspectorProfileId,
        instituteProfileId: widget.assignment.instituteProfileId,
        responses: responses,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checklist responses saved successfully.'),
        ),
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EvidenceScreen(assignment: widget.assignment),
        ),
      );
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checklist could not be saved: ${error.message}'),
        ),
      );

      debugPrint('Checklist Supabase error: $error');
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save checklist. Please try again.'),
        ),
      );

      debugPrint('Checklist save error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildProgressCard() {
    final progress = _checklistItems.isEmpty
        ? 0.0
        : _answeredCount / _checklistItems.length;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_outlined, color: Colors.indigo),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Inspection Progress',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '$_answeredCount/${_checklistItems.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 8),
          Text(
            _isComplete
                ? 'All checklist items have been answered.'
                : 'Answer every item before continuing.',
            style: TextStyle(
              fontSize: 12,
              color: _isComplete ? Colors.green : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Inspection',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            widget.assignment.projectName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
              const SizedBox(width: 8),
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

  Widget _buildChecklistItem(_ChecklistItem item) {
    final answer = _answers[item.id];

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${item.id}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.indigo,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _setAnswer(item.id, true),
                  icon: Icon(
                    answer == true
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                  ),
                  label: const Text('Yes'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: answer == true
                        ? Colors.green
                        : Colors.black54,
                    side: BorderSide(
                      color: answer == true ? Colors.green : Colors.black26,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _setAnswer(item.id, false),
                  icon: Icon(
                    answer == false ? Icons.cancel : Icons.cancel_outlined,
                  ),
                  label: const Text('No'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: answer == false
                        ? Colors.red
                        : Colors.black54,
                    side: BorderSide(
                      color: answer == false ? Colors.red : Colors.black26,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inspection Checklist')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text(
            'Inspection Checklist',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Review each requirement and record your observation for the assigned institute.',
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 20),
          _buildAssignmentCard(),
          const SizedBox(height: 12),
          _buildProgressCard(),
          const SizedBox(height: 16),
          ..._checklistItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildChecklistItem(item),
            ),
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            label: _isSaving ? 'Saving Checklist...' : 'Continue to Evidence',
            onPressed: _isSaving
                ? () {}
                : () {
                    _continueToEvidence();
                  },
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem {
  final int id;
  final String title;
  final String description;

  const _ChecklistItem({
    required this.id,
    required this.title,
    required this.description,
  });
}
