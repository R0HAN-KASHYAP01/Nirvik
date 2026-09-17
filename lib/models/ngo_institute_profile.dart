// lib/models/ngo_institute_profile.dart

class NgoInstituteProfile {
  final String profileId;
  final String? organizationId;
  final String? registrationNumber;
  final String? address;
  final double? latitude;
  final double? longitude;

  const NgoInstituteProfile({
    required this.profileId,
    this.organizationId,
    this.registrationNumber,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory NgoInstituteProfile.fromMap(Map<String, dynamic> map) {
    return NgoInstituteProfile(
      profileId: map['profile_id'] as String,
      organizationId: map['organization_id'] as String?,
      registrationNumber: map['registration_number'] as String?,
      address: map['address'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  /// Used for `upsert`. `profile_id` is the PK, so Supabase will insert
  /// a new row the first time and update it on every save afterwards.
  ///
  /// Deliberately does NOT include scheme_category/scheme_code — scheme
  /// is fixed at registration (institute_reps) and approved by admin;
  /// this self-service screen must never be able to overwrite it.
  Map<String, dynamic> toMap() {
    return {
      'profile_id': profileId,
      if (organizationId != null) 'organization_id': organizationId,
      'registration_number': registrationNumber,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  NgoInstituteProfile copyWith({
    String? organizationId,
    String? registrationNumber,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return NgoInstituteProfile(
      profileId: profileId,
      organizationId: organizationId ?? this.organizationId,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}