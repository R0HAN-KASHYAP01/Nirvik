import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../services/session_service.dart';
import '../data/national_dashboard_repository.dart';
import '../../projects/presentation/project_list_screen.dart';

/// Combined national dashboard.
///
/// This screen is now used for both:
/// - DoSJE Official
/// - MoSJE / National Admin
///
/// There is intentionally no separate MoSJE Admin dashboard UI.
class OfficialHomeScreen extends StatefulWidget {
  const OfficialHomeScreen({super.key});

  static const Color navy = Color(0xFF123E68);
  static const Color primaryBlue = Color(0xFF14568A);
  static const Color background = Color(0xFFEAF2F8);
  static const Color cardBackground = Color(0xFFF8FBFD);
  static const Color borderColor = Color(0xFFD1DEE7);
  static const Color textDark = Color(0xFF17324D);
  static const Color textGrey = Color(0xFF667788);
  static const Color green = Color(0xFF168A45);
  static const Color orange = Color(0xFFE88A18);
  static const Color red = Color(0xFFD83A3A);

  @override
  State<OfficialHomeScreen> createState() =>
      _OfficialHomeScreenState();
}

class _OfficialHomeScreenState extends State<OfficialHomeScreen> {
  final NationalDashboardRepository _repository =
      NationalDashboardRepository();

  late Future<NationalDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadDashboard();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _repository.loadDashboard();
    });

    await _future;
  }

  void _openProjects() {
    Navigator.of(context).pushNamed(
      AppRoutes.projectsPlaceholder,
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

  void _openCompliance() {
    Navigator.of(context).pushNamed(
      AppRoutes.assignmentsPlaceholder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser;

    return Scaffold(
      backgroundColor: OfficialHomeScreen.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: OfficialHomeScreen.primaryBlue,
          onRefresh: _refresh,
          child: FutureBuilder<NationalDashboardData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return ListView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    _Header(
                      userName: user?.name ?? 'Official',
                      onRefresh: _refresh,
                    ),
                    const SizedBox(height: 28),
                    _ErrorCard(
                      message:
                          'Dashboard data could not be loaded.',
                      onRetry: _refresh,
                    ),
                  ],
                );
              }

              final data = snapshot.data;

              if (data == null) {
                return ListView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    _Header(
                      userName: user?.name ?? 'Official',
                      onRefresh: _refresh,
                    ),
                    const SizedBox(height: 28),
                    const _ErrorCard(
                      message:
                          'No dashboard data available.',
                    ),
                  ],
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final horizontal =
                      constraints.maxWidth >= 700
                          ? 32.0
                          : 18.0;

                  return ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      16,
                      horizontal,
                      28,
                    ),
                    children: [
                      _Header(
                        userName: user?.name ?? 'Official',
                        onRefresh: _refresh,
                      ),
                      const SizedBox(height: 22),

                      const _PageIntro(),

                      const SizedBox(height: 16),

                      _MetricGrid(
                        data: data,
                        onProjects: _openProjects,
                        onHighRisk: _openHighRiskProjects,
                      ),

                      const SizedBox(height: 18),

                      _ComplianceCard(
                        data: data,
                        onTap: _openCompliance,
                      ),

                      const SizedBox(height: 18),

                      _FindingsCard(
                        count:
                            data.openCriticalFindingsCount,
                      ),

                      if (data.unavailableMetrics
                          .isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _LimitationsCard(
                          metrics: data.unavailableMetrics,
                        ),
                      ],
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.userName,
    required this.onRefresh,
  });

  final String userName;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: OfficialHomeScreen.navy,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.account_balance,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'DoSJE • National Monitoring',
                style: TextStyle(
                  color: OfficialHomeScreen.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Welcome, $userName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: OfficialHomeScreen.navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh dashboard',
          onPressed: onRefresh,
          icon: const Icon(
            Icons.refresh_rounded,
            color: OfficialHomeScreen.navy,
          ),
        ),
      ],
    );
  }
}

class _PageIntro extends StatelessWidget {
  const _PageIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OfficialHomeScreen.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: OfficialHomeScreen.borderColor,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.insights_outlined,
            color: OfficialHomeScreen.primaryBlue,
            size: 26,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'National Monitoring Overview',
                  style: TextStyle(
                    color: OfficialHomeScreen.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Real-time overview of projects, risk and inspection compliance.',
                  style: TextStyle(
                    color: OfficialHomeScreen.textGrey,
                    fontSize: 12,
                    height: 1.35,
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

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.data,
    required this.onProjects,
    required this.onHighRisk,
  });

  final NationalDashboardData data;
  final VoidCallback onProjects;
  final VoidCallback onHighRisk;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final columns = width >= 1000
            ? 4
            : width >= 650
                ? 2
                : 2;

        const gap = 12.0;

        final cardWidth =
            (width - gap * (columns - 1)) /
                columns;

        final cards = [
          _MetricCard(
            icon: Icons.apartment_outlined,
            title: 'TOTAL PROJECTS',
            value: data.totalProjects.toString(),
            subtitle: 'Registered institutes',
            iconColor:
                OfficialHomeScreen.navy,
            onTap: onProjects,
          ),

          _MetricCard(
            icon: Icons.warning_amber_rounded,
            title: 'HIGH-RISK PROJECTS',
            value:
                data.highRiskProjectCount.toString(),
            subtitle: 'Currently flagged',
            iconColor:
                OfficialHomeScreen.red,
            onTap: onHighRisk,
          ),

          _MetricCard(
            icon: Icons.fact_check_outlined,
            title: 'TOTAL INSPECTIONS',
            value:
                data.totalAssignedInspections
                    .toString(),
            subtitle: 'Assigned inspections',
            iconColor:
                OfficialHomeScreen.primaryBlue,
          ),

          _MetricCard(
            icon: Icons.verified_outlined,
            title: 'INSPECTION COMPLIANCE',
            value:
                '${(data.complianceRate * 100).round()}%',
            subtitle:
                '${data.completedInspections}/${data.totalAssignedInspections} completed',
            iconColor:
                OfficialHomeScreen.green,
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map(
                (card) => SizedBox(
                  width: cardWidth,
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      constraints:
          const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            OfficialHomeScreen.cardBackground,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              OfficialHomeScreen.borderColor,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(
                alpha: 0.11,
              ),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color:
                  OfficialHomeScreen.textGrey,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color:
                  OfficialHomeScreen.navy,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color:
                  OfficialHomeScreen.textGrey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return child;
    }

    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(16),
      child: child,
    );
  }
}

class _ComplianceCard extends StatelessWidget {
  const _ComplianceCard({
    required this.data,
    required this.onTap,
  });

  final NationalDashboardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rate = data.complianceRate;

    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:
              OfficialHomeScreen.cardBackground,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color:
                OfficialHomeScreen.borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.fact_check_outlined,
                  color:
                      OfficialHomeScreen.navy,
                  size: 22,
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'Inspection Compliance',
                    style: TextStyle(
                      color:
                          OfficialHomeScreen.textDark,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${(rate * 100).round()}%',
                  style: const TextStyle(
                    color:
                        OfficialHomeScreen.navy,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(8),
              child:
                  LinearProgressIndicator(
                value: rate,
                minHeight: 9,
                backgroundColor:
                    OfficialHomeScreen
                        .background,
                valueColor:
                    const AlwaysStoppedAnimation<
                        Color>(
                  OfficialHomeScreen.green,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _ComplianceItem(
                  label: 'Completed',
                  value:
                      data.completedInspections,
                  color:
                      OfficialHomeScreen.green,
                ),
                _ComplianceItem(
                  label: 'Pending',
                  value:
                      data.pendingInspections,
                  color:
                      OfficialHomeScreen.orange,
                ),
                _ComplianceItem(
                  label: 'In Progress',
                  value:
                      data.inProgressInspections,
                  color:
                      OfficialHomeScreen
                          .primaryBlue,
                ),
                _ComplianceItem(
                  label: 'Overdue',
                  value:
                      data.overdueInspections,
                  color:
                      OfficialHomeScreen.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComplianceItem
    extends StatelessWidget {
  const _ComplianceItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          '$label: $value',
          style: const TextStyle(
            color:
                OfficialHomeScreen.textGrey,
            fontSize: 11,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FindingsCard
    extends StatelessWidget {
  const _FindingsCard({
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            OfficialHomeScreen.cardBackground,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              OfficialHomeScreen.borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color:
                  OfficialHomeScreen.red
                      .withValues(alpha: 0.10),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons
                  .report_gmailerrorred_outlined,
              color:
                  OfficialHomeScreen.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Open Critical Findings',
                  style: TextStyle(
                    color:
                        OfficialHomeScreen.textDark,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'High, critical and severe inspection findings',
                  style: TextStyle(
                    color:
                        OfficialHomeScreen.textGrey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              color:
                  OfficialHomeScreen.red,
              fontSize: 27,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LimitationsCard
    extends StatelessWidget {
  const _LimitationsCard({
    required this.metrics,
  });

  final List<String> metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            OfficialHomeScreen.cardBackground,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              OfficialHomeScreen.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Data availability',
            style: TextStyle(
              color:
                  OfficialHomeScreen.textDark,
              fontSize: 14,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ...metrics.map(
            (metric) => Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 6,
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color:
                        OfficialHomeScreen
                            .textGrey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      metric,
                      style:
                          const TextStyle(
                        color:
                            OfficialHomeScreen
                                .textGrey,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              OfficialHomeScreen.borderColor,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color:
                OfficialHomeScreen.red,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign:
                TextAlign.center,
            style: const TextStyle(
              color:
                  OfficialHomeScreen.textDark,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child:
                  const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}