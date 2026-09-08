import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/assignment.dart';
import 'arrival_verification_screen.dart';

class AssignmentDetailsScreen extends StatelessWidget {
  final AssignmentSummary assignment;

  const AssignmentDetailsScreen({super.key, required this.assignment});

  Color _statusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.assigned:
        return Colors.blueGrey;
      case AssignmentStatus.inProgress:
        return Colors.indigo;
      case AssignmentStatus.overdue:
        return Colors.red;
      case AssignmentStatus.completed:
        return Colors.green;
    }
  }

  Color _priorityColor(Priority priority) {
    switch (priority) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.orange;
      case Priority.high:
        return Colors.red;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} · '
        '$hour:$minute $period';
  }

  void _startInspection(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArrivalVerificationScreen(assignment: assignment),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assignment Status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              StatusBadge(
                label: assignment.status.label,
                color: _statusColor(assignment.status),
              ),
              const SizedBox(width: 10),
              StatusBadge(
                label: '${assignment.priority.label} priority',
                color: _priorityColor(assignment.priority),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentInformation() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assignment Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),
          _buildInfoRow(
            icon: Icons.business_outlined,
            label: 'Project / Institute',
            value: assignment.projectName,
          ),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: assignment.location,
          ),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Scheduled Date & Time',
            value: _formatDateTime(assignment.scheduledDateTime),
          ),
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: 'Assignment ID',
            value: assignment.id,
          ),
          _buildInfoRow(
            icon: Icons.account_balance_outlined,
            label: 'Institute Profile ID',
            value: assignment.instituteProfileId,
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionInformation() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inspection',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          const Text(
            'Review the assignment information before starting the inspection.',
            style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.fact_check_outlined,
                size: 20,
                color: Colors.black54,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Inspection Workflow',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Arrival verification → Checklist → Evidence → Findings → Summary → Submission',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
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
    final canStartInspection =
        assignment.status == AssignmentStatus.assigned ||
        assignment.status == AssignmentStatus.inProgress ||
        assignment.status == AssignmentStatus.overdue;

    return Scaffold(
      appBar: AppBar(title: const Text('Assignment Details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            assignment.projectName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            assignment.location,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          _buildStatusSection(),
          const SizedBox(height: 12),
          _buildAssignmentInformation(),
          const SizedBox(height: 12),
          _buildInspectionInformation(),
          const SizedBox(height: 20),
          if (canStartInspection)
            PrimaryButton(
              label: 'Start Inspection',
              onPressed: () => _startInspection(context),
            )
          else
            const AppCard(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This assignment has already been completed.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
