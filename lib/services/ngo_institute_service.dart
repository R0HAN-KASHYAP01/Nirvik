import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ngo_institute_profile.dart';
import '../models/institute_map_point.dart';

class NgoInstituteService {
  NgoInstituteService._();

  static final NgoInstituteService instance = NgoInstituteService._();

  final SupabaseClient _client = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // FETCH PROFILE
  // ---------------------------------------------------------------------------

  Future<NgoInstituteProfile?> fetchProfile(String profileId) async {
    /*
     * institute_reps is now the source of truth for:
     * - registration number
     * - address
     * - latitude
     * - longitude
     *
     * We intentionally do not remove ngo_institutes support elsewhere in the
     * application.
     */

    final data = await _client
        .from('institute_reps')
        .select(
          'profile_id, registration_number, complete_address, '
          'latitude, longitude',
        )
        .eq('profile_id', profileId)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return NgoInstituteProfile(
      profileId: data['profile_id'] as String,
      registrationNumber: data['registration_number'] as String?,
      address: data['complete_address'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
    );
  }

  // ---------------------------------------------------------------------------
  // FETCH ORGANIZATION NAME
  // ---------------------------------------------------------------------------

  Future<String?> fetchOrganizationName(String profileId) async {
    final data = await _client
        .from('institute_reps')
        .select('organization_name')
        .eq('profile_id', profileId)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    final name = data['organization_name'];

    if (name is String && name.trim().isNotEmpty) {
      return name.trim();
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // FETCH REGISTERED SCHEME
  // ---------------------------------------------------------------------------

  Future<Map<String, String?>?> fetchRegisteredScheme(
    String profileId,
  ) async {
    final data = await _client
        .from('institute_reps')
        .select('scheme_category, scheme_code')
        .eq('profile_id', profileId)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return {
      'scheme_category': data['scheme_category'] as String?,
      'scheme_code': data['scheme_code'] as String?,
    };
  }

  // ---------------------------------------------------------------------------
  // SAVE PROFILE
  // ---------------------------------------------------------------------------

  Future<NgoInstituteProfile> upsertProfile(
    NgoInstituteProfile profile,
  ) async {
    /*
     * We UPDATE the existing institute_reps record.
     *
     * We deliberately do NOT upsert here because the Profile screen should
     * never create a new institute_reps row.
     *
     * The RLS policy:
     *
     *   auth.uid() = profile_id
     *
     * ensures an institute can update only its own record.
     */

    final data = await _client
        .from('institute_reps')
        .update({
          'registration_number': profile.registrationNumber,
          'complete_address': profile.address,
          'latitude': profile.latitude,
          'longitude': profile.longitude,
        })
        .eq('profile_id', profile.profileId)
        .select(
          'profile_id, registration_number, complete_address, '
          'latitude, longitude',
        )
        .single();

    return NgoInstituteProfile(
      profileId: data['profile_id'] as String,
      registrationNumber: data['registration_number'] as String?,
      address: data['complete_address'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
    );
  }

  // ---------------------------------------------------------------------------
  // MAP DATA
  // ---------------------------------------------------------------------------

  Future<List<InstituteMapPoint>> fetchAllForMap() async {
    /*
     * Keep the existing map implementation based on ngo_institutes.
     *
     * We are not changing the map architecture in this step.
     */
    final rows = await _client
        .from('ngo_institutes')
        .select(
          'profile_id, organization_id, scheme_category, scheme_code, '
          'address, registration_number, latitude, longitude, '
          'organizations(name)',
        )
        .not('latitude', 'is', null)
        .not('longitude', 'is', null);

    final points = <InstituteMapPoint>[];

    for (final row in rows as List) {
      final point = InstituteMapPoint.tryFromMap(
        row as Map<String, dynamic>,
      );

      if (point != null) {
        points.add(point);
      }
    }

    return points;
  }
}