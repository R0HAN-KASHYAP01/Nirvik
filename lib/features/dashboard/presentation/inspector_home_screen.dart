import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// =========================================
/// SIH / GOVERNMENT OF INDIA — UI COLOR SYSTEM
/// Applied inline throughout this file.
/// =========================================
class _Palette {
  // Primary
  static const Color primaryNavy = Color(0xFF174A7E);
  static const Color darkNavy = Color(0xFF123A63);
  static const Color lightBlue = Color(0xFFEAF2F9);

  // Backgrounds
  static const Color appBackground = Color(0xFFF7F8FA);
  static const Color sectionBackground = Color(0xFFF4F8FC);
  static const Color surface = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);

  // Border
  static const Color border = Color(0xFFD5D9DE);

  // Success
  static const Color success = Color(0xFF2E7D5B);
  static const Color successBg = Color(0xFFEAF5EF);

  // Warning
  static const Color warning = Color(0xFFB7791F);
  static const Color warningBg = Color(0xFFFFF4DC);

  // Danger
  static const Color danger = Color(0xFFC0392B);
  static const Color dangerBg = Color(0xFFFCEBE9);

  // Info
  static const Color info = Color(0xFF2468A8);
  static const Color infoBg = Color(0xFFEAF3FB);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryNavy, darkNavy],
  );

  static const LinearGradient lightBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sectionBackground, lightBlue],
  );

  static const LinearGradient appBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [appBackground, sectionBackground, lightBlue],
  );

  /// Returns the (foreground, background) gradient pair for a given
  /// semantic status, used for notification icons, badges and banners.
  static ({Color fg, LinearGradient bg}) statusColors(String kind) {
    switch (kind) {
      case 'success':
        return (
          fg: success,
          bg: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [successBg, Color(0xFFDCF0E5)],
          ),
        );
      case 'warning':
        return (
          fg: warning,
          bg: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [warningBg, Color(0xFFFCE9C4)],
          ),
        );
      case 'danger':
        return (
          fg: danger,
          bg: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [dangerBg, Color(0xFFF8D9D6)],
          ),
        );
      case 'info':
      default:
        return (
          fg: info,
          bg: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [infoBg, Color(0xFFDDEBF8)],
          ),
        );
    }
  }
}

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

  // Persisted notification history for the currently logged-in inspector.
  List<_InspectorNotification> _notificationHistory = [];

  List<_InspectorNotification> get _visibleNotifications {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));

    final visible = _notificationHistory
        .where((notification) => notification.createdAt.isAfter(cutoff))
        .toList();

    visible.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return visible;
  }

  List<_InspectorNotification> get _unreadNotifications {
    return _visibleNotifications
        .where((notification) => notification.readAt == null)
        .toList();
  }

  int get _unreadNotificationCount => _unreadNotifications.length;

  String? get _userId => SessionService.instance.currentUser?.id;

  String get _notificationHistoryKey =>
      'inspector_notification_history_${_userId ?? 'unknown'}';

  String get _notificationInitializedKey =>
      'inspector_notification_initialized_${_userId ?? 'unknown'}';

  String get _notificationKnownEventsKey =>
      'inspector_notification_known_events_${_userId ?? 'unknown'}';

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final assignments = await _repository.getAssignments();

      if (!mounted) return;

      setState(() {
        _assignments = assignments;
        _isLoading = false;
      });

      await _syncNotifications(assignments);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load assignments.';
      });

      debugPrint('Failed to load assignments: $error');
    }
  }

  Future<void> _syncNotifications(
    List<AssignmentSummary> assignments,
  ) async {
    final userId = _userId;

    if (userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      final initialized =
          prefs.getBool(_notificationInitializedKey) ?? false;

      final stored = prefs.getString(_notificationHistoryKey);

      final history = <_InspectorNotification>[];

      if (stored != null && stored.isNotEmpty) {
        try {
          final decoded = jsonDecode(stored);

          if (decoded is List) {
            for (final item in decoded) {
              if (item is Map) {
                try {
                  history.add(
                    _InspectorNotification.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  );
                } catch (_) {
                  // Ignore malformed notification.
                }
              }
            }
          }
        } catch (_) {
          // Ignore malformed stored notification data.
        }
      }

      final historyById = <String, _InspectorNotification>{
        for (final notification in history) notification.id: notification,
      };

      // Keep known events separate from 30-day notification history.
      final knownEvents = <String>{
        ...(prefs.getStringList(_notificationKnownEventsKey) ??
            const <String>[]),
      };

      if (!initialized) {
        // Existing assignments become baseline notifications.
        // They are marked as read so old assignments do not appear as new.
        for (final assignment in assignments) {
          if (!_shouldNotifyForStatus(assignment.status)) {
            continue;
          }

          final eventId = _eventIdFor(assignment);

          knownEvents.add(eventId);

          historyById.putIfAbsent(
            eventId,
            () => _notificationFromAssignment(
              assignment,
              createdAt: assignment.createdAt,
              readAt: assignment.createdAt,
            ),
          );
        }

        await prefs.setBool(
          _notificationInitializedKey,
          true,
        );
      } else {
        // Only new assignment events become unread notifications.
        for (final assignment in assignments) {
          if (!_shouldNotifyForStatus(assignment.status)) {
            continue;
          }

          final eventId = _eventIdFor(assignment);

          if (knownEvents.contains(eventId)) {
            continue;
          }

          historyById[eventId] = _notificationFromAssignment(
            assignment,
            createdAt: DateTime.now(),
          );

          knownEvents.add(eventId);
        }
      }

      await prefs.setStringList(
        _notificationKnownEventsKey,
        knownEvents.toList(),
      );

      // Keep notification history only for the last 30 days.
      final cutoff = DateTime.now().subtract(
        const Duration(days: 30),
      );

      final updatedHistory = historyById.values
          .where(
            (notification) =>
                notification.createdAt.isAfter(cutoff),
          )
          .toList()
        ..sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        );

      await prefs.setString(
        _notificationHistoryKey,
        jsonEncode(
          updatedHistory
              .map(
                (notification) => notification.toJson(),
              )
              .toList(),
        ),
      );

      if (!mounted) return;

      setState(() {
        _notificationHistory = updatedHistory;
      });
    } catch (error) {
      debugPrint(
        'Failed to sync inspector notifications: $error',
      );
    }
  }

  String _eventIdFor(AssignmentSummary assignment) {
    return 'assignment-${assignment.id}-${assignment.status.name}';
  }

  bool _shouldNotifyForStatus(AssignmentStatus status) {
    return status == AssignmentStatus.assigned ||
        status == AssignmentStatus.inProgress ||
        status == AssignmentStatus.expired ||
        status == AssignmentStatus.completed;
  }

  _InspectorNotification _notificationFromAssignment(
    AssignmentSummary assignment, {
    required DateTime createdAt,
    DateTime? readAt,
  }) {
    switch (assignment.status) {
      case AssignmentStatus.assigned:
        return _InspectorNotification(
          id: _eventIdFor(assignment),
          title: 'New assignment',
          message:
              '${assignment.instituteName} has been assigned to you.',
          iconType: _NotificationIconType.assignment,
          statusKind: 'info',
          status: AssignmentStatus.assigned,
          createdAt: createdAt,
          readAt: readAt,
        );

      case AssignmentStatus.inProgress:
        return _InspectorNotification(
          id: _eventIdFor(assignment),
          title: 'Inspection in progress',
          message:
              '${assignment.instituteName} inspection is currently in progress.',
          iconType: _NotificationIconType.progress,
          statusKind: 'info',
          status: AssignmentStatus.inProgress,
          createdAt: createdAt,
          readAt: readAt,
        );

      case AssignmentStatus.expired:
        return _InspectorNotification(
          id: _eventIdFor(assignment),
          title: 'Inspection expired',
          message:
              '${assignment.instituteName} inspection has expired.',
          iconType: _NotificationIconType.error,
          statusKind: 'danger',
          status: AssignmentStatus.expired,
          createdAt: createdAt,
          readAt: readAt,
        );

      case AssignmentStatus.completed:
        return _InspectorNotification(
          id: _eventIdFor(assignment),
          title: 'Inspection completed',
          message:
              '${assignment.instituteName} inspection is completed.',
          iconType: _NotificationIconType.completed,
          statusKind: 'success',
          status: AssignmentStatus.completed,
          createdAt: createdAt,
          readAt: readAt,
        );
    }
  }

  Future<void> _markNotificationAsRead(String id) async {
    final index = _notificationHistory.indexWhere(
      (notification) => notification.id == id,
    );

    if (index == -1 ||
        _notificationHistory[index].readAt != null) {
      return;
    }

    final now = DateTime.now();

    final updated =
        List<_InspectorNotification>.from(
      _notificationHistory,
    );

    updated[index] = updated[index].copyWith(
      readAt: now,
    );

    setState(() {
      _notificationHistory = updated;
    });

    await _saveNotificationHistory(updated);
  }

  Future<void> _markAllNotificationsAsRead() async {
    final now = DateTime.now();

    final updated = _notificationHistory.map(
      (notification) {
        if (notification.readAt != null) {
          return notification;
        }

        return notification.copyWith(
          readAt: now,
        );
      },
    ).toList();

    setState(() {
      _notificationHistory = updated;
    });

    await _saveNotificationHistory(updated);
  }

  Future<void> _saveNotificationHistory(
    List<_InspectorNotification> history,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final cutoff = DateTime.now().subtract(
        const Duration(days: 30),
      );

      final cleaned = history
          .where(
            (notification) =>
                notification.createdAt.isAfter(cutoff),
          )
          .toList();

      await prefs.setString(
        _notificationHistoryKey,
        jsonEncode(
          cleaned
              .map(
                (notification) => notification.toJson(),
              )
              .toList(),
        ),
      );
    } catch (error) {
      debugPrint(
        'Failed to save inspector notifications: $error',
      );
    }
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

  void _openNotifications() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _NotificationSheet(
          notifications: _visibleNotifications,
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

  List<AssignmentSummary> get _todaysAssignments {
    final now = DateTime.now();

    return _assignments.where(
      (assignment) {
        final date = assignment.scheduledDateTime;

        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      },
    ).toList();
  }

  int get _todayCount => _todaysAssignments.length;

  int get _activeCount {
    return _assignments
        .where(
          (assignment) =>
              assignment.status ==
                  AssignmentStatus.assigned ||
              assignment.status ==
                  AssignmentStatus.inProgress,
        )
        .length;
  }

  int get _expiredCount {
    return _assignments
        .where(
          (assignment) =>
              assignment.status ==
              AssignmentStatus.expired,
        )
        .length;
  }

  int get _completedCount {
    return _assignments
        .where(
          (assignment) =>
              assignment.status ==
              AssignmentStatus.completed,
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final user =
        SessionService.instance.currentUser;

    return Scaffold(
      // Subtle SIH light-blue gradient across the whole screen background
      // instead of a flat fill.
      backgroundColor: _Palette.appBackground,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: _Palette.appBackgroundGradient,
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: _Palette.primaryNavy,
            backgroundColor: _Palette.surface,
            onRefresh: _loadAssignments,
            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                24,
              ),
              children: [
                _InspectorHeader(
                  userName:
                      user?.name ?? 'PMU Inspector',
                  unreadCount:
                      _unreadNotificationCount,
                  onNotificationTap:
                      _openNotifications,
                ),

                const SizedBox(height: 20),

                PrimaryButton(
                  label:
                      'Start Assigned Inspection',
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes
                          .inspectionWorkflowPlaceholder,
                    );
                  },
                ),

                const SizedBox(height: 12),

                const SizedBox(
                  width: double.infinity,
                  child: RandomVideoCallButton(),
                ),

                if (_unreadNotifications
                    .isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _NotificationBanner(
                    notification:
                        _unreadNotifications.first,
                    count:
                        _unreadNotificationCount,
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
                        icon:
                            Icons.pending_actions_outlined,
                        label: 'Active',
                        count: _isLoading
                            ? '—'
                            : '$_activeCount',
                        accentColor: _Palette.info,
                        onTap: () =>
                            _openAssignments(
                          status:
                              AssignmentStatus.assigned,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: SummaryStatCard(
                        icon:
                            Icons.check_circle_outline,
                        label: 'Done',
                        count: _isLoading
                            ? '—'
                            : '$_completedCount',
                        accentColor:
                            _Palette.success,
                        onTap: () =>
                            _openAssignments(
                          status:
                              AssignmentStatus.completed,
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
                            _Palette.danger,
                        onTap: () =>
                            _openAssignments(
                          status:
                              AssignmentStatus.expired,
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
                  title:
                      "Today's Assignments",
                  actionLabel: 'View all',
                  onActionTap:
                      _openAssignments,
                ),

                const SizedBox(height: 10),

                if (_isLoading)
                  AppCard(
                    child: const Padding(
                      padding:
                          EdgeInsets.all(20),
                      child: Center(
                        child:
                            CircularProgressIndicator(
                          color:
                              _Palette.primaryNavy,
                        ),
                      ),
                    ),
                  )
                else if (_errorMessage != null)
                  AppCard(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(
                            Icons
                                .cloud_off_outlined,
                            size: 40,
                            color:
                                _Palette.textSecondary,
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
                                  _Palette.textSecondary,
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
                                  _Palette.primaryNavy,
                            ),
                            label:
                                const Text(
                              'Retry',
                              style:
                                  TextStyle(
                                color:
                                    _Palette.primaryNavy,
                              ),
                            ),
                            style:
                                OutlinedButton
                                    .styleFrom(
                              side:
                                  const BorderSide(
                                color:
                                    _Palette.border,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_todaysAssignments
                    .isEmpty)
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
                        _todaysAssignments
                            .map(
                      (assignment) =>
                          Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child:
                            AssignmentCard(
                          assignment:
                              assignment,
                        ),
                      ),
                    )
                            .toList(),
                  ),

                const SizedBox(height: 16),

                // "Nearby assignments on map" — highlighted card using the
                // subtle SIH light-blue gradient.
                Container(
                  decoration: BoxDecoration(
                    gradient: _Palette.lightBlueGradient,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _Palette.border,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        size: 24,
                        color:
                            _Palette.primaryNavy,
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
                                _Palette.textPrimary,
                          ),
                        ),
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pushNamed(
                            AppRoutes.instituteMap,
                          );
                        },
                        child:
                            const Text(
                          'View',
                          style:
                              TextStyle(
                            color:
                                _Palette.primaryNavy,
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
      ),
    );
  }
}

enum _NotificationIconType {
  assignment,
  progress,
  error,
  completed,
}

class _InspectorNotification {
  final String id;
  final String title;
  final String message;
  final _NotificationIconType iconType;

  /// One of: 'success', 'warning', 'danger', 'info'.
  /// Drives both the foreground color and the tinted gradient background
  /// via [_Palette.statusColors].
  final String statusKind;
  final AssignmentStatus status;
  final DateTime createdAt;
  final DateTime? readAt;

  const _InspectorNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.iconType,
    required this.statusKind,
    required this.status,
    required this.createdAt,
    this.readAt,
  });

  IconData get icon {
    switch (iconType) {
      case _NotificationIconType.assignment:
        return Icons.assignment_outlined;

      case _NotificationIconType.progress:
        return Icons.play_circle_outline;

      case _NotificationIconType.error:
        return Icons.error_outline;

      case _NotificationIconType.completed:
        return Icons.check_circle_outline;
    }
  }

  Color get color => _Palette.statusColors(statusKind).fg;

  LinearGradient get backgroundGradient =>
      _Palette.statusColors(statusKind).bg;

  _InspectorNotification copyWith({
    DateTime? readAt,
  }) {
    return _InspectorNotification(
      id: id,
      title: title,
      message: message,
      iconType: iconType,
      statusKind: statusKind,
      status: status,
      createdAt: createdAt,
      readAt: readAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'iconType': iconType.name,
      'statusKind': statusKind,
      'status': status.name,
      'createdAt':
          createdAt.toIso8601String(),
      'readAt':
          readAt?.toIso8601String(),
    };
  }

  factory _InspectorNotification.fromJson(
    Map<String, dynamic> json,
  ) {
    final statusName =
        json['status'] as String;

    final iconName =
        json['iconType'] as String;

    // Backward compatible: older persisted entries stored a raw
    // `colorValue` instead of a `statusKind`. Fall back sensibly.
    final statusKind = json['statusKind'] as String? ?? 'info';

    return _InspectorNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      iconType:
          _NotificationIconType.values
              .byName(iconName),
      statusKind: statusKind,
      status:
          AssignmentStatus.values
              .byName(statusName),
      createdAt:
          DateTime.parse(
        json['createdAt'] as String,
      ),
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(
              json['readAt'] as String,
            ),
    );
  }
}

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
            color: _Palette.surface,
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color:
                  _Palette.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration:
                    BoxDecoration(
                  gradient: notification.backgroundGradient,
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
                            _Palette.textPrimary,
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
                            _Palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.chevron_right,
                color:
                    _Palette.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationSheet
    extends StatefulWidget {
  final List<_InspectorNotification>
      notifications;

  final ValueChanged<
          _InspectorNotification>
      onNotificationTap;

  final VoidCallback onMarkAllRead;

  const _NotificationSheet({
    required this.notifications,
    required this.onNotificationTap,
    required this.onMarkAllRead,
  });

  @override
  State<_NotificationSheet> createState() =>
      _NotificationSheetState();
}

enum _NotificationFilter {
  today,
  unread,
  all,
}

class _NotificationSheetState
    extends State<_NotificationSheet> {
  _NotificationFilter
      _selectedFilter =
      _NotificationFilter.today;

  DateTime get _now =>
      DateTime.now();

  List<_InspectorNotification>
      get _filteredNotifications {
    final now = _now;

    final todayCutoff =
        now.subtract(
      const Duration(hours: 24),
    );

    final thirtyDayCutoff =
        now.subtract(
      const Duration(days: 30),
    );

    final source =
        widget.notifications.where(
      (notification) {
        if (notification.createdAt
            .isBefore(
          thirtyDayCutoff,
        )) {
          return false;
        }

        switch (_selectedFilter) {
          case _NotificationFilter.today:
            // ONLY last 24 hours.
            return !notification.createdAt
                .isBefore(
              todayCutoff,
            );

          case _NotificationFilter.unread:
            // ONLY unread from last 30 days.
            return notification.readAt ==
                null;

          case _NotificationFilter.all:
            // ALL from last 30 days.
            return true;
        }
      },
    ).toList();

    source.sort(
      (a, b) => b.createdAt
          .compareTo(a.createdAt),
    );

    return source;
  }

  int get _todayCount {
    final cutoff =
        _now.subtract(
      const Duration(hours: 24),
    );

    return widget.notifications
        .where(
          (notification) =>
              !notification.createdAt
                  .isBefore(cutoff) &&
              notification.createdAt
                  .isAfter(
                _now.subtract(
                  const Duration(days: 30),
                ),
              ),
        )
        .length;
  }

  int get _unreadCount {
    final cutoff =
        _now.subtract(
      const Duration(days: 30),
    );

    return widget.notifications
        .where(
          (notification) =>
              notification.createdAt
                  .isAfter(cutoff) &&
              notification.readAt ==
                  null,
        )
        .length;
  }

  int get _allCount {
    final cutoff =
        _now.subtract(
      const Duration(days: 30),
    );

    return widget.notifications
        .where(
          (notification) =>
              notification.createdAt
                  .isAfter(cutoff),
        )
        .length;
  }

  bool get _hasUnreadInCurrentList =>
      _filteredNotifications.any(
    (notification) =>
        notification.readAt == null,
  );

  String _relativeTime(
    DateTime dateTime,
  ) {
    final difference =
        _now.difference(
      dateTime.toLocal(),
    );

    if (difference.isNegative) {
      return 'Just now';
    }

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }

    if (difference.inDays < 30) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }

    final local =
        dateTime.toLocal();

    return '${local.day}/${local.month}/${local.year}';
  }

  String _filterTitle() {
    switch (_selectedFilter) {
      case _NotificationFilter.today:
        return 'Today (24 hours)';

      case _NotificationFilter.unread:
        return 'Unread notifications';

      case _NotificationFilter.all:
        return 'All notifications';
    }
  }

  String _filterSubtitle() {
    switch (_selectedFilter) {
      case _NotificationFilter.today:
        return 'Only notifications from the last 24 hours';

      case _NotificationFilter.unread:
        return 'Only unread notifications from the last 30 days';

      case _NotificationFilter.all:
        return 'All notifications from the last 30 days';
    }
  }

  Widget _buildFilterButton({
    required _NotificationFilter filter,
    required IconData icon,
    required String label,
    required int count,
  }) {
    final selected =
        _selectedFilter == filter;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 54,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            // Primary SIH gradient on the selected filter chip.
            gradient: selected
                ? _Palette.primaryGradient
                : null,
            color: selected
                ? null
                : _Palette.surface,
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? _Palette.primaryNavy
                  : _Palette.border,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color:
                          Color(0x22174A7E),
                      blurRadius: 10,
                      offset:
                          Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected
                    ? Colors.white
                    : _Palette.textSecondary,
              ),

              const SizedBox(width: 7),

              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w700,
                    color: selected
                        ? Colors.white
                        : _Palette.textPrimary,
                  ),
                ),
              ),

              if (count > 0) ...[
                const SizedBox(width: 6),

                Container(
                  constraints:
                      const BoxConstraints(
                    minWidth: 20,
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration:
                      BoxDecoration(
                    color: selected
                        ? Colors.white
                            .withOpacity(
                            0.18,
                          )
                        : _Palette.lightBlue,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: Text(
                    count > 99
                        ? '99+'
                        : '$count',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w800,
                      color: selected
                          ? Colors.white
                          : _Palette.textPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    _InspectorNotification
        notification,
  ) {
    final isRead =
        notification.readAt != null;

    final accent =
        notification.color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            widget.onNotificationTap(
          notification,
        ),
        borderRadius:
            BorderRadius.circular(17),
        child: Container(
          padding:
              const EdgeInsets.fromLTRB(
            13,
            13,
            10,
            13,
          ),
          decoration:
              BoxDecoration(
            // Unread cards get the tinted SIH gradient; read cards stay
            // plain white surface.
            gradient: isRead
                ? null
                : notification.backgroundGradient,
            color: isRead
                ? _Palette.surface
                : null,
            borderRadius:
                BorderRadius.circular(
              17,
            ),
            border: Border.all(
              color: isRead
                  ? _Palette.border
                  : accent.withOpacity(
                      0.25,
                    ),
            ),
            boxShadow: const [
              BoxShadow(
                color:
                    Color(0x0D202124),
                blurRadius: 8,
                offset:
                    Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                    BoxDecoration(
                  color: _Palette.surface,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  notification.icon,
                  color: accent,
                  size: 23,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                TextStyle(
                              fontSize: 13,
                              height: 1.25,
                              fontWeight:
                                  isRead
                                      ? FontWeight
                                          .w600
                                      : FontWeight
                                          .w800,
                              color:
                                  _Palette.textPrimary,
                            ),
                          ),
                        ),

                        if (!isRead) ...[
                          const SizedBox(
                            width: 6,
                          ),

                          Container(
                            width: 8,
                            height: 8,
                            margin:
                                const EdgeInsets
                                    .only(
                              top: 4,
                            ),
                            decoration:
                                const BoxDecoration(
                              color:
                                  _Palette.danger,
                              shape:
                                  BoxShape
                                      .circle,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 5),

                    Text(
                      notification.message,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color:
                            _Palette.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Icon(
                          Icons
                              .schedule_outlined,
                          size: 14,
                          color: isRead
                              ? _Palette.textSecondary
                              : accent,
                        ),

                        const SizedBox(
                          width: 4,
                        ),

                        Text(
                          _relativeTime(
                            notification
                                .createdAt,
                          ),
                          style:
                              TextStyle(
                            fontSize: 10,
                            fontWeight:
                                FontWeight
                                    .w600,
                            color: isRead
                                ? _Palette.textSecondary
                                : accent,
                          ),
                        ),

                        const Spacer(),

                        Text(
                          isRead
                              ? 'Read'
                              : 'Unread',
                          style:
                              TextStyle(
                            fontSize: 9,
                            fontWeight:
                                FontWeight
                                    .w700,
                            color: isRead
                                ? _Palette.textSecondary
                                : accent,
                          ),
                        ),

                        const SizedBox(
                          width: 2,
                        ),

                        const Icon(
                          Icons
                              .chevron_right,
                          size: 19,
                          color:
                              _Palette.textSecondary,
                        ),
                      ],
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

  Widget _buildEmptyState() {
    String title;
    String message;

    switch (_selectedFilter) {
      case _NotificationFilter.today:
        title = 'No notifications today';
        message =
            'New notifications from the last 24 hours will appear here.';
        break;

      case _NotificationFilter.unread:
        title = 'You’re all caught up!';
        message =
            'There are no unread notifications from the last 30 days.';
        break;

      case _NotificationFilter.all:
        title = 'No notifications';
        message =
            'There are no notifications from the last 30 days.';
        break;
    }

    return Container(
      margin:
          const EdgeInsets.only(top: 10),
      padding:
          const EdgeInsets.fromLTRB(
        20,
        34,
        20,
        38,
      ),
      decoration: BoxDecoration(
        gradient: _Palette.lightBlueGradient,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              _Palette.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration:
                const BoxDecoration(
              color:
                  _Palette.lightBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons
                  .notifications_none_rounded,
              size: 40,
              color:
                  _Palette.textSecondary,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            title,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w800,
              color:
                  _Palette.textPrimary,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            message,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 11,
              height: 1.4,
              color:
                  _Palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications =
        _filteredNotifications;

    return SafeArea(
      child: Container(
        constraints:
            const BoxConstraints(
          maxHeight: 760,
        ),
        decoration:
            const BoxDecoration(
          color:
              _Palette.appBackground,
          borderRadius:
              BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            10,
            18,
            12,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration:
                    BoxDecoration(
                  color:
                      _Palette.border,
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration:
                        const BoxDecoration(
                      // Primary SIH gradient for the sheet's icon avatar.
                      gradient: _Palette.primaryGradient,
                      shape:
                          BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons
                          .notifications_none_rounded,
                      color:
                          Colors.white,
                      size: 24,
                    ),
                  ),

                  const SizedBox(
                    width: 11,
                  ),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          'Notifications',
                          style:
                              TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight
                                    .w800,
                            color:
                                _Palette.textPrimary,
                          ),
                        ),

                        SizedBox(height: 2),

                        Text(
                          'Stay updated with your latest activities',
                          style:
                              TextStyle(
                            fontSize: 10.5,
                            color:
                                _Palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_hasUnreadInCurrentList)
                    TextButton(
                      onPressed:
                          widget.onMarkAllRead,
                      style:
                          TextButton.styleFrom(
                        foregroundColor:
                            _Palette.primaryNavy,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                      child:
                          const Text(
                        'Mark all read',
                        style:
                            TextStyle(
                          fontSize: 10.5,
                          fontWeight:
                              FontWeight
                                  .w700,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // =====================================================
              // THREE FILTER BUTTONS
              // Today | Unread | All
              // =====================================================
              Row(
                children: [
                  _buildFilterButton(
                    filter:
                        _NotificationFilter
                            .today,
                    icon:
                        Icons.today_outlined,
                    label: 'Today',
                    count:
                        _todayCount,
                  ),

                  const SizedBox(width: 8),

                  _buildFilterButton(
                    filter:
                        _NotificationFilter
                            .unread,
                    icon: Icons
                        .mark_email_unread_outlined,
                    label: 'Unread',
                    count:
                        _unreadCount,
                  ),

                  const SizedBox(width: 8),

                  _buildFilterButton(
                    filter:
                        _NotificationFilter
                            .all,
                    icon:
                        Icons.layers_outlined,
                    label: 'All',
                    count:
                        _allCount,
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Align(
                alignment:
                    Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _filterTitle(),
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight
                                .w800,
                        color:
                            _Palette.textPrimary,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      _filterSubtitle(),
                      style:
                          const TextStyle(
                        fontSize: 10.5,
                        color:
                            _Palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Flexible(
                child: notifications
                        .isEmpty
                    ? SingleChildScrollView(
                        child:
                            _buildEmptyState(),
                      )
                    : ListView
                        .separated(
                        shrinkWrap:
                            true,
                        padding:
                            const EdgeInsets
                                .only(
                          bottom: 4,
                        ),
                        itemCount:
                            notifications
                                .length,
                        separatorBuilder:
                            (_, __) =>
                                const SizedBox(
                          height: 9,
                        ),
                        itemBuilder:
                            (
                          context,
                          index,
                        ) =>
                                _buildNotificationCard(
                          notifications[
                              index],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        Container(
          width: 48,
          height: 48,
          decoration:
              const BoxDecoration(
            // Primary SIH gradient for the avatar badge.
            gradient: _Palette.primaryGradient,
            borderRadius:
                BorderRadius.all(
              Radius.circular(14),
            ),
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
                style:
                    TextStyle(
                  fontSize: 13,
                  color:
                      _Palette.textSecondary,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                userName,
                style:
                    const TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      _Palette.textPrimary,
                ),
                overflow:
                    TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        IconButton(
          icon: const Icon(
            Icons.map_outlined,
            color:
                _Palette.textPrimary,
          ),
          tooltip:
              'Institute Map',
          onPressed: () =>
              Navigator.of(context)
                  .pushNamed(
            AppRoutes.instituteMap,
          ),
        ),

        IconButton(
          icon: const Icon(
            Icons.history,
            color:
                _Palette.textPrimary,
          ),
          tooltip:
              'Call History',
          onPressed: () =>
              Navigator.of(context)
                  .push(
            MaterialPageRoute(
              builder: (_) =>
                  const CallHistoryScreen(),
            ),
          ),
        ),

        Stack(
          clipBehavior:
              Clip.none,
          children: [
            IconButton(
              icon: const Icon(
                Icons
                    .notifications_none,
                color:
                    _Palette.textPrimary,
              ),
              tooltip:
                  'Notifications',
              onPressed:
                  onNotificationTap,
            ),

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
                        _Palette.danger,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                    border: Border.all(
                      color:
                          _Palette.appBackground,
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
                            FontWeight
                                .w700,
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