import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../models/project.dart';
import '../../dashboard/presentation/risk_intelligence_screen.dart';
import 'widgets/status_chip.dart';

class ProjectDetailsScreen extends StatelessWidget {
  final Project project;

  const ProjectDetailsScreen({
    super.key,
    required this.project,
  });

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall,
                ),
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(
    BuildContext context,
    String label,
    String value, {
    Color? color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(
                  color:
                      color ?? AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall,
          ),
        ],
      ),
    );
  }

  void _openRiskIntelligence(
    BuildContext context,
  ) {
    if (project.profileId == null ||
        project.profileId!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Risk intelligence is unavailable because this project has no Supabase profile ID.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RiskIntelligenceScreen(
          project: project,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            16,
            20,
            24,
          ),
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: 0.08,
                    ),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.apartment,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        project.id,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          StatusChip(
                            status: project.status,
                          ),
                          RiskChip(
                            risk: project.riskLevel,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionHeader(
              title: 'Overview',
            ),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                children: [
                  _infoRow(
                    context,
                    Icons.category_outlined,
                    'Project Type',
                    project.type,
                  ),
                  _infoRow(
                    context,
                    Icons.flag_outlined,
                    'Status',
                    project.statusLabel,
                  ),
                  _infoRow(
                    context,
                    Icons.shield_outlined,
                    'Risk Level',
                    project.riskLabel,
                  ),
                  _infoRow(
                    context,
                    Icons.event_outlined,
                    'Last Inspection',
                    _formatDate(
                      project.lastInspectionDate,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(
              title: 'Project Incharge',
            ),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                children: [
                  _infoRow(
                    context,
                    Icons.person_outline,
                    'Name',
                    project.inchargeName,
                  ),
                  _infoRow(
                    context,
                    Icons.badge_outlined,
                    'Role',
                    project.inchargeRole,
                  ),
                  _infoRow(
                    context,
                    Icons.call_outlined,
                    'Phone',
                    project.inchargePhone,
                  ),
                  _infoRow(
                    context,
                    Icons.email_outlined,
                    'Email',
                    project.inchargeEmail,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(
              title: 'Location',
            ),
            const SizedBox(height: 10),
            AppCard(
              child: _infoRow(
                context,
                Icons.place_outlined,
                'Address',
                project.location,
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(
              title: 'Inspection Summary',
            ),
            const SizedBox(height: 10),
            AppCard(
              child: Row(
                children: [
                  _statTile(
                    context,
                    'Total',
                    '${project.totalInspections}',
                  ),
                  _statTile(
                    context,
                    'Completed',
                    '${project.completedInspections}',
                    color: AppColors.success,
                  ),
                  _statTile(
                    context,
                    'Pending',
                    '${project.pendingInspections}',
                    color: AppColors.warning,
                  ),
                  _statTile(
                    context,
                    'High-Risk',
                    '${project.highRiskFindings}',
                    color: AppColors.error,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(
              title: 'Recent Inspections',
            ),
            const SizedBox(height: 10),
            ...project.recentInspections.map(
              (r) => Padding(
                padding:
                    const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(r.date),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Inspector: ${r.inspectorName}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              r.status,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall,
                            ),
                          ],
                        ),
                      ),
                      RiskChip(risk: r.risk),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(
              title: 'Project Risk',
            ),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RiskChip(
                        risk: project.riskLevel,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          project.riskLevel ==
                                  RiskLevel.high
                              ? 'This project has active high-risk findings requiring review.'
                              : project.riskLevel ==
                                      RiskLevel.medium
                                  ? 'This project has moderate risk factors under monitoring.'
                                  : 'This project currently has no significant risk factors.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: project.profileId == null ||
                              project.profileId!
                                  .trim()
                                  .isEmpty
                          ? null
                          : () => _openRiskIntelligence(
                                context,
                              ),
                      icon: const Icon(
                        Icons.analytics_outlined,
                      ),
                      label: const Text(
                        'View AI Risk Intelligence',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}