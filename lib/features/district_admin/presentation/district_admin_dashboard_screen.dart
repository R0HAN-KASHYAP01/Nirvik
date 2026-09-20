// lib/features/district_admin/presentation/district_admin_dashboard_screen.dart
//
// District Administrator HOME tab (hosted by DistrictAdminShellScreen).
//
// District Overview: live counts from district_dashboard_stats(), scoped
// server-side to this admin's own district + state via institute_reps
// (see supabase/district_admin_dashboard_stats.sql).
//
// Quick Actions: District Map and Call History side by side. Institutes,
// Inspectors and Profile are bottom-navigation tabs in the shell, and Log out
// lives on the Profile tab.
//
// Notifications: the bell shares the same `notifications` table/service used
// elsewhere in the app (keyed by profile_id, not role-specific).
//
// Incoming calls: handled by the shell (IncomingCallListener), so this screen
// does not wrap itself.

import 'package:flutter/material.dart';

import '../../../models/district_dashboard_stats.dart';
import '../../../services/ngo_notification_service.dart';
import '../../../services/session_service.dart';
import '../../calls/presentation/call_history_screen.dart';
import '../../ngo/presentation/ngo_notifications_screen.dart';
import '../data/district_inspector_repository.dart';
import 'district_admin_theme.dart';
import 'district_institute_map_screen.dart';

class DistrictAdminDashboardScreen extends StatefulWidget {
  const DistrictAdminDashboardScreen({super.key, this.refreshSignal});

  /// Optional: when this notifies, the counts reload quietly (the shell uses
  /// it when the user returns to the Home tab).
  final Listenable? refreshSignal;

  @override
  State<DistrictAdminDashboardScreen> createState() =>
      _DistrictAdminDashboardScreenState();
}

class _DistrictAdminDashboardScreenState
    extends State<DistrictAdminDashboardScreen> {
  final DistrictInspectorRepository _repository =
      DistrictInspectorRepository();

  bool _loadingStats = true;
  DistrictDashboardStats _stats = DistrictDashboardStats.empty;
  String? _statsError;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    widget.refreshSignal?.addListener(_onRefreshSignal);
    _loadStats();
    _loadUnread();
  }

  @override
  void didUpdateWidget(covariant DistrictAdminDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      oldWidget.refreshSignal?.removeListener(_onRefreshSignal);
      widget.refreshSignal?.addListener(_onRefreshSignal);
    }
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_onRefreshSignal);
    super.dispose();
  }

  void _onRefreshSignal() {
    _loadStats(silent: true);
    _loadUnread();
  }

  Future<void> _loadStats({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loadingStats = true;
        _statsError = null;
      });
    }
    try {
      final stats = await _repository.fetchDashboardStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loadingStats = false;
        _statsError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _statsError = error.toString();
        _loadingStats = false;
      });
    }
  }

  Future<void> _loadUnread() async {
    final user = SessionService.instance.currentUser;
    if (user == null) return;
    try {
      final count =
          await NgoNotificationService.instance.fetchUnreadCount(user.id);
      if (!mounted) return;
      setState(() => _unreadNotifications = count);
    } catch (_) {
      // The badge is optional; ignore failures.
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadStats(), _loadUnread()]);
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NgoNotificationsScreen()),
    );
    if (mounted) _loadUnread();
  }

  void _openCallHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CallHistoryScreen()),
    );
  }

  void _openMap() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DistrictInstituteMapScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser;

    final locationParts = <String>[];
    if (user != null) {
      final district = user.district?.trim();
      final state = user.state?.trim();
      if (district != null && district.isNotEmpty) locationParts.add(district);
      if (state != null && state.isNotEmpty) locationParts.add(state);
    }
    final locationLabel = locationParts.join(', ');

    final cards = <_StatSpec>[
      _StatSpec(
        icon: Icons.apartment_outlined,
        label: 'Total Projects',
        count: _stats.totalProjects,
        tone: _Tone.blue,
      ),
      _StatSpec(
        icon: Icons.warning_amber_outlined,
        label: 'High-Risk Projects',
        count: _stats.highRiskProjects,
        tone: _Tone.red,
      ),
      _StatSpec(
        icon: Icons.fact_check_outlined,
        label: 'All Inspections',
        count: _stats.totalInspections,
        tone: _Tone.info,
      ),
      _StatSpec(
        icon: Icons.pending_actions_outlined,
        label: 'Pending Inspections',
        count: _stats.pendingInspections,
        tone: _Tone.amber,
      ),
      _StatSpec(
        icon: Icons.task_alt_outlined,
        label: 'Completed Inspections',
        count: _stats.completedInspections,
        tone: _Tone.green,
      ),
      _StatSpec(
        icon: Icons.groups_outlined,
        label: 'Assigned Inspectors',
        count: _stats.assignedInspectors,
        tone: _Tone.purple,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: DistrictColors.backgroundGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _refreshAll,
            color: DistrictColors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              children: [
                _HomeHeader(
                  name: user?.name ?? 'District Admin',
                  location: locationLabel,
                  unread: _unreadNotifications,
                  onBellTap: _openNotifications,
                ),
                const SizedBox(height: 16),

                if (_statsError != null) ...[
                  _ErrorBanner(message: _statsError!, onRetry: _loadStats),
                  const SizedBox(height: 16),
                ],

                // ========================================================
                // DISTRICT OVERVIEW — live, district-scoped counts
                // ========================================================
                const _SectionTitle('District Overview'),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final columns = width < 340 ? 2 : 3;
                    const spacing = 8.0;
                    final cardWidth =
                        (width - (spacing * (columns - 1))) / columns;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final card in cards)
                          SizedBox(
                            width: cardWidth,
                            height: 126,
                            child: _StatTile(
                              spec: card,
                              loading: _loadingStats,
                            ),
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 22),

                // ========================================================
                // QUICK ACTIONS — map and call history, side by side
                // ========================================================
                const _SectionTitle('Quick Actions'),
                const SizedBox(height: 10),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _QuickActionTile(
                          icon: Icons.map_outlined,
                          label: 'District Map',
                          subtitle: 'Institutes on the map',
                          onTap: _openMap,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickActionTile(
                          icon: Icons.call_outlined,
                          label: 'Call History',
                          subtitle: 'Recent video calls',
                          onTap: _openCallHistory,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'To start a video call, open an inspector from the '
                  'Inspectors tab and tap Start Video Call. Incoming calls '
                  'ring on every tab.',
                  style: TextStyle(
                    fontSize: 11,
                    color: DistrictColors.textSecondary,
                    height: 1.35,
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

// ============================================================================
// HEADER
// ============================================================================

class _HomeHeader extends StatelessWidget {
  final String name;
  final String location;
  final int unread;
  final VoidCallback onBellTap;

  const _HomeHeader({
    required this.name,
    required this.location,
    required this.unread,
    required this.onBellTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
      decoration: BoxDecoration(
        gradient: DistrictColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: DistrictColors.primary.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'District Administrator',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 13, color: Colors.white70),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: onBellTap,
              ),
              if (unread > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: DistrictColors.danger,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
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
      ),
    );
  }
}

// ============================================================================
// SECTION TITLE / ERROR
// ============================================================================

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: DistrictColors.textPrimary,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF7F7), Color(0xFFFDE5E5)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF2BDBD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline,
              size: 18, color: DistrictColors.dangerDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 11.5, color: DistrictColors.dangerDark),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ============================================================================
// STAT TILES — very light tinted gradients, one tone per meaning
// ============================================================================

enum _Tone { blue, info, red, amber, green, purple }

class _ToneStyle {
  final List<Color> gradient;
  final Color border;
  final Color icon;
  final Color count;

  const _ToneStyle({
    required this.gradient,
    required this.border,
    required this.icon,
    required this.count,
  });
}

const Map<_Tone, _ToneStyle> _toneStyles = {
  _Tone.blue: _ToneStyle(
    gradient: [Color(0xFFF1F8FF), Color(0xFFE5F1FF)],
    border: DistrictColors.borderMedium,
    icon: DistrictColors.primary,
    count: DistrictColors.primary,
  ),
  _Tone.info: _ToneStyle(
    gradient: [Color(0xFFF1F8FF), Color(0xFFE5F1FF)],
    border: DistrictColors.borderMedium,
    icon: DistrictColors.info,
    count: DistrictColors.textPrimary,
  ),
  _Tone.red: _ToneStyle(
    gradient: [Color(0xFFFFF7F7), Color(0xFFFDE5E5)],
    border: Color(0xFFF2BDBD),
    icon: DistrictColors.danger,
    count: DistrictColors.dangerDark,
  ),
  _Tone.amber: _ToneStyle(
    gradient: [Color(0xFFFFFBF2), Color(0xFFFFF0D0)],
    border: Color(0xFFF2D69A),
    icon: DistrictColors.warning,
    count: DistrictColors.warningDark,
  ),
  _Tone.green: _ToneStyle(
    gradient: [Color(0xFFF1FFF6), Color(0xFFDDF6E7)],
    border: Color(0xFFBFE8CF),
    icon: DistrictColors.success,
    count: DistrictColors.successDark,
  ),
  _Tone.purple: _ToneStyle(
    gradient: [Color(0xFFF8F6FF), Color(0xFFE9E5FC)],
    border: Color(0xFFD9D2F7),
    icon: DistrictColors.purple,
    count: DistrictColors.purple,
  ),
};

class _StatSpec {
  final IconData icon;
  final String label;
  final int count;
  final _Tone tone;

  const _StatSpec({
    required this.icon,
    required this.label,
    required this.count,
    required this.tone,
  });
}

class _StatTile extends StatelessWidget {
  final _StatSpec spec;
  final bool loading;

  const _StatTile({required this.spec, required this.loading});

  @override
  Widget build(BuildContext context) {
    final style = _toneStyles[spec.tone]!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.gradient,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              shape: BoxShape.circle,
            ),
            child: Icon(spec.icon, size: 18, color: style.icon),
          ),
          const Spacer(),
          Text(
            loading ? '—' : '${spec.count}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: loading ? DistrictColors.textMuted : style.count,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            spec.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.2,
              color: DistrictColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// QUICK ACTION TILE
// ============================================================================

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: DistrictColors.cardDecoration(),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: DistrictColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: DistrictColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DistrictColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: DistrictColors.textSecondary,
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