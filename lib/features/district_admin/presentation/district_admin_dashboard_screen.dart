// lib/features/district_admin/presentation/district_admin_dashboard_screen.dart
//
// District Administrator dashboard.
//
// IMPORTANT — why several cards are locked instead of showing data:
// `ngo_institutes` (and therefore `pmu_assignments`, which joins to it)
// has no `district` column today, while `district_administrators.district`
// does. There is currently no column anywhere to filter projects,
// inspections, or inspectors by district. Rendering those lists unscoped
// would violate the hard requirement that a District Admin must never see
// another district's data, so — following the same pattern this codebase
// already uses for `AppRoutes.inspectionsPlaceholder` / `rvcPlaceholder`
// (ModulePlaceholderScreen) — those sections report the gap honestly
// instead of faking or silently leaking cross-district data.
//
// Once `ngo_institutes.district` (and any `pmu_assignments` equivalent)
// exists, each locked card below has a single TODO marking exactly where
// to add the real repository call.
//
// Video calling: `CallPermission.callTypeFor` returns null for every
// pairing involving districtAdmin (see lib/utils/call_permission.dart) —
// that gate was left as a TODO by a previous developer pending the
// video_calls.call_type values for this role. Initiating a call is
// therefore not wired up here. Receiving/joining a call has no such gate
// (VideoCallService.accept/reject/end never check call_type), so that
// part is fully wired via IncomingCallListener + real CallHistoryScreen.

import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/dashboard_header.dart';
import '../../../core/widgets/profile_placeholder_screen.dart';
import '../../../core/widgets/quick_action_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/summary_stat_card.dart';
import '../../../services/auth_service.dart';
import '../../../services/session_service.dart';
import '../../calls/presentation/call_history_screen.dart';
import '../../calls/presentation/widgets/incoming_call_listener.dart';

class DistrictAdminDashboardScreen extends StatelessWidget {
  const DistrictAdminDashboardScreen({super.key});

  // Same blue-grey government palette used by OfficialHomeScreen,
  // InspectorShellScreen, ProjectListScreen and SchemesScreen — reused
  // exactly, not redefined, to keep the dashboard visually consistent.
  static const Color _background = Color(0xFFEAF2F8);
  static const Color _border = Color(0xFFD1DEE7);
  static const Color _textGrey = Color(0xFF667788);

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.logout();
    SessionService.instance.clear();
    if (!context.mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  void _showPendingSetupMessage(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature is not available yet — it needs a district field on '
          'the institute records first, which has not been added to the '
          'database.',
        ),
        duration: const Duration(seconds: 4),
      ),
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
            children: [
              DashboardHeader(
                greeting: locationLabel.isEmpty
                    ? 'District Administrator'
                    : 'District Administrator · $locationLabel',
                userName: user?.name ?? 'District Admin',
                onNotificationTap: () =>
                    _showPendingSetupMessage(context, 'Notifications'),
                onLogoutTap: () => _logout(context),
              ),

              const SizedBox(height: 14),

              // ==========================================================
              // BACKEND-DEPENDENCY NOTICE
              // ==========================================================
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: _textGrey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'District-level filtering for projects, inspections, '
                        'the map and inspectors is pending a database update '
                        '(a district field on institute records). Locked '
                        'cards below will activate once that is added.',
                        style: TextStyle(fontSize: 11.5, color: _textGrey),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==========================================================
              // PROJECT / RISK STATS — locked pending district column
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

                  final cards = <_LockedStat>[
                    const _LockedStat(
                      icon: Icons.apartment_outlined,
                      label: 'Total\nProjects',
                      feature: 'Total Projects',
                    ),
                    const _LockedStat(
                      icon: Icons.warning_amber_outlined,
                      label: 'High-Risk\nProjects',
                      feature: 'High-Risk Projects',
                    ),
                    const _LockedStat(
                      icon: Icons.fact_check_outlined,
                      label: 'All\nInspections',
                      feature: 'All Inspections',
                    ),
                    const _LockedStat(
                      icon: Icons.pending_actions_outlined,
                      label: 'Pending\nInspections',
                      feature: 'Pending Inspections',
                    ),
                    const _LockedStat(
                      icon: Icons.task_alt_outlined,
                      label: 'Completed\nInspections',
                      feature: 'Completed Inspections',
                    ),
                    const _LockedStat(
                      icon: Icons.groups_outlined,
                      label: 'Assigned\nInspectors',
                      feature: 'Assigned Inspectors',
                    ),
                  ];

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final card in cards)
                        SizedBox(
                          width: cardWidth,
                          child: Opacity(
                            opacity: 0.55,
                            child: SummaryStatCard(
                              icon: card.icon,
                              label: card.label,
                              count: '—',
                              subtitle: 'Pending setup',
                              accentColor: _textGrey,
                              onTap: () => _showPendingSetupMessage(
                                context,
                                card.feature,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 18),

              // ==========================================================
              // SCHEME / DIVISION — locked pending district column
              // ==========================================================
              const SectionHeader(title: 'Schemes & Divisions'),
              const SizedBox(height: 8),
              Opacity(
                opacity: 0.55,
                child: QuickActionCard(
                  icon: Icons.category_outlined,
                  label: 'View by Scheme / Division',
                  onTap: () => _showPendingSetupMessage(
                    context,
                    'Scheme / Division grouping',
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ==========================================================
              // MAP — locked pending district column
              // ==========================================================
              const SectionHeader(title: 'District Map'),
              const SizedBox(height: 8),
              Opacity(
                opacity: 0.55,
                child: QuickActionCard(
                  icon: Icons.map_outlined,
                  label: 'View District Map',
                  onTap: () => _showPendingSetupMessage(context, 'The map'),
                ),
              ),

              const SizedBox(height: 18),

              // ==========================================================
              // PROFILE — fully working, reuses ProfilePlaceholderScreen
              // ==========================================================
              const SectionHeader(title: 'Profile'),
              const SizedBox(height: 8),
              QuickActionCard(
                icon: Icons.person_outline,
                label: 'View Profile',
                onTap: () => _openProfile(context),
              ),

              const SizedBox(height: 18),

              // ==========================================================
              // VIDEO CALL — receive/join works now; initiating is
              // blocked by the existing CallPermission TODO for this role.
              // ==========================================================
              const SectionHeader(title: 'Video Call'),
              const SizedBox(height: 8),
              QuickActionCard(
                icon: Icons.call_outlined,
                label: 'Call History',
                onTap: () => _openCallHistory(context),
              ),
              const SizedBox(height: 6),
              const Text(
                'Incoming calls can be received and joined. Starting a new '
                'call is not yet enabled for this role — see '
                'CallPermission.callTypeFor in call_permission.dart.',
                style: TextStyle(fontSize: 11, color: _textGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedStat {
  final IconData icon;
  final String label;
  final String feature;

  const _LockedStat({
    required this.icon,
    required this.label,
    required this.feature,
  });
}