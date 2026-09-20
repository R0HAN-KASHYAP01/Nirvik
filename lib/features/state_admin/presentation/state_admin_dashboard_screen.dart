import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/quick_action_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/summary_stat_card.dart';
import '../../../features/calls/presentation/call_history_screen.dart';
import '../../../features/calls/presentation/video_call_screen.dart';
import '../../../features/calls/presentation/widgets/incoming_call_listener.dart';
import '../../../features/projects/data/projects_repository.dart';
import '../../../features/projects/presentation/project_list_screen.dart';
import '../../../models/project.dart';
import '../../../models/user.dart';
import '../../../services/auth_service.dart';
import '../../../services/session_service.dart';
import '../../../services/video_call_service.dart';
import '../../../utils/call_permission.dart';
import '../../../utils/india_locations.dart';
import 'state_district_selection_screen.dart';

class StateAdminDashboardScreen extends StatefulWidget {
  const StateAdminDashboardScreen({super.key});

  @override
  State<StateAdminDashboardScreen> createState() =>
      _StateAdminDashboardScreenState();
}

class _StateAdminDashboardScreenState
    extends State<StateAdminDashboardScreen> {
  // ============================================================
  // BLUE-GREY GOVERNMENT THEME
  // ============================================================

  static const Color _background = Color(0xFFEAF2F8);
  static const Color _primaryBlue = Color(0xFF14568A);
  static const Color _textGrey = Color(0xFF667788);

  static const Color _red = Color(0xFFE63E4D);

  // ============================================================
  // NOTIFICATION STORAGE
  // ============================================================

  static const String _notificationStorageKey =
      'state_admin_notifications';

  final List<_StateAdminNotification> _notifications = [];

  final Set<String> _readNotificationIds = <String>{};

  // ============================================================
  // STATE MONITORING DATA (real ProjectsRepository — reused,
  // not duplicated)
  // ============================================================

  final ProjectsRepository _projectsRepository = ProjectsRepository();
  late Future<List<Project>> _projectsFuture;

  // Districts come from the existing India-locations dataset for the
  // admin's assigned state, used to find the right district admin to
  // call for a given district.
  String _selectedCallDistrict = 'All Districts';

  bool _startingCall = false;

  List<String> _districtsForCurrentUser() {
    // resolveStateName tolerates a state admin's profile having a
    // district name stored where the state name should be (a
    // registration-time data error) by resolving it to its real state,
    // instead of returning an empty district list for a typo'd value.
    final state = resolveStateName(SessionService.instance.currentUser?.state);
    return districtsForState(state);
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _projectsFuture = _projectsRepository.getProjects();
  }

  Future<void> _refreshProjects() async {
    setState(() {
      _projectsFuture = _projectsRepository.getProjects();
    });
    await _projectsFuture;
  }

  Future<void> _initializeNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final saved = prefs.getString(_notificationStorageKey);

      if (saved != null && saved.isNotEmpty) {
        final decoded = jsonDecode(saved);

        if (decoded is List) {
          _notifications.clear();

          for (final item in decoded) {
            if (item is Map) {
              _notifications.add(
                _StateAdminNotification.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              );
            }
          }
        }
      }

      final savedReadIds = prefs.getStringList(
        '${_notificationStorageKey}_read',
      );

      if (savedReadIds != null) {
        _readNotificationIds
          ..clear()
          ..addAll(savedReadIds);
      }
    } catch (_) {
      // Notification storage should never break dashboard.
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final encoded = _notifications
          .map((notification) => notification.toJson())
          .toList();

      await prefs.setString(
        _notificationStorageKey,
        jsonEncode(encoded),
      );

      await prefs.setStringList(
        '${_notificationStorageKey}_read',
        _readNotificationIds.toList(),
      );
    } catch (_) {}
  }

  // ============================================================
  // NOTIFICATION FILTERS
  // ============================================================

  List<_StateAdminNotification> get _last30DaysNotifications {
    final now = DateTime.now();

    final thirtyDaysAgo = now.subtract(
      const Duration(days: 30),
    );

    final list = _notifications.where((notification) {
      return !notification.createdAt.isBefore(thirtyDaysAgo);
    }).toList();

    list.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    return list;
  }

  List<_StateAdminNotification> get _todayNotifications {
    final now = DateTime.now();

    final last24Hours = now.subtract(
      const Duration(hours: 24),
    );

    final list = _notifications.where((notification) {
      return !notification.createdAt.isBefore(last24Hours);
    }).toList();

    list.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    return list;
  }

  List<_StateAdminNotification> get _unreadNotifications {
    return _last30DaysNotifications.where((notification) {
      return !_readNotificationIds.contains(notification.id);
    }).toList();
  }

  int get _todayCount => _todayNotifications.length;

  int get _unreadCount => _unreadNotifications.length;

  int get _allCount => _last30DaysNotifications.length;

  // ============================================================
  // MARK ONE READ
  // ============================================================

  Future<void> _markNotificationAsRead(String id) async {
    if (_readNotificationIds.contains(id)) {
      return;
    }

    setState(() {
      _readNotificationIds.add(id);
    });

    await _saveNotifications();
  }

  // ============================================================
  // MARK ALL READ
  // ============================================================

  Future<void> _markAllNotificationsAsRead() async {
    setState(() {
      for (final notification in _last30DaysNotifications) {
        _readNotificationIds.add(notification.id);
      }
    });

    await _saveNotifications();
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  void _openNotifications() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _StateAdminNotificationSheet(
          notifications: _notifications,
          readIds: _readNotificationIds,
          todayCount: _todayCount,
          unreadCount: _unreadCount,
          allCount: _allCount,
          onMarkRead: (id) async {
            await _markNotificationAsRead(id);

            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
              _openNotifications();
            }
          },
          onMarkAllRead: () async {
            await _markAllNotificationsAsRead();

            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
              _openNotifications();
            }
          },
        );
      },
    );
  }

  // ============================================================
  // PROFILE
  // ============================================================

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const StateAdminProfileScreen(),
      ),
    );
  }

  // ============================================================
  // PROJECTS / RISK NAVIGATION (reuses existing ProjectListScreen)
  // ============================================================

  void _openAllProjects() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProjectListScreen()),
    );
  }

  void _openHighRiskProjects() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProjectListScreen(
          initialHighRiskFilter: true,
        ),
      ),
    );
  }

  // ============================================================
  // MAP (reuses existing InstituteMapScreen)
  // ============================================================

  void _openMap() {
    Navigator.of(context).pushNamed(AppRoutes.instituteMap);
  }

  // ============================================================
  // REPORTS (District Performance — moved here from the dashboard
  // home; same district source and same _DistrictPerformanceList
  // widget, just relocated)
  // ============================================================

  void _openReports() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StateAdminReportsScreen(
          districts: _districtsForCurrentUser(),
        ),
      ),
    );
  }

  // ============================================================
  // SCHEMES (district -> category -> scheme -> institutes; district is
  // picked first so everything after it is already scoped — see
  // StateDistrictSelectionScreen)
  // ============================================================

  void _openSchemes() {
    final state = resolveStateName(SessionService.instance.currentUser?.state) ??
        (SessionService.instance.currentUser?.state?.trim().isNotEmpty == true
            ? SessionService.instance.currentUser!.state!.trim()
            : '');

    if (state.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your profile has no state set, so schemes cannot be shown.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StateDistrictSelectionScreen(
          adminState: state,
          districts: _districtsForCurrentUser(),
        ),
      ),
    );
  }

  // ============================================================
  // VIDEO CALL (reuses existing VideoCallService / CallPermission /
  // VideoCallScreen — no new call architecture)
  // ============================================================

  void _openCallHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CallHistoryScreen()),
    );
  }

  /// Looks up the district admin's profile id + name for a district.
  ///
  /// `district_administrators` (district, state, profile_id) and
  /// `profiles` (full_name) are the same two tables AuthService already
  /// reads when loading a district admin's own session — this mirrors
  /// that exact pattern for a lookup instead of a self-read.
  Future<Map<String, String>?> _lookupDistrictAdmin(
    String district,
    String state,
  ) async {
    final client = Supabase.instance.client;

    final row = await client
        .from('district_administrators')
        .select('profile_id')
        .eq('district', district)
        .eq('state', state)
        .maybeSingle();

    final profileId = row?['profile_id']?.toString();
    if (profileId == null) return null;

    final profile = await client
        .from('profiles')
        .select('full_name')
        .eq('id', profileId)
        .maybeSingle();

    final name = profile?['full_name']?.toString() ?? 'District Admin';

    return {'profileId': profileId, 'name': name};
  }

  Future<void> _callDistrictAdmin(String profileId, String name) async {
    if (_startingCall) return;

    final me = SessionService.instance.currentUser;
    if (me == null) return;

    final callType = CallPermission.callTypeFor(
      from: me.role,
      to: UserRole.districtAdmin,
    );

    if (callType == null) {
      _showComingSoon('Calling this role');
      return;
    }

    setState(() => _startingCall = true);

    try {
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      if (!statuses.values.every((s) => s.isGranted)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Camera and microphone permissions are required to '
              'make a call.',
            ),
          ),
        );
        return;
      }

      final call = await VideoCallService.instance.startCall(
        calleeId: profileId,
        callType: callType,
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            callId: call.id,
            channelId: call.channelId,
            currentUserId: me.id,
            currentUserName: me.name,
            isCaller: true,
            onCallEnded: () {
              VideoCallService.instance.end(call.id);
            },
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start the call. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _startingCall = false);
    }
  }

  // ============================================================
  // LOCATION
  // ============================================================

  String _locationLabel(AppUser? user) {
    if (user == null) {
      return 'State Level';
    }

    // Prefer the resolved canonical state name (handles a district name
    // mistakenly stored in `state`); fall back to the raw value rather
    // than hiding it if it doesn't match anything in the dataset.
    final resolved = resolveStateName(user.state);
    if (resolved != null) {
      return resolved;
    }

    final state = user.state?.trim();

    if (state != null && state.isNotEmpty) {
      return state;
    }

    return 'State Level';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser;

    final name = user?.name.trim().isNotEmpty == true
        ? user!.name
        : 'State Administrator';

    final location = _locationLabel(user);

    return IncomingCallListener(
      child: Scaffold(
      backgroundColor: _background,

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: _primaryBlue,
                backgroundColor: Colors.white,
                onRefresh: () async {
                  await Future.wait([
                    _initializeNotifications(),
                    _refreshProjects(),
                  ]);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    14,
                    12,
                    14,
                    24,
                  ),
                  children: [
                    // ==================================================
                    // HEADER
                    // ==================================================

                    _StateAdminHeader(
                      userName: name,
                      location: location,
                      unreadCount: _unreadCount,
                      onNotificationTap: _openNotifications,
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // WELCOME
                    // ==================================================

                    _WelcomeCard(
                      userName: name,
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // PROFILE SUMMARY
                    // ==================================================

                    _ProfileSummaryCard(
                      user: user,
                      onTap: _openProfile,
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // ASSIGNED STATE
                    // ==================================================

                    _AssignedStateCard(
                      state: location,
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // STATE OVERVIEW — Total Districts / Total Projects
                    // (SummaryStatCard reused; districts come from the
                    // existing India-locations dataset, projects from
                    // the existing ProjectsRepository)
                    // ==================================================

                    const SectionHeader(title: 'State Overview'),

                    const SizedBox(height: 9),

                    FutureBuilder<List<Project>>(
                      future: _projectsFuture,
                      builder: (context, snapshot) {
                        final projects = snapshot.data;
                        final totalProjects = projects?.length.toString() ??
                            (snapshot.connectionState ==
                                    ConnectionState.waiting
                                ? '…'
                                : '—');

                        return Row(
                          children: [
                            Expanded(
                              child: SummaryStatCard(
                                icon: Icons.map_outlined,
                                label: 'Total\nDistricts',
                                count: _districtsForCurrentUser()
                                    .length
                                    .toString(),
                                subtitle: location,
                                accentColor: _primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SummaryStatCard(
                                icon: Icons.domain_outlined,
                                label: 'Total\nProjects',
                                count: totalProjects,
                                subtitle: 'All districts',
                                accentColor: _primaryBlue,
                                onTap: _openAllProjects,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // HIGH-RISK PROJECTS (reuses Project.riskLevel +
                    // ProjectListScreen's existing high-risk filter —
                    // same source AnalyticsScreen already relies on)
                    // ==================================================

                    const SectionHeader(title: 'High-Risk Projects'),

                    const SizedBox(height: 9),

                    FutureBuilder<List<Project>>(
                      future: _projectsFuture,
                      builder: (context, snapshot) {
                        final projects = snapshot.data;
                        final highRiskCount = projects
                            ?.where((p) => p.riskLevel == RiskLevel.high)
                            .length
                            .toString();

                        return SummaryStatCard(
                          icon: Icons.warning_amber_outlined,
                          label: 'High-Risk Projects',
                          count: highRiskCount ??
                              (snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? '…'
                                  : '—'),
                          subtitle: 'Tap to view flagged projects',
                          accentColor: _red,
                          onTap: _openHighRiskProjects,
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // MAP FEATURES (reuses existing InstituteMapScreen)
                    // ==================================================

                    const SectionHeader(title: 'Map & Video Call'),

                    const SizedBox(height: 9),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: QuickActionCard(
                            icon: Icons.map_outlined,
                            label: 'Map Features',
                            onTap: _openMap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: QuickActionCard(
                            icon: Icons.call_outlined,
                            label: 'Call History',
                            onTap: _openCallHistory,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    _DistrictFilterDropdown(
                      label: 'Video call district filter',
                      districts: _districtsForCurrentUser(),
                      value: _selectedCallDistrict,
                      onChanged: (value) {
                        setState(() => _selectedCallDistrict = value);
                      },
                    ),

                    const SizedBox(height: 8),

                    if (_selectedCallDistrict == 'All Districts')
                      const Text(
                        'Select a district above to find its district '
                        'admin and start a call.',
                        style: TextStyle(fontSize: 11, color: _textGrey),
                      )
                    else
                      FutureBuilder<Map<String, String>?>(
                        future: _lookupDistrictAdmin(
                          _selectedCallDistrict,
                          location,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: LinearProgressIndicator(),
                            );
                          }

                          final target = snapshot.data;
                          if (target == null) {
                            return Text(
                              'No district admin found for '
                              '$_selectedCallDistrict.',
                              style: const TextStyle(
                                fontSize: 11,
                                color: _textGrey,
                              ),
                            );
                          }

                          return QuickActionCard(
                            icon: Icons.video_call_outlined,
                            label: _startingCall
                                ? 'Calling…'
                                : 'Call ${target['name']}',
                            onTap: _startingCall
                                ? () {}
                                : () => _callDistrictAdmin(
                                      target['profileId']!,
                                      target['name']!,
                                    ),
                          );
                        },
                      ),

                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            // ==========================================================
            // BOTTOM NAVIGATION
            // ==========================================================

            _StateAdminBottomNavigation(
              selectedIndex: 0,
              onHome: () {},
              onReports: _openReports,
              onSchemes: _openSchemes,
              onProfile: _openProfile,
            ),
          ],
        ),
      ),
      ),
    );
  }

  // ============================================================
  // COMING SOON
  // ============================================================

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature will open here.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ============================================================================
// HEADER
// ============================================================================

class _StateAdminHeader extends StatelessWidget {
  final String userName;
  final String location;
  final int unreadCount;
  final VoidCallback onNotificationTap;

  const _StateAdminHeader({
    required this.userName,
    required this.location,
    required this.unreadCount,
    required this.onNotificationTap,
  });

  static const Color navy = Color(0xFF123E68);
  static const Color textGrey = Color(0xFF8FA8BA);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        14,
        12,
        10,
        12,
      ),
      decoration: const BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.all(
          Radius.circular(17),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'State Administrator',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Government Portal • $location',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 9.5,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D9B68),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '●  APPROVED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onNotificationTap,
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 22,
                ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE63E4D),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: navy,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9
                            ? '9+'
                            : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
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
}

// ============================================================================
// WELCOME CARD
// ============================================================================

class _WelcomeCard extends StatelessWidget {
  final String userName;

  const _WelcomeCard({
    required this.userName,
  });

  static const Color navy = Color(0xFF123E68);
  static const Color border = Color(0xFFBFD2E0);
  static const Color textGrey = Color(0xFF667788);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        14,
        14,
        12,
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome Back,',
                  style: TextStyle(
                    color: navy,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  'State Administrator',
                  style: TextStyle(
                    color: navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Manage. Monitor. Build a Better State.',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 9.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hello, $userName',
                  style: const TextStyle(
                    color: navy,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFDCE9F2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: navy,
              size: 29,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PROFILE SUMMARY
// ============================================================================

class _ProfileSummaryCard extends StatelessWidget {
  final AppUser? user;
  final VoidCallback onTap;

  const _ProfileSummaryCard({
    required this.user,
    required this.onTap,
  });

  static const Color navy = Color(0xFF123E68);
  static const Color border = Color(0xFFBFD2E0);
  static const Color textGrey = Color(0xFF667788);
  static const Color green = Color(0xFF20A77A);

  @override
  Widget build(BuildContext context) {
    final name = user?.name.isNotEmpty == true
        ? user!.name
        : 'State Administrator';

    final email = user?.email.isNotEmpty == true
        ? user!.email
        : '—';

    final state = resolveStateName(user?.state) ??
        (user?.state?.isNotEmpty == true ? user!.state! : 'State level');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFDCEBFA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFF2776C7),
                size: 27,
              ),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 34,
                        child: Text(
                          'Name',
                          style: TextStyle(
                            color: textGrey,
                            fontSize: 8,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: navy,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const SizedBox(
                        width: 34,
                        child: Text(
                          'Email',
                          style: TextStyle(
                            color: textGrey,
                            fontSize: 8,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: navy,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              width: 1,
              height: 42,
              color: border,
            ),

            const SizedBox(width: 11),

            SizedBox(
              width: 108,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'State Administrator',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: navy,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$state level operations\nand oversight',
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 7.5,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1F5EC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '●  Approved',
                      style: TextStyle(
                        color: green,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                      ),
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
}

// ============================================================================
// ASSIGNED STATE
// ============================================================================

class _AssignedStateCard extends StatelessWidget {
  final String state;

  const _AssignedStateCard({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F1FF),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFC6DDF5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFD7E8FB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Color(0xFF1460A1),
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assigned State: $state',
                  style: const TextStyle(
                    color: Color(0xFF173F66),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Your profile is assigned to this state. '
                  'State-level features will use this scope.',
                  style: TextStyle(
                    color: Color(0xFF667788),
                    fontSize: 8,
                    height: 1.3,
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

// ============================================================================
// DISTRICT FILTER DROPDOWN
//
// Shared by the Total Projects and Video Call sections. Districts come
// from the existing India-locations dataset (utils/india_locations.dart)
// for the admin's assigned state — the same source used for "Total
// Districts" — so this never duplicates or invents a district list.
// ============================================================================

class _DistrictFilterDropdown extends StatelessWidget {
  final String label;
  final List<String> districts;
  final String value;
  final ValueChanged<String> onChanged;

  const _DistrictFilterDropdown({
    required this.label,
    required this.districts,
    required this.value,
    required this.onChanged,
  });

  static const Color _border = Color(0xFFBFD2E0);
  static const Color _textGrey = Color(0xFF667788);
  static const Color _navy = Color(0xFF123E68);

  @override
  Widget build(BuildContext context) {
    final options = ['All Districts', ...districts];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_alt_outlined,
            color: _navy,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 9.5, color: _textGrey),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isDense: true,
                    isExpanded: true,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _navy,
                    ),
                    items: [
                      for (final district in options)
                        DropdownMenuItem(
                          value: district,
                          child: Text(district),
                        ),
                    ],
                    onChanged: (selected) {
                      if (selected != null) onChanged(selected);
                    },
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

// ============================================================================
// DISTRICT PERFORMANCE LIST
//
// Districts are real (India-locations dataset for the admin's state).
// Per-district performance is honestly marked pending: no existing
// project/inspection record carries a district field to aggregate
// against, matching the same gap District Admin's own dashboard already
// discloses for its locked stats.
// ============================================================================

class _DistrictPerformanceList extends StatelessWidget {
  final List<String> districts;

  const _DistrictPerformanceList({required this.districts});

  static const Color _border = Color(0xFFBFD2E0);
  static const Color _navy = Color(0xFF123E68);
  static const Color _textGrey = Color(0xFF667788);

  @override
  Widget build(BuildContext context) {
    if (districts.isEmpty) {
      return const Text(
        'No districts found for the assigned state.',
        style: TextStyle(fontSize: 11, color: _textGrey),
      );
    }

    return Column(
      children: [
        for (final district in districts) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    district,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const StatusBadge(
                  label: 'Data pending',
                  color: _textGrey,
                ),
              ],
            ),
          ),
          if (district != districts.last) const SizedBox(height: 7),
        ],
      ],
    );
  }
}

// ============================================================================
// BOTTOM NAVIGATION
// ============================================================================

class _StateAdminBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback onHome;
  final VoidCallback onReports;
  final VoidCallback onSchemes;
  final VoidCallback onProfile;

  const _StateAdminBottomNavigation({
    required this.selectedIndex,
    required this.onHome,
    required this.onReports,
    required this.onSchemes,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _NavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: 'Home',
              selected: selectedIndex == 0,
              onTap: onHome,
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.bar_chart_outlined,
              selectedIcon: Icons.bar_chart_rounded,
              label: 'Reports',
              selected: selectedIndex == 1,
              onTap: onReports,
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.description_outlined,
              selectedIcon: Icons.description_rounded,
              label: 'Schemes',
              selected: selectedIndex == 2,
              onTap: onSchemes,
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              label: 'Profile',
              selected: selectedIndex == 3,
              onTap: onProfile,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                color: selected
                    ? const Color(0xFF14568A)
                    : const Color(0xFF667788),
                size: 19,
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE63E4D),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: selected
                  ? const Color(0xFF14568A)
                  : const Color(0xFF667788),
              fontSize: 7.5,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          if (selected)
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 20,
              height: 2,
              decoration: BoxDecoration(
                color: const Color(0xFF14568A),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// NOTIFICATION FILTER
// ============================================================================

enum _StateAdminNotificationFilter {
  today,
  unread,
  all,
}

// ============================================================================
// NOTIFICATION MODEL
// ============================================================================

class _StateAdminNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final IconData icon;
  final Color color;

  const _StateAdminNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory _StateAdminNotification.fromJson(
    Map<String, dynamic> json,
  ) {
    return _StateAdminNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(
            json['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      icon: Icons.notifications_rounded,
      color: const Color(0xFF14568A),
    );
  }
}

// ============================================================================
// NOTIFICATION SHEET
// ============================================================================

class _StateAdminNotificationSheet extends StatefulWidget {
  final List<_StateAdminNotification> notifications;
  final Set<String> readIds;

  final int todayCount;
  final int unreadCount;
  final int allCount;

  final Future<void> Function(String id) onMarkRead;
  final Future<void> Function() onMarkAllRead;

  const _StateAdminNotificationSheet({
    required this.notifications,
    required this.readIds,
    required this.todayCount,
    required this.unreadCount,
    required this.allCount,
    required this.onMarkRead,
    required this.onMarkAllRead,
  });

  @override
  State<_StateAdminNotificationSheet> createState() =>
      _StateAdminNotificationSheetState();
}

class _StateAdminNotificationSheetState
    extends State<_StateAdminNotificationSheet> {
  _StateAdminNotificationFilter _selectedFilter =
      _StateAdminNotificationFilter.today;

  static const Color background = Color(0xFFEAF2F8);
  static const Color navy = Color(0xFF123E68);
  static const Color primaryBlue = Color(0xFF14568A);
  static const Color border = Color(0xFFBFD2E0);
  static const Color textGrey = Color(0xFF667788);

  List<_StateAdminNotification> get _filteredNotifications {
    final now = DateTime.now();

    late final List<_StateAdminNotification> result;

    switch (_selectedFilter) {
      case _StateAdminNotificationFilter.today:
        final last24Hours = now.subtract(
          const Duration(hours: 24),
        );

        result = widget.notifications.where((notification) {
          return !notification.createdAt.isBefore(last24Hours);
        }).toList();

      case _StateAdminNotificationFilter.unread:
        final thirtyDaysAgo = now.subtract(
          const Duration(days: 30),
        );

        result = widget.notifications.where((notification) {
          return !notification.createdAt.isBefore(
                thirtyDaysAgo,
              ) &&
              !widget.readIds.contains(notification.id);
        }).toList();

      case _StateAdminNotificationFilter.all:
        final thirtyDaysAgo = now.subtract(
          const Duration(days: 30),
        );

        result = widget.notifications.where((notification) {
          return !notification.createdAt.isBefore(thirtyDaysAgo);
        }).toList();
    }

    result.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: background,
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
                color: border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                14,
                14,
                7,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        color: navy,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  if (widget.unreadCount > 0)
                    TextButton(
                      onPressed: widget.onMarkAllRead,
                      child: const Text(
                        'Mark all read',
                        style: TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: textGrey,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                14,
                2,
                14,
                9,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _NotificationFilterButton(
                      label: 'Today',
                      count: widget.todayCount,
                      icon: Icons.today_outlined,
                      selected:
                          _selectedFilter ==
                              _StateAdminNotificationFilter.today,
                      onTap: () {
                        setState(() {
                          _selectedFilter =
                              _StateAdminNotificationFilter.today;
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 7),

                  Expanded(
                    child: _NotificationFilterButton(
                      label: 'Unread',
                      count: widget.unreadCount,
                      icon: Icons.notifications_none_rounded,
                      selected:
                          _selectedFilter ==
                              _StateAdminNotificationFilter.unread,
                      onTap: () {
                        setState(() {
                          _selectedFilter =
                              _StateAdminNotificationFilter.unread;
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 7),

                  Expanded(
                    child: _NotificationFilterButton(
                      label: 'All',
                      count: widget.allCount,
                      icon: Icons.history_rounded,
                      selected:
                          _selectedFilter ==
                              _StateAdminNotificationFilter.all,
                      onTap: () {
                        setState(() {
                          _selectedFilter =
                              _StateAdminNotificationFilter.all;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                0,
                18,
                8,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _selectedFilter ==
                          _StateAdminNotificationFilter.today
                      ? 'Showing notifications from the last 24 hours'
                      : _selectedFilter ==
                              _StateAdminNotificationFilter.unread
                          ? 'Showing unread notifications from the last 30 days'
                          : 'Showing all notifications from the last 30 days',
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 10,
                  ),
                ),
              ),
            ),

            if (_filteredNotifications.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  35,
                  20,
                  55,
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFilter ==
                              _StateAdminNotificationFilter.today
                          ? Icons.today_outlined
                          : _selectedFilter ==
                                  _StateAdminNotificationFilter.unread
                              ? Icons.notifications_none_rounded
                              : Icons.history_toggle_off_rounded,
                      size: 52,
                      color: const Color(0xFF9EAFBC),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      _selectedFilter ==
                              _StateAdminNotificationFilter.today
                          ? 'No notifications today'
                          : _selectedFilter ==
                                  _StateAdminNotificationFilter.unread
                              ? 'No unread notifications'
                              : 'No notification history',
                      style: const TextStyle(
                        color: navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _selectedFilter ==
                              _StateAdminNotificationFilter.today
                          ? 'There are no notifications from the last 24 hours.'
                          : _selectedFilter ==
                                  _StateAdminNotificationFilter.unread
                              ? 'You are all caught up.'
                              : 'There are no notifications from the last 30 days.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: textGrey,
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
                    3,
                    14,
                    20,
                  ),
                  itemCount: _filteredNotifications.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final notification =
                        _filteredNotifications[index];

                    final isRead =
                        widget.readIds.contains(notification.id);

                    return _NotificationTile(
                      notification: notification,
                      isRead: isRead,
                      onTap: () async {
                        await widget.onMarkRead(
                          notification.id,
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
  }
}

// ============================================================================
// FILTER BUTTON
// ============================================================================

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
    const primaryBlue = Color(0xFF14568A);
    const navy = Color(0xFF123E68);
    const border = Color(0xFFBFD2E0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFD7E8F4)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? primaryBlue
                : border,
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected
                  ? primaryBlue
                  : const Color(0xFF667788),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? navy
                      : const Color(0xFF667788),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 3),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 1.5,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? primaryBlue
                    : const Color(0xFFE5EDF3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : const Color(0xFF667788),
                  fontSize: 7.5,
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

// ============================================================================
// NOTIFICATION TILE
// ============================================================================

class _NotificationTile extends StatelessWidget {
  final _StateAdminNotification notification;
  final bool isRead;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.isRead,
    required this.onTap,
  });

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0
        ? 12
        : dateTime.hour % 12;

    final minute = dateTime.minute
        .toString()
        .padLeft(2, '0');

    final period = dateTime.hour >= 12
        ? 'PM'
        : 'AM';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF123E68);
    const textGrey = Color(0xFF667788);
    const border = Color(0xFFBFD2E0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.white
              : const Color(0xFFF2F8FC),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isRead
                ? border
                : const Color(0xFF9FC5DF),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: notification.color.withValues(
                      alpha: 0.10,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notification.icon,
                    color: notification.color,
                    size: 19,
                  ),
                ),
                if (!isRead)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE63E4D),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 10,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    _formatDateTime(notification.createdAt),
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),

            if (!isRead)
              const Padding(
                padding: EdgeInsets.only(
                  left: 5,
                  top: 4,
                ),
                child: Text(
                  'NEW',
                  style: TextStyle(
                    color: Color(0xFFE63E4D),
                    fontSize: 7,
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

// ============================================================================
// REPORTS PAGE — District Performance
//
// Moved here from the dashboard home. Districts still come from the same
// source as before (StateAdminDashboardScreen._districtsForCurrentUser,
// backed by utils/india_locations.dart), and this reuses the exact same
// _DistrictPerformanceList widget already defined above — no new data,
// no duplicate district/status logic.
// ============================================================================

class StateAdminReportsScreen extends StatelessWidget {
  final List<String> districts;

  const StateAdminReportsScreen({
    super.key,
    required this.districts,
  });

  static const Color background = Color(0xFFEAF2F8);
  static const Color navy = Color(0xFF123E68);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
          ),
        ),
        title: const Text(
          'Reports',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
          children: [
            const SectionHeader(title: 'District Performance'),
            const SizedBox(height: 9),
            _DistrictPerformanceList(districts: districts),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PROFILE PAGE
// ============================================================================

class StateAdminProfileScreen extends StatelessWidget {
  const StateAdminProfileScreen({
    super.key,
  });

  static const Color background = Color(0xFFEAF2F8);
  static const Color navy = Color(0xFF123E68);
  static const Color textGrey = Color(0xFF667788);
  static const Color red = Color(0xFFE63E4D);
  static const Color green = Color(0xFF20A77A);

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.logout();

    SessionService.instance.clear();

    if (!context.mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser;

    final name = user?.name.isNotEmpty == true
        ? user!.name
        : 'State Administrator';

    final email = user?.email.isNotEmpty == true
        ? user!.email
        : '—';

    final state = resolveStateName(user?.state) ??
        (user?.state?.isNotEmpty == true ? user!.state! : 'State level');

    final status = user?.status.isNotEmpty == true
        ? user!.status
        : 'approved';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
          ),
        ),
        title: const Text(
          'Administrator Profile',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            30,
          ),
          children: [
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCEBFA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF2776C7),
                  size: 39,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Center(
              child: Text(
                name,
                style: const TextStyle(
                  color: navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(height: 3),

            Center(
              child: Text(
                email,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 10,
                ),
              ),
            ),

            const SizedBox(height: 22),

            _ProfileDetailRow(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Role',
              value: 'State Administrator',
            ),

            const SizedBox(height: 8),

            _ProfileDetailRow(
              icon: Icons.location_on_outlined,
              label: 'State',
              value: state,
            ),

            const SizedBox(height: 8),

            _ProfileDetailRow(
              icon: Icons.verified_outlined,
              label: 'Status',
              value: status,
              valueColor: green,
            ),

            const SizedBox(height: 22),

            InkWell(
              onTap: () => _logout(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFC8CC),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE4E6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: red,
                        size: 18,
                      ),
                    ),

                    const SizedBox(width: 10),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Log out',
                            style: TextStyle(
                              color: red,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Sign out from the State Administrator account',
                            style: TextStyle(
                              color: textGrey,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.chevron_right_rounded,
                      color: red,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PROFILE DETAIL ROW
// ============================================================================

class _ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8FC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFC9DCE8),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF14568A),
            size: 16,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF667788),
                fontSize: 9,
              ),
            ),
          ),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor ??
                    const Color(0xFF17324D),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}