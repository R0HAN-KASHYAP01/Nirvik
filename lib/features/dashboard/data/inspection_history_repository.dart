import 'package:supabase_flutter/supabase_flutter.dart';

class InspectionHistoryRepository {
  InspectionHistoryRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  Future<List<Map<String, dynamic>>> getInspectionHistory() async {
    final inspectorProfileId = getCurrentUserId();

    if (inspectorProfileId == null) {
      throw Exception('No authenticated inspector session was found.');
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
          report_summary,
          pmu_assignments (
            scheduled_datetime,
            priority,
            status
          )
        ''')
        .eq('inspector_profile_id', inspectorProfileId)
        .order('submitted_at', ascending: false);

    return response.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>?> getInspectionById(
    String submissionId,
  ) async {
    final inspectorProfileId = getCurrentUserId();

    if (inspectorProfileId == null) {
      throw Exception('No authenticated inspector session was found.');
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
          report_summary,
          pmu_assignments (
            scheduled_datetime,
            priority,
            status
          )
        ''')
        .eq('id', submissionId)
        .eq('inspector_profile_id', inspectorProfileId)
        .maybeSingle();

    return response;
  }
}