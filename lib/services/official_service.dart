import 'package:supabase_flutter/supabase_flutter.dart';

class OfficialProfileData {
  final String fullName;
  final String? phone;
  final String status; // pending, approved, rejected
  final String department;
  final String? designation;
  final DateTime createdAt;
  final bool isOnline;
  final DateTime? lastSeen;

  const OfficialProfileData({
    required this.fullName,
    this.phone,
    required this.status,
    required this.department,
    this.designation,
    required this.createdAt,
    required this.isOnline,
    this.lastSeen,
  });

  factory OfficialProfileData.fromMaps({
    required Map<String, dynamic> profile,
    required Map<String, dynamic> official,
  }) {
    return OfficialProfileData(
      fullName: profile['full_name'] as String,
      phone: profile['phone'] as String?,
      status: profile['status'] as String,
      department: official['department'] as String,
      designation: official['designation'] as String?,
      createdAt: DateTime.parse(profile['created_at'] as String),
      isOnline: profile['is_online'] as bool? ?? false,
      lastSeen: profile['last_seen'] != null
          ? DateTime.parse(profile['last_seen'] as String)
          : null,
    );
  }
}

class OfficialService {
  OfficialService._();
  static final OfficialService instance = OfficialService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// Fetches the currently logged-in official's profile by joining
  /// `profiles` + `officials` on profile_id, scoped by RLS to auth.uid().
  Future<OfficialProfileData?> fetchCurrentProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;

    final profile = await _client
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();
    if (profile == null) return null;

    final official = await _client
        .from('officials')
        .select()
        .eq('profile_id', uid)
        .maybeSingle();
    if (official == null) return null;

    return OfficialProfileData.fromMaps(profile: profile, official: official);
  }
}