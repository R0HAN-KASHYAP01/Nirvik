import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  State<OfficialHomeScreen> createState() =>
      _OfficialHomeScreenState();
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

  // ============================================================
  // NOTIFICATION STORAGE
  // ============================================================

  static const String _notificationStorageKey =
      'official_notification_history';

  List<_OfficialNotification> _notifications = [];

  final Set<String> _readNotificationIds = <String>{};

  bool _notificationStorageLoaded = false;


  // ============================================================
  // UNREAD NOTIFICATIONS
  // ============================================================

  List<_OfficialNotification> get _unreadNotifications {
    return _notifications
        .where(
          (notification) =>
              !_readNotificationIds.contains(notification.id),
        )
        .toList();
  }

  int get _unreadNotificationCount =>
      _unreadNotifications.length;

  // ============================================================
  // LAST 30 DAYS HISTORY
  // ============================================================

  List<_OfficialNotification> get _last30DaysNotifications {
    final cutoff =
        DateTime.now().subtract(const Duration(days: 30));

    final list = _notifications
        .where(
          (notification) =>
              !notification.createdAt.isBefore(cutoff),
        )
        .toList();

    list.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    return list;
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _loadNotificationHistory();

    if (!mounted) return;

    await _loadHomeStats();
  }

  // ============================================================
  // LOAD SAVED NOTIFICATIONS
  // ============================================================

  Future<void> _loadNotificationHistory() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final rawList =
          prefs.getStringList(_notificationStorageKey) ?? [];

      final loadedNotifications =
          <_OfficialNotification>[];

      for (final raw in rawList) {
        try {
          final jsonMap =
              jsonDecode(raw) as Map<String, dynamic>;

          final notification =
              _OfficialNotification.fromJson(jsonMap);

          if (notification.id.isNotEmpty) {
            loadedNotifications.add(notification);
          }
        } catch (error) {
          debugPrint(
            'Invalid official notification: $error',
          );
        }
      }

      final cutoff =
          DateTime.now().subtract(const Duration(days: 30));

      final validNotifications =
          loadedNotifications
              .where(
                (notification) =>
                    !notification.createdAt
                        .isBefore(cutoff),
              )
              .toList();

      validNotifications.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      final readIds = <String>{};

      for (final notification in validNotifications) {
        if (notification.readAt != null) {
          readIds.add(notification.id);
        }
      }

      if (!mounted) return;

      setState(() {
        _notifications = validNotifications;

        _readNotificationIds
          ..clear()
          ..addAll(readIds);

        _notificationStorageLoaded = true;
      });
    } catch (error) {
      debugPrint(
        'Failed to load official notification history: $error',
      );

      if (!mounted) return;

      setState(() {
        _notificationStorageLoaded = true;
      });
    }
  }

  // ============================================================
  // SAVE NOTIFICATIONS
  // ============================================================

  Future<void> _saveNotificationHistory() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final cutoff =
          DateTime.now().subtract(const Duration(days: 30));

      final validNotifications = _notifications
          .where(
            (notification) =>
                !notification.createdAt.isBefore(cutoff),
          )
          .toList();

      validNotifications.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      await prefs.setStringList(
        _notificationStorageKey,
        validNotifications
            .map(
              (notification) =>
                  jsonEncode(notification.toJson()),
            )
            .toList(),
      );
    } catch (error) {
      debugPrint(
        'Failed to save official notification history: $error',
      );
    }
  }

  // ============================================================
  // SAME DAY
  // ============================================================

  bool _isSameDay(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  // ============================================================
  // INSPECTION STATUS
  // ============================================================

  InspectionStatus _parseInspectionStatus(
    String? value,
  ) {
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

  // ============================================================
  // RISK LEVEL
  // ============================================================

  RiskLevel _parseRiskLevel(
    String? value,
  ) {
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

  // ============================================================
  // RECENT INSPECTIONS
  // ============================================================

  List<InspectionSummary> _mapToRecentInspections(
    List<Map<String, dynamic>> rows,
  ) {
    final topFive = rows.take(5).toList();

    return List.generate(
      topFive.length,
      (index) {
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
          inspectorName:
              'Institute ID: $shortInstituteId',
          dateTime:
              submittedAt ?? DateTime.now(),
          status: _parseInspectionStatus(
            row['overall_status']?.toString(),
          ),
          risk: _parseRiskLevel(
            row['risk_level']?.toString(),
          ),
        );
      },
    );
  }

  // ============================================================
  // CREATE / UPDATE NOTIFICATIONS
  // ============================================================

  List<_OfficialNotification> _buildNotifications({
    required List<project_model.Project> projects,
    required List<AssignmentSummary> assignments,
  }) {
    final existingById =
        <String, _OfficialNotification>{
      for (final notification in _notifications)
        notification.id: notification,
    };

    final currentNotifications =
        <_OfficialNotification>[];

    // ==========================================================
    // HIGH RISK PROJECTS
    // ==========================================================

    final highRiskProjects = projects.where(
      (project) =>
          project.riskLevel ==
          project_model.RiskLevel.high,
    );

    for (final project in highRiskProjects) {
      final id = 'high-risk-${project.id}';

      final existing = existingById[id];

      currentNotifications.add(
        _OfficialNotification(
          id: id,
          title: 'High Risk Project',
          message:
              '${project.name} has been marked as a high-risk project.',
          type: _NotificationType.highRisk,
          createdAt:
              existing?.createdAt ?? DateTime.now(),
          readAt: existing?.readAt,
        ),
      );
    }

    // ==========================================================
    // PENDING REVIEW ASSIGNMENTS
    // ==========================================================

    final staleThreshold =
        DateTime.now().subtract(
      const Duration(days: 3),
    );

    final pendingAssignments = assignments.where(
      (assignment) =>
          assignment.status ==
              AssignmentStatus.assigned &&
          assignment.scheduledDateTime
              .isBefore(staleThreshold),
    );

    for (final assignment in pendingAssignments) {
      final id =
          'pending-review-${assignment.id}';

      final existing = existingById[id];

      currentNotifications.add(
        _OfficialNotification(
          id: id,
          title: 'Pending Review',
          message:
              '${assignment.instituteName} requires review.',
          type: _NotificationType.pendingReview,
          createdAt:
              existing?.createdAt ??
              assignment.createdAt,
          readAt: existing?.readAt,
        ),
      );
    }

    return currentNotifications;
  }

  // ============================================================
  // MERGE CURRENT NOTIFICATIONS WITH HISTORY
  // ============================================================

  Future<void> _updateNotificationHistory({
    required List<_OfficialNotification>
        currentNotifications,
  }) async {
    final existingById =
        <String, _OfficialNotification>{
      for (final notification in _notifications)
        notification.id: notification,
    };

    // Keep existing history.
    // Update/create current notifications.
    for (final notification in currentNotifications) {
      final existing =
          existingById[notification.id];

      if (existing != null) {
        existingById[notification.id] =
            notification.copyWith(
          createdAt: existing.createdAt,
          readAt: existing.readAt,
        );
      } else {
        existingById[notification.id] =
            notification;
      }
    }

    final cutoff =
        DateTime.now().subtract(
      const Duration(days: 30),
    );

    final history = existingById.values
        .where(
          (notification) =>
              !notification.createdAt
                  .isBefore(cutoff),
        )
        .toList();

    history.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    if (!mounted) return;

    setState(() {
      _notifications = history;

      _readNotificationIds
        ..clear()
        ..addAll(
          history
              .where(
                (notification) =>
                    notification.readAt != null,
              )
              .map(
                (notification) =>
                    notification.id,
              ),
        );
    });

    await _saveNotificationHistory();
  }

  // ============================================================
  // LOAD HOME STATS
  // ============================================================

  Future<void> _loadHomeStats() async {
    try {
      final assignments =
          await _assignmentsRepository.getAssignments();

      final projects =
          await _projectsRepository.getProjects();

      final inspectionRows =
          await _inspectionHistoryRepository
              .getInspectionHistory();

      final now = DateTime.now();

      final staleThreshold =
          now.subtract(
        const Duration(days: 3),
      );

      // ========================================================
      // TODAY'S INSPECTIONS
      // ========================================================

      final todaysCount = assignments
          .where(
            (assignment) => _isSameDay(
              assignment.scheduledDateTime,
              now,
            ),
          )
          .length;

      // ========================================================
      // PENDING REVIEWS
      // ========================================================

      final pendingReviewCount =
          assignments
              .where(
                (assignment) =>
                    assignment.status ==
                        AssignmentStatus.assigned &&
                    assignment.scheduledDateTime
                        .isBefore(staleThreshold),
              )
              .length;

      // ========================================================
      // HIGH RISK
      // ========================================================

      final highRiskCount =
          projects
              .where(
                (project) =>
                    project.riskLevel ==
                    project_model.RiskLevel.high,
              )
              .length;

      // ========================================================
      // NOTIFICATIONS
      // ========================================================

      final newNotifications =
          _buildNotifications(
        projects: projects,
        assignments: assignments,
      );

      await _updateNotificationHistory(
        currentNotifications:
            newNotifications,
      );

      if (!mounted) return;

      setState(() {
        _todaysInspectionsCount =
            todaysCount;

        _pendingReviewsCount =
            pendingReviewCount;

        _totalProjectsCount =
            projects.length;

        _highRiskCount =
            highRiskCount;

        _recentInspections =
            _mapToRecentInspections(
          inspectionRows,
        );
      });
    } catch (error) {
      debugPrint(
        'Failed to load official homepage stats: $error',
      );
    }
  }

  // ============================================================
  // MARK ONE NOTIFICATION READ
  // ============================================================

  Future<void> _markNotificationAsRead(
    String notificationId,
  ) async {
    final index =
        _notifications.indexWhere(
      (notification) =>
          notification.id ==
          notificationId,
    );

    if (index == -1) return;

    final notification =
        _notifications[index];

    if (notification.readAt != null) {
      return;
    }

    final readAt = DateTime.now();

    final updated =
        notification.copyWith(
      readAt: readAt,
    );

    setState(() {
      _notifications[index] = updated;

      _readNotificationIds.add(
        notificationId,
      );
    });

    await _saveNotificationHistory();
  }

  // ============================================================
  // MARK ALL READ
  // ============================================================

  Future<void> _markAllNotificationsAsRead() async {
    if (_unreadNotificationCount == 0) {
      return;
    }

    final readAt = DateTime.now();

    final updatedNotifications =
        _notifications
            .map(
              (notification) =>
                  notification.readAt == null
                      ? notification.copyWith(
                          readAt: readAt,
                        )
                      : notification,
            )
            .toList();

    setState(() {
      _notifications =
          updatedNotifications;

      _readNotificationIds
        ..clear()
        ..addAll(
          updatedNotifications.map(
            (notification) =>
                notification.id,
          ),
        );
    });

    await _saveNotificationHistory();
  }

  // ============================================================
  // NOTIFICATION ACTION
  // ============================================================

  Future<void> _handleNotificationTap(
    BuildContext context,
    _OfficialNotification notification,
  ) async {
    await _markNotificationAsRead(
      notification.id,
    );

    if (!context.mounted) return;

    Navigator.of(context).pop();

    if (notification.type ==
        _NotificationType.highRisk) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              const ProjectListScreen(
            initialHighRiskFilter: true,
          ),
        ),
      );
    } else if (notification.type ==
        _NotificationType.pendingReview) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              const AssignmentsScreen(
            initialFilter:
                'pendingReview',
          ),
        ),
      );
    }
  }

  // ============================================================
  // SHOW NOTIFICATION HISTORY
  // ============================================================

  void _showNotifications(BuildContext context) {
    _NotificationFilter selectedFilter =
        _NotificationFilter.unread;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            final now = DateTime.now();
            final last30DaysCutoff =
                now.subtract(const Duration(days: 30));
            final todayCutoff =
                now.subtract(const Duration(hours: 24));

            final todayNotifications = _notifications
                .where((notification) =>
                    !notification.createdAt.isBefore(todayCutoff))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            final unreadNotifications = _notifications
                .where((notification) =>
                    !notification.createdAt.isBefore(last30DaysCutoff) &&
                    notification.readAt == null)
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            final allNotifications = _notifications
                .where((notification) =>
                    !notification.createdAt.isBefore(last30DaysCutoff))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            final todayCount = todayNotifications.length;
            final unreadCount = unreadNotifications.length;
            final allCount = allNotifications.length;

            final List<_OfficialNotification> notifications;
            switch (selectedFilter) {
              case _NotificationFilter.today:
                notifications = todayNotifications;
                break;
              case _NotificationFilter.unread:
                notifications = unreadNotifications;
                break;
              case _NotificationFilter.all:
                notifications = allNotifications;
                break;
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.82,
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
                      padding: const EdgeInsets.fromLTRB(18, 15, 14, 8),
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
                          if (unreadCount > 0)
                            TextButton(
                              onPressed: () async {
                                await _markAllNotificationsAsRead();
                                if (context.mounted) {
                                  modalSetState(() {});
                                }
                              },
                              child: const Text(
                                'Mark all read',
                                style: TextStyle(
                                  color: OfficialHomeScreen.primaryBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: _NotificationFilterButton(
                              label: 'Today',
                              count: todayCount,
                              icon: Icons.today_outlined,
                              selected: selectedFilter ==
                                  _NotificationFilter.today,
                              onTap: () {
                                modalSetState(() {
                                  selectedFilter = _NotificationFilter.today;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: _NotificationFilterButton(
                              label: 'Unread',
                              count: unreadCount,
                              icon: Icons.notifications_none_rounded,
                              selected: selectedFilter ==
                                  _NotificationFilter.unread,
                              onTap: () {
                                modalSetState(() {
                                  selectedFilter = _NotificationFilter.unread;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: _NotificationFilterButton(
                              label: 'All',
                              count: allCount,
                              icon: Icons.history_rounded,
                              selected: selectedFilter ==
                                  _NotificationFilter.all,
                              onTap: () {
                                modalSetState(() {
                                  selectedFilter = _NotificationFilter.all;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          selectedFilter == _NotificationFilter.today
                              ? 'Showing notifications from the last 24 hours'
                              : selectedFilter == _NotificationFilter.unread
                                  ? 'Showing unread notifications from the last 30 days'
                                  : 'Showing all notifications from the last 30 days',
                          style: const TextStyle(
                            color: OfficialHomeScreen.textGrey,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    if (notifications.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 45, 20, 55),
                        child: Column(
                          children: [
                            Icon(
                              selectedFilter == _NotificationFilter.today
                                  ? Icons.today_outlined
                                  : selectedFilter == _NotificationFilter.unread
                                      ? Icons.notifications_none_rounded
                                      : Icons.history_toggle_off_rounded,
                              size: 52,
                              color: const Color(0xFF9EAFBC),
                            ),
                            const SizedBox(height: 13),
                            Text(
                              selectedFilter == _NotificationFilter.today
                                  ? 'No notifications today'
                                  : selectedFilter == _NotificationFilter.unread
                                      ? 'No unread notifications'
                                      : 'No notification history',
                              style: const TextStyle(
                                color: OfficialHomeScreen.textDark,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              selectedFilter == _NotificationFilter.today
                                  ? 'There are no notifications from the last 24 hours.'
                                  : selectedFilter == _NotificationFilter.unread
                                      ? 'You are all caught up.'
                                      : 'There are no notifications from the last 30 days.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: OfficialHomeScreen.textGrey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(14, 3, 14, 20),
                          itemCount: notifications.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            final isRead = notification.readAt != null;

                            return _NotificationTile(
                              notification: notification,
                              isRead: isRead,
                              onTap: () async {
                                await _handleNotificationTap(
                                  context,
                                  notification,
                                );
                                if (context.mounted) {
                                  modalSetState(() {});
                                }
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
  Widget build(
    BuildContext context,
  ) {
    final user =
        SessionService.instance.currentUser;

    final inspections =
        _recentInspections;

    final unreadNotifications =
        _unreadNotifications;

    return Scaffold(
      backgroundColor:
          OfficialHomeScreen.background,
      body: SafeArea(
        child: ListView(
          padding:
              const EdgeInsets.fromLTRB(
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
              userName:
                  user?.name ??
                  'DoSJE Official',
              alertCount:
                  _unreadNotificationCount,
              onNotificationTap: () {
                _showNotifications(
                  context,
                );
              },
            ),

            // ======================================================
            // DYNAMIC NOTIFICATION BANNER
            // ======================================================

            if (unreadNotifications
                .isNotEmpty) ...[
              const SizedBox(
                height: 12,
              ),

              _AlertBanner(
                notification:
                    unreadNotifications.first,
                count:
                    unreadNotifications.length,
                onTap: () {
                  _showNotifications(
                    context,
                  );
                },
              ),
            ],

            const SizedBox(
              height: 10,
            ),

            // ======================================================
            // STATISTICS
            // ======================================================

            LayoutBuilder(
              builder: (
                context,
                constraints,
              ) {
                final width =
                    constraints.maxWidth;

                final columns =
                    width < 340 ? 2 : 3;

                const spacing = 8.0;

                final cardWidth =
                    (width -
                            (spacing *
                                (columns -
                                    1))) /
                        columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    // TODAY'S INSPECTIONS
                    SizedBox(
                      width: cardWidth,
                      child: _MiniStatCard(
                        icon: Icons
                            .calendar_today_outlined,
                        label:
                            "Today's\nInspections",
                        count:
                            _todaysInspectionsCount
                                    ?.toString() ??
                                '—',
                        color:
                            OfficialHomeScreen
                                .primaryBlue,
                        onTap: () {
                          Navigator.of(
                            context,
                          ).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const OfficialTodayInstitutesScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    // PENDING REVIEWS
                    SizedBox(
                      width: cardWidth,
                      child: _MiniStatCard(
                        icon: Icons
                            .assignment_outlined,
                        label:
                            'Pending\nReviews',
                        count:
                            _pendingReviewsCount
                                    ?.toString() ??
                                '—',
                        color:
                            OfficialHomeScreen
                                .saffron,
                        onTap: () {
                          Navigator.of(
                            context,
                          ).push(
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

                    // TOTAL PROJECTS
                    SizedBox(
                      width: cardWidth,
                      child: _MiniStatCard(
                        icon: Icons
                            .apartment_outlined,
                        label:
                            'Total\nProjects',
                        count:
                            _totalProjectsCount
                                    ?.toString() ??
                                '—',
                        color:
                            OfficialHomeScreen
                                .green,
                        onTap: () {
                          Navigator.of(
                            context,
                          ).pushNamed(
                            AppRoutes
                                .projectsPlaceholder,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(
              height: 16,
            ),

            // ======================================================
            // RECENT INSPECTIONS
            // ======================================================

            SectionHeader(
              title:
                  'Recent Inspections',
              actionLabel:
                  'View all',
              onActionTap: () {
                Navigator.of(
                  context,
                ).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const InspectionHistoryScreen(),
                  ),
                );
              },
            ),

            const SizedBox(
              height: 7,
            ),

            if (inspections.isEmpty)
              const _CompactEmptyInspectionState()
            else
              Column(
                children:
                    inspections
                        .map(
                          (
                            inspection,
                          ) =>
                              Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              bottom: 7,
                            ),
                            child:
                                _RecentInspectionTile(
                              inspection:
                                  inspection,
                            ),
                          ),
                        )
                        .toList(),
              ),

            const SizedBox(
              height: 14,
            ),

            // ======================================================
            // QUICK ACTIONS
            // ======================================================

            const SectionHeader(
              title:
                  'Quick Actions',
            ),

            const SizedBox(
              height: 8,
            ),

            LayoutBuilder(
              builder: (
                context,
                constraints,
              ) {
                final width =
                    constraints.maxWidth;

                final columns =
                    width >= 620
                        ? 5
                        : width >= 390
                            ? 3
                            : 2;

                const spacing = 8.0;

                final itemWidth =
                    (width -
                            (spacing *
                                (columns -
                                    1))) /
                        columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    // PROJECTS
                    SizedBox(
                      width: itemWidth,
                      child:
                          QuickActionCard(
                        icon:
                            Icons.apartment,
                        label:
                            'Projects',
                        onTap: () {
                          Navigator.of(
                            context,
                          ).pushNamed(
                            AppRoutes
                                .projectsPlaceholder,
                          );
                        },
                      ),
                    ),

                    // INSPECTIONS
                    SizedBox(
                      width: itemWidth,
                      child:
                          QuickActionCard(
                        icon: Icons
                            .fact_check_outlined,
                        label:
                            'Inspections',
                        onTap: () {
                          Navigator.of(
                            context,
                          ).pushNamed(
                            AppRoutes
                                .inspectionsPlaceholder,
                          );
                        },
                      ),
                    ),

                    // CCTV
                    SizedBox(
                      width: itemWidth,
                      child:
                          QuickActionCard(
                        icon: Icons
                            .videocam_outlined,
                        label:
                            'CCTV',
                        onTap: () {
                          Navigator.of(
                            context,
                          ).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const OfficialCctvScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    // ANALYTICS
                    SizedBox(
                      width: itemWidth,
                      child:
                          QuickActionCard(
                        icon:
                            Icons.bar_chart,
                        label:
                            'Analytics',
                        onTap: () {
                          Navigator.of(
                            context,
                          ).pushNamed(
                            AppRoutes
                                .analyticsPlaceholder,
                          );
                        },
                      ),
                    ),

                    // CALL HISTORY
                    SizedBox(
                      width: itemWidth,
                      child:
                          QuickActionCard(
                        icon:
                            Icons.history,
                        label:
                            'Call History',
                        onTap: () {
                          Navigator.of(
                            context,
                          ).push(
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
// NOTIFICATION FILTER
// ============================================================

enum _NotificationFilter {
  today,
  unread,
  all,
}

// ============================================================
// NOTIFICATION TYPE
// ============================================================

enum _NotificationType {
  highRisk,
  pendingReview,
}

// ============================================================
// NOTIFICATION MODEL
// ============================================================

class _OfficialNotification {
  final String id;
  final String title;
  final String message;
  final _NotificationType type;
  final DateTime createdAt;
  final DateTime? readAt;

  const _OfficialNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.readAt,
  });

  IconData get icon {
    switch (type) {
      case _NotificationType.highRisk:
        return Icons.warning_amber_rounded;

      case _NotificationType.pendingReview:
        return Icons.assignment_outlined;
    }
  }

  Color get color {
    switch (type) {
      case _NotificationType.highRisk:
        return OfficialHomeScreen.red;

      case _NotificationType.pendingReview:
        return OfficialHomeScreen.saffron;
    }
  }

  _OfficialNotification copyWith({
    String? id,
    String? title,
    String? message,
    _NotificationType? type,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return _OfficialNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'createdAt':
          createdAt.toIso8601String(),
      'readAt':
          readAt?.toIso8601String(),
    };
  }

  factory _OfficialNotification.fromJson(
    Map<String, dynamic> json,
  ) {
    final typeValue =
        json['type']?.toString();

    final type =
        _NotificationType.values.firstWhere(
      (value) =>
          value.name == typeValue,
      orElse: () =>
          _NotificationType.highRisk,
    );

    return _OfficialNotification(
      id:
          json['id']?.toString() ?? '',
      title:
          json['title']?.toString() ?? '',
      message:
          json['message']?.toString() ?? '',
      type: type,
      createdAt:
          DateTime.tryParse(
                json['createdAt']
                        ?.toString() ??
                    '',
              ) ??
              DateTime.now(),
      readAt:
          json['readAt'] == null
              ? null
              : DateTime.tryParse(
                  json['readAt'].toString(),
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
  final VoidCallback onNotificationTap;

  const _HomeHeader({
    required this.userName,
    required this.alertCount,
    required this.onNotificationTap,
  });

  String _greeting() {
    final hour =
        DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning,';
    }

    if (hour < 17) {
      return 'Good Afternoon,';
    }

    return 'Good Evening,';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color:
            OfficialHomeScreen.navy,
        borderRadius:
            BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color:
                OfficialHomeScreen.navy
                    .withValues(
              alpha: 0.12,
            ),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 21,
            backgroundColor:
                Colors.white,
            child: Icon(
              Icons.person,
              color:
                  OfficialHomeScreen.navy,
              size: 22,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Text(
                  _greeting(),
                  style:
                      const TextStyle(
                    fontSize: 10,
                    color:
                        Colors.white70,
                  ),
                ),

                const SizedBox(
                  height: 1,
                ),

                Text(
                  userName,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Colors.white,
                  ),
                ),

                const Text(
                  'Official',
                  style:
                      TextStyle(
                    fontSize: 9,
                    color:
                        Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // NOTIFICATION BELL
          // ======================================================

          Stack(
            clipBehavior:
                Clip.none,
            children: [
              IconButton(
                padding:
                    EdgeInsets.zero,
                constraints:
                    const BoxConstraints(
                  minWidth: 38,
                  minHeight: 38,
                ),
                visualDensity:
                    VisualDensity.compact,
                icon: Icon(
                  alertCount > 0
                      ? Icons
                          .notifications
                      : Icons
                          .notifications_none,
                  color:
                      Colors.white,
                  size: 23,
                ),
                onPressed:
                    onNotificationTap,
              ),

              if (alertCount > 0)
                Positioned(
                  right: 1,
                  top: 1,
                  child: Container(
                    padding:
                        const EdgeInsets
                            .all(
                      3,
                    ),
                    constraints:
                        const BoxConstraints(
                      minWidth: 15,
                      minHeight: 15,
                    ),
                    decoration:
                        const BoxDecoration(
                      color:
                          OfficialHomeScreen
                              .red,
                      shape:
                          BoxShape.circle,
                    ),
                    child: Text(
                      alertCount > 99
                          ? '99+'
                          : '$alertCount',
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        fontSize: 8,
                        color:
                            Colors.white,
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
// DYNAMIC ALERT BANNER
// ============================================================

class _AlertBanner
    extends StatelessWidget {
  final _OfficialNotification notification;
  final int count;
  final VoidCallback onTap;

  const _AlertBanner({
    required this.notification,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(11),
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color:
              const Color(0xFFFFF6E8),
          borderRadius:
              BorderRadius.circular(11),
          border: Border.all(
            color:
                notification.color
                    .withValues(
              alpha: 0.35,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.all(6),
              decoration:
                  BoxDecoration(
                color:
                    notification.color
                        .withValues(
                  alpha: 0.12,
                ),
                borderRadius:
                    BorderRadius.circular(7),
              ),
              child: Icon(
                notification.icon,
                color:
                    notification.color,
                size: 19,
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    count == 1
                        ? notification.title
                        : '$count notifications require attention',
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          OfficialHomeScreen
                              .textDark,
                    ),
                  ),

                  if (count == 1)
                    Text(
                      notification.message,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 10,
                        color:
                            OfficialHomeScreen
                                .textGrey,
                      ),
                    ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color:
                  OfficialHomeScreen.navy,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// NOTIFICATION FILTER BUTTON
// ============================================================

class _NotificationFilterButton extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NotificationFilterButton({
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? OfficialHomeScreen.primaryBlue
              : OfficialHomeScreen.softBlue,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? OfficialHomeScreen.primaryBlue
                : OfficialHomeScreen.borderColor,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected
                  ? Colors.white
                  : OfficialHomeScreen.primaryBlue,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : OfficialHomeScreen.textDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              constraints: const BoxConstraints(minWidth: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : OfficialHomeScreen.primaryBlue,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
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

class _NotificationTile
    extends StatelessWidget {
  final _OfficialNotification notification;
  final bool isRead;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.isRead,
    required this.onTap,
  });

  String _formatDateTime(
    DateTime dateTime,
  ) {
    final hour =
        dateTime.hour % 12 == 0
            ? 12
            : dateTime.hour % 12;

    final minute =
        dateTime.minute
            .toString()
            .padLeft(2, '0');

    final period =
        dateTime.hour >= 12
            ? 'PM'
            : 'AM';

    return '${dateTime.day}/'
        '${dateTime.month}/'
        '${dateTime.year} · '
        '$hour:$minute $period';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(14),
      child: Container(
        padding:
            const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.white
              : notification.color
                  .withValues(
                  alpha: 0.07,
                ),
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color: isRead
                ? OfficialHomeScreen
                    .borderColor
                : notification.color
                    .withValues(
                    alpha: 0.25,
                  ),
          ),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // ICON
            // ==================================================

            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color:
                    notification.color
                        .withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
              child: Icon(
                notification.icon,
                color:
                    notification.color,
                size: 21,
              ),
            ),

            const SizedBox(
              width: 11,
            ),

            // ==================================================
            // CONTENT
            // ==================================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style: TextStyle(
                            color:
                                OfficialHomeScreen
                                    .textDark,
                            fontSize: 13,
                            fontWeight:
                                isRead
                                    ? FontWeight
                                        .w600
                                    : FontWeight
                                        .w800,
                          ),
                        ),
                      ),

                      if (!isRead)
                        Container(
                          width: 7,
                          height: 7,
                          decoration:
                              BoxDecoration(
                            color:
                                notification
                                    .color,
                            shape:
                                BoxShape
                                    .circle,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color:
                          OfficialHomeScreen
                              .textGrey,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  // CREATED TIME
                  Text(
                    _formatDateTime(
                      notification
                          .createdAt,
                    ),
                    style:
                        const TextStyle(
                      color:
                          OfficialHomeScreen
                              .textGrey,
                      fontSize: 9,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  // READ STATUS
                  if (isRead &&
                      notification.readAt !=
                          null)
                    Text(
                      'Read · ${_formatDateTime(notification.readAt!)}',
                      style:
                          const TextStyle(
                        color:
                            OfficialHomeScreen
                                .green,
                        fontSize: 9,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    )
                  else
                    Text(
                      'Unread • Tap to open',
                      style: TextStyle(
                        color:
                            notification
                                .color,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(
              width: 5,
            ),

            const Padding(
              padding:
                  EdgeInsets.only(
                top: 12,
              ),
              child: Icon(
                Icons.chevron_right,
                size: 18,
                color:
                    OfficialHomeScreen
                        .textGrey,
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

class _MiniStatCard
    extends StatelessWidget {
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
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color:
              OfficialHomeScreen
                  .cardBackground,
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color:
                OfficialHomeScreen
                    .borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  OfficialHomeScreen
                      .navy
                      .withValues(
                alpha: 0.035,
              ),
              blurRadius: 6,
              offset:
                  const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.all(6),
              decoration:
                  BoxDecoration(
                color:
                    color.withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                    BorderRadius.circular(
                  7,
                ),
              ),
              child: Icon(
                icon,
                size: 16,
                color: color,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              count,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.bold,
                color:
                    OfficialHomeScreen
                        .navy,
              ),
            ),

            const SizedBox(
              height: 1,
            ),

            Text(
              label,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                fontSize: 10,
                color:
                    OfficialHomeScreen
                        .textGrey,
                height: 1.15,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            Row(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children:
                  List.generate(
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
                        const EdgeInsets
                            .only(
                      right: 2,
                    ),
                    child: Container(
                      width: 4,
                      height:
                          heights[i],
                      decoration:
                          BoxDecoration(
                        color:
                            color.withValues(
                          alpha:
                              0.35 +
                                  (i *
                                      0.15),
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
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
// EMPTY INSPECTION STATE
// ============================================================

class _CompactEmptyInspectionState
    extends StatelessWidget {
  const _CompactEmptyInspectionState();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color:
            OfficialHomeScreen
                .cardBackground,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              OfficialHomeScreen
                  .borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.all(8),
            decoration:
                BoxDecoration(
              color:
                  OfficialHomeScreen
                      .softBlue,
              borderRadius:
                  BorderRadius.circular(
                9,
              ),
            ),
            child: const Icon(
              Icons
                  .fact_check_outlined,
              size: 22,
              color:
                  OfficialHomeScreen
                      .navy,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  'No recent inspections',
                  style:
                      TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        OfficialHomeScreen
                            .textDark,
                  ),
                ),
                SizedBox(
                  height: 2,
                ),
                Text(
                  'Inspections will appear here once submitted.',
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      TextStyle(
                    fontSize: 10,
                    color:
                        OfficialHomeScreen
                            .textGrey,
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
        return OfficialHomeScreen
            .green;

      case InspectionStatus.overdue:
        return OfficialHomeScreen
            .red;

      case InspectionStatus.underReview:
        return OfficialHomeScreen
            .saffron;

      case InspectionStatus.submitted:
        return OfficialHomeScreen
            .primaryBlue;

      case InspectionStatus.inProgress:
        return OfficialHomeScreen
            .navy;

      case InspectionStatus.assigned:
        return OfficialHomeScreen
            .textGrey;
    }
  }

  Color get _riskColor {
    switch (inspection.risk) {
      case RiskLevel.high:
        return OfficialHomeScreen
            .red;

      case RiskLevel.medium:
        return OfficialHomeScreen
            .saffron;

      case RiskLevel.low:
        return OfficialHomeScreen
            .green;
    }
  }

  String _formatTime(
    DateTime dt,
  ) {
    final hour =
        dt.hour % 12 == 0
            ? 12
            : dt.hour % 12;

    final period =
        dt.hour >= 12
            ? 'PM'
            : 'AM';

    final minute =
        dt.minute
            .toString()
            .padLeft(2, '0');

    return '${dt.day} Sep ${dt.year} · '
        '$hour:$minute $period';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap: () {},
      borderRadius:
          BorderRadius.circular(12),
      child: Container(
        padding:
            const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color:
              OfficialHomeScreen
                  .cardBackground,
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color:
                OfficialHomeScreen
                    .borderColor,
          ),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration:
                  BoxDecoration(
                color:
                    OfficialHomeScreen
                        .softBlue,
                borderRadius:
                    BorderRadius.circular(
                  9,
                ),
              ),
              child: const Icon(
                Icons.apartment,
                color:
                    OfficialHomeScreen
                        .navy,
                size: 21,
              ),
            ),

            const SizedBox(
              width: 9,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Text(
                    inspection.projectName,
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          OfficialHomeScreen
                              .textDark,
                    ),
                  ),

                  const SizedBox(
                    height: 1,
                  ),

                  Text(
                    'Inspector: ${inspection.inspectorName}',
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 10,
                      color:
                          OfficialHomeScreen
                              .textGrey,
                    ),
                  ),

                  const SizedBox(
                    height: 2,
                  ),

                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 11,
                        color:
                            OfficialHomeScreen
                                .textGrey,
                      ),

                      const SizedBox(
                        width: 3,
                      ),

                      Expanded(
                        child: Text(
                          _formatTime(
                            inspection
                                .dateTime,
                          ),
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 10,
                            color:
                                OfficialHomeScreen
                                    .textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: [
                      _SmallStatusBadge(
                        label:
                            inspection
                                .status
                                .label,
                        color:
                            _statusColor,
                      ),

                      _SmallStatusBadge(
                        label:
                            '${inspection.risk.label} Risk',
                        color:
                            _riskColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 3,
            ),

            const Padding(
              padding:
                  EdgeInsets.only(
                top: 12,
              ),
              child: Icon(
                Icons.chevron_right,
                size: 17,
                color:
                    OfficialHomeScreen
                        .textGrey,
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
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(6),
        border: Border.all(
          color:
              color.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Text(
        label,
        style:
            TextStyle(
          fontSize: 9,
          fontWeight:
              FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}