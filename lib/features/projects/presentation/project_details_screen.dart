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

  String _formatDate(DateTime date) {
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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  softWrap: true,
                  style: Theme.of(context).textTheme.bodyLarge,
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
    return Container(
      constraints: const BoxConstraints(
        minHeight: 72,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(
                    color: color ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
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

  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    final iconSize = screenWidth < 360 ? 48.0 : 56.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.apartment,
            color: AppColors.primary,
            size: screenWidth < 360 ? 24 : 28,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.name,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium,
              ),

              const SizedBox(height: 4),

              Text(
                project.id,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 9),

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
    );
  }

  Widget _buildInspectionSummary(BuildContext context) {
    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          /*
           * On narrow phones, use a 2 x 2 layout.
           * On wider screens, use all 4 statistics in one row.
           */
          final isNarrow = constraints.maxWidth < 430;

          if (isNarrow) {
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.65,
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
            );
          }

          return Row(
            children: [
              Expanded(
                child: _statTile(
                  context,
                  'Total',
                  '${project.totalInspections}',
                ),
              ),
              Expanded(
                child: _statTile(
                  context,
                  'Completed',
                  '${project.completedInspections}',
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _statTile(
                  context,
                  'Pending',
                  '${project.pendingInspections}',
                  color: AppColors.warning,
                ),
              ),
              Expanded(
                child: _statTile(
                  context,
                  'High-Risk',
                  '${project.highRiskFindings}',
                  color: AppColors.error,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    final horizontalPadding = screenWidth < 360 ? 12.0 : 20.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            16,
            horizontalPadding,
            24,
          ),
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            _buildHeader(context),

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
                    _formatDate(project.lastInspectionDate),
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

            _buildInspectionSummary(context),

            const SizedBox(height: 24),

            const SectionHeader(
              title: 'Recent Inspections',
            ),

            const SizedBox(height: 10),

            ...project.recentInspections.map(
              (inspection) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(inspection.date),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),

                            const SizedBox(height: 3),

                            Text(
                              'Inspector: ${inspection.inspectorName}',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium,
                            ),

                            const SizedBox(height: 3),

                            Text(
                              inspection.status,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      Flexible(
                        child: Align(
                          alignment: Alignment.topRight,
                          child: RiskChip(
                            risk: inspection.risk,
                          ),
                        ),
                      ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RiskChip(
                        risk: project.riskLevel,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          project.riskLevel == RiskLevel.high
                              ? 'This project has active high-risk findings requiring review.'
                              : project.riskLevel == RiskLevel.medium
                                  ? 'This project has moderate risk factors under monitoring.'
                                  : 'This project currently has no significant risk factors.',
                          softWrap: true,
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
                              project.profileId!.trim().isEmpty
                          ? null
                          : () => _openRiskIntelligence(context),
                      icon: const Icon(
                        Icons.analytics_outlined,
                      ),
                      label: const Text(
                        'View AI Risk Intelligence',
                        overflow: TextOverflow.ellipsis,
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