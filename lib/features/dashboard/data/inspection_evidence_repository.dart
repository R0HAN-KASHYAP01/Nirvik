import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class InspectionEvidenceRepository {
  InspectionEvidenceRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String bucketName = 'inspection-evidence';

  String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  Future<String> uploadEvidenceFile({
    required String assignmentId,
    required Uint8List fileBytes,
    required String fileExtension,
  }) async {
    final inspectorProfileId = getCurrentUserId();

    if (inspectorProfileId == null) {
      throw Exception('No authenticated inspector session was found.');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final sanitizedExtension = fileExtension
        .replaceAll('.', '')
        .trim()
        .toLowerCase();

    final extension = sanitizedExtension.isEmpty ? 'jpg' : sanitizedExtension;

    final storagePath =
        '$inspectorProfileId/$assignmentId/evidence_$timestamp.$extension';

    await _client.storage
        .from(bucketName)
        .uploadBinary(
          storagePath,
          fileBytes,
          fileOptions: FileOptions(upsert: false),
        );

    return storagePath;
  }

  Future<Map<String, dynamic>> saveEvidence({
    required String assignmentId,
    required String inspectorProfileId,
    required String instituteProfileId,
    required String storagePath,
    String? description,
  }) async {
    final response = await _client
        .from('pmu_inspection_evidence')
        .insert({
          'assignment_id': assignmentId,
          'inspector_profile_id': inspectorProfileId,
          'institute_profile_id': instituteProfileId,
          'storage_path': storagePath,
          'description': description,
        })
        .select()
        .single();

    return response;
  }

  Future<List<Map<String, dynamic>>> getEvidence(String assignmentId) async {
    final response = await _client
        .from('pmu_inspection_evidence')
        .select()
        .eq('assignment_id', assignmentId)
        .order('created_at', ascending: true);

    return response.whereType<Map<String, dynamic>>().toList();
  }
}
