// FILE: lib/features/district_admin/presentation/district_admin_dashboard_screen.dart
//
// District Administrator dashboard.
//
// District Overview: live counts from district_dashboard_stats(), scoped
// server-side to this admin's own district + state via institute_reps
// (see supabase/district_admin_dashboard_stats.sql).
//
// Institutes: opens InstituteCategoryScreen (category -> scheme ->
// institutes), scoped to the admin's district + state by RLS.
//
// Inspectors: DistrictInspectorsScreen lists approved inspectors in the
// admin's district + state via RPC.
//
// District Map: DistrictInstituteMapScreen filters the shared InstituteMap
// widget to this district's institutes only.
//
// Notifications: shares the same `notifications` table/service used
// elsewhere in the app (keyed by profile_id, not role-specific).

import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/dashboard_header.dart';
import '../../../core/widgets/profile_placeholder_screen.dart';
import '../../../core/widgets/quick_action_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/summary_stat_card.dart';
import '../../../models/district_dashboard_stats.dart';
import '../../../services/auth_service.dart';
import '../../../services/session_service.dart';
import '../../calls/presentation/call_history_screen.dart';
import '../../calls/presentation/widgets/incoming_call_listener.dart';
import '../../ngo/presentation/ngo_notifications_screen.dart';
import '../data/district_inspector_repository.dart';
import 'district_inspectors_screen.dart';
import 'district_institute_map_screen.dart';

class DistrictAdminDashboardScreen extends StatefulWidget {
  const DistrictAdminDashboardScreen({super.key});

  @override
  State<DistrictAdminDashboardScreen> createState() =>
      _DistrictAdminDashboardScreenState();
}

class _DistrictAdminDashboardScreenState
    extends State<DistrictAdminDashboardScreen> {
  static const Color _background = Color(0xFFEAF2F8);
  static const Color _border = Color(0xFFD1DEE7);
  static const Color _textGrey = Color(0xFF667788);
  static const Color _errorColor = Color(0xFFC0392B);

  final DistrictInspectorRepository _repository =
  DistrictInspectorRepository();

  bool _loadingStats = true;
  DistrictDashboardStats _stats = DistrictDashboardStats.empty;
  String? _statsError;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loadingStats = true;
      _statsError = null;
    });
    try {
      final stats = await _repository.fetchDashboardStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loadingStats = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _statsError = error.toString();
        _loadingStats = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.logout();
    SessionService.instance.clear();
    if (!context.mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  void _openNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NgoNotificationsScreen()),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfilePlaceholderScreen()),
    );
  }

  void _openCallHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CallHistoryScreen()),
    );
  }

  void _openInstitutes(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.districtInstitutes);
  }

  void _openInspectors(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DistrictInspectorsScreen()),
    );
  }

  void _openMap(BuildContext context) {
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
      if (district != null && district.isNotEmpty) {
        locationParts.add(district);
      }
      if (state != null && state.isNotEmpty) {
        locationParts.add(state);
      }
    }
    final locationLabel = locationParts.join(', ');

    return IncomingCallListener(
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadStats,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              children: [
                DashboardHeader(
                  greeting: locationLabel.isEmpty
                      ? 'District Administrator'
                      : 'District Administrator · $locationLabel',
                  userName: user?.name ?? 'District Admin',
                  onNotificationTap: () => _openNotifications(context),
                  onLogoutTap: () => _logout(context),
                ),

                const SizedBox(height: 14),

                if (_statsError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 18, color: _errorColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statsError!,
                            style:
                            const TextStyle(fontSize: 11.5, color: _errorColor),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadStats,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ==========================================================
                // DISTRICT OVERVIEW — live, district-scoped counts
                // ==========================================================
                const SectionHeader(title: 'District Overview'),
                const SizedBox(height: 8),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final columns = width < 340 ? 2 : 3;
                    const spacing = 8.0;
                    final cardWidth =
                        (width - (spacing * (columns - 1))) / columns;

                    final cards = <_OverviewStat>[
                      _OverviewStat(
                        icon: Icons.apartment_outlined,
                        label: 'Total\nProjects',
                        count: _stats.totalProjects,
                        accentColor: const Color(0xFF0D4778),
                      ),
                      _OverviewStat(
                        icon: Icons.warning_amber_outlined,
                        label: 'High-Risk\nProjects',
                        count: _stats.highRiskProjects,
                        accentColor: const Color(0xFFC0392B),
                      ),
                      _OverviewStat(
                        icon: Icons.fact_check_outlined,
                        label: 'All\nInspections',
                        count: _stats.totalInspections,
                        accentColor: const Color(0xFF0D4778),
                      ),
                      _OverviewStat(
                        icon: Icons.pending_actions_outlined,
                        label: 'Pending\nInspections',
                        count: _stats.pendingInspections,
                        accentColor: const Color(0xFFF5A623),
                      ),
                      _OverviewStat(
                        icon: Icons.task_alt_outlined,
                        label: 'Completed\nInspections',
                        count: _stats.completedInspections,
                        accentColor: const Color(0xFF159447),
                      ),
                      _OverviewStat(
                        icon: Icons.groups_outlined,
                        label: 'Assigned\nInspectors',
                        count: _stats.assignedInspectors,
                        accentColor: const Color(0xFF0D4778),
                      ),
                    ];

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final card in cards)
                          SizedBox(
                            width: cardWidth,
                            child: SummaryStatCard(
                              icon: card.icon,
                              label: card.label,
                              count: _loadingStats ? '—' : '${card.count}',
                              subtitle: _loadingStats ? 'Loading…' : null,
                              accentColor:
                              _loadingStats ? _textGrey : card.accentColor,
                            ),
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 18),

                const SectionHeader(title: 'Institutes'),
                const SizedBox(height: 8),
                QuickActionCard(
                  icon: Icons.apartment_outlined,
                  label: 'Institutes',
                  onTap: () => _openInstitutes(context),
                ),

                const SizedBox(height: 18),

                const SectionHeader(title: 'Inspectors'),
                const SizedBox(height: 8),
                QuickActionCard(
                  icon: Icons.groups_outlined,
                  label: 'Inspectors',
                  onTap: () => _openInspectors(context),
                ),

                const SizedBox(height: 18),

                const SectionHeader(title: 'District Map'),
                const SizedBox(height: 8),
                QuickActionCard(
                  icon: Icons.map_outlined,
                  label: 'View District Map',
                  onTap: () => _openMap(context),
                ),

                const SizedBox(height: 18),

                const SectionHeader(title: 'Profile'),
                const SizedBox(height: 8),
                QuickActionCard(
                  icon: Icons.person_outline,
                  label: 'View Profile',
                  onTap: () => _openProfile(context),
                ),

                const SizedBox(height: 18),

                const SectionHeader(title: 'Video Call'),
                const SizedBox(height: 8),
                QuickActionCard(
                  icon: Icons.call_outlined,
                  label: 'Call History',
                  onTap: () => _openCallHistory(context),
                ),
                const SizedBox(height: 6),
                const Text(
                  'To start a call, open an inspector from the Inspectors '
                      'list and tap Start Video Call. Incoming calls can be '
                      'received and joined from here.',
                  style: TextStyle(fontSize: 11, color: _textGrey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewStat {
  final IconData icon;
  final String label;
  final int count;
  final Color accentColor;

  const _OverviewStat({
    required this.icon,
    required this.label,
    required this.count,
    required this.accentColor,
  });
}