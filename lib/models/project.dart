enum ProjectStatus { active, underReview }

enum RiskLevel { low, medium, high }

class InspectionRecord {
  final DateTime date;
  final String inspectorName;
  final String status;
  final RiskLevel risk;

  const InspectionRecord({
    required this.date,
    required this.inspectorName,
    required this.status,
    required this.risk,
  });
}

class Project {
  /// Display/project identifier.
  ///
  /// Usually this is the registration number.
  final String id;

  /// Supabase ngo_institutes.profile_id.
  ///
  /// This is the stable identifier used when loading
  /// project-specific assignments, inspections, findings,
  /// and risk data.
  final String? profileId;

  final String name;
  final String type;
  final String location;
  final ProjectStatus status;
  final RiskLevel riskLevel;
  final DateTime lastInspectionDate;

  final String inchargeName;
  final String inchargeRole;
  final String inchargePhone;
  final String inchargeEmail;

  final int totalInspections;
  final int completedInspections;
  final int pendingInspections;
  final int highRiskFindings;

  final List<InspectionRecord> recentInspections;

  const Project({
    required this.id,
    this.profileId,
    required this.name,
    required this.type,
    required this.location,
    required this.status,
    required this.riskLevel,
    required this.lastInspectionDate,
    required this.inchargeName,
    required this.inchargeRole,
    required this.inchargePhone,
    required this.inchargeEmail,
    required this.totalInspections,
    required this.completedInspections,
    required this.pendingInspections,
    required this.highRiskFindings,
    required this.recentInspections,
  });

  String get statusLabel {
    switch (status) {
      case ProjectStatus.active:
        return 'Active';
      case ProjectStatus.underReview:
        return 'Under Review';
    }
  }

  String get riskLabel {
    switch (riskLevel) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.medium:
        return 'Medium Risk';
      case RiskLevel.high:
        return 'High Risk';
    }
  }
}