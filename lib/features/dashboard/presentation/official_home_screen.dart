import 'package:flutter/material.dart';

import '../../../services/session_service.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/quick_action_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/inspection.dart';
import '../data/mock_dashboard_data.dart';
import '../../calls/presentation/call_history_screen.dart';
import 'assignments_screen.dart';
import 'inspection_history_screen.dart';
import '../../projects/presentation/project_list_screen.dart';

class OfficialHomeScreen extends StatelessWidget {
  const OfficialHomeScreen({super.key});

  // Government Digital India style theme
  static const Color navy = Color(0xFF123E68);
  static const Color darkNavy = Color(0xFF0B3154);
  static const Color primaryBlue = Color(0xFF14568A);
  static const Color background = Color(0xFFEAF1F6);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color softBlue = Color(0xFFE4EDF3);
  static const Color borderColor = Color(0xFFD3E0E8);
  static const Color textDark = Color(0xFF17324D);
  static const Color textGrey = Color(0xFF667788);
  static const Color green = Color(0xFF168A45);
  static const Color saffron = Color(0xFFE88A18);

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser;
    final inspections = MockDashboardData.recentInspections;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _HomeHeader(
              userName: user?.name ?? 'DoSJE Official',
              alertCount: 3,
            ),

            const SizedBox(height: 18),

            const _HeroBanner(),

            const SizedBox(height: 16),

            // High-risk alerts get visual priority without alarming the whole screen.
            _AlertBanner(
              count: 3,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const ProjectListScreen(initialHighRiskFilter: true),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _MiniStatCard(
                    icon: Icons.calendar_today_outlined,
                    label: "Today's\nInspections",
                    count: '6',
                    color: primaryBlue,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AssignmentsScreen(
                          initialFilter: 'today',
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _MiniStatCard(
                    icon: Icons.assignment_outlined,
                    label: 'Pending\nReviews',
                    count: '9',
                    color: saffron,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AssignmentsScreen(
                          initialFilter: 'pendingReview',
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _MiniStatCard(
                    icon: Icons.apartment_outlined,
                    label: 'Total\nProjects',
                    count: '42',
                    color: green,
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.projectsPlaceholder,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),

            SectionHeader(
              title: 'Recent Inspections',
              actionLabel: 'View all',
              onActionTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const InspectionHistoryScreen(),
                ),
              ),
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
                    .map(
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RecentInspectionTile(inspection: i),
                      ),
                    )
                    .toList(),
              ),

            const SizedBox(height: 26),

            const SectionHeader(title: 'Quick Actions'),

            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.apartment,
                    label: 'Projects',
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.projectsPlaceholder,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: QuickActionCard(
                    icon: Icons.fact_check_outlined,
                    label: 'Inspections',
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.inspectionsPlaceholder,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: QuickActionCard(
                    icon: Icons.videocam_outlined,
                    label: 'CCTV',
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.cctvPlaceholder,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: QuickActionCard(
                    icon: Icons.bar_chart,
                    label: 'Analytics',
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.analyticsPlaceholder,
                    ),
                  ),
                ),

                QuickActionCard(
                  icon: Icons.history,
                  label: 'Call History',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CallHistoryScreen(),
                    ),
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

/// Header: avatar, greeting + name, notification bell with badge.
/// Local to this screen — shared DashboardHeader remains untouched.
class _HomeHeader extends StatelessWidget {
  final String userName;
  final int alertCount;

  const _HomeHeader({
    required this.userName,
    required this.alertCount,
  });

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: OfficialHomeScreen.navy,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: OfficialHomeScreen.navy.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: const Icon(
              Icons.person,
              color: OfficialHomeScreen.navy,
              size: 25,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),

                const Text(
                  'Official',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                ),
                onPressed: () {},
              ),

              if (alertCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD83A3A),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$alertCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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

/// Government-style hero banner with subtle tricolor accent.
class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: OfficialHomeScreen.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: OfficialHomeScreen.navy.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            child: Text(
              "Let's build a stronger,\nmore inclusive society",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: OfficialHomeScreen.navy,
                height: 1.3,
              ),
            ),
          ),

          Positioned(
            right: 18,
            top: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Government',
                  style: TextStyle(
                    fontSize: 9,
                    color: OfficialHomeScreen.textGrey,
                  ),
                ),
                const Text(
                  'for a Brighter',
                  style: TextStyle(
                    fontSize: 9,
                    color: OfficialHomeScreen.textGrey,
                  ),
                ),
                const Text(
                  'Tomorrow',
                  style: TextStyle(
                    fontSize: 9,
                    color: OfficialHomeScreen.textGrey,
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: 145,
            bottom: 16,
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 4,
                  decoration: BoxDecoration(
                    color: OfficialHomeScreen.saffron,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 70,
                  height: 3,
                  decoration: BoxDecoration(
                    color: OfficialHomeScreen.green,
                    borderRadius: BorderRadius.circular(10),
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

class _AlertBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _AlertBanner({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6E8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: OfficialHomeScreen.saffron.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: OfficialHomeScreen.saffron.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: OfficialHomeScreen.saffron,
                size: 21,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                '$count high-risk alerts require attention',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: OfficialHomeScreen.textDark,
                ),
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: OfficialHomeScreen.navy,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// Stat card with government theme styling.
class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final Color color;
  final VoidCallback onTap;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OfficialHomeScreen.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: OfficialHomeScreen.borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: OfficialHomeScreen.navy.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 17,
                color: color,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              count,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: OfficialHomeScreen.navy,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: OfficialHomeScreen.textGrey,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                4,
                (i) {
                  final heights = [6.0, 10.0, 8.0, 14.0];

                  return Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Container(
                      width: 5,
                      height: heights[i],
                      decoration: BoxDecoration(
                        color: color.withValues(
                          alpha: 0.35 + (i * 0.15),
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
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

/// Recent-inspection row.
/// Functionality and data remain unchanged.
class _RecentInspectionTile extends StatelessWidget {
  final InspectionSummary inspection;

  const _RecentInspectionTile({
    required this.inspection,
  });

  Color get _statusColor {
    switch (inspection.status) {
      case InspectionStatus.approved:
        return OfficialHomeScreen.green;
      case InspectionStatus.overdue:
        return const Color(0xFFD83A3A);
      case InspectionStatus.underReview:
        return OfficialHomeScreen.saffron;
      case InspectionStatus.submitted:
        return OfficialHomeScreen.primaryBlue;
      case InspectionStatus.inProgress:
        return OfficialHomeScreen.navy;
      case InspectionStatus.assigned:
        return OfficialHomeScreen.textGrey;
    }
  }

  Color get _riskColor {
    switch (inspection.risk) {
      case RiskLevel.high:
        return const Color(0xFFD83A3A);
      case RiskLevel.medium:
        return OfficialHomeScreen.saffron;
      case RiskLevel.low:
        return OfficialHomeScreen.green;
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');

    return '${dt.day} Sep ${dt.year} · $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: OfficialHomeScreen.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: OfficialHomeScreen.borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: OfficialHomeScreen.navy.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: OfficialHomeScreen.softBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.apartment,
                color: OfficialHomeScreen.navy,
                size: 26,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inspection.projectName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: OfficialHomeScreen.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 2),

                  Text(
                    'Inspector: ${inspection.inspectorName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: OfficialHomeScreen.textGrey,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: OfficialHomeScreen.textGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(inspection.dateTime),
                        style: const TextStyle(
                          fontSize: 11,
                          color: OfficialHomeScreen.textGrey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Wrap(
                    spacing: 6,
                    children: [
                      StatusBadge(
                        label: inspection.status.label,
                        color: _statusColor,
                      ),
                      StatusBadge(
                        label: '${inspection.risk.label} Risk',
                        color: _riskColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              size: 18,
              color: OfficialHomeScreen.textGrey,
            ),
          ],
        ),
      ),
    );
  }
}