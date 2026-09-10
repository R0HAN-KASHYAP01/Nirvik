import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user.dart';

class NgoReport {
  final String id;
  final String title;
  final String? description;
  final String? attachmentPath;
  final DateTime createdAt;

  NgoReport({
    required this.id,
    required this.title,
    this.description,
    this.attachmentPath,
    required this.createdAt,
  });

  factory NgoReport.fromMap(Map<String, dynamic> map) {
    return NgoReport(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      attachmentPath: map['attachment_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class NgoReportsService {
  NgoReportsService._();

  static final NgoReportsService instance = NgoReportsService._();

  final SupabaseClient _client = Supabase.instance.client;

  Future<void> submitReport({
    required AppUser user,
    required String title,
    String? description,
    String? attachmentPath,
  }) async {
    await _client.from('ngo_reports').insert({
      'profile_id': user.id,
      'organization_id': user.organizationId,
      'title': title,
      'description': description,
      'attachment_path': attachmentPath,
    });
  }

  Future<List<NgoReport>> fetchReports(
    String profileId,
  ) async {
    final rows = await _client
        .from('ngo_reports')
        .select()
        .eq('profile_id', profileId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map(
          (r) => NgoReport.fromMap(
            r as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// Returns only reports created today.
  Future<List<NgoReport>> fetchTodayReports(
    String profileId,
  ) async {
    final now = DateTime.now();

    final startOfToday = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final startOfTomorrow = startOfToday.add(
      const Duration(days: 1),
    );

    final rows = await _client
        .from('ngo_reports')
        .select()
        .eq('profile_id', profileId)
        .gte(
          'created_at',
          startOfToday.toUtc().toIso8601String(),
        )
        .lt(
          'created_at',
          startOfTomorrow.toUtc().toIso8601String(),
        )
        .order('created_at', ascending: false);

    return (rows as List)
        .map(
          (r) => NgoReport.fromMap(
            r as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}