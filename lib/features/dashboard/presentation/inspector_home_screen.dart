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

  // Keeps track of notifications that the inspector has already read.
  final Set<String> _readNotificationIds = <String>{};

  List<_InspectorNotification> get _notifications {
    final notifications = <_InspectorNotification>[];

    for (final assignment in _assignments) {
      if (assignment.status == AssignmentStatus.assigned) {
        notifications.add(
          _InspectorNotification(
            id: 'assignment-${assignment.id}',
            title: 'New assignment',
            message:
                '${assignment.instituteName} has been assigned to you.',
            icon: Icons.assignment_outlined,
            color: const Color(0xFF123E68),
            status: AssignmentStatus.assigned,
          ),
        );
      } else if (assignment.status == AssignmentStatus.inProgress) {
        notifications.add(
          _InspectorNotification(
            id: 'assignment-${assignment.id}',
            title: 'Inspection in progress',
            message:
                '${assignment.instituteName} inspection is currently in progress.',
            icon: Icons.play_circle_outline,
            color: const Color(0xFF3157B7),
            status: AssignmentStatus.inProgress,
          ),
        );
      } else if (assignment.status == AssignmentStatus.expired) {
        notifications.add(
          _InspectorNotification(
            id: 'assignment-${assignment.id}',
            title: 'Inspection expired',
            message:
                '${assignment.instituteName} inspection has expired.',
            icon: Icons.error_outline,
            color: const Color(0xFFD64545),
            status: AssignmentStatus.expired,
          ),
        );
      }
    }

    return notifications;
  }

  List<_InspectorNotification> get _unreadNotifications {
    return _notifications
        .where(
          (notification) =>
              !_readNotificationIds.contains(notification.id),
        )
        .toList();
  }

  int get _unreadNotificationCount {
    return _unreadNotifications.length;
  }

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
        .where(
          (assignment) =>
              assignment.status == AssignmentStatus.assigned ||
              assignment.status == AssignmentStatus.inProgress,
        )
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

  void _markNotificationAsRead(String id) {
    if (!mounted) return;

    setState(() {
      _readNotificationIds.add(id);
    });
  }

  void _openNotifications() {
    final notifications =
        List<_InspectorNotification>.from(_unreadNotifications);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _NotificationSheet(
          notifications: notifications,
          onNotificationTap: (notification) {
            _markNotificationAsRead(notification.id);

            Navigator.of(sheetContext).pop();

            _openAssignments(
              status: notification.status,
            );
          },
          onMarkAllRead: () {
            setState(() {
              _readNotificationIds.addAll(
                notifications.map(
                  (notification) => notification.id,
                ),
              );
            });

            Navigator.of(sheetContext).pop();
          },
        );
      },
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
            padding: const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              24,
            ),
            children: [
              _InspectorHeader(
                userName: user?.name ?? 'PMU Inspector',
                unreadCount: _unreadNotificationCount,
                onNotificationTap: _openNotifications,
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

              // Notification banner appears ONLY when
              // there are unread notifications.
              if (_unreadNotifications.isNotEmpty) ...[
                const SizedBox(height: 14),
                _NotificationBanner(
                  notification: _unreadNotifications.first,
                  count: _unreadNotificationCount,
                  onTap: _openNotifications,
                ),
              ],

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: SummaryStatCard(
                      icon: Icons.today,
                      label: 'Today',
                      count:
                          _isLoading ? '—' : '$_todayCount',
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
                      count:
                          _isLoading ? '—' : '$_activeCount',
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
                      count:
                          _isLoading ? '—' : '$_completedCount',
                      accentColor:
                          const Color(0xFF159447),
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
                      count:
                          _isLoading ? '—' : '$_expiredCount',
                      accentColor:
                          const Color(0xFFD64545),
                      onTap: () => _openAssignments(
                        status: AssignmentStatus.expired,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Expanded(
                    child: SizedBox(),
                  ),

                  const SizedBox(width: 8),

                  const Expanded(
                    child: SizedBox(),
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


// ============================================================
// NOTIFICATION MODEL
// ============================================================

class _InspectorNotification {
  final String id;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final AssignmentStatus status;

  const _InspectorNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.status,
  });
}


// ============================================================
// NOTIFICATION BANNER
// ============================================================

class _NotificationBanner extends StatelessWidget {
  final _InspectorNotification notification;
  final int count;
  final VoidCallback onTap;

  const _NotificationBanner({
    required this.notification,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFD1DEE7),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: notification.color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  notification.icon,
                  color: notification.color,
                  size: 21,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 1
                          ? notification.title
                          : '$count new notifications',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF17324D),
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      count == 1
                          ? notification.message
                          : 'You have unread notifications that need attention.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF667788),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.chevron_right,
                color: Color(0xFF667788),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ============================================================
// NOTIFICATION BOTTOM SHEET
// ============================================================

class _NotificationSheet extends StatelessWidget {
  final List<_InspectorNotification> notifications;
  final ValueChanged<_InspectorNotification>
      onNotificationTap;
  final VoidCallback onMarkAllRead;

  const _NotificationSheet({
    required this.notifications,
    required this.onNotificationTap,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 560,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(22),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            14,
            20,
            12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1DEE7),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF17324D),
                      ),
                    ),
                  ),

                  if (notifications.isNotEmpty)
                    TextButton(
                      onPressed: onMarkAllRead,
                      child: const Text(
                        'Mark all as read',
                        style: TextStyle(
                          color: Color(0xFF123E68),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 6),

              if (notifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    10,
                    30,
                    10,
                    36,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 44,
                        color: Color(0xFF9AA9B5),
                      ),

                      SizedBox(height: 12),

                      Text(
                        'No new notifications',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF17324D),
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        'You are all caught up.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF667788),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) =>
                        const Divider(
                      height: 1,
                      color: Color(0xFFE7EDF2),
                    ),
                    itemBuilder: (context, index) {
                      final notification =
                          notifications[index];

                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: notification.color
                                .withOpacity(0.10),
                            borderRadius:
                                BorderRadius.circular(11),
                          ),
                          child: Icon(
                            notification.icon,
                            color: notification.color,
                            size: 21,
                          ),
                        ),
                        title: Text(
                          notification.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF17324D),
                          ),
                        ),
                        subtitle: Padding(
                          padding:
                              const EdgeInsets.only(top: 4),
                          child: Text(
                            notification.message,
                            style: const TextStyle(
                              fontSize: 11,
                              height: 1.35,
                              color: Color(0xFF667788),
                            ),
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF8293A1),
                        ),
                        onTap: () =>
                            onNotificationTap(notification),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


// ============================================================
// INSPECTOR HEADER
// ============================================================

class _InspectorHeader extends StatelessWidget {
  final String userName;
  final int unreadCount;
  final VoidCallback onNotificationTap;

  const _InspectorHeader({
    required this.userName,
    required this.unreadCount,
    required this.onNotificationTap,
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
            crossAxisAlignment:
                CrossAxisAlignment.start,
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
          onPressed: () =>
              Navigator.of(context).pushNamed(
            AppRoutes.instituteMap,
          ),
        ),

        IconButton(
          icon: const Icon(
            Icons.history,
            color: Color(0xFF17324D),
          ),
          tooltip: 'Call History',
          onPressed: () =>
              Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  const CallHistoryScreen(),
            ),
          ),
        ),

        // Notification bell + dynamic unread badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none,
                color: Color(0xFF17324D),
              ),
              tooltip: 'Notifications',
              onPressed: onNotificationTap,
            ),

            if (unreadCount > 0)
              Positioned(
                right: 5,
                top: 5,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD64545),
                    borderRadius:
                        BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFEAF1F6),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9
                          ? '9+'
                          : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}