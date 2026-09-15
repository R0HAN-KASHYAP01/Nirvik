import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/routes.dart';
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
import '../../calls/presentation/widgets/random_call_button.dart';
import '../../calls/presentation/call_history_screen.dart';

class InspectorHomeScreen extends StatefulWidget {
  const InspectorHomeScreen({super.key});

  @override
  State<InspectorHomeScreen> createState() =>
      _InspectorHomeScreenState();
}

class _InspectorHomeScreenState extends State<InspectorHomeScreen> {
  final AssignmentsRepository _repository =
      AssignmentsRepository();

  List<AssignmentSummary> _assignments = [];

  bool _isLoading = true;
  String? _errorMessage;

  // ============================================================
  // NOTIFICATION STORAGE
  // ============================================================

  static const String _notificationStorageKey =
      'inspector_notifications';

  final List<_InspectorNotification> _notifications = [];

  // IDs of notifications which user has read.
  final Set<String> _readNotificationIds = <String>{};

  bool _notificationsLoaded = false;

  // ============================================================
  // NOTIFICATION GETTERS
  // ============================================================

  List<_InspectorNotification> get _last30DaysNotifications {
    final now = DateTime.now();

    final thirtyDaysAgo =
        now.subtract(const Duration(days: 30));

    final list = _notifications.where((notification) {
      return !notification.createdAt.isBefore(thirtyDaysAgo);
    }).toList();

    list.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    return list;
  }

  List<_InspectorNotification> get _unreadNotifications {
    return _last30DaysNotifications.where(
      (notification) {
        return !_readNotificationIds.contains(notification.id);
      },
    ).toList();
  }

  int get _unreadNotificationCount =>
      _unreadNotifications.length;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _initializeNotifications();
    _loadAssignments();
  }

  // ============================================================
  // LOAD NOTIFICATIONS FROM PHONE STORAGE
  // ============================================================

  Future<void> _initializeNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final saved =
          prefs.getString(_notificationStorageKey);

      if (saved != null && saved.isNotEmpty) {
        final decoded = jsonDecode(saved);

        if (decoded is List) {
          _notifications.clear();

          for (final item in decoded) {
            if (item is Map) {
              final notification =
                  _InspectorNotification.fromJson(
                Map<String, dynamic>.from(item),
              );

              _notifications.add(notification);

              if (notification.isRead) {
                _readNotificationIds.add(
                  notification.id,
                );
              }
            }
          }
        }
      }

      _removeOlderThan30Days();

      _notificationsLoaded = true;

      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      debugPrint(
        'Failed to load inspector notifications: $error',
      );

      _notificationsLoaded = true;
    }
  }

  // ============================================================
  // SAVE NOTIFICATIONS
  // ============================================================

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final data = _notifications.map((notification) {
        return notification
            .copyWith(
              isRead: _readNotificationIds.contains(
                notification.id,
              ),
            )
            .toJson();
      }).toList();

      await prefs.setString(
        _notificationStorageKey,
        jsonEncode(data),
      );
    } catch (error) {
      debugPrint(
        'Failed to save inspector notifications: $error',
      );
    }
  }

  // ============================================================
  // REMOVE ONLY OLD HISTORY
  // ============================================================

  void _removeOlderThan30Days() {
    final cutoff =
        DateTime.now().subtract(
      const Duration(days: 30),
    );

    _notifications.removeWhere(
      (notification) {
        if (notification.createdAt.isBefore(cutoff)) {
          _readNotificationIds.remove(
            notification.id,
          );

          return true;
        }

        return false;
      },
    );
  }

  // ============================================================
  // LOAD ASSIGNMENTS
  // ============================================================

  Future<void> _loadAssignments() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final assignments =
          await _repository.getAssignments();

      if (!mounted) return;

      setState(() {
        _assignments = assignments;
        _isLoading = false;
      });

      // Create/update notification history.
      await _syncNotifications(assignments);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Unable to load assignments.';
      });

      debugPrint(
        'Failed to load assignments: $error',
      );
    }
  }

  // ============================================================
  // CREATE NOTIFICATIONS FROM REAL ASSIGNMENT DATA
  // ============================================================

  Future<void> _syncNotifications(
    List<AssignmentSummary> assignments,
  ) async {
    if (!_notificationsLoaded) {
      // Wait until old notification history has loaded.
      await _initializeNotifications();
    }

    for (final assignment in assignments) {
      _addNotificationIfNeeded(
        assignment,
      );
    }

    _removeOlderThan30Days();

    await _saveNotifications();

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // ADD NOTIFICATION ONLY ONCE
  // ============================================================

  void _addNotificationIfNeeded(
    AssignmentSummary assignment,
  ) {
    String? id;
    String? title;
    String? message;
    IconData? icon;
    Color? color;

    // ----------------------------------------------------------
    // NEW ASSIGNMENT
    // ----------------------------------------------------------

    if (assignment.status ==
        AssignmentStatus.assigned) {
      id =
          'assignment-${assignment.id}-assigned';

      title = 'New assignment';

      message =
          '${assignment.instituteName} has been assigned to you.';

      icon = Icons.assignment_outlined;

      color = const Color(0xFF123E68);
    }

    // ----------------------------------------------------------
    // INSPECTION IN PROGRESS
    // ----------------------------------------------------------

    else if (assignment.status ==
        AssignmentStatus.inProgress) {
      id =
          'assignment-${assignment.id}-in-progress';

      title = 'Inspection in progress';

      message =
          '${assignment.instituteName} inspection is currently in progress.';

      icon = Icons.play_circle_outline;

      color = const Color(0xFF3157B7);
    }

    // ----------------------------------------------------------
    // EXPIRED
    // ----------------------------------------------------------

    else if (assignment.status ==
        AssignmentStatus.expired) {
      id =
          'assignment-${assignment.id}-expired';

      title = 'Inspection expired';

      message =
          '${assignment.instituteName} inspection has expired.';

      icon = Icons.error_outline;

      color = const Color(0xFFD64545);
    }

    // Completed assignment does not create
    // an unread notification automatically.
    else {
      return;
    }

    if (id == null ||
        title == null ||
        message == null ||
        icon == null ||
        color == null) {
      return;
    }

    // Already exists -> DO NOT create again.
    final alreadyExists = _notifications.any(
      (notification) => notification.id == id,
    );

    if (alreadyExists) {
      return;
    }

    // Use assignment creation time as the notification
    // creation time so it does not reset on every login.
    final createdAt = assignment.createdAt;

    _notifications.add(
      _InspectorNotification(
        id: id,
        title: title,
        message: message,
        iconCode: icon.codePoint,
        colorValue: color.value,
        status: assignment.status,
        createdAt: createdAt,
        isRead: false,
      ),
    );
  }

  // ============================================================
  // TODAY'S ASSIGNMENTS
  // ============================================================

  List<AssignmentSummary> get _todaysAssignments {
    final now = DateTime.now();

    return _assignments.where((assignment) {
      final date =
          assignment.scheduledDateTime;

      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList();
  }

  int get _todayCount =>
      _todaysAssignments.length;

  int get _activeCount {
    return _assignments.where(
      (assignment) {
        return assignment.status ==
                AssignmentStatus.assigned ||
            assignment.status ==
                AssignmentStatus.inProgress;
      },
    ).length;
  }

  int get _expiredCount {
    return _assignments.where(
      (assignment) {
        return assignment.status ==
            AssignmentStatus.expired;
      },
    ).length;
  }

  int get _completedCount {
    return _assignments.where(
      (assignment) {
        return assignment.status ==
            AssignmentStatus.completed;
      },
    ).length;
  }

  // ============================================================
  // OPEN ASSIGNMENTS
  // ============================================================

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

  // ============================================================
  // MARK ONE NOTIFICATION READ
  // ============================================================

  Future<void> _markNotificationAsRead(
    String id,
  ) async {
    if (!_readNotificationIds.contains(id)) {
      setState(() {
        _readNotificationIds.add(id);
      });

      await _saveNotifications();
    }
  }

  // ============================================================
  // MARK ALL READ
  // ============================================================

  Future<void> _markAllNotificationsAsRead() async {
    setState(() {
      for (final notification
          in _last30DaysNotifications) {
        _readNotificationIds.add(
          notification.id,
        );
      }
    });

    await _saveNotifications();
  }

  // ============================================================
  // OPEN NOTIFICATIONS
  // ============================================================

  void _openNotifications() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _NotificationSheet(
          notifications:
              _last30DaysNotifications,
          unreadCount:
              _unreadNotificationCount,
          readIds:
              _readNotificationIds,
          onNotificationTap:
              (notification) async {
            await _markNotificationAsRead(
              notification.id,
            );

            if (!mounted) return;

            Navigator.of(sheetContext).pop();

            _openAssignments(
              status: notification.status,
            );
          },
          onMarkAllRead: () async {
            await _markAllNotificationsAsRead();

            if (!mounted) return;

            Navigator.of(sheetContext).pop();
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
    final user =
        SessionService.instance.currentUser;

    final unread =
        _unreadNotifications;

    return Scaffold(
      backgroundColor:
          const Color(0xFFEAF1F6),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF123E68),
          backgroundColor: Colors.white,
          onRefresh: _loadAssignments,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              24,
            ),
            children: [
              // =================================================
              // HEADER
              // =================================================

              _InspectorHeader(
                userName:
                    user?.name ?? 'PMU Inspector',
                unreadCount:
                    _unreadNotificationCount,
                onNotificationTap:
                    _openNotifications,
              ),

              const SizedBox(height: 20),

              // =================================================
              // START INSPECTION
              // =================================================

              PrimaryButton(
                label:
                    'Start Assigned Inspection',
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed(
                    AppRoutes
                        .inspectionWorkflowPlaceholder,
                  );
                },
              ),

              const SizedBox(height: 12),

              // =================================================
              // RANDOM CALL
              // =================================================

              const SizedBox(
                width: double.infinity,
                child:
                    RandomVideoCallButton(),
              ),

              // =================================================
              // DYNAMIC NOTIFICATION BANNER
              // =================================================

              if (unread.isNotEmpty) ...[
                const SizedBox(height: 14),

                _NotificationBanner(
                  notification: unread.first,
                  count:
                      _unreadNotificationCount,
                  onTap:
                      _openNotifications,
                ),
              ],

              const SizedBox(height: 24),

              // =================================================
              // STATS
              // =================================================

              Row(
                children: [
                  Expanded(
                    child: SummaryStatCard(
                      icon: Icons.today,
                      label: 'Today',
                      count: _isLoading
                          ? '—'
                          : '$_todayCount',
                      onTap: () =>
                          _openAssignments(
                        filter: 'today',
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: SummaryStatCard(
                      icon: Icons
                          .pending_actions_outlined,
                      label: 'Active',
                      count: _isLoading
                          ? '—'
                          : '$_activeCount',
                      accentColor:
                          Colors.indigo,
                      onTap: () =>
                          _openAssignments(
                        status:
                            AssignmentStatus
                                .assigned,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: SummaryStatCard(
                      icon: Icons
                          .check_circle_outline,
                      label: 'Done',
                      count: _isLoading
                          ? '—'
                          : '$_completedCount',
                      accentColor:
                          const Color(
                        0xFF159447,
                      ),
                      onTap: () =>
                          _openAssignments(
                        status:
                            AssignmentStatus
                                .completed,
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
                      icon:
                          Icons.error_outline,
                      label: 'Expired',
                      count: _isLoading
                          ? '—'
                          : '$_expiredCount',
                      accentColor:
                          const Color(
                        0xFFD64545,
                      ),
                      onTap: () =>
                          _openAssignments(
                        status:
                            AssignmentStatus
                                .expired,
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

              // =================================================
              // TODAY'S ASSIGNMENTS
              // =================================================

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
                    padding:
                        EdgeInsets.all(20),
                    child: Center(
                      child:
                          CircularProgressIndicator(
                        color:
                            Color(0xFF123E68),
                      ),
                    ),
                  ),
                )
              else if (_errorMessage != null)
                AppCard(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      20,
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons
                              .cloud_off_outlined,
                          size: 40,
                          color:
                              Color(0xFF667788),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        Text(
                          _errorMessage!,
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            fontSize: 13,
                            color:
                                Color(0xFF667788),
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        OutlinedButton.icon(
                          onPressed:
                              _loadAssignments,
                          icon:
                              const Icon(
                            Icons.refresh,
                            color:
                                Color(
                              0xFF123E68,
                            ),
                          ),
                          label:
                              const Text(
                            'Retry',
                            style:
                                TextStyle(
                              color:
                                  Color(
                                0xFF123E68,
                              ),
                            ),
                          ),
                          style:
                              OutlinedButton
                                  .styleFrom(
                            side:
                                const BorderSide(
                              color:
                                  Color(
                                0xFFB8CBD8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_todaysAssignments.isEmpty)
                const EmptyState(
                  icon:
                      Icons.assignment_outlined,
                  title:
                      'No assignments today',
                  message:
                      'New assignments will appear here once scheduled.',
                )
              else
                Column(
                  children:
                      _todaysAssignments.map(
                    (assignment) {
                      return Padding(
                        padding:
                            const EdgeInsets
                                .only(
                          bottom: 10,
                        ),
                        child:
                            AssignmentCard(
                          assignment:
                              assignment,
                        ),
                      );
                    },
                  ).toList(),
                ),

              const SizedBox(height: 16),

              // =================================================
              // MAP
              // =================================================

              AppCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.map_outlined,
                      size: 24,
                      color:
                          Color(0xFF123E68),
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Text(
                        'Nearby assignments on map',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              Color(0xFF17324D),
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pushNamed(
                          AppRoutes
                              .instituteMap,
                        );
                      },
                      child: const Text(
                        'View',
                        style: TextStyle(
                          color:
                              Color(0xFF123E68),
                          fontWeight:
                              FontWeight.w600,
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

  final int iconCode;
  final int colorValue;

  final AssignmentStatus status;

  final DateTime createdAt;

  final bool isRead;

  const _InspectorNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.iconCode,
    required this.colorValue,
    required this.status,
    required this.createdAt,
    required this.isRead,
  });

  IconData get icon =>
      IconData(
        iconCode,
        fontFamily: 'MaterialIcons',
      );

  Color get color =>
      Color(colorValue);

  _InspectorNotification copyWith({
    bool? isRead,
  }) {
    return _InspectorNotification(
      id: id,
      title: title,
      message: message,
      iconCode: iconCode,
      colorValue: colorValue,
      status: status,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'iconCode': iconCode,
      'colorValue': colorValue,
      'status': status.name,
      'createdAt':
          createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory _InspectorNotification.fromJson(
    Map<String, dynamic> json,
  ) {
    final statusName =
        json['status']?.toString();

    final status =
        AssignmentStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () =>
          AssignmentStatus.assigned,
    );

    return _InspectorNotification(
      id: json['id']?.toString() ?? '',
      title:
          json['title']?.toString() ?? '',
      message:
          json['message']?.toString() ?? '',
      iconCode:
          (json['iconCode'] as num?)?.toInt() ??
              Icons.notifications.codePoint,
      colorValue:
          (json['colorValue'] as num?)?.toInt() ??
              const Color(0xFF123E68).value,
      status: status,
      createdAt:
          DateTime.tryParse(
                json['createdAt']
                    ?.toString() ??
                    '',
              ) ??
              DateTime.now(),
      isRead:
          json['isRead'] == true,
    );
  }
}

// ============================================================
// NOTIFICATION BANNER
// ============================================================

class _NotificationBanner
    extends StatelessWidget {
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
        borderRadius:
            BorderRadius.circular(14),
        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color:
                  const Color(0xFFD1DEE7),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: notification.color
                      .withOpacity(0.10),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
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
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            Color(0xFF17324D),
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      count == 1
                          ? notification.message
                          : 'You have unread notifications that need attention.',
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 11,
                        color:
                            Color(0xFF667788),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.chevron_right,
                color:
                    Color(0xFF667788),
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
// NOTIFICATION SHEET
// ============================================================

class _NotificationSheet
    extends StatefulWidget {
  final List<_InspectorNotification>
      notifications;

  final int unreadCount;

  final Set<String> readIds;

  final ValueChanged<
          _InspectorNotification>
      onNotificationTap;

  final VoidCallback onMarkAllRead;

  const _NotificationSheet({
    required this.notifications,
    required this.unreadCount,
    required this.readIds,
    required this.onNotificationTap,
    required this.onMarkAllRead,
  });

  @override
  State<_NotificationSheet> createState() =>
      _NotificationSheetState();
}

class _NotificationSheetState
    extends State<_NotificationSheet> {
  bool _showHistory = false;

  List<_InspectorNotification>
      get _visibleNotifications {
    if (_showHistory) {
      return widget.notifications;
    }

    final unread =
        widget.notifications.where(
      (notification) {
        return !widget.readIds.contains(
          notification.id,
        );
      },
    ).toList();

    return unread;
  }

  @override
  Widget build(BuildContext context) {
    final notifications =
        _visibleNotifications;

    return SafeArea(
      child: Container(
        constraints:
            const BoxConstraints(
          maxHeight: 650,
        ),
        decoration:
            const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(
            top: Radius.circular(22),
          ),
        ),
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            14,
            20,
            12,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              // ----------------------------------------------
              // HANDLE
              // ----------------------------------------------

              Container(
                width: 38,
                height: 4,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFD1DEE7,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ----------------------------------------------
              // TITLE
              // ----------------------------------------------

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style:
                          TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            Color(0xFF17324D),
                      ),
                    ),
                  ),

                  if (widget.unreadCount > 0)
                    TextButton(
                      onPressed:
                          widget.onMarkAllRead,
                      child:
                          const Text(
                        'Mark all as read',
                        style:
                            TextStyle(
                          color:
                              Color(
                            0xFF123E68,
                          ),
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              // ----------------------------------------------
              // LAST 30 DAYS OPTION
              // ----------------------------------------------

              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showHistory =
                            !_showHistory;
                      });
                    },
                    child: Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration:
                          BoxDecoration(
                        color: _showHistory
                            ? const Color(
                                0xFF123E68,
                              )
                            : const Color(
                                0xFFEAF1F6,
                              ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          20,
                        ),
                      ),
                      child: Text(
                        'Last 30 days',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w600,
                          color: _showHistory
                              ? Colors.white
                              : const Color(
                                  0xFF123E68,
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    _showHistory
                        ? 'Showing all notifications'
                        : widget.unreadCount > 0
                            ? '${widget.unreadCount} unread'
                            : 'No unread notifications',
                    style:
                        const TextStyle(
                      fontSize: 11,
                      color:
                          Color(0xFF667788),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ----------------------------------------------
              // CONTENT
              // ----------------------------------------------

              if (notifications.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    10,
                    35,
                    10,
                    40,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons
                            .notifications_none,
                        size: 48,
                        color:
                            Color(0xFF9AA9B5),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      Text(
                        _showHistory
                            ? 'No notifications in the last 30 days'
                            : 'No new notifications',
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              Color(0xFF17324D),
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      const Text(
                        'You are all caught up.',
                        style:
                            TextStyle(
                          fontSize: 12,
                          color:
                              Color(0xFF667788),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child:
                      ListView.separated(
                    shrinkWrap: true,
                    itemCount:
                        notifications.length,
                    separatorBuilder:
                        (_, __) =>
                            const Divider(
                      height: 1,
                      color:
                          Color(0xFFE7EDF2),
                    ),
                    itemBuilder:
                        (context, index) {
                      final notification =
                          notifications[
                              index];

                      final isRead = widget
                          .readIds
                          .contains(
                        notification.id,
                      );

                      return ListTile(
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 5,
                        ),

                        leading:
                            Container(
                          width: 44,
                          height: 44,
                          decoration:
                              BoxDecoration(
                            color: notification
                                .color
                                .withOpacity(
                              0.10,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              11,
                            ),
                          ),
                          child: Icon(
                            notification
                                .icon,
                            color:
                                notification
                                    .color,
                            size: 21,
                          ),
                        ),

                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification
                                    .title,
                                style:
                                    const TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                  color:
                                      Color(
                                    0xFF17324D,
                                  ),
                                ),
                              ),
                            ),

                            if (!isRead)
                              Container(
                                width: 7,
                                height: 7,
                                decoration:
                                    const BoxDecoration(
                                  color:
                                      Color(
                                    0xFFD64545,
                                  ),
                                  shape:
                                      BoxShape
                                          .circle,
                                ),
                              ),
                          ],
                        ),

                        subtitle:
                            Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            top: 5,
                          ),
                          child:
                              Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                notification
                                    .message,
                                style:
                                    const TextStyle(
                                  fontSize: 11,
                                  height:
                                      1.35,
                                  color:
                                      Color(
                                    0xFF667788,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 5,
                              ),

                              Text(
                                isRead
                                    ? 'Read • ${_formatNotificationDate(notification.createdAt)}'
                                    : 'Unread • ${_formatNotificationDate(notification.createdAt)}',
                                style:
                                    TextStyle(
                                  fontSize: 10,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                  color: isRead
                                      ? const Color(
                                          0xFF8A9AA7,
                                        )
                                      : const Color(
                                          0xFFD64545,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        trailing:
                            const Icon(
                          Icons
                              .chevron_right,
                          color:
                              Color(
                            0xFF8293A1,
                          ),
                        ),

                        onTap: () =>
                            widget
                                .onNotificationTap(
                          notification,
                        ),
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

  String _formatNotificationDate(
    DateTime date,
  ) {
    final now = DateTime.now();

    final difference =
        now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

// ============================================================
// INSPECTOR HEADER
// ============================================================

class _InspectorHeader
    extends StatelessWidget {
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
        // ----------------------------------------------
        // PROFILE ICON
        // ----------------------------------------------

        Container(
          width: 48,
          height: 48,
          decoration:
              BoxDecoration(
            color:
                const Color(0xFF123E68),
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 25,
          ),
        ),

        const SizedBox(width: 12),

        // ----------------------------------------------
        // NAME
        // ----------------------------------------------

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back,',
                style:
                    TextStyle(
                  fontSize: 13,
                  color:
                      Color(0xFF667788),
                  fontWeight:
                      FontWeight.w500,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                userName,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      Color(0xFF17324D),
                ),
              ),
            ],
          ),
        ),

        // ----------------------------------------------
        // MAP
        // ----------------------------------------------

        IconButton(
          icon: const Icon(
            Icons.map_outlined,
            color:
                Color(0xFF17324D),
          ),
          tooltip: 'Institute Map',
          onPressed: () {
            Navigator.of(context)
                .pushNamed(
              AppRoutes.instituteMap,
            );
          },
        ),

        // ----------------------------------------------
        // CALL HISTORY
        // ----------------------------------------------

        IconButton(
          icon: const Icon(
            Icons.history,
            color:
                Color(0xFF17324D),
          ),
          tooltip: 'Call History',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const CallHistoryScreen(),
              ),
            );
          },
        ),

        // ----------------------------------------------
        // NOTIFICATION BELL
        // ----------------------------------------------

        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none,
                color:
                    Color(0xFF17324D),
              ),
              tooltip:
                  'Notifications',
              onPressed:
                  onNotificationTap,
            ),

            // 🔴 BADGE ONLY IF UNREAD EXISTS
            if (unreadCount > 0)
              Positioned(
                right: 5,
                top: 5,
                child: Container(
                  constraints:
                      const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 4,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFD64545,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                    border:
                        Border.all(
                      color:
                          const Color(
                        0xFFEAF1F6,
                      ),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9
                          ? '9+'
                          : '$unreadCount',
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize: 9,
                        fontWeight:
                            FontWeight.w700,
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