import 'package:flutter/material.dart';

import '../../../../models/assignment.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../assignment_details_screen.dart';

class AssignmentCard extends StatelessWidget {
  final AssignmentSummary assignment;

  const AssignmentCard({super.key, required this.assignment});

  Color get _priorityColor {
    switch (assignment.priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }

  Color get _statusColor {
    switch (assignment.status) {
      case AssignmentStatus.overdue:
        return Colors.red;
      case AssignmentStatus.inProgress:
        return Colors.indigo;
      case AssignmentStatus.completed:
        return Colors.green;
      case AssignmentStatus.assigned:
        return Colors.blueGrey;
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');

    return '${dt.day}/${dt.month} · $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AssignmentDetailsScreen(assignment: assignment),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    assignment.projectName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusBadge(
                  label: assignment.status.label,
                  color: _statusColor,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Colors.black38,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    assignment.location,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.black38),
                const SizedBox(width: 4),
                Text(
                  _formatTime(assignment.scheduledDateTime),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const Spacer(),
                StatusBadge(
                  label: '${assignment.priority.label} priority',
                  color: _priorityColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
