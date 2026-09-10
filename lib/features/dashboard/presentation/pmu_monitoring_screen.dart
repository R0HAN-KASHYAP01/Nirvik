import 'package:flutter/material.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_start.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/summary_stat_card.dart';
import '../../../models/pmu_officer_summary.dart';
import '../data/pmu_monitoring_repository.dart';
import 'widgets/pmu_officer_card.dart';
import 'widgets/pmu_officer_detail_screen.dart';

class PmuMonitoringScreen extends StatefulWidget {
  const PmuMonitoringScreen({super.key});

  @override
  State<PmuMonitoringScreen> createState() => _PmuMonitoringScreenState();
}

class _PmuMonitoringScreenState extends State<PmuMonitoringScreen> {
  final _repository = PmuMonitoringRepository();
  late Future<List<PmuOfficerSummary>> _future;

  final _searchController = TextEditingController();
  OfficerAvailability? _statusFilter;

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchOfficers();
  }

  void _reload() {
    setState(() => _future = _repository.fetchOfficers());
  }

  List<PmuOfficerSummary> _applyFilters(List<PmuOfficerSummary> officers) {
    final query = _searchController.text.trim().toLowerCase();
    return officers.where((o) {
      final matchesQuery = query.isEmpty || o.name.toLowerCase().contains(query);
      final matchesStatus = _statusFilter == null || o.availability == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PMU Monitoring')),
      body: FutureBuilder<List<PmuOfficerSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading PMU officers…');
          }
          if (snapshot.hasError) {
            return ErrorStateView(
              message: 'Could not load PMU officer data.',
              onRetry: _reload,
            );
          }

          final officers = snapshot.data ?? [];
          if (officers.isEmpty) {
            return const EmptyState(
              icon: Icons.groups_outlined,
              title: 'No PMU officers found',
              message: 'No PMU/Inspection officers are currently on record.',
            );
          }

          final filtered = _applyFilters(officers);

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryStats(officers: officers),
                const SizedBox(height: 20),
                SectionHeader(title: 'Officers (${filtered.length})'),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search officer by name',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                _StatusFilterRow(
                  selected: _statusFilter,
                  onSelected: (s) => setState(() => _statusFilter = s),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const EmptyState(
                    title: 'No matches',
                    message: 'Try a different name or status filter.',
                  )
                else
                  ...filtered.map(
                    (officer) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PmuOfficerCard(
                        officer: officer,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PmuOfficerDetailScreen(officer: officer),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryStats extends StatelessWidget {
  final List<PmuOfficerSummary> officers;

  const _SummaryStats({required this.officers});

  @override
  Widget build(BuildContext context) {
    final total = officers.length;
    final available =
        officers.where((o) => o.availability == OfficerAvailability.available).length;
    final totalAssignments = officers.fold<int>(0, (sum, o) => sum + o.assignmentsCount);
    final completed = officers.fold<int>(0, (sum, o) => sum + o.completedInspectionsCount);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        SummaryStatCard(icon: Icons.groups_outlined, label: 'Total PMU Officers', count: '$total'),
        SummaryStatCard(
          icon: Icons.check_circle_outline,
          label: 'Available Officers',
          count: '$available',
          accentColor: const Color(0xFF1E7A46),
        ),
        SummaryStatCard(icon: Icons.assignment_outlined, label: 'Total Assignments', count: '$totalAssignments'),
        SummaryStatCard(icon: Icons.fact_check_outlined, label: 'Completed Inspections', count: '$completed'),
      ],
    );
  }
}

class _StatusFilterRow extends StatelessWidget {
  final OfficerAvailability? selected;
  final ValueChanged<OfficerAvailability?> onSelected;

  const _StatusFilterRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(context, null, 'All'),
          ...OfficerAvailability.values.map((s) => _chip(context, s, s.label)),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, OfficerAvailability? value, String label) {
    final isSelected = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(value),
      ),
    );
  }
}