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
  static const Color red = Color(0xFFD83A3A);

  @override
  State<OfficialHomeScreen> createState() => _OfficialHomeScreenState();
}

class _OfficialHomeScreenState extends State<OfficialHomeScreen> {
  final AssignmentsRepository _assignmentsRepository =
      AssignmentsRepository();

  final ProjectsRepository _projectsRepository = ProjectsRepository();

  final InspectionHistoryRepository _inspectionHistoryRepository =
      InspectionHistoryRepository();

  int? _todaysInspectionsCount;
  int? _pendingReviewsCount;
  int? _totalProjectsCount;
  int? _highRiskCount;

  List<InspectionSummary> _recentInspections = [];

  // ============================================================
  // DYNAMIC NOTIFICATIONS
  // ============================================================

  List<_OfficialNotification> _notifications = [];

  final Set<String> _readNotificationIds = <String>{};

  List<_OfficialNotification> get _unreadNotifications {
    return _notifications
        .where(
          (notification) =>
              !_readNotificationIds.contains(notification.id),
        )
        .toList();
  }

  int get _unreadNotificationCount => _unreadNotifications.length;

  @override
  void initState() {
    super.initState();
    _loadHomeStats();
  }

  // ============================================================
  // HELPERS
  // ============================================================

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

  // ============================================================
  // CREATE REAL NOTIFICATIONS FROM REAL DATA
  // ============================================================

  List<_OfficialNotification> _buildNotifications({
    required List<project_model.Project> projects,
    required List<AssignmentSummary> assignments,
  }) {
    final notifications = <_OfficialNotification>[];

    // ----------------------------------------------------------
    // HIGH RISK PROJECTS
    // ----------------------------------------------------------

    final highRiskProjects = projects.where(
      (project) =>
          project.riskLevel == project_model.RiskLevel.high,
    );

    for (final project in highRiskProjects) {
      notifications.add(
        _OfficialNotification(
          id: 'high-risk-${project.id}',
          title: 'High Risk Project',
          message:
              '${project.name} has been marked as a high-risk project.',
          type: _NotificationType.highRisk,
          icon: Icons.warning_amber_rounded,
          color: OfficialHomeScreen.red,
        ),
      );
    }

    // ----------------------------------------------------------
    // PENDING REVIEW ASSIGNMENTS
    // ----------------------------------------------------------

    final pendingAssignments = assignments.where(
      (assignment) =>
          assignment.status == AssignmentStatus.assigned &&
          assignment.scheduledDateTime.isBefore(
            DateTime.now().subtract(
              const Duration(days: 3),
            ),
          ),
    );

    for (final assignment in pendingAssignments) {
      notifications.add(
        _OfficialNotification(
          id: 'pending-review-${assignment.id}',
          title: 'Pending Review',
          message:
              '${assignment.instituteName} requires review.',
          type: _NotificationType.pendingReview,
          icon: Icons.assignment_outlined,
          color: OfficialHomeScreen.saffron,
        ),
      );
    }

    return notifications;
  }

  // ============================================================
  // LOAD HOME DATA
  // ============================================================

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
            (assignment) => _isSameDay(
              assignment.scheduledDateTime,
              now,
            ),
          )
          .length;

      final pendingReviewCount = assignments
          .where(
            (assignment) =>
                assignment.status ==
                    AssignmentStatus.assigned &&
                assignment.scheduledDateTime
                    .isBefore(staleThreshold),
          )
          .length;

      final highRiskCount = projects
          .where(
            (project) =>
                project.riskLevel ==
                project_model.RiskLevel.high,
          )
          .length;

      final newNotifications = _buildNotifications(
        projects: projects,
        assignments: assignments,
      );

      if (!mounted) return;

      setState(() {
        _todaysInspectionsCount = todaysCount;
        _pendingReviewsCount = pendingReviewCount;
        _totalProjectsCount = projects.length;
        _highRiskCount = highRiskCount;

        _recentInspections =
            _mapToRecentInspections(inspectionRows);

        _notifications = newNotifications;
      });
    } catch (error) {
      debugPrint(
        'Failed to load official homepage stats: $error',
      );
    }
  }

  // ============================================================
  // MARK NOTIFICATION AS READ
  // ============================================================

  void _markNotificationAsRead(String notificationId) {
    if (!_readNotificationIds.contains(notificationId)) {
      setState(() {
        _readNotificationIds.add(notificationId);
      });
    }
  }

  void _markAllNotificationsAsRead() {
    if (_unreadNotificationCount == 0) return;

    setState(() {
      _readNotificationIds.addAll(
        _notifications.map((notification) => notification.id),
      );
    });
  }

  // ============================================================
  // NOTIFICATION ACTION
  // ============================================================

  void _handleNotificationTap(
    BuildContext context,
    _OfficialNotification notification,
  ) {
    _markNotificationAsRead(notification.id);

    Navigator.of(context).pop();

    if (notification.type == _NotificationType.highRisk) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ProjectListScreen(
            initialHighRiskFilter: true,
          ),
        ),
      );
    } else if (
        notification.type ==
        _NotificationType.pendingReview
    ) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AssignmentsScreen(
            initialFilter: 'pendingReview',
          ),
        ),
      );
    }
  }

  // ============================================================
  // NOTIFICATION BOTTOM SHEET
  // ============================================================

  void _showNotifications(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            final notifications = _notifications;

            return Container(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.sizeOf(context).height * 0.78,
              ),
              decoration: const BoxDecoration(
                color: OfficialHomeScreen.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),

                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: OfficialHomeScreen.borderColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        18,
                        16,
                        14,
                        10,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Notifications',
                              style: TextStyle(
                                color: OfficialHomeScreen.textDark,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                          if (_unreadNotificationCount > 0)
                            TextButton(
                              onPressed: () {
                                _markAllNotificationsAsRead();
                                modalSetState(() {});
                              },
                              child: const Text(
                                'Mark all read',
                                style: TextStyle(
                                  color:
                                      OfficialHomeScreen.primaryBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    if (notifications.isEmpty)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          35,
                          20,
                          45,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 48,
                              color: OfficialHomeScreen.textGrey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No notifications',
                              style: TextStyle(
                                color:
                                    OfficialHomeScreen.textDark,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'You are all caught up.',
                              style: TextStyle(
                                color:
                                    OfficialHomeScreen.textGrey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            14,
                            4,
                            14,
                            20,
                          ),
                          itemCount: notifications.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final notification =
                                notifications[index];

                            final isRead =
                                _readNotificationIds.contains(
                              notification.id,
                            );

                            return _NotificationTile(
                              notification: notification,
                              isRead: isRead,
                              onTap: () {
                                _handleNotificationTap(
                                  context,
                                  notification,
                                );
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser;

    final inspections = _recentInspections;

    final unreadNotifications = _unreadNotifications;

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
            // ======================================================
            // HEADER
            // ======================================================

            _HomeHeader(
              userName: user?.name ?? 'DoSJE Official',
              alertCount: _unreadNotificationCount,
              onNotificationTap: () {
                _showNotifications(context);
              },
            ),

            // ======================================================
            // DYNAMIC NOTIFICATION BANNER
            // ======================================================

            if (unreadNotifications.isNotEmpty) ...[
              const SizedBox(height: 12),

              _AlertBanner(
                notification: unreadNotifications.first,
                count: unreadNotifications.length,
                onTap: () {
                  _showNotifications(context);
                },
              ),
            ],

            const SizedBox(height: 10),

            // ======================================================
            // STATISTICS
            // ======================================================

            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                final columns = width < 340 ? 2 : 3;

                const spacing = 8.0;

                final cardWidth =
                    (width -
                            (spacing * (columns - 1))) /
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

            // ======================================================
            // RECENT INSPECTIONS
            // ======================================================

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
                            const EdgeInsets.only(bottom: 7),
                        child: _RecentInspectionTile(
                          inspection: inspection,
                        ),
                      ),
                    )
                    .toList(),
              ),

            const SizedBox(height: 14),

            // ======================================================
            // QUICK ACTIONS
            // ======================================================

            const SectionHeader(
              title: 'Quick Actions',
            ),

            const SizedBox(height: 8),

            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                final columns = width >= 620
                    ? 5
                    : width >= 390
                        ? 3
                        : 2;

                const spacing = 8.0;

                final itemWidth =
                    (width -
                            (spacing * (columns - 1))) /
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
// NOTIFICATION MODEL
// ============================================================

enum _NotificationType {
  highRisk,
  pendingReview,
}

class _OfficialNotification {
  final String id;
  final String title;
  final String message;
  final _NotificationType type;
  final IconData icon;
  final Color color;

  const _OfficialNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.icon,
    required this.color,
  });
}

// ============================================================
// HOME HEADER
// ============================================================

class _HomeHeader extends StatelessWidget {
  final String userName;
  final int alertCount;
  final VoidCallback onNotificationTap;

  const _HomeHeader({
    required this.userName,
    required this.alertCount,
    required this.onNotificationTap,
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
            color: OfficialHomeScreen.navy.withValues(
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
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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

          // ======================================================
          // DYNAMIC BELL
          // ======================================================

          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 38,
                  minHeight: 38,
                ),
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  alertCount > 0
                      ? Icons.notifications
                      : Icons.notifications_none,
                  color: Colors.white,
                  size: 23,
                ),
                onPressed: onNotificationTap,
              ),

              if (alertCount > 0)
                Positioned(
                  right: 1,
                  top: 1,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    constraints: const BoxConstraints(
                      minWidth: 15,
                      minHeight: 15,
                    ),
                    decoration: const BoxDecoration(
                      color: OfficialHomeScreen.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$alertCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
// DYNAMIC ALERT BANNER
// ============================================================

class _AlertBanner extends StatelessWidget {
  final _OfficialNotification notification;
  final int count;
  final VoidCallback onTap;

  const _AlertBanner({
    required this.notification,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6E8),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: notification.color.withValues(
              alpha: 0.35,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: notification.color.withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                notification.icon,
                color: notification.color,
                size: 19,
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    count == 1
                        ? notification.title
                        : '$count notifications require attention',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: OfficialHomeScreen.textDark,
                    ),
                  ),

                  if (count == 1)
                    Text(
                      notification.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: OfficialHomeScreen.textGrey,
                      ),
                    ),
                ],
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
// NOTIFICATION TILE
// ============================================================

class _NotificationTile extends StatelessWidget {
  final _OfficialNotification notification;
  final bool isRead;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.white
              : notification.color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead
                ? OfficialHomeScreen.borderColor
                : notification.color.withValues(
                    alpha: 0.25,
                  ),
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
                color: notification.color.withValues(
                  alpha: 0.10,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                notification.icon,
                color: notification.color,
                size: 21,
              ),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                OfficialHomeScreen.textDark,
                            fontSize: 13,
                            fontWeight: isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                          ),
                        ),
                      ),

                      if (!isRead)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: notification.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: OfficialHomeScreen.textGrey,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    isRead ? 'Read' : 'Unread • Tap to open',
                    style: TextStyle(
                      color: isRead
                          ? OfficialHomeScreen.textGrey
                          : notification.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 5),

            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Icon(
                Icons.chevron_right,
                size: 18,
                color: OfficialHomeScreen.textGrey,
              ),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: OfficialHomeScreen.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: OfficialHomeScreen.borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: OfficialHomeScreen.navy.withValues(
                alpha: 0.035,
              ),
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
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
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: OfficialHomeScreen.navy,
              ),
            ),

            const SizedBox(height: 1),

            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: OfficialHomeScreen.textGrey,
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
                    padding: const EdgeInsets.only(
                      right: 2,
                    ),
                    child: Container(
                      width: 4,
                      height: heights[i],
                      decoration: BoxDecoration(
                        color: color.withValues(
                          alpha: 0.35 + (i * 0.15),
                        ),
                        borderRadius:
                            BorderRadius.circular(2),
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
// EMPTY INSPECTION STATE
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
        color: OfficialHomeScreen.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: OfficialHomeScreen.borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: OfficialHomeScreen.softBlue,
              borderRadius:
                  BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              size: 22,
              color: OfficialHomeScreen.navy,
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
                    fontWeight: FontWeight.w600,
                    color: OfficialHomeScreen.textDark,
                  ),
                ),

                SizedBox(height: 2),

                Text(
                  'Inspections will appear here once submitted.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: OfficialHomeScreen.textGrey,
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
        return OfficialHomeScreen.red;

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
        return OfficialHomeScreen.red;

      case RiskLevel.medium:
        return OfficialHomeScreen.saffron;

      case RiskLevel.low:
        return OfficialHomeScreen.green;
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0
        ? 12
        : dt.hour % 12;

    final period = dt.hour >= 12 ? 'PM' : 'AM';

    final minute =
        dt.minute.toString().padLeft(2, '0');

    return '${dt.day} Sep ${dt.year} · '
        '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: OfficialHomeScreen.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: OfficialHomeScreen.borderColor,
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
                color: OfficialHomeScreen.softBlue,
                borderRadius:
                    BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.apartment,
                color: OfficialHomeScreen.navy,
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
                      fontWeight: FontWeight.w600,
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
              padding: EdgeInsets.only(top: 12),
              child: Icon(
                Icons.chevron_right,
                size: 17,
                color: OfficialHomeScreen.textGrey,
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
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
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