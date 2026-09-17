// FILE: lib/services/inspector_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Combined `profiles` + `inspectors` data for the authenticated inspector.
class InspectorProfileData {
  final String profileId;
  final String fullName;
  final String officialEmail;
  final String mobileNumber;
  final String status; // pending, approved, rejected
  final String pmuUnitName;
  final String inspectorId;
  final String designation;
  final String department;
  final String state;
  final String district;
  final String assignedRegion;
  final String? schemeCategory;
  final String? schemeCode;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
  final DateTime? locationUpdatedAt;

  const InspectorProfileData({
    required this.profileId,
    required this.fullName,
    required this.officialEmail,
    required this.mobileNumber,
    required this.status,
    required this.pmuUnitName,
    required this.inspectorId,
    required this.designation,
    required this.department,
    required this.state,
    required this.district,
    required this.assignedRegion,
    this.schemeCategory,
    this.schemeCode,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.locationUpdatedAt,
  });

  bool get hasLocation => latitude != null && longitude != null;

  factory InspectorProfileData.fromMaps({
    required Map<String, dynamic> profile,
    required Map<String, dynamic> inspector,
  }) {
    return InspectorProfileData(
      profileId: profile['id'] as String,
      fullName: profile['full_name'] as String,
      officialEmail: inspector['official_email'] as String? ?? '—',
      mobileNumber: inspector['mobile_number'] as String? ?? '—',
      status: profile['status'] as String,
      pmuUnitName: inspector['pmu_unit_name'] as String? ?? '—',
      inspectorId: inspector['inspector_id'] as String? ?? '—',
      designation: inspector['designation'] as String? ?? '—',
      department: inspector['department'] as String? ?? '—',
      state: inspector['state'] as String? ?? '—',
      district: inspector['district'] as String? ?? '—',
      assignedRegion: inspector['assigned_region'] as String? ?? '—',
      schemeCategory: inspector['scheme_category'] as String?,
      schemeCode: inspector['scheme_code'] as String?,
      createdAt: DateTime.parse(profile['created_at'] as String),
      latitude: (inspector['latitude'] as num?)?.toDouble(),
      longitude: (inspector['longitude'] as num?)?.toDouble(),
      locationUpdatedAt: inspector['location_updated_at'] != null
          ? DateTime.parse(inspector['location_updated_at'] as String)
          : null,
    );
  }

  InspectorProfileData copyWithLocation({
    required double latitude,
    required double longitude,
    required DateTime locationUpdatedAt,
  }) {
    return InspectorProfileData(
      profileId: profileId,
      fullName: fullName,
      officialEmail: officialEmail,
      mobileNumber: mobileNumber,
      status: status,
      pmuUnitName: pmuUnitName,
      inspectorId: inspectorId,
      designation: designation,
      department: department,
      state: state,
      district: district,
      assignedRegion: assignedRegion,
      schemeCategory: schemeCategory,
      schemeCode: schemeCode,
      createdAt: createdAt,
      latitude: latitude,
      longitude: longitude,
      locationUpdatedAt: locationUpdatedAt,
    );
  }
}

class InspectorService {
  InspectorService._();
  static final InspectorService instance = InspectorService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// Loads the currently authenticated inspector's combined profile.
  /// Returns null if not logged in, not an inspector, or the
  /// `inspectors` row hasn't been created yet.
  Future<InspectorProfileData?> fetchCurrentProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;

    final profile = await _client.from('profiles').select().eq('id', uid).maybeSingle();
    if (profile == null) return null;

    final inspector = await _client.from('inspectors').select().eq('profile_id', uid).maybeSingle();
    if (inspector == null) return null;

    return InspectorProfileData.fromMaps(profile: profile, inspector: inspector);
  }

  /// Persists a newly detected GPS position to the inspector's own row.
  /// Requires the `inspectors_update_own` RLS policy from the migration.
  Future<DateTime> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Not authenticated.');
    }
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      throw ArgumentError('Invalid coordinates.');
    }

    final now = DateTime.now().toUtc();
    await _client.from('inspectors').update({
      'latitude': latitude,
      'longitude': longitude,
      'location_updated_at': now.toIso8601String(),
    }).eq('profile_id', uid);

    return now;
  }
}