import 'package:supabase_flutter/supabase_flutter.dart';

class InspectionFindingsRepository {
  InspectionFindingsRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  Future<Map<String, dynamic>> saveFinding({
    required String assignmentId,
    required String inspectorProfileId,
    required String instituteProfileId,
    required String title,
    required String category,
    required String severity,
    String? description,
    String? recommendation,
    String status = 'open',
  }) async {
    final response = await _client
        .from('pmu_inspection_findings')
        .insert({
          'assignment_id': assignmentId,
          'inspector_profile_id': inspectorProfileId,
          'institute_profile_id': instituteProfileId,
          'title': title,
          'description': description,
          'category': category,
          'severity': severity,
          'recommendation': recommendation,
          'status': status,
        })
        .select()
        .single();

    return response;
  }

  Future<List<Map<String, dynamic>>> getFindings(String assignmentId) async {
    final response = await _client
        .from('pmu_inspection_findings')
        .select()
        .eq('assignment_id', assignmentId)
        .order('created_at', ascending: true);

    return response.whereType<Map<String, dynamic>>().toList();
  }
}
