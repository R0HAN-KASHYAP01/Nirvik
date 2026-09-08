import 'package:supabase_flutter/supabase_flutter.dart';

class ArrivalVerificationRepository {
  ArrivalVerificationRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  Future<Map<String, dynamic>> saveArrivalVerification({
    required String assignmentId,
    required String inspectorProfileId,
    required String instituteProfileId,
    required DateTime verifiedAt,
    required double inspectorLatitude,
    required double inspectorLongitude,
    required double distanceKm,
  }) async {
    final response = await _client
        .from('pmu_arrival_verifications')
        .insert({
          'assignment_id': assignmentId,
          'inspector_profile_id': inspectorProfileId,
          'institute_profile_id': instituteProfileId,
          'verified_at': verifiedAt.toUtc().toIso8601String(),
          'inspector_latitude': inspectorLatitude,
          'inspector_longitude': inspectorLongitude,
          'distance_km': distanceKm,
          'status': 'verified',
        })
        .select()
        .single();

    return response;
  }

  Future<Map<String, dynamic>?> getVerificationByAssignmentId(
    String assignmentId,
  ) async {
    final response = await _client
        .from('pmu_arrival_verifications')
        .select()
        .eq('assignment_id', assignmentId)
        .order('verified_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response;
  }
}
