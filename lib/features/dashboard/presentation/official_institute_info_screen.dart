import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/assignment.dart';

/// Basic, read-only information about an institute's scheduled inspection,
/// shown to the Official role. Intentionally has no "Start Inspection"
/// action — officials review institutes, they don't perform inspections.
class OfficialInstituteInfoScreen extends StatelessWidget {
  final AssignmentSummary assignment;

  const OfficialInstituteInfoScreen({super.key, required this.assignment});

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

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.black45),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Institute Information')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        assignment.projectName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    StatusBadge(
                      label: assignment.status.label,
                      color: _statusColor(assignment.status),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                StatusBadge(
                  label: '${assignment.priority.label} priority',
                  color: _priorityColor(assignment.priority),
                ),
                const SizedBox(height: 20),
                _infoRow(
                  Icons.location_on_outlined,
                  'Location',
                  assignment.location,
                ),
                _infoRow(
                  Icons.calendar_today_outlined,
                  'Scheduled Date & Time',
                  _formatDateTime(assignment.scheduledDateTime),
                ),
                if (assignment.instituteLatitude != null &&
                    assignment.instituteLongitude != null)
                  _infoRow(
                    Icons.map_outlined,
                    'Coordinates',
                    '${assignment.instituteLatitude!.toStringAsFixed(5)}, '
                        '${assignment.instituteLongitude!.toStringAsFixed(5)}',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}