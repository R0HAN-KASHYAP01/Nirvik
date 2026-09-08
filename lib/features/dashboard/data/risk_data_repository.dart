
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository responsible for collecting and normalizing the real
/// Supabase data required by the Sentinal Risk Engine.
///
/// This class does NOT calculate the final risk score.
/// Risk calculation remains the responsibility of the Python
/// Risk Engine.
///
/// Data flow:
///
/// Supabase
///   ├── ngo_institutes
///   ├── pmu_assignments
///   ├── pmu_inspection_submissions
///   └── pmu_inspection_findings
///             ↓
///     normalized project data
///             ↓
///     FastAPI Risk Engine
class RiskDataRepository {
  RiskDataRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Fetches all institutes/projects available to the current
  /// Supabase client.
  ///
  /// This is useful for project-level risk inspection and testing.
  Future<List<Map<String, dynamic>>> getInstitutes() async {
    final response = await _client
        .from('ngo_institutes')
        .select()
        .order('created_at', ascending: false);

    return response
        .whereType<Map<String, dynamic>>()
        .map(Map<String, dynamic>.from)
        .toList();
  }

  /// Fetch all risk-related data for one institute.
  ///
  /// The returned structure is ready to be passed into
  /// AiAttendanceService.calculateProjectRisk().
  Future<Map<String, dynamic>?> getProjectRiskInput(
    String instituteProfileId,
  ) async {
    if (instituteProfileId.trim().isEmpty) {
      throw ArgumentError(
        'instituteProfileId cannot be empty.',
      );
    }

    final project = await getProjectRiskData(
      instituteProfileId,
    );

    if (project == null) {
      return null;
    }

    final assignments = await getProjectAssignments(
      instituteProfileId,
    );

    final inspections = await getProjectInspectionHistory(
      instituteProfileId,
    );

    final findings = await getProjectFindings(
      instituteProfileId,
    );

    final projectData = _buildProjectAggregate(
      project: project,
      assignments: assignments,
      inspections: inspections,
      findings: findings,
    );

    final inspectionData = _buildInspectionInputs(
      inspections: inspections,
      findings: findings,
    );

    return <String, dynamic>{
      'project': projectData,
      'inspections': inspectionData,
      'assignments': assignments,
      'findings': findings,
    };
  }

  /// Fetch one institute/project by its profile ID.
  Future<Map<String, dynamic>?> getProjectRiskData(
    String instituteProfileId,
  ) async {
    if (instituteProfileId.trim().isEmpty) {
      throw ArgumentError(
        'instituteProfileId cannot be empty.',
      );
    }

    final response = await _client
        .from('ngo_institutes')
        .select()
        .eq('profile_id', instituteProfileId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Map<String, dynamic>.from(response);
  }

  /// Fetch all assignments belonging to one institute.
  Future<List<Map<String, dynamic>>> getProjectAssignments(
    String instituteProfileId,
  ) async {
    if (instituteProfileId.trim().isEmpty) {
      throw ArgumentError(
        'instituteProfileId cannot be empty.',
      );
    }

    final response = await _client
        .from('pmu_assignments')
        .select('''
          id,
          institute_profile_id,
          scheduled_datetime,
          priority,
          status
        ''')
        .eq('institute_profile_id', instituteProfileId)
        .order('scheduled_datetime', ascending: false);

    return response
        .whereType<Map<String, dynamic>>()
        .map(Map<String, dynamic>.from)
        .toList();
  }

  /// Fetch all submitted inspection history for one institute.
  Future<List<Map<String, dynamic>>> getProjectInspectionHistory(
    String instituteProfileId,
  ) async {
    if (instituteProfileId.trim().isEmpty) {
      throw ArgumentError(
        'instituteProfileId cannot be empty.',
      );
    }

    final response = await _client
        .from('pmu_inspection_submissions')
        .select('''
          id,
          assignment_id,
          inspector_profile_id,
          institute_profile_id,
          submitted_at,
          overall_status,
          risk_level,
          inspector_remarks,
          report_summary
        ''')
        .eq('institute_profile_id', instituteProfileId)
        .order('submitted_at', ascending: false);

    return response
        .whereType<Map<String, dynamic>>()
        .map(Map<String, dynamic>.from)
        .toList();
  }

  /// Fetch all findings associated with the institute's assignments.
  Future<List<Map<String, dynamic>>> getProjectFindings(
    String instituteProfileId,
  ) async {
    if (instituteProfileId.trim().isEmpty) {
      throw ArgumentError(
        'instituteProfileId cannot be empty.',
      );
    }

    final assignments = await getProjectAssignments(
      instituteProfileId,
    );

    if (assignments.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final assignmentIds = assignments
        .map((row) => row['id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();

    if (assignmentIds.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final response = await _client
        .from('pmu_inspection_findings')
        .select('''
          id,
          assignment_id,
          inspector_profile_id,
          institute_profile_id,
          title,
          description,
          category,
          severity,
          recommendation,
          status,
          created_at
        ''')
        .inFilter('assignment_id', assignmentIds)
        .order('created_at', ascending: false);

    return response
        .whereType<Map<String, dynamic>>()
        .map(Map<String, dynamic>.from)
        .toList();
  }

  /// Converts raw project, assignment, inspection and finding data
  /// into the structure expected by the Python Risk Engine.
  Map<String, dynamic> _buildProjectAggregate({
    required Map<String, dynamic> project,
    required List<Map<String, dynamic>> assignments,
    required List<Map<String, dynamic>> inspections,
    required List<Map<String, dynamic>> findings,
  }) {
    final totalInspections = assignments.length;

    final completedInspections = assignments.where((assignment) {
      final status = _normalizeText(
        assignment['status'],
      );

      return status == 'completed';
    }).length;

    final pendingInspections = assignments.where((assignment) {
      final status = _normalizeText(
        assignment['status'],
      );

      return status != 'completed';
    }).length;

    final highRiskFindings = findings.where((finding) {
      final severity = _normalizeText(
        finding['severity'],
      );

      return severity == 'high' || severity == 'critical';
    }).length;

    return <String, dynamic>{
      'status': _normalizeStatus(project['status']),
      'risk_level': _normalizeRiskLevel(
        project['risk_level'],
      ),
      'total_inspections': totalInspections,
      'completed_inspections': completedInspections,
      'pending_inspections': pendingInspections,
      'high_risk_findings': highRiskFindings,
      'inspection_submission_count': inspections.length,
      'finding_count': findings.length,
    };
  }

  /// Converts inspection history and findings into the structure
  /// expected by the Python anomaly detector.
  List<Map<String, dynamic>> _buildInspectionInputs({
    required List<Map<String, dynamic>> inspections,
    required List<Map<String, dynamic>> findings,
  }) {
    final findingsByAssignment =
        <String, List<Map<String, dynamic>>>{};

    for (final finding in findings) {
      final assignmentId = finding['assignment_id']?.toString();

      if (assignmentId == null || assignmentId.isEmpty) {
        continue;
      }

      findingsByAssignment
          .putIfAbsent(
            assignmentId,
            () => <Map<String, dynamic>>[],
          )
          .add(finding);
    }

    return inspections.map((inspection) {
      final assignmentId =
          inspection['assignment_id']?.toString() ?? '';

      final inspectionFindings =
          findingsByAssignment[assignmentId] ??
          <Map<String, dynamic>>[];

      final openFindingCount = inspectionFindings.where((finding) {
        final status = _normalizeText(
          finding['status'],
        );

        return status == 'open' ||
            status == 'pending' ||
            status == 'unresolved';
      }).length;

      final repeatedIssueCount =
          _calculateRepeatedIssueCount(
            inspectionFindings,
          );

      return <String, dynamic>{
        'risk_level': _normalizeRiskLevel(
          inspection['risk_level'],
        ),
        'status': _normalizeInspectionStatus(
          inspection['overall_status'],
        ),
        'findings': inspectionFindings.map((finding) {
          return <String, dynamic>{
            'status': _normalizeText(
              finding['status'],
            ),
            'title': finding['title']?.toString() ?? '',
            'severity': _normalizeText(
              finding['severity'],
            ),
            'category': finding['category']?.toString() ?? '',
          };
        }).toList(),
        'open_finding_count': openFindingCount,
        'repeated_issue_count': repeatedIssueCount,
      };
    }).toList();
  }

  /// Counts repeated finding categories within one inspection.
  int _calculateRepeatedIssueCount(
    List<Map<String, dynamic>> findings,
  ) {
    final categoryCounts = <String, int>{};

    for (final finding in findings) {
      final category = finding['category']?.toString().trim();

      if (category == null || category.isEmpty) {
        continue;
      }

      final normalized = category.toLowerCase();

      categoryCounts[normalized] =
          (categoryCounts[normalized] ?? 0) + 1;
    }

    var repeatedCount = 0;

    for (final count in categoryCounts.values) {
      if (count > 1) {
        repeatedCount += count - 1;
      }
    }

    return repeatedCount;
  }

  String _normalizeText(dynamic value) {
    return value?.toString().trim().toLowerCase() ?? '';
  }

  String _normalizeStatus(dynamic value) {
    final status = _normalizeText(value);

    switch (status) {
      case 'active':
        return 'active';

      case 'under_review':
      case 'under review':
      case 'review':
        return 'under_review';

      case 'inactive':
        return 'inactive';

      default:
        return 'unknown';
    }
  }

  String _normalizeRiskLevel(dynamic value) {
    final risk = _normalizeText(value);

    switch (risk) {
      case 'low':
        return 'low';

      case 'medium':
        return 'medium';

      case 'high':
        return 'high';

      case 'critical':
        return 'critical';

      default:
        return 'low';
    }
  }

  String _normalizeInspectionStatus(dynamic value) {
    final status = _normalizeText(value);

    switch (status) {
      case 'completed':
      case 'submitted':
      case 'approved':
      case 'under_review':
      case 'under review':
      case 'overdue':
      case 'rejected':
      case 'flagged':
        return status.replaceAll(' ', '_');

      default:
        return status.isEmpty ? 'unknown' : status;
    }
  }
}

