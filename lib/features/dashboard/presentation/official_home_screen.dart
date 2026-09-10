import 'package:flutter/material.dart';

import '../../../services/session_service.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/quick_action_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/inspection.dart';
import '../data/assignments_repository.dart';
import '../data/inspection_history_repository.dart';
import '../../projects/data/projects_repository.dart';
import '../../../models/assignment.dart';
import '../../../models/project.dart' as project_model;
import '../../calls/presentation/call_history_screen.dart';
import 'assignments_screen.dart';
import 'official_today_institutes_screen.dart';
import 'inspection_history_screen.dart';
import '../../projects/presentation/project_list_screen.dart';

class OfficialHomeScreen extends StatefulWidget {
  const OfficialHomeScreen({super.key});

  @override
  State<OfficialHomeScreen> createState() => _OfficialHomeScreenState();
}

class _OfficialHomeScreenState extends State<OfficialHomeScreen> {
  final AssignmentsRepository _assignmentsRepository = AssignmentsRepository();
  final ProjectsRepository _projectsRepository = ProjectsRepository();
  final InspectionHistoryRepository _inspectionHistoryRepository =
      InspectionHistoryRepository();

  int? _todaysInspectionsCount;
  int? _pendingReviewsCount;
  int? _totalProjectsCount;
  int? _highRiskCount;
  List<InspectionSummary> _recentInspections = [];

  @override
  void initState() {
    super.initState();
    _loadHomeStats();
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  /// Same fallback pattern already used by AssignmentsRepository/
  /// ProjectsRepository for parsing free-form DB status strings.
  InspectionStatus _parseInspectionStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'approved':
        return InspectionStatus.approved;
      case 'overdue':
        return InspectionStatus.overdue;
      case 'under_review':
      case 'under review':
        return InspectionStatus.underReview;
      case 'in_progress':
      case 'in progress':
        return InspectionStatus.inProgress;
      case 'assigned':
        return InspectionStatus.assigned;
      case 'submitted':
      default:
        return InspectionStatus.submitted;
    }
  }

  RiskLevel _parseRiskLevel(String? value) {
    switch (value?.toLowerCase()) {
      case 'high':
        return RiskLevel.high;
      case 'medium':
        return RiskLevel.medium;
      case 'low':
      default:
        return RiskLevel.low;
    }
  }

  /// Map the same raw rows InspectionHistoryScreen fetches into the
  /// InspectionSummary shape this screen's tile already renders.
  List<InspectionSummary> _mapToRecentInspections(
    List<Map<String, dynamic>> rows,
  ) {
    final topFive = rows.take(5).toList();

    return List.generate(topFive.length, (index) {
      final row = topFive[index];

      final instituteId = row['institute_profile_id']?.toString() ?? '';
      final shortInstituteId = instituteId.isEmpty
          ? 'Unknown'
          : instituteId.substring(0, instituteId.length < 8 ? instituteId.length : 8);

      final submittedAt = DateTime.tryParse(
        row['submitted_at']?.toString() ?? '',
      );

      return InspectionSummary(
        projectName: 'Inspection #${index + 1}',
        inspectorName: 'Institute ID: $shortInstituteId',
        dateTime: submittedAt ?? DateTime.now(),
        status: _parseInspectionStatus(row['overall_status']?.toString()),
        risk: _parseRiskLevel(row['risk_level']?.toString()),
      );
    });
  }

  Future<void> _loadHomeStats() async {
    try {
      final assignments = await _assignmentsRepository.getAssignments();
      final projects = await _projectsRepository.getProjects();
      final inspectionRows =
          await _inspectionHistoryRepository.getInspectionHistory();

      final now = DateTime.now();
      final staleThreshold = now.subtract(const Duration(days: 3));

      final todaysCount = assignments
          .where((a) => _isSameDay(a.scheduledDateTime, now))
          .length;

      final pendingReviewCount = assignments
          .where((a) =>
              a.status == AssignmentStatus.assigned &&
              a.scheduledDateTime.isBefore(staleThreshold))
          .length;

      if (!mounted) return;

      setState(() {
        _todaysInspectionsCount = todaysCount;
        _pendingReviewsCount = pendingReviewCount;
        _totalProjectsCount = projects.length;
        _highRiskCount =
            projects.where((p) => p.riskLevel == project_model.RiskLevel.high).length;
        _recentInspections = _mapToRecentInspections(inspectionRows);
      });
    } catch (error) {
      debugPrint('Failed to load official homepage stats: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser;
    final inspections = _recentInspections;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _HomeHeader(
              userName: user?.name ?? 'DoSJE Official',
              alertCount: 3,
            ),
            const SizedBox(height: 18),

            const _HeroBanner(),
            const SizedBox(height: 16),

            // High-risk alerts get visual priority without alarming the whole screen.
            _AlertBanner(
              count: _highRiskCount ?? 0,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProjectListScreen(initialHighRiskFilter: true),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _MiniStatCard(
                    icon: Icons.calendar_today_outlined,
                    label: "Today's\nInspections",
                    count: _todaysInspectionsCount?.toString() ?? '—',
                    color: AppColors.info,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OfficialTodayInstitutesScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStatCard(
                    icon: Icons.assignment_outlined,
                    label: 'Pending\nReviews',
                    count: _pendingReviewsCount?.toString() ?? '—',
                    color: AppColors.warning,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AssignmentsScreen(initialFilter: 'pendingReview'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStatCard(
                    icon: Icons.apartment_outlined,
                    label: 'Total\nProjects',
                    count: _totalProjectsCount?.toString() ?? '—',
                    color: const Color(0xFF6C4FC2),
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.projectsPlaceholder),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),
            SectionHeader(
              title: 'Recent Inspections',
              actionLabel: 'View all',
              onActionTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const InspectionHistoryScreen(),
                ),
              ),
            ),
            const SizedBox(height: 10),

            if (inspections.isEmpty)
              const EmptyState(
                icon: Icons.fact_check_outlined,
                title: 'No recent inspections',
                message: 'Inspections will appear here once submitted.',
              )
            else
              Column(
                children: inspections
                    .map((i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RecentInspectionTile(inspection: i),
                        ))
                    .toList(),
              ),

            const SizedBox(height: 26),
            const SectionHeader(title: 'Quick Actions'),
            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.apartment,
                    label: 'Projects',
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.projectsPlaceholder),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.fact_check_outlined,
                    label: 'Inspections',
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.inspectionsPlaceholder),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.videocam_outlined,
                    label: 'CCTV',
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.cctvPlaceholder),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.bar_chart,
                    label: 'Analytics',
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.analyticsPlaceholder),
                  ),
                ),
                QuickActionCard(
                  icon: Icons.history,
                  label: 'Call History',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CallHistoryScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Header: avatar, greeting + name, notification bell with badge.
/// Local to this screen — the shared DashboardHeader (used elsewhere) is untouched.
class _HomeHeader extends StatelessWidget {
  final String userName;
  final int alertCount;

  const _HomeHeader({
    required this.userName,
    required this.alertCount,
  });

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

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
              Text(_greeting(), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text(
                userName,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
              const Text('Official', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary),
              onPressed: () {},
            ),
            if (alertCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$alertCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Decorative gradient hero banner with a tricolor wave accent.
class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 96,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: Stack(
          children: [
            // Tricolor wave accent, bottom-right.
            Positioned(
              right: -20,
              bottom: -30,
              child: Transform.rotate(
                angle: -0.35,
                child: Column(
                  children: [
                    Container(width: 160, height: 14, color: const Color(0xFFFF9933).withValues(alpha: 0.55)),
                    Container(width: 160, height: 14, color: Colors.white.withValues(alpha: 0.35)),
                    Container(width: 160, height: 14, color: const Color(0xFF138808).withValues(alpha: 0.55)),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Text(
                'Equitable Society\nStronger India',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _AlertBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEDED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF3C6C6)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFB3261E),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count high-risk alerts require attention',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB3261E),
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFB3261E), size: 18),
        ],
      ),
      ),
    );
  }
}

/// Stat card with a colored icon chip and a small decorative sparkline,
/// matching the reference design. Local to this screen only.
class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final Color color;
  final VoidCallback onTap;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 10),
            Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.2)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(4, (i) {
                final heights = [6.0, 10.0, 8.0, 14.0];
                return Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Container(
                    width: 5,
                    height: heights[i],
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.35 + (i * 0.15)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recent-inspection row with a placeholder thumbnail, matching the
/// reference design. Local to this screen — the shared RecentInspectionCard
/// (used elsewhere) is untouched.
class _RecentInspectionTile extends StatelessWidget {
  final InspectionSummary inspection;
  const _RecentInspectionTile({required this.inspection});

  Color get _statusColor {
    switch (inspection.status) {
      case InspectionStatus.approved:
        return AppColors.success;
      case InspectionStatus.overdue:
        return AppColors.error;
      case InspectionStatus.underReview:
        return AppColors.warning;
      case InspectionStatus.submitted:
        return AppColors.info;
      case InspectionStatus.inProgress:
        return Colors.indigo;
      case InspectionStatus.assigned:
        return Colors.blueGrey;
    }
  }

  Color get _riskColor {
    switch (inspection.risk) {
      case RiskLevel.high:
        return AppColors.error;
      case RiskLevel.medium:
        return AppColors.warning;
      case RiskLevel.low:
        return AppColors.success;
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} Sep ${dt.year} · $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.apartment, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inspection.projectName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(inspection.inspectorName,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 12, color: Colors.black38),
                      const SizedBox(width: 4),
                      Text(_formatTime(inspection.dateTime),
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      StatusBadge(label: inspection.status.label, color: _statusColor),
                      StatusBadge(label: '${inspection.risk.label} Risk', color: _riskColor),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}