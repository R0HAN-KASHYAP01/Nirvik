import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/summary_stat_card.dart';
import '../../../models/assignment.dart';
import '../../../services/session_service.dart';
import '../data/assignments_repository.dart';
import 'assignments_screen.dart';
import 'widgets/assignment_card.dart';
import '../../calls/presentation/widgets/random_call_button.dart';
import '../../calls/presentation/call_history_screen.dart';

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

  int get _activeCount {
    return _assignments
        .where((assignment) =>
            assignment.status == AssignmentStatus.assigned ||
            assignment.status == AssignmentStatus.inProgress)
        .length;
  }

  int get _expiredCount {
    return _assignments
        .where(
          (assignment) =>
              assignment.status == AssignmentStatus.expired,
        )
        .length;
  }

  int get _completedCount {
    return _assignments
        .where(
          (assignment) =>
              assignment.status == AssignmentStatus.completed,
        )
        .length;
  }

  void _openAssignments({
    AssignmentStatus? status,
    String? filter,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AssignmentsScreen(
          initialStatus: status,
          initialFilter: filter,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF1F6),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF123E68),
          backgroundColor: Colors.white,
          onRefresh: _loadAssignments,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              _InspectorHeader(
                userName: user?.name ?? 'PMU Inspector',
              ),

              const SizedBox(height: 20),

              PrimaryButton(
                label: 'Start Assigned Inspection',
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.inspectionWorkflowPlaceholder,
                  );
                },
              ),

              const SizedBox(height: 12),

              const SizedBox(
                width: double.infinity,
                child: RandomVideoCallButton(),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: SummaryStatCard(
                      icon: Icons.today,
                      label: 'Today',
                      count: _isLoading ? '—' : '$_todayCount',
                      onTap: () => _openAssignments(
                        filter: 'today',
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: SummaryStatCard(
                      icon: Icons.pending_actions_outlined,
                      label: 'Active',
                      count: _isLoading ? '—' : '$_activeCount',
                      accentColor: Colors.indigo,
                      onTap: () => _openAssignments(
                        status: AssignmentStatus.assigned,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: SummaryStatCard(
                      icon: Icons.check_circle_outline,
                      label: 'Done',
                      count: _isLoading ? '—' : '$_completedCount',
                      accentColor: const Color(0xFF159447),
                      onTap: () => _openAssignments(
                        status: AssignmentStatus.completed,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: SummaryStatCard(
                      icon: Icons.error_outline,
                      label: 'Expired',
                      count: _isLoading ? '—' : '$_expiredCount',
                      accentColor: const Color(0xFFD64545),
                      onTap: () => _openAssignments(
                        status: AssignmentStatus.expired,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Expanded(child: SizedBox()),

                  const SizedBox(width: 8),

                  const Expanded(child: SizedBox()),
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
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF123E68),
                      ),
                    ),
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
                          color: Color(0xFF667788),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF667788),
                          ),
                        ),

                        const SizedBox(height: 12),

                        OutlinedButton.icon(
                          onPressed: _loadAssignments,
                          icon: const Icon(
                            Icons.refresh,
                            color: Color(0xFF123E68),
                          ),
                          label: const Text(
                            'Retry',
                            style: TextStyle(
                              color: Color(0xFF123E68),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFB8CBD8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_todaysAssignments.isEmpty)
                const EmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'No assignments today',
                  message:
                      'New assignments will appear here once scheduled.',
                )
              else
                Column(
                  children: _todaysAssignments
                      .map(
                        (assignment) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: 10),
                          child: AssignmentCard(
                            assignment: assignment,
                          ),
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
                      color: Color(0xFF123E68),
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Text(
                        'Nearby assignments on map',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF17324D),
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.instituteMap,
                        );
                      },
                      child: const Text(
                        'View',
                        style: TextStyle(
                          color: Color(0xFF123E68),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

class _InspectorHeader extends StatelessWidget {
  final String userName;

  const _InspectorHeader({
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF123E68),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 25,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back,',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF667788),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                userName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF17324D),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        IconButton(
          icon: const Icon(
            Icons.map_outlined,
            color: Color(0xFF17324D),
          ),
          tooltip: 'Institute Map',
          onPressed: () => Navigator.of(context).pushNamed(
            AppRoutes.instituteMap,
          ),
        ),

        IconButton(
          icon: const Icon(
            Icons.history,
            color: Color(0xFF17324D),
          ),
          tooltip: 'Call History',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CallHistoryScreen(),
            ),
          ),
        ),

        IconButton(
          icon: const Icon(
            Icons.notifications_none,
            color: Color(0xFF17324D),
          ),
          onPressed: () {},
        ),
      ],
    );
  }
}