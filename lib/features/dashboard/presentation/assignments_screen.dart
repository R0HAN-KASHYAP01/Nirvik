import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/assignment.dart';
import '../data/assignments_repository.dart';
import 'assignment_details_screen.dart';

class AssignmentsScreen extends StatefulWidget {
  final AssignmentStatus? initialStatus;
  final String? initialFilter;

  const AssignmentsScreen({super.key, this.initialStatus, this.initialFilter});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final AssignmentsRepository _repository = AssignmentsRepository();

  List<AssignmentSummary> _assignments = [];
  bool _isLoading = true;
  String? _errorMessage;

  AssignmentStatus? _selectedStatus;
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();

    _selectedStatus = widget.initialStatus;
    _selectedFilter = widget.initialFilter;

    _loadAssignments();
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
        _errorMessage = 'Unable to load assignments.';
      });

      debugPrint('Failed to load assignments: $error');
    }
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  List<AssignmentSummary> get _filteredAssignments {
    var result = List<AssignmentSummary>.from(_assignments);

    if (_selectedFilter == 'today') {
      final now = DateTime.now();

      result = result.where((assignment) {
        return _isSameDay(assignment.scheduledDateTime, now);
      }).toList();
    } else if (_selectedFilter == 'upcoming') {
      final now = DateTime.now();

      result = result.where((assignment) {
        return assignment.scheduledDateTime.isAfter(now) &&
            assignment.status != AssignmentStatus.completed;
      }).toList();
    }

    if (_selectedStatus != null) {
      result = result
          .where((assignment) => assignment.status == _selectedStatus)
          .toList();
    }

    return result;
  }

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

  String _statusFilterLabel(AssignmentStatus? status) {
    if (status == null) {
      return 'All';
    }

    return status.label;
  }

  Widget _buildFilterBar() {
    final filters = <AssignmentStatus?>[
      null,
      AssignmentStatus.assigned,
      AssignmentStatus.inProgress,
      AssignmentStatus.overdue,
      AssignmentStatus.completed,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((status) {
          final selected = _selectedStatus == status;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_statusFilterLabel(status)),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _selectedStatus = status;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAssignmentCard(AssignmentSummary assignment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      assignment.projectName,
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
                      assignment.location,
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
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  StatusBadge(
                    label: '${assignment.priority.label} priority',
                    color: _priorityColor(assignment.priority),
                  ),
                  const Spacer(),
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

  String get _screenTitle {
    if (_selectedFilter == 'today') {
      return "Today's Assignments";
    }

    if (_selectedFilter == 'upcoming') {
      return 'Upcoming Assignments';
    }

    if (_selectedStatus == AssignmentStatus.overdue) {
      return 'Overdue Assignments';
    }

    if (_selectedStatus == AssignmentStatus.completed) {
      return 'Completed Assignments';
    }

    return 'Assignments';
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

    final assignments = _filteredAssignments;

    if (_assignments.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.assignment_outlined,
          title: 'No assignments found',
          message:
              'Assignments will appear here when they are assigned to you.',
        ),
      );
    }

    if (assignments.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.filter_alt_off_outlined,
          title: 'No matching assignments',
          message: 'There are no assignments matching this category.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAssignments,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          SectionHeader(
            title: _screenTitle,
            actionLabel: '${assignments.length} found',
          ),
          const SizedBox(height: 12),
          _buildFilterBar(),
          const SizedBox(height: 16),
          ...assignments.map(_buildAssignmentCard),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_screenTitle)),
      body: _buildBody(),
    );
  }
}
