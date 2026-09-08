import 'package:supabase_flutter/supabase_flutter.dart';

class InspectionChecklistRepository {
  InspectionChecklistRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  Future<void> saveChecklistResponses({
    required String assignmentId,
    required String inspectorProfileId,
    required String instituteProfileId,
    required List<Map<String, dynamic>> responses,
  }) async {
    if (responses.isEmpty) {
      return;
    }

    final rows = responses.map((response) {
      return {
        'assignment_id': assignmentId,
        'inspector_profile_id': inspectorProfileId,
        'institute_profile_id': instituteProfileId,
        'checklist_item_id': response['checklist_item_id'],
        'checklist_item_title': response['checklist_item_title'],
        'answer': response['answer'],
      };
    }).toList();

    await _client.from('pmu_inspection_checklist_responses').insert(rows);
  }

  Future<List<Map<String, dynamic>>> getChecklistResponses(
    String assignmentId,
  ) async {
    final response = await _client
        .from('pmu_inspection_checklist_responses')
        .select()
        .eq('assignment_id', assignmentId)
        .order('checklist_item_id', ascending: true);

    return response.whereType<Map<String, dynamic>>().toList();
  }
}
