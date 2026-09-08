// lib/features/schemes/presentation/widgets/institute_list_item.dart
import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../models/institute.dart';
import '../../../../models/user.dart';
import '../../../calls/presentation/widgets/call_button.dart';
import 'institute_status_chip.dart';

class InstituteListItem extends StatelessWidget {
  final Institute institute;
  final VoidCallback onTap;

  const InstituteListItem({super.key, required this.institute, required this.onTap});

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final lastInspection = institute.lastInspection;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_outlined, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(institute.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(institute.category, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(institute.location, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastInspection == null
                        ? 'No inspections yet'
                        : 'Last Inspection: ${_formatDate(lastInspection.dateTime)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  InstituteStatusChip(status: institute.status),
                ],
              ),
            ),
            Column(
              children: [
                CallButton(
                  calleeId: institute.id,
                  calleeName: institute.name,
                  calleeRole: UserRole.ngoInstitute,
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}