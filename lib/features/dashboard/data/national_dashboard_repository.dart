import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/project.dart';
import '../../projects/data/projects_repository.dart';

/// Data used by the combined DoSJE / MoSJE Official Dashboard.
///
/// This is the single dashboard data source for the national-level
/// monitoring screen.
///
/// Removed from this dashboard:
/// - Scheme catalog
/// - Scheme categories
/// - State/state_name lookup
/// - PMU Monitoring screen-specific data
///
/// Retained:
/// - Projects
/// - High-risk projects
/// - Inspection compliance
/// - Inspection status breakdown
/// - Critical findings
class NationalDashboardData {
  final int totalProjects;
  final int highRiskProjectCount;
  final List<Project> highRiskProjects;

  final int totalAssignedInspections;
  final int completedInspections;
  final int inProgressInspections;
  final int pendingInspections;
  final int overdueInspections;

  final int openCriticalFindingsCount;

  final List<String> unavailableMetrics;

  const NationalDashboardData({
    required this.totalProjects,
    required this.highRiskProjectCount,
    required this.highRiskProjects,
    required this.totalAssignedInspections,
    required this.completedInspections,
    required this.inProgressInspections,
    required this.pendingInspections,
    required this.overdueInspections,
    required this.openCriticalFindingsCount,
    required this.unavailableMetrics,
  });

  double get complianceRate {
    if (totalAssignedInspections == 0) {
      return 0;
    }

    return completedInspections / totalAssignedInspections;
  }
}

/// Single repository for the combined Official / MoSJE dashboard.
///
/// Important:
/// This repository intentionally does NOT query:
/// - scheme_catalog
/// - ngo_institutes.state
/// - ngo_institutes.state_name
/// - profiles.state
/// - profiles.state_name
///
/// Therefore the dashboard will no longer generate PostgreSQL
/// "column does not exist" errors for those fields.
class NationalDashboardRepository {
  NationalDashboardRepository({
    SupabaseClient? client,
    ProjectsRepository? projectsRepository,
  })  : _client = client ?? Supabase.instance.client,
        _projectsRepository =
            projectsRepository ?? ProjectsRepository(client: client);

  final SupabaseClient _client;
  final ProjectsRepository _projectsRepository;

  Future<NationalDashboardData> loadDashboard() async {
    final unavailable = <String>[];

    // ------------------------------------------------------------
    // PROJECTS
    // ------------------------------------------------------------

    List<Project> projects = const [];

    try {
      projects = await _projectsRepository.getProjects();
    } catch (e, st) {
      debugPrint(
        'NationalDashboardRepository: projects failed: $e\n$st',
      );

      unavailable.add(
        'Project data could not be loaded.',
      );
    }

    final highRiskProjects = projects
        .where(
          (project) => project.riskLevel == RiskLevel.high,
        )
        .toList();

    // ------------------------------------------------------------
    // INSPECTION COMPLIANCE
    // ------------------------------------------------------------

    var totalAssigned = 0;
    var completed = 0;
    var inProgress = 0;
    var pending = 0;
    var overdue = 0;

    try {
      final rows = await _client
          .from('pmu_assignments')
          .select('status');

      for (final row in rows as List) {
        totalAssigned++;

        final status = row['status']
            ?.toString()
            .trim()
            .toLowerCase();

        switch (status) {
          case 'completed':
            completed++;
            break;

          case 'in_progress':
          case 'in progress':
          case 'in-progress':
            inProgress++;
            break;

          case 'expired':
          case 'overdue':
            overdue++;
            break;

          case 'assigned':
          default:
            pending++;
            break;
        }
      }
    } catch (e, st) {
      debugPrint(
        'NationalDashboardRepository: inspection compliance failed: '
        '$e\n$st',
      );

      unavailable.add(
        'Inspection compliance could not be loaded.',
      );
    }

    // ------------------------------------------------------------
    // CRITICAL FINDINGS
    // ------------------------------------------------------------

    var criticalFindings = 0;

    try {
      final rows = await _client
          .from('pmu_inspection_findings')
          .select('severity');

      for (final row in rows as List) {
        final severity = row['severity']
            ?.toString()
            .trim()
            .toLowerCase();

        if (severity == 'high' ||
            severity == 'critical' ||
            severity == 'severe') {
          criticalFindings++;
        }
      }
    } catch (e, st) {
      debugPrint(
        'NationalDashboardRepository: critical findings failed: '
        '$e\n$st',
      );

      unavailable.add(
        'Critical findings could not be loaded.',
      );
    }

    return NationalDashboardData(
      totalProjects: projects.length,
      highRiskProjectCount: highRiskProjects.length,
      highRiskProjects: highRiskProjects,
      totalAssignedInspections: totalAssigned,
      completedInspections: completed,
      inProgressInspections: inProgress,
      pendingInspections: pending,
      overdueInspections: overdue,
      openCriticalFindingsCount: criticalFindings,
      unavailableMetrics: unavailable,
    );
  }
}