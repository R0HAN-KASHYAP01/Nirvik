import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/summary_stat_card.dart';
import '../../../models/assignment.dart';
import '../../../services/session_service.dart';
import '../data/assignments_repository.dart';
import 'assignments_screen.dart';
import 'widgets/assignment_card.dart';

class InspectorHomeScreen extends StatefulWidget {
  const InspectorHomeScreen({super.key});

  @override
  State<InspectorHomeScreen> createState() => _InspectorHomeScreenState();
}

class _InspectorHomeScreenState extends State<InspectorHomeScreen> {
  final AssignmentsRepository _repository = AssignmentsRepository();

  List<AssignmentSummary> _assignments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
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

  List<AssignmentSummary> get _todaysAssignments {
    final now = DateTime.now();

    return _assignments.where((assignment) {
      final date = assignment.scheduledDateTime;

      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList();
  }

  int get _todayCount => _todaysAssignments.length;

  int get _overdueCount {
    return _assignments
        .where((assignment) => assignment.status == AssignmentStatus.overdue)
        .length;
  }

  int get _upcomingCount {
    final now = DateTime.now();

    return _assignments.where((assignment) {
      return assignment.scheduledDateTime.isAfter(now) &&
          assignment.status != AssignmentStatus.completed;
    }).length;
  }

  int get _completedCount {
    return _assignments
        .where((assignment) => assignment.status == AssignmentStatus.completed)
        .length;
  }

  void _openAssignments({AssignmentStatus? status, String? filter}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AssignmentsScreen(initialStatus: status, initialFilter: filter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAssignments,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              _InspectorHeader(userName: user?.name ?? 'PMU Inspector'),

              const SizedBox(height: 20),

              PrimaryButton(
                label: 'Start Assigned Inspection',
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed(AppRoutes.inspectionWorkflowPlaceholder);
                },
              ),

              const SizedBox(height: 24),

              // Row of Expanded cards — each sizes to its own content, so it
              // can never overflow regardless of text length or font scale
              // (the previous fixed-aspect-ratio GridView could).
              Row(
                children: [
                  Expanded(
                    child: SummaryStatCard(
                      icon: Icons.today,
                      label: 'Today',
                      count: _isLoading ? '—' : '$_todayCount',
                      onTap: () => _openAssignments(filter: 'today'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SummaryStatCard(
                      icon: Icons.error_outline,
                      label: 'Overdue',
                      count: _isLoading ? '—' : '$_overdueCount',
                      accentColor: Colors.red,
                      onTap: () => _openAssignments(status: AssignmentStatus.overdue),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SummaryStatCard(
                      icon: Icons.upcoming_outlined,
                      label: 'Upcoming',
                      count: _isLoading ? '—' : '$_upcomingCount',
                      accentColor: Colors.orange,
                      onTap: () => _openAssignments(filter: 'upcoming'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SummaryStatCard(
                      icon: Icons.check_circle_outline,
                      label: 'Done',
                      count: _isLoading ? '—' : '$_completedCount',
                      accentColor: Colors.green,
                      onTap: () => _openAssignments(status: AssignmentStatus.completed),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              SectionHeader(
                title: "Today's Assignments",
                actionLabel: 'View all',
                onActionTap: () {
                  _openAssignments();
                },
              ),

              const SizedBox(height: 10),

              if (_isLoading)
                const AppCard(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (_errorMessage != null)
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          size: 40,
                          color: Colors.black45,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _loadAssignments,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_todaysAssignments.isEmpty)
                const EmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'No assignments today',
                  message: 'New assignments will appear here once scheduled.',
                )
              else
                Column(
                  children: _todaysAssignments
                      .map(
                        (assignment) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AssignmentCard(assignment: assignment),
                        ),
                      )
                      .toList(),
                ),

              const SizedBox(height: 16),

              AppCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.map_outlined,
                      size: 24,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Nearby assignments on map',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRoutes.instituteMap);
                      },
                      child: const Text('View'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header for this screen only — greeting, name, and the map/notification
/// actions, with no logout button. The shared DashboardHeader (still used
/// elsewhere, e.g. NGO dashboard) is untouched.
class _InspectorHeader extends StatelessWidget {
  final String userName;
  const _InspectorHeader({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withValues(alpha: 0.10),
          child: const Icon(Icons.person, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Welcome back,', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text(
                userName,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.map_outlined, color: AppColors.textPrimary),
          tooltip: 'Institute Map',
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.instituteMap),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary),
          onPressed: () {},
        ),
      ],
    );
  }
}