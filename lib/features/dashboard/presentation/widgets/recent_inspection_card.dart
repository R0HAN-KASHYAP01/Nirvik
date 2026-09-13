import 'package:flutter/material.dart';
import '../../../../models/inspection.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../app/theme.dart';

class RecentInspectionCard extends StatelessWidget {
  final InspectionSummary inspection;

  const RecentInspectionCard({super.key, required this.inspection});

  Color get _statusColor {
    switch (inspection.status) {
      case InspectionStatus.approved:
        return AppColors.success;
      case InspectionStatus.overdue:
        return AppColors.error;
      case InspectionStatus.underReview:
        return AppColors.warning;
      case InspectionStatus.submitted:
        return AppColors.info;
      case InspectionStatus.inProgress:
        return Colors.indigo;
      case InspectionStatus.assigned:
        return Colors.blueGrey;
    }
  }

  Color get _riskColor {
    switch (inspection.risk) {
      case RiskLevel.high:
        return AppColors.error;
      case RiskLevel.medium:
        return AppColors.warning;
      case RiskLevel.low:
        return AppColors.success;
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month} · $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          inspection.projectName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Flexible(
                        child: StatusBadge(label: inspection.status.label, color: _statusColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Inspector: ${inspection.inspectorName}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.black38),
                      const SizedBox(width: 4),
                      // Flexible + ellipsis: lets the time text shrink
                      // instead of overflowing when combined with the risk
                      // badge below exceeds the available row width (narrow
                      // screens / large system font scale).
                      Flexible(
                        child: Text(
                          _formatTime(inspection.dateTime),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      // Flexible so the badge can compress rather than push
                      // the row past its bounds.
                      Flexible(
                        child: StatusBadge(label: '${inspection.risk.label} risk', color: _riskColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 18, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}