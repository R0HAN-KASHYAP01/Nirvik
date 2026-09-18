// lib/features/mosje_admin/presentation/mosje_admin_dashboard_screen.dart
import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/dashboard_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_start.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/summary_stat_card.dart';
import '../../../models/project.dart';
import '../../../services/session_service.dart';
import '../../calls/presentation/call_history_screen.dart';
import '../../schemes/data/mock_schemes_data.dart';
import '../data/national_dashboard_repository.dart';

/// National-level dashboard for the MoSJE Admin role.
///
/// Aggregates real data across every state/district/project/scheme via
/// [NationalDashboardRepository], which itself reuses the existing
/// SchemesRepository / ProjectsRepository rather than duplicating their
/// query logic. Reuses the existing map (InstituteMapScreen) and
/// video-call (CallHistoryScreen) features as-is.
class MosjeAdminDashboardScreen extends StatefulWidget {
  const MosjeAdminDashboardScreen({super.key});

  @override
  State<MosjeAdminDashboardScreen> createState() =>
      _MosjeAdminDashboardScreenState();
}

class _MosjeAdminDashboardScreenState
    extends State<MosjeAdminDashboardScreen> {
  final _repository = NationalDashboardRepository();

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

  void _logout() {
    SessionService.instance.logout();
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  void _openMap() {
    Navigator.of(context).pushNamed(AppRoutes.instituteMap);
  }

  void _openCallHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CallHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DashboardHeader(
                greeting: 'MoSJE / National Admin',
                userName: user?.name ?? 'National Admin',
                onNotificationTap: () {},
                onLogoutTap: _logout,
              ),
              const SizedBox(height: 20),
              FutureBuilder<NationalDashboardData>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingState(
                      message: 'Loading national dashboard…',
                    );
                  }

                  if (snapshot.hasError) {
                    return ErrorStateView(
                      message:
                          'Could not load the national dashboard.\n${snapshot.error}',
                      onRetry: _refresh,
                    );
                  }

                  final data = snapshot.data;
                  if (data == null) {
                    return const EmptyState(
                      title: 'No data',
                      message: 'Nothing to show yet.',
                    );
                  }

                  return _DashboardBody(
                    data: data,
                    onOpenMap: _openMap,
                    onOpenCallHistory: _openCallHistory,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.data,
    required this.onOpenMap,
    required this.onOpenCallHistory,
  });

  final NationalDashboardData data;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenCallHistory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('National Overview', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            SummaryStatCard(
              icon: Icons.category_outlined,
              label: 'Scheme Categories',
              count: data.totalSchemeTypes.toString(),
              subtitle: 'broad groupings',
              accentColor: AppColors.info,
              onTap: () => _showSchemeBreakdown(context),
            ),
            SummaryStatCard(
              icon: Icons.menu_book_outlined,
              label: 'Total Schemes',
              count: data.totalCatalogSchemes?.toString() ?? 'N/A',
              subtitle: 'from scheme catalog',
              accentColor: AppColors.secondary,
            ),
            const SummaryStatCard(
              icon: Icons.map_outlined,
              label: 'Total States',
              count: 'N/A',
              subtitle: 'Not tracked yet',
              accentColor: AppColors.textSecondary,
            ),
            SummaryStatCard(
              icon: Icons.apartment_outlined,
              label: 'Total Projects',
              count: data.totalProjects.toString(),
              accentColor: AppColors.primary,
              onTap: onOpenMap,
            ),
            SummaryStatCard(
              icon: Icons.warning_amber_outlined,
              label: 'High-Risk Projects',
              count: data.highRiskProjectCount.toString(),
              accentColor: AppColors.error,
              onTap: () => _showHighRiskProjects(context),
            ),
          ],
        ),

        const SizedBox(height: 24),
        Text('Inspection Compliance', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Based on ${data.totalAssignedInspections} assigned inspections nationally.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SummaryStatCard(
                icon: Icons.check_circle_outline,
                label: 'Completed',
                count: data.completedInspections.toString(),
                accentColor: AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryStatCard(
                icon: Icons.hourglass_empty,
                label: 'Pending',
                count: data.pendingInspections.toString(),
                accentColor: AppColors.warning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryStatCard(
                icon: Icons.error_outline,
                label: 'Overdue',
                count: data.overdueInspections.toString(),
                accentColor: AppColors.error,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        Text('Findings', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        SummaryStatCard(
          icon: Icons.report_gmailerrorred_outlined,
          label: 'Open Critical Findings',
          count: data.openCriticalFindingsCount.toString(),
          subtitle: 'high / critical / severe severity',
          accentColor: AppColors.error,
        ),

        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onOpenMap,
                icon: const Icon(Icons.map_outlined),
                label: const Text('National Map'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onOpenCallHistory,
                icon: const Icon(Icons.video_call_outlined),
                label: const Text('Video Calls'),
              ),
            ),
          ],
        ),

        if (data.unavailableMetrics.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Known limitations',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...data.unavailableMetrics.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(m, style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showSchemeBreakdown(BuildContext context) {
    if (data.instituteCountsByScheme.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          content: EmptyState(
            title: 'No scheme data',
            message: 'Institute counts by scheme are not available right now.',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Schemes'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: MockSchemesData.schemes.map((scheme) {
              final count = data.instituteCountsByScheme[scheme.type] ?? 0;
              return ListTile(
                leading: Icon(scheme.icon, color: scheme.color),
                title: Text(scheme.name),
                trailing: Text('$count institutes'),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHighRiskProjects(BuildContext context) {
    if (data.highRiskProjects.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          content: EmptyState(
            icon: Icons.check_circle_outline,
            title: 'No high-risk projects',
            message: 'No projects are currently flagged as high risk.',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('High-Risk Projects'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: data.highRiskProjects.length,
            itemBuilder: (context, index) {
              final Project p = data.highRiskProjects[index];
              return ListTile(
                leading: const Icon(Icons.warning_amber_outlined, color: AppColors.error),
                title: Text(p.name),
                subtitle: Text(p.location),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}