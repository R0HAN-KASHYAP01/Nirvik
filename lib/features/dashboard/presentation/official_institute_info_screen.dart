import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/assignment.dart';

/// Basic, read-only information about an institute's scheduled inspection,
/// shown to the Official role. Intentionally has no "Start Inspection"
/// action — officials review institutes, they don't perform inspections.
class OfficialInstituteInfoScreen extends StatelessWidget {
  final AssignmentSummary assignment;

  const OfficialInstituteInfoScreen({
    super.key,
    required this.assignment,
  });

  // Government Digital India theme
  static const Color _navy = Color(0xFF123E68);
  static const Color _background = Color(0xFFEAF1F6);
  static const Color _cardBackground = Color(0xFFE1ECF3);
  static const Color _textDark = Color(0xFF17324D);
  static const Color _textGrey = Color(0xFF667788);
  static const Color _border = Color(0xFFD1DEE7);
  static const Color _green = Color(0xFF168A45);
  static const Color _saffron = Color(0xFFE88A18);
  static const Color _red = Color(0xFFD64545);

  Color _statusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.assigned:
        return _navy;
      case AssignmentStatus.inProgress:
        return Colors.indigo;
      case AssignmentStatus.completed:
        return _green;
      case AssignmentStatus.expired:
        return Colors.grey;
    }
  }

  Color _priorityColor(Priority priority) {
    switch (priority) {
      case Priority.low:
        return _green;
      case Priority.medium:
        return _saffron;
      case Priority.high:
        return _red;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} · '
        '$hour:$minute $period';
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: _navy,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
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
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Institute Information',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: _cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _border,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          assignment.displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
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
                    assignment.displayLocation,
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
          ),
        ],
      ),
    );
  }
}