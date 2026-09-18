// lib/features/mosje_admin/data/national_dashboard_repository.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/project.dart';
import '../../../models/scheme.dart';
import '../../projects/data/projects_repository.dart';
import '../../schemes/data/schemes_repository.dart';

/// Result of loading the national (MoSJE Admin) dashboard.
///
/// Every count here is derived from a real Supabase query. Where the
/// current schema does not support a metric, the corresponding field is
/// left `null` and `unavailableMetrics` explains why, instead of a fake
/// number being shown.
class NationalDashboardData {
  /// Total number of scheme *types* the system currently defines.
  ///
  /// This mirrors the existing [SchemeType] enum used throughout the
  /// app (see SchemesRepository) — it is a fixed constant (4), not a
  /// database table, because that's how schemes are modelled today.
  final int totalSchemeTypes;

  /// Total rows in the real `scheme_catalog` Supabase table (the
  /// actual named government schemes — Post-Matric Scholarship, PM
  /// YASASVI, SEED, PM-AJAY, SMILE, etc.).
  ///
  /// NOTE: this table exists in the database but, at the time this
  /// was written, no other part of the app queries it — the rest of
  /// the codebase labels `ngo_institutes.scheme_code` using a
  /// hardcoded duplicate list in `lib/utils/scheme_catalog.dart`
  /// instead. This field queries the real table directly so "Total
  /// Schemes" reflects the actual scheme catalog rather than the
  /// broader 4-category `SchemeType` grouping. It is shown alongside,
  /// not instead of, [totalSchemeTypes] so neither number is
  /// mislabeled. `null` if the table could not be read.
  final int? totalCatalogSchemes;

  /// Registered institutes/projects per scheme type (real data, from
  /// SchemesRepository.fetchSchemeCounts()).
  final Map<SchemeType, int> instituteCountsByScheme;

  /// Total projects/institutes nationally.
  final int totalProjects;

  /// Projects whose `ngo_institutes.risk_level` is high.
  ///
  /// NOTE: `ngo_institutes.risk_level` is a simple stored column, not
  /// the output of the full per-project Risk Engine (RiskDataRepository
  /// computes that on demand, one project at a time, and is not
  /// batchable today). This number reuses the existing risk_level
  /// column exactly as ProjectsRepository/ProjectListScreen already do
  /// for the "High Risk" filter, so it stays consistent with the rest
  /// of the app — but it can under-report true risk until every
  /// project has been scored by the Risk Engine at least once.
  final int highRiskProjectCount;
  final List<Project> highRiskProjects;

  /// Inspection compliance, computed from real `pmu_assignments` rows.
  final int totalAssignedInspections;
  final int completedInspections;
  final int inProgressInspections;
  final int pendingInspections; // status == 'assigned' (not yet started)
  final int overdueInspections; // status == 'expired'

  /// Open critical findings, computed from real
  /// `pmu_inspection_findings` rows.
  ///
  /// `pmu_inspection_findings` has no resolution/status column today,
  /// so — exactly like RiskDataRepository already does for the
  /// per-project risk engine — every matching finding is counted as
  /// open until the database adds one.
  final int openCriticalFindingsCount;

  /// Metrics that could not be computed from the current schema, and
  /// why, so the UI can show an honest "not available" state instead
  /// of a hardcoded/fake value.
  final List<String> unavailableMetrics;

  const NationalDashboardData({
    required this.totalSchemeTypes,
    required this.totalCatalogSchemes,
    required this.instituteCountsByScheme,
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
}

/// Aggregation repository for the MoSJE / National Admin dashboard.
///
/// This does NOT introduce new database tables or duplicate query
/// logic that already exists elsewhere — it composes
/// [SchemesRepository] and [ProjectsRepository], and adds only the two
/// national-scope queries (`pmu_assignments`, `pmu_inspection_findings`)
/// that no existing repository already exposes as an aggregate.
class NationalDashboardRepository {
  NationalDashboardRepository({
    SupabaseClient? client,
    SchemesRepository? schemesRepository,
    ProjectsRepository? projectsRepository,
  })  : _client = client ?? Supabase.instance.client,
        _schemesRepository = schemesRepository ?? SchemesRepository(),
        _projectsRepository =
            projectsRepository ?? ProjectsRepository(client: client);

  final SupabaseClient _client;
  final SchemesRepository _schemesRepository;
  final ProjectsRepository _projectsRepository;

  Future<NationalDashboardData> loadDashboard() async {
    final unavailable = <String>[];

    // ------------------------------------------------------------
    // Schemes (reuse SchemesRepository — no new query logic).
    // ------------------------------------------------------------
    Map<SchemeType, int> instituteCountsByScheme = const {};
    try {
      instituteCountsByScheme = await _schemesRepository.fetchSchemeCounts();
    } catch (e, st) {
      debugPrint('NationalDashboardRepository: scheme counts failed: $e\n$st');
      unavailable.add(
        'Institute counts by scheme could not be loaded.',
      );
    }

    // ------------------------------------------------------------
    // Real scheme_catalog table row count. This table exists in the
    // database but nothing else in the app queries it yet — see the
    // note on [NationalDashboardData.totalCatalogSchemes].
    // ------------------------------------------------------------
    int? totalCatalogSchemes;
    try {
      final rows = await _client.from('scheme_catalog').select('code');
      totalCatalogSchemes = (rows as List).length;
    } catch (e, st) {
      debugPrint(
        'NationalDashboardRepository: scheme_catalog count failed: $e\n$st',
      );
      unavailable.add(
        'Real scheme catalog count could not be loaded (scheme_catalog '
        'table query failed — verify the column name "code" matches '
        'the actual table schema).',
      );
    }

    // ------------------------------------------------------------
    // Projects (reuse ProjectsRepository — no new query logic).
    // ------------------------------------------------------------
    List<Project> projects = const [];
    try {
      projects = await _projectsRepository.getProjects();
    } catch (e, st) {
      debugPrint('NationalDashboardRepository: projects failed: $e\n$st');
      unavailable.add('Total projects could not be loaded.');
      unavailable.add('High-risk projects could not be loaded.');
    }

    final highRiskProjects =
        projects.where((p) => p.riskLevel == RiskLevel.high).toList();

    // ------------------------------------------------------------
    // Inspection compliance, from pmu_assignments.status.
    // Only the `status` column is fetched — no unnecessary payload.
    // ------------------------------------------------------------
    var totalAssigned = 0;
    var completed = 0;
    var inProgress = 0;
    var pending = 0;
    var overdue = 0;

    try {
      final rows =
          await _client.from('pmu_assignments').select('status');

      for (final row in rows as List) {
        totalAssigned++;

        final status = (row['status'] as String?)?.toLowerCase().trim();

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
        'NationalDashboardRepository: inspection compliance failed: $e\n$st',
      );
      unavailable.add('Inspection compliance could not be loaded.');
    }

    // ------------------------------------------------------------
    // Open critical findings, from pmu_inspection_findings.severity.
    // Same "no status column yet -> treat as open" convention already
    // used by RiskDataRepository.getProjectFindings/_buildProjectAggregate.
    // ------------------------------------------------------------
    var criticalFindings = 0;

    try {
      final rows = await _client
          .from('pmu_inspection_findings')
          .select('severity');

      for (final row in rows as List) {
        final severity =
            (row['severity'] as String?)?.toLowerCase().trim();

        if (severity == 'high' ||
            severity == 'critical' ||
            severity == 'severe') {
          criticalFindings++;
        }
      }
    } catch (e, st) {
      debugPrint(
        'NationalDashboardRepository: critical findings failed: $e\n$st',
      );
      unavailable.add('Open critical findings could not be loaded.');
    }

    // ------------------------------------------------------------
    // Total states: intentionally not computed.
    // ngo_institutes has no state/district column today, so there is
    // no real source of truth for this yet.
    // ------------------------------------------------------------
    unavailable.add(
      'Total states is not available yet — institutes/projects do not '
      'currently store a state or district field in the database.',
    );

    return NationalDashboardData(
      totalSchemeTypes: SchemeType.values.length,
      totalCatalogSchemes: totalCatalogSchemes,
      instituteCountsByScheme: instituteCountsByScheme,
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