import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../models/user.dart';
import '../../../services/auth_service.dart';
import '../../../services/session_service.dart';

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
  static const Color _card = Color(0xFFF8FBFD);
  static const Color _navy = Color(0xFF123E68);
  static const Color _primaryBlue = Color(0xFF14568A);
  static const Color _softBlue = Color(0xFFD7E5EE);
  static const Color _border = Color(0xFFBFD2E0);
  static const Color _textDark = Color(0xFF17324D);
  static const Color _textGrey = Color(0xFF667788);

  static const Color _green = Color(0xFF20A77A);
  static const Color _red = Color(0xFFE63E4D);
  static const Color _orange = Color(0xFFFF9D2E);
  static const Color _purple = Color(0xFF7256C7);

  // ============================================================
  // NOTIFICATION STORAGE
  // ============================================================

  static const String _notificationStorageKey =
      'state_admin_notifications';

  final List<_StateAdminNotification> _notifications = [];

  final Set<String> _readNotificationIds = <String>{};

  bool _notificationsLoaded = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
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
      setState(() {
        _notificationsLoaded = true;
      });
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
  // QUICK ACTIONS VIEW ALL
  // ============================================================

  void _openAllQuickActions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const StateAdminQuickActionsScreen(),
      ),
    );
  }

  // ============================================================
  // STATE MONITORING
  // ============================================================

  void _openDistrictOverview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const StateDistrictOverviewScreen(),
      ),
    );
  }

  void _openProjectMonitoring() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const StateProjectMonitoringScreen(),
      ),
    );
  }

  void _openInspectionMonitoring() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const StateInspectionMonitoringScreen(),
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    await AuthService.instance.logout();

    SessionService.instance.clear();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  // ============================================================
  // LOCATION
  // ============================================================

  String _locationLabel(AppUser? user) {
    if (user == null) {
      return 'State Level';
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

    return Scaffold(
      backgroundColor: _background,

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: _primaryBlue,
                backgroundColor: Colors.white,
                onRefresh: _initializeNotifications,
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
                      onProfileTap: _openProfile,
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
                    // QUICK ACTIONS
                    // ==================================================

                    _SectionHeader(
                      title: 'Quick Actions',
                      actionLabel: 'View All',
                      onActionTap: _openAllQuickActions,
                    ),

                    const SizedBox(height: 9),

                    _QuickActionsGrid(
                      onViewAll: _openAllQuickActions,
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
                    // STATE MONITORING
                    // ==================================================

                    _SectionHeader(
                      title: 'State Monitoring',
                    ),

                    const SizedBox(height: 8),

                    _StateMonitoringCard(
                      onDistrictTap: _openDistrictOverview,
                      onProjectTap: _openProjectMonitoring,
                      onInspectionTap: _openInspectionMonitoring,
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
              onReports: () {
                _showComingSoon('Reports');
              },
              onSchemes: () {
                _showComingSoon('Schemes');
              },
              onAlerts: _openNotifications,
              onProfile: _openProfile,
              unreadCount: _unreadCount,
            ),
          ],
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
  final VoidCallback onProfileTap;

  const _StateAdminHeader({
    required this.userName,
    required this.location,
    required this.unreadCount,
    required this.onNotificationTap,
    required this.onProfileTap,
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

          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
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

    final state = user?.state?.isNotEmpty == true
        ? user!.state!
        : 'State level';

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
// SECTION HEADER
// ============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  static const Color navy = Color(0xFF123E68);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: navy,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (actionLabel != null)
          InkWell(
            onTap: onActionTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
              child: Row(
                children: [
                  Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: Color(0xFF14568A),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF14568A),
                    size: 15,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// QUICK ACTIONS GRID
// ============================================================================

class _QuickActionsGrid extends StatelessWidget {
  final VoidCallback onViewAll;

  const _QuickActionsGrid({
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;

        final width = constraints.maxWidth;

        final columns = width >= 600 ? 4 : 2;

        final itemWidth =
            (width - spacing * (columns - 1)) / columns;

        final actions = [
          _QuickActionData(
            title: 'User Management',
            subtitle: 'Manage state-level users',
            icon: Icons.groups_rounded,
            color: const Color(0xFF2876D5),
            background: const Color(0xFFE7F0FF),
          ),
          _QuickActionData(
            title: 'Reports & Analytics',
            subtitle: 'View state reports and insights',
            icon: Icons.description_outlined,
            color: const Color(0xFF16895D),
            background: const Color(0xFFE5F6EF),
          ),
          _QuickActionData(
            title: 'State Overview',
            subtitle: 'Check schemes across districts',
            icon: Icons.location_on_rounded,
            color: const Color(0xFF7358D0),
            background: const Color(0xFFF0EBFF),
          ),
          _QuickActionData(
            title: 'Settings',
            subtitle: 'State & application settings',
            icon: Icons.settings_rounded,
            color: const Color(0xFFC77616),
            background: const Color(0xFFFFF0E1),
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final action in actions)
              SizedBox(
                width: itemWidth,
                child: _QuickActionTile(
                  data: action,
                  onTap: onViewAll,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuickActionData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color background;

  const _QuickActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.background,
  });
}

class _QuickActionTile extends StatelessWidget {
  final _QuickActionData data;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.data,
    required this.onTap,
  });

  static const Color navy = Color(0xFF123E68);
  static const Color border = Color(0xFFBFD2E0);
  static const Color textGrey = Color(0xFF667788);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        height: 126,
        padding: const EdgeInsets.fromLTRB(
          10,
          10,
          9,
          9,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                    color: data.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    data.icon,
                    color: data.color,
                    size: 17,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: data.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: data.color,
                    size: 14,
                  ),
                ),
              ],
            ),

            const Spacer(),

            Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: navy,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              data.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: textGrey,
                fontSize: 7.5,
                height: 1.25,
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
// STATE MONITORING
// ============================================================================

class _StateMonitoringCard extends StatelessWidget {
  final VoidCallback onDistrictTap;
  final VoidCallback onProjectTap;
  final VoidCallback onInspectionTap;

  const _StateMonitoringCard({
    required this.onDistrictTap,
    required this.onProjectTap,
    required this.onInspectionTap,
  });

  static const Color border = Color(0xFFBFD2E0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          _MonitoringRow(
            icon: Icons.apartment_rounded,
            title: 'District Overview',
            subtitle: 'State-wise district monitoring',
            onTap: onDistrictTap,
          ),
          const SizedBox(height: 7),
          _MonitoringRow(
            icon: Icons.domain_rounded,
            title: 'Project Monitoring',
            subtitle: 'Projects across districts',
            onTap: onProjectTap,
          ),
          const SizedBox(height: 7),
          _MonitoringRow(
            icon: Icons.fact_check_outlined,
            title: 'Inspection Monitoring',
            subtitle: 'Inspection compliance',
            onTap: onInspectionTap,
          ),
        ],
      ),
    );
  }
}

class _MonitoringRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MonitoringRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8FB),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: const Color(0xFFD7E3EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFE1EDF6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFF14568A),
                size: 17,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF17324D),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF667788),
                      fontSize: 7.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF14568A),
              size: 17,
            ),
          ],
        ),
      ),
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
  final VoidCallback onAlerts;
  final VoidCallback onProfile;
  final int unreadCount;

  const _StateAdminBottomNavigation({
    required this.selectedIndex,
    required this.onHome,
    required this.onReports,
    required this.onSchemes,
    required this.onAlerts,
    required this.onProfile,
    required this.unreadCount,
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
              icon: Icons.notifications_none_outlined,
              selectedIcon: Icons.notifications_rounded,
              label: 'Alerts',
              selected: selectedIndex == 3,
              onTap: onAlerts,
              badgeCount: unreadCount,
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              label: 'Profile',
              selected: selectedIndex == 4,
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
                  separatorBuilder: (_, __) =>
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

    final state = user?.state?.isNotEmpty == true
        ? user!.state!
        : 'State level';

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

// ============================================================================
// QUICK ACTIONS FULL PAGE
// ============================================================================

class StateAdminQuickActionsScreen extends StatelessWidget {
  const StateAdminQuickActionsScreen({
    super.key,
  });

  static const Color background = Color(0xFFEAF2F8);
  static const Color navy = Color(0xFF123E68);

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionData(
        title: 'User Management',
        subtitle: 'Manage state-level users',
        icon: Icons.groups_rounded,
        color: const Color(0xFF2876D5),
        background: const Color(0xFFE7F0FF),
      ),
      _QuickActionData(
        title: 'Reports & Analytics',
        subtitle: 'View state reports and insights',
        icon: Icons.description_outlined,
        color: const Color(0xFF16895D),
        background: const Color(0xFFE5F6EF),
      ),
      _QuickActionData(
        title: 'State Overview',
        subtitle: 'Check schemes across districts',
        icon: Icons.location_on_rounded,
        color: const Color(0xFF7358D0),
        background: const Color(0xFFF0EBFF),
      ),
      _QuickActionData(
        title: 'Settings',
        subtitle: 'State & application settings',
        icon: Icons.settings_rounded,
        color: const Color(0xFFC77616),
        background: const Color(0xFFFFF0E1),
      ),
      _QuickActionData(
        title: 'Compliance',
        subtitle: 'Track compliance and approvals',
        icon: Icons.shield_outlined,
        color: const Color(0xFF16879A),
        background: const Color(0xFFE4F6F8),
      ),
      _QuickActionData(
        title: 'Notifications',
        subtitle: 'View latest updates and alerts',
        icon: Icons.notifications_rounded,
        color: const Color(0xFFE63E4D),
        background: const Color(0xFFFFE7EA),
      ),
    ];

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
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          14,
          16,
          14,
          28,
        ),
        children: [
          const Text(
            'All Actions',
            style: TextStyle(
              color: navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'State-level administrative tools and modules.',
            style: TextStyle(
              color: Color(0xFF667788),
              fontSize: 10,
            ),
          ),

          const SizedBox(height: 14),

          for (final action in actions) ...[
            _FullQuickActionTile(
              data: action,
            ),
            const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// FULL QUICK ACTION TILE
// ============================================================================

class _FullQuickActionTile extends StatelessWidget {
  final _QuickActionData data;

  const _FullQuickActionTile({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${data.title} will open here.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: const Color(0xFFBFD2E0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: data.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                data.icon,
                color: data.color,
                size: 20,
              ),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      color: Color(0xFF123E68),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF667788),
                      fontSize: 8.5,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                color: data.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: data.color,
                size: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// STATE DISTRICT OVERVIEW PAGE
// ============================================================================

class StateDistrictOverviewScreen extends StatelessWidget {
  const StateDistrictOverviewScreen({
    super.key,
  });

  static const Color background = Color(0xFFEAF2F8);
  static const Color navy = Color(0xFF123E68);
  static const Color blue = Color(0xFF14568A);
  static const Color border = Color(0xFFBFD2E0);
  static const Color grey = Color(0xFF667788);

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser;

    final state = user?.state?.trim().isNotEmpty == true
        ? user!.state!
        : 'State Level';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
          ),
        ),
        title: const Text(
          'District Overview',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          14,
          16,
          14,
          28,
        ),
        children: [
          _MonitoringPageHeader(
            icon: Icons.apartment_rounded,
            title: 'District Overview',
            subtitle:
                'State-level view of district performance and monitoring.',
          ),

          const SizedBox(height: 12),

          _AssignedScopeCard(
            state: state,
            title: 'Monitoring Scope',
            subtitle:
                'Only districts belonging to the assigned state should appear here.',
          ),

          const SizedBox(height: 14),

          const _MonitoringSectionTitle(
            title: 'District Summary',
          ),

          const SizedBox(height: 8),

          Row(
            children: const [
              Expanded(
                child: _MetricCard(
                  icon: Icons.apartment_rounded,
                  title: 'Total Districts',
                  value: '—',
                  color: Color(0xFF2876D5),
                  background: Color(0xFFE7F0FF),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  icon: Icons.domain_rounded,
                  title: 'Projects',
                  value: '—',
                  color: Color(0xFF16895D),
                  background: Color(0xFFE5F6EF),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: const [
              Expanded(
                child: _MetricCard(
                  icon: Icons.fact_check_outlined,
                  title: 'Inspections',
                  value: '—',
                  color: Color(0xFF7358D0),
                  background: Color(0xFFF0EBFF),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  icon: Icons.warning_amber_rounded,
                  title: 'High Risk',
                  value: '—',
                  color: Color(0xFFE63E4D),
                  background: Color(0xFFFFE7EA),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const _MonitoringSectionTitle(
            title: 'District Performance',
          ),

          const SizedBox(height: 8),

          _UnavailableDataCard(
            icon: Icons.bar_chart_rounded,
            title: 'District-wise data is not available yet',
            message:
                'The current database does not expose a reliable district field on institute/project records. District-wise numbers should be connected after the backend adds the state/district mapping.',
          ),

          const SizedBox(height: 16),

          const _MonitoringSectionTitle(
            title: 'District List',
          ),

          const SizedBox(height: 8),

          _UnavailableDataCard(
            icon: Icons.location_city_rounded,
            title: 'District list needs backend mapping',
            message:
                'Once the district relationship is available, this section can show District → Projects → Inspections → Risk drill-down.',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STATE PROJECT MONITORING PAGE
// ============================================================================

class StateProjectMonitoringScreen extends StatelessWidget {
  const StateProjectMonitoringScreen({
    super.key,
  });

  static const Color background = Color(0xFFEAF2F8);
  static const Color navy = Color(0xFF123E68);

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser;

    final state = user?.state?.trim().isNotEmpty == true
        ? user!.state!
        : 'State Level';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
          ),
        ),
        title: const Text(
          'Project Monitoring',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          14,
          16,
          14,
          28,
        ),
        children: [
          _MonitoringPageHeader(
            icon: Icons.domain_rounded,
            title: 'Project Monitoring',
            subtitle:
                'Monitor projects within the assigned state scope.',
          ),

          const SizedBox(height: 12),

          _AssignedScopeCard(
            state: state,
            title: 'Project Scope',
            subtitle:
                'Project counts and risk should be restricted to the assigned state.',
          ),

          const SizedBox(height: 14),

          const _MonitoringSectionTitle(
            title: 'Project Summary',
          ),

          const SizedBox(height: 8),

          Row(
            children: const [
              Expanded(
                child: _MetricCard(
                  icon: Icons.domain_rounded,
                  title: 'Total Projects',
                  value: '—',
                  color: Color(0xFF2876D5),
                  background: Color(0xFFE7F0FF),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  icon: Icons.warning_amber_rounded,
                  title: 'High Risk',
                  value: '—',
                  color: Color(0xFFE63E4D),
                  background: Color(0xFFFFE7EA),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: const [
              Expanded(
                child: _MetricCard(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Active',
                  value: '—',
                  color: Color(0xFF16895D),
                  background: Color(0xFFE5F6EF),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  icon: Icons.pending_actions_rounded,
                  title: 'Under Review',
                  value: '—',
                  color: Color(0xFFC77616),
                  background: Color(0xFFFFF0E1),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const _MonitoringSectionTitle(
            title: 'District Filter',
          ),

          const SizedBox(height: 8),

          _DisabledDistrictFilter(),

          const SizedBox(height: 16),

          const _MonitoringSectionTitle(
            title: 'Project List',
          ),

          const SizedBox(height: 8),

          _UnavailableDataCard(
            icon: Icons.domain_rounded,
            title: 'State-wise project list is not connected',
            message:
                'ProjectsRepository currently reads project records nationally. It does not yet apply state/district filtering, so showing those records here would risk exposing projects outside the administrator’s assigned state.',
          ),

          const SizedBox(height: 12),

          _InfoActionCard(
            icon: Icons.security_rounded,
            title: 'State-level security',
            message:
                'Backend/RLS filtering should be added before real state-wise project data is displayed.',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STATE INSPECTION MONITORING PAGE
// ============================================================================

class StateInspectionMonitoringScreen extends StatelessWidget {
  const StateInspectionMonitoringScreen({
    super.key,
  });

  static const Color background = Color(0xFFEAF2F8);
  static const Color navy = Color(0xFF123E68);

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser;

    final state = user?.state?.trim().isNotEmpty == true
        ? user!.state!
        : 'State Level';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
          ),
        ),
        title: const Text(
          'Inspection Monitoring',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          14,
          16,
          14,
          28,
        ),
        children: [
          _MonitoringPageHeader(
            icon: Icons.fact_check_outlined,
            title: 'Inspection Monitoring',
            subtitle:
                'Track inspection progress and compliance at state level.',
          ),

          const SizedBox(height: 12),

          _AssignedScopeCard(
            state: state,
            title: 'Inspection Scope',
            subtitle:
                'Inspection metrics should only represent the assigned state.',
          ),

          const SizedBox(height: 14),

          const _MonitoringSectionTitle(
            title: 'Inspection Summary',
          ),

          const SizedBox(height: 8),

          Row(
            children: const [
              Expanded(
                child: _MetricCard(
                  icon: Icons.fact_check_outlined,
                  title: 'Total',
                  value: '—',
                  color: Color(0xFF2876D5),
                  background: Color(0xFFE7F0FF),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Completed',
                  value: '—',
                  color: Color(0xFF16895D),
                  background: Color(0xFFE5F6EF),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: const [
              Expanded(
                child: _MetricCard(
                  icon: Icons.play_circle_outline_rounded,
                  title: 'In Progress',
                  value: '—',
                  color: Color(0xFF7358D0),
                  background: Color(0xFFF0EBFF),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  icon: Icons.pending_actions_rounded,
                  title: 'Pending',
                  value: '—',
                  color: Color(0xFFC77616),
                  background: Color(0xFFFFF0E1),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: const [
              Expanded(
                child: _MetricCard(
                  icon: Icons.schedule_rounded,
                  title: 'Overdue',
                  value: '—',
                  color: Color(0xFFE63E4D),
                  background: Color(0xFFFFE7EA),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  icon: Icons.rate_review_outlined,
                  title: 'Under Review',
                  value: '—',
                  color: Color(0xFF16879A),
                  background: Color(0xFFE4F6F8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const _MonitoringSectionTitle(
            title: 'District Filter',
          ),

          const SizedBox(height: 8),

          _DisabledDistrictFilter(),

          const SizedBox(height: 16),

          const _MonitoringSectionTitle(
            title: 'Inspection Status',
          ),

          const SizedBox(height: 8),

          _InspectionStatusList(),

          const SizedBox(height: 14),

          _UnavailableDataCard(
            icon: Icons.security_rounded,
            title: 'State-wise inspection data is not connected',
            message:
                'The existing inspection tables contain assignment/status information, but the current repository does not safely scope those records by the State Administrator’s assigned state.',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MONITORING PAGE HEADER
// ============================================================================

class _MonitoringPageHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _MonitoringPageHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFBFD2E0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Color(0xFFE1EDF6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF14568A),
              size: 23,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF123E68),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF667788),
                    fontSize: 9,
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
// ASSIGNED SCOPE CARD
// ============================================================================

class _AssignedScopeCard extends StatelessWidget {
  final String state;
  final String title;
  final String subtitle;

  const _AssignedScopeCard({
    required this.state,
    required this.title,
    required this.subtitle,
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
          const Icon(
            Icons.verified_user_rounded,
            color: Color(0xFF1460A1),
            size: 23,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF173F66),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Assigned state: $state',
                  style: const TextStyle(
                    color: Color(0xFF14568A),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
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
// MONITORING SECTION TITLE
// ============================================================================

class _MonitoringSectionTitle extends StatelessWidget {
  final String title;

  const _MonitoringSectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF123E68),
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

// ============================================================================
// METRIC CARD
// ============================================================================

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Color background;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFBFD2E0),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 17,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF123E68),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF667788),
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// UNAVAILABLE DATA CARD
// ============================================================================

class _UnavailableDataCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _UnavailableDataCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFBFD2E0),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF2F8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF14568A),
              size: 19,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF123E68),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF667788),
                    fontSize: 8.5,
                    height: 1.4,
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
// INFO ACTION CARD
// ============================================================================

class _InfoActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InfoActionCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC9DCE8),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF14568A),
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF123E68),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
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
// DISTRICT FILTER
// ============================================================================

class _DisabledDistrictFilter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFBFD2E0),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_alt_outlined,
            color: Color(0xFF14568A),
            size: 19,
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'All Districts',
              style: TextStyle(
                color: Color(0xFF17324D),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Awaiting district mapping',
              style: TextStyle(
                color: Color(0xFF667788),
                fontSize: 7,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// INSPECTION STATUS LIST
// ============================================================================

class _InspectionStatusList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final statuses = [
      (
        'Completed',
        Icons.check_circle_outline_rounded,
        const Color(0xFF16895D),
        const Color(0xFFE5F6EF),
      ),
      (
        'In Progress',
        Icons.play_circle_outline_rounded,
        const Color(0xFF7358D0),
        const Color(0xFFF0EBFF),
      ),
      (
        'Pending',
        Icons.pending_actions_rounded,
        const Color(0xFFC77616),
        const Color(0xFFFFF0E1),
      ),
      (
        'Overdue',
        Icons.schedule_rounded,
        const Color(0xFFE63E4D),
        const Color(0xFFFFE7EA),
      ),
    ];

    return Column(
      children: [
        for (final status in statuses) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: const Color(0xFFBFD2E0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: status.$4,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    status.$2,
                    color: status.$3,
                    size: 17,
                  ),
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Text(
                    status.$1,
                    style: const TextStyle(
                      color: Color(0xFF17324D),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const Text(
                  '—',
                  style: TextStyle(
                    color: Color(0xFF123E68),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (status != statuses.last)
            const SizedBox(height: 7),
        ],
      ],
    );
  }
}