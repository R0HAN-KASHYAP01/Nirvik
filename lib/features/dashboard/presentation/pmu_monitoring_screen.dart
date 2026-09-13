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
  State<PmuMonitoringScreen> createState() =>
      _PmuMonitoringScreenState();
}

class _PmuMonitoringScreenState extends State<PmuMonitoringScreen> {
  final _repository = PmuMonitoringRepository();

  late Future<List<PmuOfficerSummary>> _future;

  final _searchController = TextEditingController();

  OfficerAvailability? _statusFilter;

  // Government Digital India theme
  static const Color _navy = Color(0xFF123E68);
  static const Color _background = Color(0xFFEAF1F6);
  static const Color _cardBackground = Color(0xFFE1ECF3);
  static const Color _textDark = Color(0xFF17324D);
  static const Color _textGrey = Color(0xFF667788);
  static const Color _border = Color(0xFFD1DEE7);
  static const Color _green = Color(0xFF168A45);
  static const Color _saffron = Color(0xFFE88A18);
  static const Color _red = Color(0xFFD64545);

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchOfficers();
  }

  void _reload() {
    setState(() => _future = _repository.fetchOfficers());
  }

  List<PmuOfficerSummary> _applyFilters(
    List<PmuOfficerSummary> officers,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    return officers.where((o) {
      final matchesQuery =
          query.isEmpty || o.name.toLowerCase().contains(query);

      final matchesStatus =
          _statusFilter == null ||
          o.availability == _statusFilter;

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
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'PMU Monitoring',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<PmuOfficerSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState(
              message: 'Loading PMU officers…',
            );
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
              message:
                  'No PMU/Inspection officers are currently on record.',
            );
          }

          final filtered = _applyFilters(officers);

          return RefreshIndicator(
            color: _navy,
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryStats(
                  officers: officers,
                ),

                const SizedBox(height: 20),

                SectionHeader(
                  title: 'Officers (${filtered.length})',
                ),

                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color: _cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _border,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search officer by name',
                      hintStyle: const TextStyle(
                        color: _textGrey,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: _navy,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: _cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: _navy,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                _StatusFilterRow(
                  selected: _statusFilter,
                  onSelected: (s) =>
                      setState(() => _statusFilter = s),
                ),

                const SizedBox(height: 12),

                if (filtered.isEmpty)
                  const EmptyState(
                    title: 'No matches',
                    message:
                        'Try a different name or status filter.',
                  )
                else
                  ...filtered.map(
                    (officer) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: 12),
                      child: PmuOfficerCard(
                        officer: officer,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PmuOfficerDetailScreen(
                              officer: officer,
                            ),
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

  const _SummaryStats({
    required this.officers,
  });

  @override
  Widget build(BuildContext context) {
    final total = officers.length;

    final available = officers
        .where(
          (o) =>
              o.availability ==
              OfficerAvailability.available,
        )
        .length;

    final totalAssignments = officers.fold<int>(
      0,
      (sum, o) => sum + o.assignmentsCount,
    );

    final pending = officers.fold<int>(
      0,
      (sum, o) => sum + o.pendingInspectionsCount,
    );

    final completed = officers.fold<int>(
      0,
      (sum, o) => sum + o.completedInspectionsCount,
    );

    final overdue = officers.fold<int>(
      0,
      (sum, o) => sum + o.overdueInspectionsCount,
    );

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _ThemeSummaryCard(
          icon: Icons.groups_outlined,
          label: 'Total PMU Officers',
          count: '$total',
          accentColor: const Color(0xFF123E68),
        ),
        _ThemeSummaryCard(
          icon: Icons.check_circle_outline,
          label: 'Available Officers',
          count: '$available',
          accentColor: const Color(0xFF168A45),
        ),
        _ThemeSummaryCard(
          icon: Icons.assignment_outlined,
          label: 'Total Assignments',
          count: '$totalAssignments',
          accentColor: const Color(0xFF123E68),
        ),
        _ThemeSummaryCard(
          icon: Icons.pending_actions_outlined,
          label: 'Pending Inspections',
          count: '$pending',
          accentColor: const Color(0xFFE88A18),
        ),
        _ThemeSummaryCard(
          icon: Icons.fact_check_outlined,
          label: 'Completed Inspections',
          count: '$completed',
          accentColor: const Color(0xFF168A45),
        ),
        _ThemeSummaryCard(
          icon: Icons.error_outline,
          label: 'Overdue Inspections',
          count: '$overdue',
          accentColor: const Color(0xFFD64545),
        ),
      ],
    );
  }
}

class _ThemeSummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final Color accentColor;

  const _ThemeSummaryCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    const cardBackground = Color(0xFFE1ECF3);
    const border = Color(0xFFD1DEE7);
    const textDark = Color(0xFF17324D);
    const textGrey = Color(0xFF667788);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 17,
              color: accentColor,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            count,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: textGrey,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterRow extends StatelessWidget {
  final OfficerAvailability? selected;
  final ValueChanged<OfficerAvailability?> onSelected;

  const _StatusFilterRow({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(context, null, 'All'),
          ...OfficerAvailability.values.map(
            (s) => _chip(context, s, s.label),
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    OfficerAvailability? value,
    String label,
  ) {
    final isSelected = selected == value;

    const navy = Color(0xFF123E68);
    const cardBackground = Color(0xFFE1ECF3);
    const border = Color(0xFFD1DEE7);
    const textGrey = Color(0xFF667788);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : textGrey,
          ),
        ),
        selected: isSelected,
        selectedColor: navy,
        backgroundColor: cardBackground,
        side: BorderSide(
          color: isSelected ? navy : border,
        ),
        showCheckmark: false,
        onSelected: (_) => onSelected(value),
      ),
    );
  }
}