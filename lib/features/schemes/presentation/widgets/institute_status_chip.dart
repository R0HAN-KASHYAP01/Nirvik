import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../models/institute.dart';

class InstituteStatusChip extends StatelessWidget {
  final InstituteStatus status;
  const InstituteStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    late Color color;
    switch (status) {
      case InstituteStatus.active:
        color = AppColors.success;
        break;
      case InstituteStatus.underReview:
        color = AppColors.warning;
        break;
      case InstituteStatus.suspended:
        color = AppColors.error;
        break;
    }
    return StatusBadge(label: status.label, color: color);
  }
}