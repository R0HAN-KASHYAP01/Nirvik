import 'package:flutter/material.dart';
import '../../../services/session_service.dart';
import '../../../app/routes.dart';
import '../../../core/widgets/dashboard_header.dart';
import '../../../core/widgets/summary_stat_card.dart';
import '../../../core/widgets/quick_action_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/mock_dashboard_data.dart';
import 'widgets/recent_inspection_card.dart';
import '../../calls/presentation/call_history_screen.dart';

class OfficialHomeScreen extends StatelessWidget {
  const OfficialHomeScreen({super.key});

  void _logout(BuildContext context) {
    SessionService.instance.clear();
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser;
    final inspections = MockDashboardData.recentInspections;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            DashboardHeader(
              greeting: _todayLabel(),
              userName: user?.name ?? 'DoSJE Official',
              onNotificationTap: () {},
              onLogoutTap: () => _logout(context),
            ),
            const SizedBox(height: 24),

            // Primary stat — high-risk alerts get visual priority without alarming the whole screen.
            _AlertBanner(count: 3),
            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.05,
              children: [
                SummaryStatCard(
                  icon: Icons.today,
                  label: "Today's Inspections",
                  count: '6',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.inspectionsPlaceholder),
                ),
                SummaryStatCard(
                  icon: Icons.rate_review_outlined,
                  label: 'Pending Reviews',
                  count: '9',
                  accentColor: Colors.orange,
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.inspectionsPlaceholder),
                ),
                SummaryStatCard(
                  icon: Icons.apartment,
                  label: 'Total Projects',
                  count: '42',
                  accentColor: Colors.indigo,
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.projectsPlaceholder),
                ),
              ],
            ),

            const SizedBox(height: 28),
            SectionHeader(
              title: 'Recent Inspections',
              actionLabel: 'View all',
              onActionTap: () => Navigator.of(context).pushNamed(AppRoutes.inspectionsPlaceholder),
            ),
            const SizedBox(height: 10),

            if (inspections.isEmpty)
              const EmptyState(
                icon: Icons.fact_check_outlined,
                title: 'No recent inspections',
                message: 'Inspections will appear here once submitted.',
              )
            else
              Column(
                children: inspections
                    .map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RecentInspectionCard(inspection: i),
                ))
                    .toList(),
              ),

            const SizedBox(height: 28),
            const SectionHeader(title: 'Quick Actions'),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
              children: [
                QuickActionCard(
                  icon: Icons.apartment,
                  label: 'Projects',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.projectsPlaceholder),
                ),
                QuickActionCard(
                  icon: Icons.fact_check_outlined,
                  label: 'Inspections',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.inspectionsPlaceholder),
                ),
                QuickActionCard(
                  icon: Icons.videocam_outlined,
                  label: 'CCTV',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.cctvPlaceholder),
                ),
                QuickActionCard(
                  icon: Icons.bar_chart,
                  label: 'Analytics',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.analyticsPlaceholder),
                ),
                QuickActionCard(
                  icon: Icons.history,
                  label: 'Call History',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CallHistoryScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final int count;
  const _AlertBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEDED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF3C6C6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB3261E), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count high-risk alerts require attention',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB3261E),
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFB3261E), size: 18),
        ],
      ),
    );
  }
}