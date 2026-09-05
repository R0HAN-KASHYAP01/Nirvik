// lib/features/dashboard/presentation/widgets/pmu_officer_card.dart
import 'package:flutter/material.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../models/pmu_officer_summary.dart';
import '../../../../models/user.dart';
import '../../../calls/presentation/widgets/call_button.dart';

class PmuOfficerCard extends StatelessWidget {
  final PmuOfficerSummary officer;
  final VoidCallback? onTap;

  const PmuOfficerCard({super.key, required this.officer, this.onTap});

  Color _availabilityColor(OfficerAvailability a) {
    switch (a) {
      case OfficerAvailability.available:
        return const Color(0xFF1E7A46); // AppColors.success
      case OfficerAvailability.assigned:
        return const Color(0xFF2A5C8A); // AppColors.info
      case OfficerAvailability.inInspection:
        return const Color(0xFFB56B00); // AppColors.warning
      case OfficerAvailability.offline:
        return const Color(0xFF5B6472); // AppColors.textSecondary
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = [officer.designation, officer.department]
        .where((e) => e != null)
        .join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(officer.name, style: Theme.of(context).textTheme.titleMedium),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (officer.region != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.place_outlined, size: 13, color: Colors.black38),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                officer.region!,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusBadge(
                      label: officer.availability.label,
                      color: _availabilityColor(officer.availability),
                    ),
                    CallButton(
                      calleeId: officer.id,
                      calleeName: officer.name,
                      calleeRole: UserRole.inspector,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _MiniStat(icon: Icons.assignment_outlined, label: '${officer.assignmentsCount} Assignments'),
                _MiniStat(icon: Icons.fact_check_outlined, label: '${officer.completedInspectionsCount} Completed'),
                if (officer.pendingInspectionsCount > 0)
                  _MiniStat(icon: Icons.pending_outlined, label: '${officer.pendingInspectionsCount} Pending'),
                if (officer.overdueInspectionsCount > 0)
                  _MiniStat(
                    icon: Icons.error_outline,
                    label: '${officer.overdueInspectionsCount} Overdue',
                    color: Colors.redAccent,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MiniStat({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: c),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}