import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../models/scheme.dart';

class SchemeCard extends StatelessWidget {
  final Scheme scheme;
  final int instituteCount;
  final VoidCallback onTap;

  const SchemeCard({
    super.key,
    required this.scheme,
    required this.instituteCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: scheme.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(scheme.icon, color: scheme.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(scheme.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(scheme.description, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 10),
                  StatusBadge(
                    label: '$instituteCount institute${instituteCount == 1 ? '' : 's'}',
                    color: scheme.color,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}