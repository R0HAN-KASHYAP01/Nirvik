// lib/features/district_admin/presentation/district_admin_dashboard_screen.dart
//
// District Administrator dashboard.
//
// Institutes: opens InstituteCategoryScreen (category -> scheme ->
// institutes). That flow reads `institute_reps`, which has its own
// state / district / scheme_category / scheme_code columns, and is scoped
// to the admin's own district + state both in the app and by RLS
// (see district_admin_institutes_rls.sql).
//
// Still locked: project / inspection / map / inspector cards. Those depend
// on `ngo_institutes` and `pmu_assignments`, which have no district column
// of their own, so rendering them unscoped would leak other districts'
// data. Each locked card reports that honestly instead of faking data.
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
          '$feature is not available yet for the district dashboard.',
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

  void _openInstitutes(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.districtInstitutes);
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
                        'Institutes are available for your district. '
                            'District-level filtering for projects, inspections, '
                            'the map and inspectors is still pending, so those '
                            'cards stay locked.',
                        style: TextStyle(fontSize: 11.5, color: _textGrey),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==========================================================
              // PROJECT / RISK STATS — locked (no district scoping yet)
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
              // INSTITUTES — category -> scheme -> institutes
              // ==========================================================
              const SectionHeader(title: 'Institutes'),
              const SizedBox(height: 8),
              QuickActionCard(
                icon: Icons.apartment_outlined,
                label: 'Institutes',
                onTap: () => _openInstitutes(context),
              ),

              const SizedBox(height: 18),

              // ==========================================================
              // MAP — locked (no district scoping yet)
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