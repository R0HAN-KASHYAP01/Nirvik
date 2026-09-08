// FILE: lib/features/ngo/presentation/ngo_dashboard_screen.dart

import 'package:flutter/material.dart';

import '../../../services/session_service.dart';
import '../../../services/ngo_reports_service.dart';
import '../../../services/ngo_camera_service.dart';
import '../../../app/routes.dart';
import '../../calls/presentation/call_history_screen.dart';

class NgoDashboardScreen extends StatefulWidget {
  const NgoDashboardScreen({super.key});

  @override
  State<NgoDashboardScreen> createState() => _NgoDashboardScreenState();
}

class _NgoDashboardScreenState extends State<NgoDashboardScreen> {
  int? _reportsCount;
  int? _feedsCount;
  bool _loadingStats = true;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color navy = Color(0xFF123E68);
  static const Color darkBlue = Color(0xFF0D4778);

  // Main blue-grey background
  static const Color background = Color(0xFFEAF1F6);

  // Blue-grey cards
  static const Color cardBackground = Color(0xFFE4EDF3);

  // Slightly lighter blue-grey for icon containers
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
    _loadStats();
  }

  // ============================================================
  // LOAD STATS
  // ============================================================

  Future<void> _loadStats() async {
    final user = SessionService.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loadingStats = false;
        });
      }
      return;
    }

    try {
      final reports =
          await NgoReportsService.instance.fetchReports(user.id);

      final feeds =
          await NgoCameraService.instance.fetchFeeds(user.id);

      if (!mounted) return;

      setState(() {
        _reportsCount = reports.length;
        _feedsCount = feeds.length;
        _loadingStats = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingStats = false;
      });
    }
  }

  // ============================================================
  // NOTIFICATION
  // ============================================================

  void _showNotifications() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('You have 2 new notifications'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // GREETING
  // ============================================================

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning,';
    } else if (hour < 17) {
      return 'Good afternoon,';
    } else {
      return 'Good evening,';
    }
  }

  // ============================================================
  // BUILD
  // ============================================================
  //
  // NOTE: This screen is rendered as a TAB PAGE inside
  // NgoShellScreen's IndexedStack. It must NOT return its own
  // Scaffold or bottom navigation bar — NgoShellScreen already
  // owns the Scaffold + NavigationBar for Home/Tasks/Profile.
  // Returning a second Scaffold/bottom-nav here was causing two
  // bottom nav bars to render stacked on top of each other.
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser;

    final userName =
        user?.name.isNotEmpty == true ? user!.name : 'Uday';

    return Container(
      color: background,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadStats,
          color: darkBlue,
          backgroundColor: Colors.white,

          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),

            padding: EdgeInsets.zero,

            children: [
              _buildTopHeader(userName),

              const SizedBox(height: 12),

              _buildGovernmentBanner(),

              const SizedBox(height: 18),

              _buildTodayStatus(),

              const SizedBox(height: 20),

              _buildQuickStatus(),

              const SizedBox(height: 20),

              _buildTodayOverview(),

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

  Widget _buildTopHeader(String userName) {
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
          // PROFILE CIRCLE
          Container(
            width: 55,
            height: 55,

            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.person_rounded,
              size: 34,
              color: darkBlue,
            ),
          ),

          const SizedBox(width: 13),

          // USER INFORMATION
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  _getGreeting(),

                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  userName,

                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 2),

                const Text(
                  'NGO / Institute',

                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // NOTIFICATION
          Stack(
            clipBehavior: Clip.none,

            children: [
              IconButton(
                onPressed: _showNotifications,

                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 31,
                ),
              ),

              Positioned(
                right: 5,
                top: 2,

                child: Container(
                  width: 19,
                  height: 19,

                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,

                    border: Border.all(
                      color: darkBlue,
                      width: 2,
                    ),
                  ),

                  child: const Center(
                    child: Text(
                      '2',

                      style: TextStyle(
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
        height: 82,

        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(10),

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

        child: Row(
          children: [
            // LEFT TEXT
            Expanded(
              flex: 6,

              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: const [
                  Text(
                    "Let's build a stronger,",

                    style: TextStyle(
                      color: navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  Text(
                    "more inclusive society",

                    style: TextStyle(
                      color: navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            // TRICOLOR LINES
            Expanded(
              flex: 4,

              child: Stack(
                alignment: Alignment.center,

                children: [
                  Positioned(
                    bottom: 11,
                    left: 0,
                    right: 0,

                    child: Container(
                      height: 4,

                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(10),

                        color:
                            const Color(0xFFFFC66D),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 6,
                    left: 18,
                    right: 4,

                    child: Container(
                      height: 4,

                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(10),

                        color:
                            const Color(0xFF54B96B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // RIGHT TEXT
            Expanded(
              flex: 4,

              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: const [
                  Text(
                    'Government',

                    textAlign:
                        TextAlign.center,

                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  Text(
                    'for a Brighter',

                    textAlign:
                        TextAlign.center,

                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  Text(
                    'Tomorrow',

                    textAlign:
                        TextAlign.center,

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
    );
  }

  // ============================================================
  // TODAY'S STATUS
  // ============================================================

  Widget _buildTodayStatus() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 18),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          _buildSectionTitle(
            'Today’s Status',
            showViewAll: true,
          ),

          const SizedBox(height: 4),

          const Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: Colors.grey,
              ),

              SizedBox(width: 4),

              Text(
                'Thu, 03 Sep 2026',

                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  icon: Icons.groups_rounded,
                  iconColor: green,
                  title: 'Attendance',
                  bottomText: 'Submitted',
                  bottomColor: green,
                  showCheck: true,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: _buildStatusCard(
                  icon: Icons.description_rounded,
                  iconColor: darkBlue,
                  title: 'Reports',
                  bottomText:
                      '${_reportsCount ?? 2} Submitted',
                  bottomColor: green,
                  showCheck: true,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: _buildStatusCard(
                  icon: Icons.videocam_rounded,
                  iconColor: orange,
                  title: 'Camera Feeds',
                  bottomText:
                      '${_feedsCount ?? 1} Online',
                  bottomColor: green,
                  showCheck: true,
                ),
              ),
            ],
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
    bool showCheck = false,
  }) {
    return Container(
      height: 108,

      padding: const EdgeInsets.symmetric(
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
            offset: const Offset(0, 2),
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
              fontWeight: FontWeight.w700,
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
                    fontWeight: FontWeight.w700,
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
          _buildSectionTitle('Quick Status'),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildQuickCard(
                  icon: Icons.groups_rounded,
                  title: 'Daily Attendance',

                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.ngoAttendance,
                    );
                  },
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _buildQuickCard(
                  icon: Icons.description_rounded,
                  title: 'Reports',

                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.ngoReports,
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildQuickCard(
                  icon: Icons.videocam_rounded,
                  title: 'Camera / Video',

                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.ngoCamera,
                    );
                  },
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _buildQuickCard(
                  icon: Icons.business_rounded,
                  title: 'Institute Profile',

                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.ngoProfile,
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildQuickCard(
                  icon: Icons.history,
                  title: 'Call History',

                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CallHistoryScreen(),
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
          height: 86,

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
                offset: const Offset(0, 2),
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

              Text(
                title,

                textAlign:
                    TextAlign.center,

                style: const TextStyle(
                  color: navy,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
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

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  icon: Icons.groups_rounded,
                  iconColor: green,
                  number: '45',
                  label: 'Beneficiaries\npresent',
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: _buildOverviewCard(
                  icon: Icons.badge_rounded,
                  iconColor: darkBlue,
                  number: '10',
                  label: 'Staff present',
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: _buildOverviewCard(
                  icon: Icons.description_rounded,
                  iconColor: darkBlue,
                  number:
                      '${_reportsCount ?? 2}',
                  label: 'Reports\nsubmitted',
                ),
              ),
            ],
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
      height: 105,

      padding: const EdgeInsets.fromLTRB(
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
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            icon,
            size: 22,
            color: iconColor,
          ),

          const SizedBox(height: 5),

          Text(
            number,

            style: const TextStyle(
              color: navy,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 1),

          Text(
            label,

            style: const TextStyle(
              color: Colors.grey,
              fontSize: 9,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
    String title, {
    bool showViewAll = false,
  }) {
    return Row(
      children: [
        Text(
          title,

          style: const TextStyle(
            color: navy,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),

        const Spacer(),

        if (showViewAll)
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(
                AppRoutes.ngoReports,
              );
            },

            child: const Text(
              'View all',

              style: TextStyle(
                color: Color(0xFF2A78B8),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}