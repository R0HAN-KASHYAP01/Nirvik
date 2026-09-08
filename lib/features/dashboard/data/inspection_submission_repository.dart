import 'package:supabase_flutter/supabase_flutter.dart';

class InspectionSubmissionRepository {
  InspectionSubmissionRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  Future<Map<String, dynamic>> saveSubmission({
    required String assignmentId,
    required String inspectorProfileId,
    required String instituteProfileId,
    required String overallStatus,
    required String riskLevel,
    String? inspectorRemarks,
    String? reportSummary,
  }) async {
    final response = await _client
        .from('pmu_inspection_submissions')
        .insert({
          'assignment_id': assignmentId,
          'inspector_profile_id': inspectorProfileId,
          'institute_profile_id': instituteProfileId,
          'overall_status': overallStatus,
          'risk_level': riskLevel,
          'inspector_remarks': inspectorRemarks,
          'report_summary': reportSummary,
        })
        .select()
        .single();

    return response;
  }

  Future<Map<String, dynamic>?> getSubmissionByAssignmentId(
    String assignmentId,
  ) async {
    final response = await _client
        .from('pmu_inspection_submissions')
        .select()
        .eq('assignment_id', assignmentId)
        .order('submitted_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response;
  }
}
