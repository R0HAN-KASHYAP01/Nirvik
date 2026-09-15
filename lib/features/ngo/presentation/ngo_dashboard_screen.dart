import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../services/ngo_attendance_service.dart';
import '../../../services/ngo_camera_service.dart';
import '../../../services/ngo_institute_service.dart';
import '../../../services/ngo_reports_service.dart';
import '../../../services/ngo_notification_service.dart';
import '../../../services/session_service.dart';
import '../../calls/presentation/call_history_screen.dart';
import 'ngo_notifications_screen.dart';

class NgoDashboardScreen extends StatefulWidget {
  const NgoDashboardScreen({super.key});

  @override
  State<NgoDashboardScreen> createState() => _NgoDashboardScreenState();
}

class _NgoDashboardScreenState extends State<NgoDashboardScreen> {
  // ============================================================
  // TOTAL STATUS DATA
  // ============================================================

  int _totalAttendance = 0;
  int _totalReports = 0;
  int _totalCameraFeeds = 0;

  // ============================================================
  // TODAY'S OVERVIEW DATA
  // ============================================================

  int _todayBeneficiaries = 0;
  int _todayStaff = 0;
  int _todayReports = 0;
  bool _attendanceSubmittedToday = false;

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  int _unreadNotificationCount = 0;

  // ============================================================
  // GENERAL STATE
  // ============================================================

  bool _loadingStats = true;
  String? _organizationName;
  Timer? _autoReloadTimer;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color navy = Color(0xFF123E68);
  static const Color darkBlue = Color(0xFF0D4778);
  static const Color background = Color(0xFFEAF1F6);
  static const Color cardBackground = Color(0xFFE4EDF3);
  static const Color softBlueGrey = Color(0xFFDCE8F0);
  static const Color green = Color(0xFF159447);
  static const Color orange = Color(0xFFF5A623);
  static const Color borderColor = Color(0xFFD3E0E8);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadDashboardData();

    _autoReloadTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        _loadDashboardData();
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _autoReloadTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // LOAD DASHBOARD DATA
  // ============================================================

  Future<void> _loadDashboardData() async {
    final user = SessionService.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _loadingStats = false;
        _unreadNotificationCount = 0;
      });

      return;
    }

    try {
      // ----------------------------------------------------------
      // ATTENDANCE
      // ----------------------------------------------------------

      final attendanceFuture =
          NgoAttendanceService.instance.fetchHistory(user.id);

      // ----------------------------------------------------------
      // REPORTS
      // ----------------------------------------------------------

      final reportsFuture =
          NgoReportsService.instance.fetchReports(user.id);

      // ----------------------------------------------------------
      // CAMERA FEEDS
      // ----------------------------------------------------------

      final feedsFuture =
          NgoCameraService.instance.fetchFeeds(user.id);

      // ----------------------------------------------------------
      // NGO / INSTITUTE NAME
      // ----------------------------------------------------------

      final organizationFuture =
          NgoInstituteService.instance.fetchOrganizationName(
        user.id,
      );

      // ----------------------------------------------------------
      // NOTIFICATIONS
      // ----------------------------------------------------------

      final unreadNotificationFuture =
          NgoNotificationService.instance.fetchUnreadCount(
        user.id,
      );

      final results = await Future.wait([
        attendanceFuture,
        reportsFuture,
        feedsFuture,
        organizationFuture,
        unreadNotificationFuture,
      ]);

      // ==========================================================
      // DATA
      // ==========================================================

      final attendance =
          results[0] as List<AttendanceRecord>;

      final reports =
          results[1] as List<NgoReport>;

      final feeds = results[2] as List;

      final organizationName =
          results[3] as String?;

      final unreadNotificationCount =
          results[4] as int;

      // ==========================================================
      // TOTAL ATTENDANCE
      // ==========================================================

      final totalAttendance = attendance.length;

      // ==========================================================
      // TODAY
      // ==========================================================

      final now = DateTime.now();

      final todayYear = now.year;
      final todayMonth = now.month;
      final todayDay = now.day;

      int todayBeneficiaries = 0;
      int todayStaff = 0;
      bool attendanceSubmittedToday = false;

      for (final record in attendance) {
        final recordDate = record.date;

        final isToday =
            recordDate.year == todayYear &&
            recordDate.month == todayMonth &&
            recordDate.day == todayDay;

        if (!isToday) {
          continue;
        }

        attendanceSubmittedToday = true;

        if (record.type == AttendanceType.beneficiary) {
          todayBeneficiaries = record.presentCount;
        }

        if (record.type == AttendanceType.staff) {
          todayStaff = record.presentCount;
        }
      }

      // ==========================================================
      // TODAY'S REPORTS
      // ==========================================================

      int todayReports = 0;

      for (final report in reports) {
        final reportDate = report.createdAt;

        final isToday =
            reportDate.year == todayYear &&
            reportDate.month == todayMonth &&
            reportDate.day == todayDay;

        if (isToday) {
          todayReports++;
        }
      }

      // ==========================================================
      // UPDATE UI
      // ==========================================================

      if (!mounted) return;

      setState(() {
        _totalAttendance = totalAttendance;
        _totalReports = reports.length;
        _totalCameraFeeds = feeds.length;

        _todayBeneficiaries = todayBeneficiaries;
        _todayStaff = todayStaff;
        _todayReports = todayReports;

        _attendanceSubmittedToday =
            attendanceSubmittedToday;

        _organizationName = organizationName;

        _unreadNotificationCount =
            unreadNotificationCount;

        _loadingStats = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingStats = false;
      });

      debugPrint(
        'NGO dashboard refresh error: $error',
      );
    }
  }

  // ============================================================
  // OPEN NOTIFICATIONS
  // ============================================================

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NgoNotificationsScreen(),
      ),
    );

    // Refresh unread badge after coming back.
    await _refreshUnreadNotificationCount();
  }

  // ============================================================
  // REFRESH ONLY NOTIFICATION COUNT
  // ============================================================

  Future<void> _refreshUnreadNotificationCount() async {
    final user = SessionService.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _unreadNotificationCount = 0;
      });

      return;
    }

    try {
      final count =
          await NgoNotificationService.instance
              .fetchUnreadCount(user.id);

      if (!mounted) return;

      setState(() {
        _unreadNotificationCount = count;
      });
    } catch (error) {
      debugPrint(
        'Notification count refresh error: $error',
      );
    }
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _openAttendance() {
    Navigator.of(context).pushNamed(
      AppRoutes.ngoAttendance,
    );
  }

  void _openReports() {
    Navigator.of(context).pushNamed(
      AppRoutes.ngoReports,
    );
  }

  void _openCamera() {
    Navigator.of(context).pushNamed(
      AppRoutes.ngoCamera,
    );
  }

  void _openNotices() async {
    await _openNotifications();
  }

  // ============================================================
  // GREETING
  // ============================================================

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  // ============================================================
  // TODAY LABEL
  // ============================================================

  String _todayLabel() {
    final now = DateTime.now();

    const weekdays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${weekdays[now.weekday - 1]}, '
        '${now.day.toString().padLeft(2, '0')} '
        '${months[now.month - 1]} '
        '${now.year}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: darkBlue,
          backgroundColor: Colors.white,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              _buildTopHeader(),

              const SizedBox(height: 12),

              _buildGovernmentBanner(),

              const SizedBox(height: 18),

              _buildTotalStatus(),

              const SizedBox(height: 20),

              _buildTodayOverview(),

              const SizedBox(height: 20),

              _buildQuickStatus(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOP HEADER
  // ============================================================

  Widget _buildTopHeader() {
    final organizationName =
        _organizationName?.trim().isNotEmpty == true
            ? _organizationName!.trim()
            : 'NGO / Institute';

    final unreadCount = _unreadNotificationCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        17,
        18,
        18,
      ),
      decoration: const BoxDecoration(
        color: darkBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          // ======================================================
          // PROFILE CIRCLE
          // ======================================================

          Container(
            width: 55,
            height: 55,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.business_rounded,
              size: 31,
              color: darkBlue,
            ),
          ),

          const SizedBox(width: 13),

          // ======================================================
          // USER INFORMATION
          // ======================================================

          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  organizationName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // NOTIFICATION BELL
          // ======================================================

          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: _openNotifications,
                tooltip: 'Notifications',
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 31,
                ),
              ),

              // ==================================================
              // RED UNREAD BADGE
              // ==================================================

              if (unreadCount > 0)
                Positioned(
                  right: 5,
                  top: 2,
                  child: Container(
                    constraints:
                        const BoxConstraints(
                      minWidth: 19,
                      minHeight: 19,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: unreadCount < 10
                          ? BoxShape.circle
                          : BoxShape.rectangle,
                      borderRadius: unreadCount >= 10
                          ? BorderRadius.circular(10)
                          : null,
                      border: Border.all(
                        color: darkBlue,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99
                            ? '99+'
                            : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
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

  // ============================================================
  // GOVERNMENT BANNER
  // ============================================================

  Widget _buildGovernmentBanner() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        width: double.infinity,
        constraints:
            const BoxConstraints(minHeight: 82),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFE0E8EE),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: 0.035),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              // ==================================================
              // LEFT TEXT
              // ==================================================

              const Expanded(
                flex: 6,
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Let's build a stronger,",
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      "more inclusive society",
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // TRICOLOR LINES
              // ==================================================

              Expanded(
                flex: 4,
                child: Center(
                  child: SizedBox(
                    height: 34,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          bottom: 11,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 4,
                            decoration:
                                BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(
                                10,
                              ),
                              color: const Color(
                                0xFFFFC66D,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          left: 18,
                          right: 4,
                          child: Container(
                            height: 4,
                            decoration:
                                BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(
                                10,
                              ),
                              color: const Color(
                                0xFF54B96B,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ==================================================
              // RIGHT TEXT
              // ==================================================

              const Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      'Government',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'for a Brighter',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Tomorrow',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
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

  // ============================================================
  // TOTAL STATUS
  // ============================================================

  Widget _buildTotalStatus() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Total Status'),

          const SizedBox(height: 12),

          IntrinsicHeight(
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildStatusCard(
                    icon: Icons.groups_rounded,
                    iconColor: green,
                    title: 'Attendance',
                    bottomText:
                        '$_totalAttendance Submitted',
                    bottomColor: green,
                    showCheck:
                        _totalAttendance > 0,
                    onTap: _openAttendance,
                  ),
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: _buildStatusCard(
                    icon:
                        Icons.description_rounded,
                    iconColor: darkBlue,
                    title: 'Reports',
                    bottomText:
                        '$_totalReports Submitted',
                    bottomColor: green,
                    showCheck:
                        _totalReports > 0,
                    onTap: _openReports,
                  ),
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: _buildStatusCard(
                    icon: Icons.notifications_active_rounded,
                    iconColor: orange,
                    title: 'Notices',
                    bottomText: 'View',
                    bottomColor: darkBlue,
                    showCheck: false,
                    onTap: _openNotices,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS CARD
  // ============================================================

  Widget _buildStatusCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String bottomText,
    required Color bottomColor,
    required bool showCheck,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          constraints:
              const BoxConstraints(
            minHeight: 108,
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius:
                BorderRadius.circular(9),
            border: Border.all(
              color: borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(alpha: 0.025),
                blurRadius: 4,
                offset:
                    const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: softBlueGrey,
                  borderRadius:
                      BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color: iconColor,
                ),
              ),

              const SizedBox(height: 7),

              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: navy,
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(height: 5),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  if (showCheck) ...[
                    Icon(
                      Icons.check_circle_rounded,
                      color: bottomColor,
                      size: 13,
                    ),
                    const SizedBox(width: 3),
                  ],
                  Flexible(
                    child: Text(
                      bottomText,
                      textAlign:
                          TextAlign.center,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: bottomColor,
                        fontSize: 9,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TODAY'S OVERVIEW
  // ============================================================

  Widget _buildTodayOverview() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'Today’s Overview',
          ),

          const SizedBox(height: 4),

          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: Colors.grey,
              ),

              const SizedBox(width: 4),

              Flexible(
                child: Text(
                  _todayLabel(),
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          IntrinsicHeight(
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildOverviewCard(
                    icon: Icons.groups_rounded,
                    iconColor: green,
                    number:
                        '$_todayBeneficiaries',
                    label:
                        'Beneficiaries\npresent',
                  ),
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: _buildOverviewCard(
                    icon: Icons.badge_rounded,
                    iconColor: darkBlue,
                    number:
                        '$_todayStaff',
                    label:
                        'Staff present',
                  ),
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: _buildOverviewCard(
                    icon:
                        Icons.description_rounded,
                    iconColor: darkBlue,
                    number:
                        '$_todayReports',
                    label:
                        'Reports\nsubmitted',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OVERVIEW CARD
  // ============================================================

  Widget _buildOverviewCard({
    required IconData icon,
    required Color iconColor,
    required String number,
    required String label,
  }) {
    return Container(
      constraints:
          const BoxConstraints(
        minHeight: 105,
      ),
      padding:
          const EdgeInsets.fromLTRB(
        10,
        10,
        7,
        8,
      ),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius:
            BorderRadius.circular(9),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.025),
            blurRadius: 4,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: iconColor,
          ),

          const SizedBox(height: 5),

          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment:
                  Alignment.centerLeft,
              child: Text(
                number,
                maxLines: 1,
                style: const TextStyle(
                  color: navy,
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),
          ),

          const SizedBox(height: 1),

          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 9,
                height: 1.2,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK STATUS
  // ============================================================

  Widget _buildQuickStatus() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'Quick Status',
          ),

          const SizedBox(height: 12),

          IntrinsicHeight(
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildQuickCard(
                    icon:
                        Icons.groups_rounded,
                    title:
                        'Daily Attendance',
                    onTap:
                        _openAttendance,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _buildQuickCard(
                    icon:
                        Icons.description_rounded,
                    title:
                        'Reports',
                    onTap:
                        _openReports,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          IntrinsicHeight(
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildQuickCard(
                    icon:
                        Icons.videocam_rounded,
                    title:
                        'Camera / Video',
                    onTap:
                        _openCamera,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _buildQuickCard(
                    icon:
                        Icons.business_rounded,
                    title:
                        'Institute Profile',
                    onTap: () async {
                      await Navigator.of(context)
                          .pushNamed(
                        AppRoutes.ngoProfile,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickCard(
                    icon:
                        Icons.history_rounded,
                    title:
                        'Call History',
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

                const SizedBox(width: 10),

                const Expanded(
                  child: SizedBox(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK CARD
  // ============================================================

  Widget _buildQuickCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius:
          BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(9),
        child: Container(
          constraints:
              const BoxConstraints(
            minHeight: 86,
          ),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius:
                BorderRadius.circular(9),
            border: Border.all(
              color: borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(alpha: 0.025),
                blurRadius: 4,
                offset:
                    const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 31,
                color: darkBlue,
              ),

              const SizedBox(height: 8),

              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 4,
                ),
                child: Text(
                  title,
                  textAlign:
                      TextAlign.center,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
    String title,
  ) {
    return Text(
      title,
      maxLines: 1,
      overflow:
          TextOverflow.ellipsis,
      style: const TextStyle(
        color: navy,
        fontSize: 15,
        fontWeight:
            FontWeight.w800,
      ),
    );
  }
}