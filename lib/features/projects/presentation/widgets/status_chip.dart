import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../models/project.dart';

class StatusChip extends StatelessWidget {
  final ProjectStatus status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == ProjectStatus.active;
    final color = isActive ? AppColors.success : AppColors.warning;
    final label = isActive ? 'Active' : 'Under Review';
    return StatusBadge(label: label, color: color);
  }
}

class RiskChip extends StatelessWidget {
  final RiskLevel risk;
  const RiskChip({super.key, required this.risk});

  @override
  Widget build(BuildContext context) {
    late Color color;
    late String label;
    switch (risk) {
      case RiskLevel.low:
        color = AppColors.success;
        label = 'Low Risk';
        break;
      case RiskLevel.medium:
        color = AppColors.warning;
        label = 'Medium Risk';
        break;
      case RiskLevel.high:
        color = AppColors.error;
        label = 'High Risk';
        break;
    }
    return StatusBadge(label: label, color: color);
  }
}