import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/assignment.dart';

/// Basic, read-only information about an institute's scheduled inspection,
/// shown to the Official role.
///
/// Officials can review institute information but do not perform inspections.
class OfficialInstituteInfoScreen extends StatelessWidget {
  final AssignmentSummary assignment;

  const OfficialInstituteInfoScreen({
    super.key,
    required this.assignment,
  });

  // ---------------------------------------------------------------------------
  // Theme
  // ---------------------------------------------------------------------------

  static const Color _navy = Color(0xFF123E68);
  static const Color _primaryBlue = Color(0xFF14568A);

  static const Color _background = Color(0xFFEAF2F8);
  static const Color _cardBackground = Color(0xFFE1ECF3);
  static const Color _borderColor = Color(0xFFD1DEE7);

  static const Color _textDark = Color(0xFF17324D);
  static const Color _textGrey = Color(0xFF667788);

  // ---------------------------------------------------------------------------
  // Status / Priority
  // ---------------------------------------------------------------------------

  Color _statusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.assigned:
        return Colors.blueGrey;
      case AssignmentStatus.inProgress:
        return Colors.indigo;
      case AssignmentStatus.expired:
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

  // ---------------------------------------------------------------------------
  // Info Row
  // ---------------------------------------------------------------------------

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
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: _borderColor,
              ),
            ),
            child: Icon(
              icon,
              size: 17,
              color: _navy,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
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

  // ---------------------------------------------------------------------------
  // Responsive Header
  // ---------------------------------------------------------------------------

  Widget _buildInstituteHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 350;

        if (isSmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                assignment.instituteName,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 10),
              StatusBadge(
                label: assignment.status.label,
                color: _statusColor(assignment.status),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                assignment.instituteName,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Align(
                alignment: Alignment.topRight,
                child: StatusBadge(
                  label: assignment.status.label,
                  color: _statusColor(assignment.status),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Screen
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final hasInspectorDetails =
        (assignment.inspectorDesignation != null &&
                assignment.inspectorDesignation!.isNotEmpty) ||
            (assignment.inspectorDepartment != null &&
                assignment.inspectorDepartment!.isNotEmpty);

    final inspectorDetails = [
      assignment.inspectorDesignation,
      assignment.inspectorDepartment,
    ].where((value) => value != null && value.isNotEmpty).join(' · ');

    return Scaffold(
      backgroundColor: _background,

      // -----------------------------------------------------------------------
      // App Bar
      // -----------------------------------------------------------------------
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: const Text(
          'Institute Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // -----------------------------------------------------------------------
      // Body
      // -----------------------------------------------------------------------
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            28,
          ),
          children: [
            // =================================================================
            // Institute Information Card
            // =================================================================
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInstituteHeader(context),

                  const SizedBox(height: 10),

                  // Priority badge
                  Align(
                    alignment: Alignment.centerLeft,
                    child: StatusBadge(
                      label: '${assignment.priority.label} priority',
                      color: _priorityColor(assignment.priority),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Location
                  _infoRow(
                    Icons.location_on_outlined,
                    'Location',
                    assignment.fullAddress,
                  ),

                  // Scheduled date
                  _infoRow(
                    Icons.calendar_today_outlined,
                    'Scheduled Date & Time',
                    _formatDateTime(
                      assignment.scheduledDateTime,
                    ),
                  ),

                  // Coordinates
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

            const SizedBox(height: 16),

            // =================================================================
            // Inspector Information Card
            // =================================================================
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _borderColor,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 19,
                          color: _primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Assigned PMU Inspector',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Inspector name
                  _infoRow(
                    Icons.person_outline,
                    'Inspector Name',
                    assignment.inspectorName ??
                        'No inspector assigned',
                  ),

                  // Inspector designation / department
                  if (hasInspectorDetails)
                    _infoRow(
                      Icons.badge_outlined,
                      'Designation / Department',
                      inspectorDetails,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // =================================================================
            // Read-only information note
            // =================================================================
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _borderColor,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: _primaryBlue,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'This is a read-only institute information view for '
                      'Officials.',
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: _textGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}