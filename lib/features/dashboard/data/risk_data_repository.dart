import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository responsible for collecting the data required by the
/// Risk Engine.
///
/// IMPORTANT:
/// - This repository does NOT calculate risk.
/// - Risk calculation is handled by the Risk Engine.
/// - ngo_institutes does NOT contain a risk_level column.
/// - Historical inspection risk_level comes from
///   pmu_inspection_submissions.
/// - pmu_inspection_findings does NOT contain finding_type, so the
///   repository does not request or depend on that column.
class RiskDataRepository {
  final SupabaseClient _supabase;

  RiskDataRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  /// Collects all data required for project-level risk calculation.
  ///
  /// Returns:
  /// {
  ///   "project": {...},
  ///   "inspections": [...]
  /// }
  Future<Map<String, dynamic>> getProjectRiskInput(
    String instituteProfileId,
  ) async {
    final project = await getProjectRiskData(instituteProfileId);

    if (project == null) {
      throw Exception(
        'Project not found for institute profile: $instituteProfileId',
      );
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

    final aggregate = _buildProjectAggregate(
      project: project,
      assignments: assignments,
      inspections: inspections,
      findings: findings,
    );

    final inspectionInputs = _buildInspectionInputs(
      inspections: inspections,
      findings: findings,
    );

    return <String, dynamic>{
      'project': <String, dynamic>{
        ...project,
        'aggregate': aggregate,
      },
      'inspections': inspectionInputs,
    };
  }

  /// Gets basic project/institute information.
  Future<Map<String, dynamic>?> getProjectRiskData(
    String instituteProfileId,
  ) async {
    final response = await _supabase
        .from('ngo_institutes')
        .select('''
          profile_id,
          organization_id,
          registration_number,
          scheme_type,
          address,
          latitude,
          longitude,
          updated_at,
          institute_name,
          category,
          funds_allocated,
          funds_utilized,
          created_at
        ''')
        .eq('profile_id', instituteProfileId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Map<String, dynamic>.from(response);
  }

  /// Gets all assignments associated with a project.
  Future<List<Map<String, dynamic>>> getProjectAssignments(
    String instituteProfileId,
  ) async {
    final response = await _supabase
        .from('pmu_assignments')
        .select('''
          id,
          inspector_profile_id,
          institute_profile_id,
          scheduled_datetime,
          priority,
          status,
          created_at
        ''')
        .eq('institute_profile_id', instituteProfileId)
        .order('scheduled_datetime', ascending: false);

    return (response as List)
        .map(
          (row) => Map<String, dynamic>.from(row),
        )
        .toList();
  }

  /// Gets inspection submission history for a project.
  ///
  /// Historical risk_level is valid here because it belongs to
  /// pmu_inspection_submissions.
  Future<List<Map<String, dynamic>>> getProjectInspectionHistory(
    String instituteProfileId,
  ) async {
    final response = await _supabase
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

    return (response as List)
        .map(
          (row) => Map<String, dynamic>.from(row),
        )
        .toList();
  }

  /// Gets all findings belonging to the project's assignments.
  ///
  /// IMPORTANT:
  /// The current pmu_inspection_findings table does not contain
  /// `finding_type`, so it is intentionally NOT selected here.
     Future<List<Map<String, dynamic>>> getProjectFindings(
    String instituteProfileId,
  ) async {
    final assignments = await _supabase
        .from('pmu_assignments')
        .select('id')
        .eq('institute_profile_id', instituteProfileId);

    final assignmentIds = (assignments as List)
        .map((row) => row['id'])
        .where((id) => id != null)
        .map((id) => id.toString())
        .toList();

    if (assignmentIds.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final response = await _supabase
        .from('pmu_inspection_findings')
        .select('''
          id,
          assignment_id,
          inspector_profile_id,
          institute_profile_id,
          severity,
          description,
          created_at
        ''')
        .inFilter('assignment_id', assignmentIds)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (row) => Map<String, dynamic>.from(row),
        )
        .toList();
  }

  /// Builds project-level aggregate features.
  ///
  /// IMPORTANT:
  /// ngo_institutes does NOT have a risk_level column.
  /// Therefore risk_level is intentionally NOT read from the project.
  ///
  /// The current risk score/level must be generated by the Risk Engine.
  Map<String, dynamic> _buildProjectAggregate({
    required Map<String, dynamic> project,
    required List<Map<String, dynamic>> assignments,
    required List<Map<String, dynamic>> inspections,
    required List<Map<String, dynamic>> findings,
  }) {
    final totalInspections = inspections.length;

    final completedInspections = inspections.where((inspection) {
      final status = _normalizeInspectionStatus(
        inspection['overall_status'],
      );

      return status == 'completed' ||
          status == 'approved' ||
          status == 'submitted';
    }).length;

    final highRiskFindings = findings.where((finding) {
      final severity = finding['severity']
          ?.toString()
          .toLowerCase()
          .trim();

      return severity == 'high' ||
          severity == 'critical' ||
          severity == 'severe';
    }).length;

    // pmu_inspection_findings currently does not expose a finding
    // status column in this repository, so findings are treated as
    // open unless/until the database provides a status field.
    final openFindings = findings.length;

    final pendingAssignments = assignments.where((assignment) {
      final status = assignment['status']
          ?.toString()
          .toLowerCase()
          .trim();

      return status == 'assigned' ||
          status == 'in_progress' ||
          status == 'overdue';
    }).length;

    final completedAssignments = assignments.where((assignment) {
      final status = assignment['status']
          ?.toString()
          .toLowerCase()
          .trim();

      return status == 'completed';
    }).length;

    return <String, dynamic>{
      'status': _normalizeStatus(project['status']),
      'total_assignments': assignments.length,
      'pending_assignments': pendingAssignments,
      'completed_assignments': completedAssignments,
      'total_inspections': totalInspections,
      'completed_inspections': completedInspections,
      'high_risk_findings': highRiskFindings,
      'open_findings': openFindings,
      'inspection_submission_count': inspections.length,
      'finding_count': findings.length,
    };
  }

  /// Converts historical inspection data into the structure consumed
  /// by the Risk Engine.
  List<Map<String, dynamic>> _buildInspectionInputs({
    required List<Map<String, dynamic>> inspections,
    required List<Map<String, dynamic>> findings,
  }) {
    return inspections.map((inspection) {
      final assignmentId =
          inspection['assignment_id']?.toString();

      final inspectionFindings = findings.where((finding) {
        return finding['assignment_id']?.toString() ==
            assignmentId;
      }).toList();

      // The current findings table does not contain `finding_type`.
      //
      // Instead of fabricating a finding type, we use the number
      // of findings for this inspection as the available issue
      // signal. This keeps the Risk Engine input valid without
      // inventing database data.
      final repeatedIssueCount = inspectionFindings.length;

      return <String, dynamic>{
        'id': inspection['id'],
        'assignment_id': inspection['assignment_id'],
        'inspector_profile_id':
            inspection['inspector_profile_id'],
        'institute_profile_id':
            inspection['institute_profile_id'],
        'submitted_at': inspection['submitted_at'],
        'overall_status': _normalizeInspectionStatus(
          inspection['overall_status'],
        ),

        // Historical inspection risk.
        // This is NOT the current project risk.
        'risk_level': _normalizeRiskLevel(
          inspection['risk_level'],
        ),

        'inspector_remarks':
            inspection['inspector_remarks'],
        'report_summary':
            inspection['report_summary'],

        'open_finding_count':
            inspectionFindings.length,

        'repeated_issue_count':
            repeatedIssueCount,

        'finding_count':
            inspectionFindings.length,
      };
    }).toList();
  }

  /// Normalizes historical risk levels.
  ///
  /// Unknown/missing values are represented as "unknown".
  /// We do NOT silently convert missing risk information to "low".
  String _normalizeRiskLevel(dynamic value) {
    final normalized =
        value?.toString().toLowerCase().trim();

    switch (normalized) {
      case 'critical':
        return 'critical';

      case 'high':
        return 'high';

      case 'medium':
        return 'medium';

      case 'low':
        return 'low';

      default:
        return 'unknown';
    }
  }

  /// Normalizes project status.
  String _normalizeStatus(dynamic value) {
    final normalized =
        value?.toString().toLowerCase().trim();

    if (normalized == null || normalized.isEmpty) {
      return 'unknown';
    }

    return normalized;
  }

  /// Normalizes inspection submission status.
  String _normalizeInspectionStatus(dynamic value) {
    final normalized =
        value?.toString().toLowerCase().trim();

    switch (normalized) {
      case 'completed':
        return 'completed';

      case 'submitted':
        return 'submitted';

      case 'approved':
        return 'approved';

      case 'under_review':
      case 'under review':
        return 'under_review';

      case 'overdue':
        return 'overdue';

      case 'rejected':
        return 'rejected';

      case 'flagged':
        return 'flagged';

      default:
        return 'unknown';
    }
  }
}