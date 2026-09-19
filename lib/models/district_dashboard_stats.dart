// FILE: lib/models/district_dashboard_stats.dart

/// "District Overview" counts for the District Administrator dashboard.
/// Populated from the district_dashboard_stats() RPC, which scopes every
/// number to the caller's own district + state server-side.
class DistrictDashboardStats {
  final int totalProjects;
  final int highRiskProjects;
  final int totalInspections;
  final int pendingInspections;
  final int completedInspections;
  final int assignedInspectors;

  const DistrictDashboardStats({
    required this.totalProjects,
    required this.highRiskProjects,
    required this.totalInspections,
    required this.pendingInspections,
    required this.completedInspections,
    required this.assignedInspectors,
  });

  factory DistrictDashboardStats.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) => value == null ? 0 : (value as num).toInt();

    return DistrictDashboardStats(
      totalProjects: asInt(json['total_projects']),
      highRiskProjects: asInt(json['high_risk_projects']),
      totalInspections: asInt(json['total_inspections']),
      pendingInspections: asInt(json['pending_inspections']),
      completedInspections: asInt(json['completed_inspections']),
      assignedInspectors: asInt(json['assigned_inspectors']),
    );
  }

  static const empty = DistrictDashboardStats(
    totalProjects: 0,
    highRiskProjects: 0,
    totalInspections: 0,
    pendingInspections: 0,
    completedInspections: 0,
    assignedInspectors: 0,
  );
}