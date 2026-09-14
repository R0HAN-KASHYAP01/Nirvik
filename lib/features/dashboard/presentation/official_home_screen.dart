import 'package:flutter/material.dart';

import '../../../services/session_service.dart';
import '../../../app/routes.dart';
import '../../../core/widgets/quick_action_card.dart';
import '../../../core/widgets/section_header.dart';
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
import 'official_cctv_screen.dart';

class OfficialHomeScreen extends StatefulWidget {
  const OfficialHomeScreen({super.key});

  // Government Digital India style theme
  static const Color navy = Color(0xFF123E68);
  static const Color darkNavy = Color(0xFF0B3154);
  static const Color primaryBlue = Color(0xFF14568A);
  static const Color background = Color(0xFFEAF2F8);
  static const Color cardBackground = Color(0xFFE1ECF3);
  static const Color softBlue = Color(0xFFD7E5EE);
  static const Color borderColor = Color(0xFFD1DEE7);
  static const Color textDark = Color(0xFF17324D);
  static const Color textGrey = Color(0xFF667788);
  static const Color green = Color(0xFF168A45);
  static const Color saffron = Color(0xFFE88A18);

  @override
  State<OfficialHomeScreen> createState() => _OfficialHomeScreenState();
}

class _OfficialHomeScreenState extends State<OfficialHomeScreen> {
  final AssignmentsRepository _assignmentsRepository =
      AssignmentsRepository();

  final ProjectsRepository _projectsRepository =
      ProjectsRepository();

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

  List<InspectionSummary> _mapToRecentInspections(
    List<Map<String, dynamic>> rows,
  ) {
    final topFive = rows.take(5).toList();

    return List.generate(topFive.length, (index) {
      final row = topFive[index];

      final instituteId =
          row['institute_profile_id']?.toString() ?? '';

      final shortInstituteId = instituteId.isEmpty
          ? 'Unknown'
          : instituteId.substring(
              0,
              instituteId.length < 8
                  ? instituteId.length
                  : 8,
            );

      final submittedAt = DateTime.tryParse(
        row['submitted_at']?.toString() ?? '',
      );

      return InspectionSummary(
        projectName: 'Inspection #${index + 1}',
        inspectorName: 'Institute ID: $shortInstituteId',
        dateTime: submittedAt ?? DateTime.now(),
        status: _parseInspectionStatus(
          row['overall_status']?.toString(),
        ),
        risk: _parseRiskLevel(
          row['risk_level']?.toString(),
        ),
      );
    });
  }

  Future<void> _loadHomeStats() async {
    try {
      final assignments =
          await _assignmentsRepository.getAssignments();

      final projects =
          await _projectsRepository.getProjects();

      final inspectionRows =
          await _inspectionHistoryRepository.getInspectionHistory();

      final now = DateTime.now();

      final staleThreshold =
          now.subtract(const Duration(days: 3));

      final todaysCount = assignments
          .where(
            (a) => _isSameDay(
              a.scheduledDateTime,
              now,
            ),
          )
          .length;

      final pendingReviewCount = assignments
          .where(
            (a) =>
                a.status == AssignmentStatus.assigned &&
                a.scheduledDateTime.isBefore(
                  staleThreshold,
                ),
          )
          .length;

      if (!mounted) return;

      setState(() {
        _todaysInspectionsCount = todaysCount;

        _pendingReviewsCount = pendingReviewCount;

        _totalProjectsCount = projects.length;

        _highRiskCount = projects
            .where(
              (p) =>
                  p.riskLevel ==
                  project_model.RiskLevel.high,
            )
            .length;

        _recentInspections =
            _mapToRecentInspections(inspectionRows);
      });
    } catch (error) {
      debugPrint(
        'Failed to load official homepage stats: $error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user =
        SessionService.instance.currentUser;

    final inspections = _recentInspections;

    return Scaffold(
      backgroundColor: OfficialHomeScreen.background,

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            14,
            12,
            14,
            18,
          ),

          children: [
            // --------------------------------------------------
            // HEADER
            // --------------------------------------------------
            _HomeHeader(
              userName: user?.name ?? 'DoSJE Official',
              alertCount: 3,
            ),

            const SizedBox(height: 12),

            // --------------------------------------------------
            // HIGH RISK ALERT
            // --------------------------------------------------
            _AlertBanner(
              count: _highRiskCount ?? 0,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const ProjectListScreen(
                      initialHighRiskFilter: true,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // --------------------------------------------------
            // STATISTICS
            // --------------------------------------------------
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                final columns = width < 340 ? 2 : 3;

                final spacing = 8.0;

                final cardWidth =
                    (width -
                            (spacing *
                                (columns - 1))) /
                        columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,

                  children: [
                    SizedBox(
                      width: cardWidth,

                      child: _MiniStatCard(
                        icon:
                            Icons.calendar_today_outlined,
                        label: "Today's\nInspections",
                        count:
                            _todaysInspectionsCount
                                    ?.toString() ??
                                '—',
                        color:
                            OfficialHomeScreen.primaryBlue,

                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const OfficialTodayInstitutesScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(
                      width: cardWidth,

                      child: _MiniStatCard(
                        icon:
                            Icons.assignment_outlined,
                        label: 'Pending\nReviews',
                        count:
                            _pendingReviewsCount
                                    ?.toString() ??
                                '—',
                        color:
                            OfficialHomeScreen.saffron,

                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AssignmentsScreen(
                                initialFilter:
                                    'pendingReview',
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(
                      width: cardWidth,

                      child: _MiniStatCard(
                        icon:
                            Icons.apartment_outlined,
                        label: 'Total\nProjects',
                        count:
                            _totalProjectsCount
                                    ?.toString() ??
                                '—',
                        color:
                            OfficialHomeScreen.green,

                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.projectsPlaceholder,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // RECENT INSPECTIONS
            // --------------------------------------------------
            SectionHeader(
              title: 'Recent Inspections',
              actionLabel: 'View all',
              onActionTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const InspectionHistoryScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 7),

            if (inspections.isEmpty)
              const _CompactEmptyInspectionState()
            else
              Column(
                children: inspections
                    .map(
                      (inspection) => Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 7,
                        ),
                        child:
                            _RecentInspectionTile(
                          inspection: inspection,
                        ),
                      ),
                    )
                    .toList(),
              ),

            const SizedBox(height: 14),

            // --------------------------------------------------
            // QUICK ACTIONS
            // --------------------------------------------------
            const SectionHeader(
              title: 'Quick Actions',
            ),

            const SizedBox(height: 8),

            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                final columns =
                    width >= 620
                        ? 5
                        : width >= 390
                            ? 3
                            : 2;

                final spacing = 8.0;

                final itemWidth =
                    (width -
                            (spacing *
                                (columns - 1))) /
                        columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,

                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: QuickActionCard(
                        icon: Icons.apartment,
                        label: 'Projects',
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.projectsPlaceholder,
                          );
                        },
                      ),
                    ),

                    SizedBox(
                      width: itemWidth,
                      child: QuickActionCard(
                        icon:
                            Icons.fact_check_outlined,
                        label: 'Inspections',
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.inspectionsPlaceholder,
                          );
                        },
                      ),
                    ),

                    SizedBox(
                      width: itemWidth,
                      child: QuickActionCard(
                        icon:
                            Icons.videocam_outlined,
                        label: 'CCTV',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const OfficialCctvScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(
                      width: itemWidth,
                      child: QuickActionCard(
                        icon: Icons.bar_chart,
                        label: 'Analytics',
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.analyticsPlaceholder,
                          );
                        },
                      ),
                    ),

                    SizedBox(
                      width: itemWidth,
                      child: QuickActionCard(
                        icon: Icons.history,
                        label: 'Call History',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const CallHistoryScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HOME HEADER
// ============================================================

class _HomeHeader extends StatelessWidget {
  final String userName;
  final int alertCount;

  const _HomeHeader({
    required this.userName,
    required this.alertCount,
  });

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning,';
    }

    if (hour < 17) {
      return 'Good Afternoon,';
    }

    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),

      decoration: BoxDecoration(
        color: OfficialHomeScreen.navy,
        borderRadius: BorderRadius.circular(17),

        boxShadow: [
          BoxShadow(
            color:
                OfficialHomeScreen.navy.withValues(
              alpha: 0.12,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          const CircleAvatar(
            radius: 21,

            backgroundColor: Colors.white,

            child: Icon(
              Icons.person,
              color: OfficialHomeScreen.navy,
              size: 22,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              mainAxisSize: MainAxisSize.min,

              children: [
                Text(
                  _greeting(),

                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 1),

                Text(
                  userName,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w700,
                    color: Colors.white,
                  ),
                ),

                const Text(
                  'Official',

                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          Stack(
            clipBehavior: Clip.none,

            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(
                  minWidth: 38,
                  minHeight: 38,
                ),

                visualDensity:
                    VisualDensity.compact,

                icon: const Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                  size: 23,
                ),

                onPressed: () {},
              ),

              if (alertCount > 0)
                Positioned(
                  right: 1,
                  top: 1,

                  child: Container(
                    padding:
                        const EdgeInsets.all(3),

                    constraints:
                        const BoxConstraints(
                      minWidth: 15,
                      minHeight: 15,
                    ),

                    decoration:
                        const BoxDecoration(
                      color: Color(0xFFD83A3A),
                      shape: BoxShape.circle,
                    ),

                    child: Text(
                      '$alertCount',

                      textAlign:
                          TextAlign.center,

                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HIGH RISK ALERT
// ============================================================

class _AlertBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _AlertBanner({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,

      borderRadius:
          BorderRadius.circular(11),

      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 9,
        ),

        decoration: BoxDecoration(
          color: const Color(0xFFFFF6E8),

          borderRadius:
              BorderRadius.circular(11),

          border: Border.all(
            color:
                OfficialHomeScreen.saffron
                    .withValues(alpha: 0.35),
          ),
        ),

        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.all(6),

              decoration: BoxDecoration(
                color:
                    OfficialHomeScreen.saffron
                        .withValues(alpha: 0.12),

                borderRadius:
                    BorderRadius.circular(7),
              ),

              child: const Icon(
                Icons.warning_amber_rounded,
                color:
                    OfficialHomeScreen.saffron,
                size: 19,
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                '$count high-risk alerts require attention',

                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,

                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      OfficialHomeScreen.textDark,
                ),
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: OfficialHomeScreen.navy,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MINI STAT CARD
// ============================================================

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

      borderRadius:
          BorderRadius.circular(12),

      child: Container(
        width: double.infinity,

        padding: const EdgeInsets.all(9),

        decoration: BoxDecoration(
          color:
              OfficialHomeScreen.cardBackground,

          borderRadius:
              BorderRadius.circular(12),

          border: Border.all(
            color:
                OfficialHomeScreen.borderColor,
          ),

          boxShadow: [
            BoxShadow(
              color:
                  OfficialHomeScreen.navy
                      .withValues(alpha: 0.035),

              blurRadius: 6,

              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              padding:
                  const EdgeInsets.all(6),

              decoration: BoxDecoration(
                color:
                    color.withValues(alpha: 0.10),

                borderRadius:
                    BorderRadius.circular(7),
              ),

              child: Icon(
                icon,
                size: 16,
                color: color,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              count,

              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,

              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color:
                    OfficialHomeScreen.navy,
              ),
            ),

            const SizedBox(height: 1),

            Text(
              label,

              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,

              style: const TextStyle(
                fontSize: 10,
                color:
                    OfficialHomeScreen.textGrey,
                height: 1.15,
              ),
            ),

            const SizedBox(height: 5),

            Row(
              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment:
                  CrossAxisAlignment.end,

              children: List.generate(
                4,
                (i) {
                  const heights = [
                    5.0,
                    8.0,
                    7.0,
                    11.0,
                  ];

                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      right: 2,
                    ),

                    child: Container(
                      width: 4,
                      height: heights[i],

                      decoration:
                          BoxDecoration(
                        color: color.withValues(
                          alpha:
                              0.35 +
                                  (i * 0.15),
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// COMPACT EMPTY INSPECTION STATE
// ============================================================

class _CompactEmptyInspectionState
    extends StatelessWidget {
  const _CompactEmptyInspectionState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),

      decoration: BoxDecoration(
        color:
            OfficialHomeScreen.cardBackground,

        borderRadius:
            BorderRadius.circular(12),

        border: Border.all(
          color:
              OfficialHomeScreen.borderColor,
        ),
      ),

      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.all(8),

            decoration: BoxDecoration(
              color:
                  OfficialHomeScreen.softBlue,

              borderRadius:
                  BorderRadius.circular(9),
            ),

            child: const Icon(
              Icons.fact_check_outlined,
              size: 22,
              color:
                  OfficialHomeScreen.navy,
            ),
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  'No recent inspections',

                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        OfficialHomeScreen.textDark,
                  ),
                ),

                SizedBox(height: 2),

                Text(
                  'Inspections will appear here once submitted.',

                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: 10,
                    color:
                        OfficialHomeScreen.textGrey,
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

// ============================================================
// RECENT INSPECTION TILE
// ============================================================

class _RecentInspectionTile
    extends StatelessWidget {
  final InspectionSummary inspection;

  const _RecentInspectionTile({
    required this.inspection,
  });

  Color get _statusColor {
    switch (inspection.status) {
      case InspectionStatus.approved:
        return OfficialHomeScreen.green;

      case InspectionStatus.overdue:
        return const Color(0xFFD83A3A);

      case InspectionStatus.underReview:
        return OfficialHomeScreen.saffron;

      case InspectionStatus.submitted:
        return OfficialHomeScreen.primaryBlue;

      case InspectionStatus.inProgress:
        return OfficialHomeScreen.navy;

      case InspectionStatus.assigned:
        return OfficialHomeScreen.textGrey;
    }
  }

  Color get _riskColor {
    switch (inspection.risk) {
      case RiskLevel.high:
        return const Color(0xFFD83A3A);

      case RiskLevel.medium:
        return OfficialHomeScreen.saffron;

      case RiskLevel.low:
        return OfficialHomeScreen.green;
    }
  }

  String _formatTime(DateTime dt) {
    final hour =
        dt.hour % 12 == 0
            ? 12
            : dt.hour % 12;

    final period =
        dt.hour >= 12 ? 'PM' : 'AM';

    final minute =
        dt.minute.toString().padLeft(2, '0');

    return '${dt.day} Sep ${dt.year} · '
        '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},

      borderRadius:
          BorderRadius.circular(12),

      child: Container(
        padding: const EdgeInsets.all(9),

        decoration: BoxDecoration(
          color:
              OfficialHomeScreen.cardBackground,

          borderRadius:
              BorderRadius.circular(12),

          border: Border.all(
            color:
                OfficialHomeScreen.borderColor,
          ),
        ),

        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Container(
              width: 42,
              height: 42,

              decoration: BoxDecoration(
                color:
                    OfficialHomeScreen.softBlue,

                borderRadius:
                    BorderRadius.circular(9),
              ),

              child: const Icon(
                Icons.apartment,
                color:
                    OfficialHomeScreen.navy,
                size: 21,
              ),
            ),

            const SizedBox(width: 9),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                mainAxisSize: MainAxisSize.min,

                children: [
                  Text(
                    inspection.projectName,

                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          OfficialHomeScreen.textDark,
                    ),
                  ),

                  const SizedBox(height: 1),

                  Text(
                    'Inspector: ${inspection.inspectorName}',

                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 10,
                      color:
                          OfficialHomeScreen.textGrey,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 11,
                        color:
                            OfficialHomeScreen.textGrey,
                      ),

                      const SizedBox(width: 3),

                      Expanded(
                        child: Text(
                          _formatTime(
                            inspection.dateTime,
                          ),

                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 10,
                            color:
                                OfficialHomeScreen.textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Wrap(
                    spacing: 5,
                    runSpacing: 4,

                    children: [
                      _SmallStatusBadge(
                        label:
                            inspection.status.label,
                        color: _statusColor,
                      ),

                      _SmallStatusBadge(
                        label:
                            '${inspection.risk.label} Risk',
                        color: _riskColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 3),

            const Padding(
              padding:
                  EdgeInsets.only(top: 12),

              child: Icon(
                Icons.chevron_right,
                size: 17,
                color:
                    OfficialHomeScreen.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SMALL STATUS BADGE
// ============================================================

class _SmallStatusBadge
    extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallStatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),

      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),

        borderRadius:
            BorderRadius.circular(6),

        border: Border.all(
          color: color.withValues(
            alpha: 0.18,
          ),
        ),
      ),

      child: Text(
        label,

        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}