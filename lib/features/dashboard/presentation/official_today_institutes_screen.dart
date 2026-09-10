import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/assignment.dart';
import '../data/assignments_repository.dart';
import 'official_institute_info_screen.dart';

/// Read-only list of institutes assigned for today's inspections, shown to
/// the Official role from the homepage "Today's Inspections" tile.
///
/// Unlike [AssignmentsScreen] (used by PMU Inspectors), tapping an item here
/// never opens the inspection workflow — it only opens a basic-info view.
class OfficialTodayInstitutesScreen extends StatefulWidget {
  const OfficialTodayInstitutesScreen({super.key});

  @override
  State<OfficialTodayInstitutesScreen> createState() =>
      _OfficialTodayInstitutesScreenState();
}

class _OfficialTodayInstitutesScreenState
    extends State<OfficialTodayInstitutesScreen> {
  final AssignmentsRepository _repository = AssignmentsRepository();

  List<AssignmentSummary> _assignments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final assignments = await _repository.getAssignments();

      if (!mounted) return;

      setState(() {
        _assignments = assignments;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load institutes.';
      });

      debugPrint('Failed to load today\'s institutes: $error');
    }
  }

  List<AssignmentSummary> get _todaysInstitutes {
    final now = DateTime.now();
    return _assignments
        .where((assignment) => _isSameDay(assignment.scheduledDateTime, now))
        .toList();
  }

  Color _statusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.assigned:
        return Colors.blueGrey;
      case AssignmentStatus.inProgress:
        return Colors.indigo;
      case AssignmentStatus.completed:
        return Colors.green;
      case AssignmentStatus.expired:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} · '
        '$hour:$minute $period';
  }

  Widget _buildInstituteCard(AssignmentSummary assignment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    OfficialInstituteInfoScreen(assignment: assignment),
              ),
            );
          },
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  StatusBadge(
                    label: assignment.status.label,
                    color: _statusColor(assignment.status),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.black45,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      assignment.displayLocation,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: Colors.black45,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _formatDateTime(assignment.scheduledDateTime),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.black38,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 44,
                  color: Colors.black45,
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _loadAssignments,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final institutes = _todaysInstitutes;

    if (institutes.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.apartment_outlined,
          title: 'No institutes scheduled today',
          message: 'Institutes assigned for inspection today will appear here.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAssignments,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: institutes.map(_buildInstituteCard).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Inspections")),
      body: _buildBody(),
    );
  }
}