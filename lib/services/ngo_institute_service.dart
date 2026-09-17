// lib/services/ngo_institute_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ngo_institute_profile.dart';
import '../models/institute_map_point.dart';

class NgoInstituteService {
  NgoInstituteService._();
  static final NgoInstituteService instance = NgoInstituteService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// Returns null if the institute hasn't created a profile row yet.
  Future<NgoInstituteProfile?> fetchProfile(String profileId) async {
    final data = await _client
        .from('ngo_institutes')
        .select()
        .eq('profile_id', profileId)
        .maybeSingle();

    if (data == null) return null;
    return NgoInstituteProfile.fromMap(data);
  }

  /// Fetches the NGO / Institute organization name for a profile.
  ///
  /// Flow:
  /// profiles.id
  ///   -> ngo_institutes.profile_id
  ///   -> ngo_institutes.organization_id
  ///   -> organizations.id
  ///   -> organizations.name
  Future<String?> fetchOrganizationName(String profileId) async {
    final data = await _client
        .from('ngo_institutes')
        .select('organization_id, organizations(name)')
        .eq('profile_id', profileId)
        .maybeSingle();

    if (data == null) return null;

    final organization = data['organizations'];

    if (organization is Map<String, dynamic>) {
      final name = organization['name'];

      if (name is String && name.trim().isNotEmpty) {
        return name.trim();
      }
    }

    return null;
  }

  /// Read-only lookup of the scheme this institute registered with.
  /// Source of truth is institute_reps (set at registration, approved
  /// by admin) — never ngo_institutes, which the self-service profile
  /// screen must not write scheme data into.
  Future<Map<String, String?>?> fetchRegisteredScheme(
      String profileId,
      ) async {
    final data = await _client
        .from('institute_reps')
        .select('scheme_category, scheme_code')
        .eq('profile_id', profileId)
        .maybeSingle();

    if (data == null) return null;

    return {
      'scheme_category': data['scheme_category'] as String?,
      'scheme_code': data['scheme_code'] as String?,
    };
  }

  /// Insert-or-update in one call (profile_id is the primary key).
  Future<NgoInstituteProfile> upsertProfile(
      NgoInstituteProfile profile,
      ) async {
    final data = await _client
        .from('ngo_institutes')
        .upsert(profile.toMap())
        .select()
        .single();

    return NgoInstituteProfile.fromMap(data);
  }

  /// Fetches every institute with valid coordinates, joined with its
  /// organization name, for use on the monitoring map.
  ///
  /// Requires the `ngo_institutes_select_staff` RLS policy (staff-only
  /// read-all) to be present — callers without that access will only ever
  /// get their own row back, per RLS, not an error.
  Future<List<InstituteMapPoint>> fetchAllForMap() async {
    final rows = await _client
        .from('ngo_institutes')
        .select(
      'profile_id, organization_id, scheme_category, scheme_code, address, '
          'registration_number, latitude, longitude, organizations(name)',
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