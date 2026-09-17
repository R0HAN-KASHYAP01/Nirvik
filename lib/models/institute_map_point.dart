// lib/models/institute_map_point.dart

/// Read-only data for displaying an institute on the map.
/// Kept separate from [NgoInstituteProfile] because that model's `toMap()`
/// is used for `upsert` into `ngo_institutes` — adding joined fields to
/// it would break that insert/update path.
class InstituteMapPoint {
  final String profileId;
  final String? organizationId;
  final String name;
  final String? address;
  final String? registrationNumber;
  final String? schemeCategory;
  final String? schemeCode;
  final double latitude;
  final double longitude;

  const InstituteMapPoint({
    required this.profileId,
    this.organizationId,
    required this.name,
    this.address,
    this.registrationNumber,
    this.schemeCategory,
    this.schemeCode,
    required this.latitude,
    required this.longitude,
  });

  /// Returns null (instead of throwing) when coordinates are missing or
  /// invalid, so the caller can safely skip bad records.
  static InstituteMapPoint? tryFromMap(Map<String, dynamic> map) {
    final lat = (map['latitude'] as num?)?.toDouble();
    final lng = (map['longitude'] as num?)?.toDouble();

    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;

    final orgData = map['organizations'];
    final orgName = (orgData is Map) ? orgData['name'] as String? : null;

    return InstituteMapPoint(
      profileId: map['profile_id'] as String,
      organizationId: map['organization_id'] as String?,
      name: (orgName != null && orgName.trim().isNotEmpty) ? orgName : 'Unnamed Institute',
      address: map['address'] as String?,
      registrationNumber: map['registration_number'] as String?,
      schemeCategory: map['scheme_category'] as String?,
      schemeCode: map['scheme_code'] as String?,
      latitude: lat,
      longitude: lng,
    );
  }
}