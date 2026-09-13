import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../models/project.dart';
import 'status_chip.dart';

class ProjectListItem extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const ProjectListItem({
    super.key,
    required this.project,
    required this.onTap,
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    final cardPadding = screenWidth < 360 ? 12.0 : 14.0;
    final iconBoxSize = screenWidth < 360 ? 48.0 : 56.0;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AppCard(
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Institute icon
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.apartment,
                color: AppColors.primary,
                size: screenWidth < 360 ? 24 : 26,
              ),
            ),

            const SizedBox(width: 10),

            // Main content
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project name
                  Text(
                    project.name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  const SizedBox(height: 3),

                  // Project type
                  Text(
                    project.type,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 7),

                  // Location
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),

                      // IMPORTANT:
                      // Expanded prevents long locations from
                      // overflowing horizontally.
                      Expanded(
                        child: Text(
                          project.location,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  // Last inspection
                  Text(
                    'Last Inspection: ${_formatDate(project.lastInspectionDate)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),

                  const SizedBox(height: 9),

                  // Status + Risk
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

            // Right arrow
            const SizedBox(width: 4),

            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}