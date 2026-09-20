// FILE: lib/features/district_admin/data/district_inspector_repository.dart
//
// All inspector- and dashboard-related reads/writes for the District
// Administrator go through the RPC functions defined in
// supabase/district_admin_inspectors.sql and
// supabase/district_admin_dashboard_stats.sql. Those functions enforce
// "own district + state only" on the server, so nothing here needs to (or
// can) widen access.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/district_inspector.dart';
import '../../../models/district_dashboard_stats.dart';

/// A failure with a message that is safe to show to the user as-is.
class DistrictInspectorException implements Exception {
  const DistrictInspectorException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DistrictInspectorRepository {
  DistrictInspectorRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Approved inspectors in the admin's own district + state.
  Future<List<DistrictInspector>> fetchInspectors() async {
    try {
      final response = await _client.rpc('district_list_inspectors');
      return _rows(response).map(DistrictInspector.fromJson).toList();
    } on PostgrestException catch (e) {
      throw DistrictInspectorException(_describe(e, feature: 'Inspector'));
    }
  }

  /// Active assignments for institutes in the admin's district, keyed by
  /// institute profile id.
  Future<Map<String, InstituteAssignmentInfo>> fetchActiveAssignments() async {
    try {
      final response = await _client.rpc('district_active_assignments');
      final map = <String, InstituteAssignmentInfo>{};
      for (final row in _rows(response)) {
        final info = InstituteAssignmentInfo.fromJson(row);
        // Rows come back newest first; keep the newest per institute.
        map.putIfAbsent(info.instituteProfileId, () => info);
      }
      return map;
    } on PostgrestException catch (e) {
      throw DistrictInspectorException(_describe(e, feature: 'Assignment'));
    }
  }

  /// Creates the assignment and returns its id. [priority] is one of
  /// 'low' | 'medium' | 'high'.
  Future<String> assignInspector({
    required String instituteProfileId,
    required String inspectorProfileId,
    required DateTime scheduledDateTime,
    required String priority,
  }) async {
    try {
      final response = await _client.rpc(
        'district_assign_inspector',
        params: {
          'p_institute_profile_id': instituteProfileId,
          'p_inspector_profile_id': inspectorProfileId,
          'p_scheduled_datetime': scheduledDateTime.toUtc().toIso8601String(),
          'p_priority': priority,
        },
      );
      return response.toString();
    } on PostgrestException catch (e) {
      throw DistrictInspectorException(_describe(e, feature: 'Assignment'));
    }
  }

  /// Aggregate counts for the "District Overview" cards — total
  /// institutes, high-risk institutes (from each institute's latest
  /// inspection submission), inspection totals, and how many distinct
  /// inspectors currently hold an active assignment. Scoped server-side
  /// to the admin's own district + state.
  Future<DistrictDashboardStats> fetchDashboardStats() async {
    try {
      final response = await _client.rpc('district_dashboard_stats');
      final rows = _rows(response);
      if (rows.isEmpty) return DistrictDashboardStats.empty;
      return DistrictDashboardStats.fromJson(rows.first);
    } on PostgrestException catch (e) {
      throw DistrictInspectorException(_describe(e, feature: 'Dashboard stats'));
    }
  }

  /// Profile ids of every institute (from `institute_reps`) inside the
  /// admin's own district + state — used to filter the shared
  /// [InstituteMap] widget down to this district only.
  Future<Set<String>> fetchScopedInstituteProfileIds() async {
    try {
      final response = await _client.rpc('district_scoped_institute_ids');
      return _rows(response)
          .map((row) => row['profile_id']?.toString())
          .whereType<String>()
          .toSet();
    } on PostgrestException catch (e) {
      throw DistrictInspectorException(_describe(e, feature: 'District map'));
    }
  }

  List<Map<String, dynamic>> _rows(dynamic response) {
    if (response is! List) return const [];
    return response.whereType<Map<String, dynamic>>().toList();
  }

  String _describe(PostgrestException e, {required String feature}) {
    // PGRST202 / 42883: the function does not exist yet.
    if (e.code == 'PGRST202' || e.code == '42883') {
      return '$feature features are not set up in the database yet. '
          'Run the SQL files in supabase/ in the Supabase SQL editor.';
    }
    return e.message;
  }
}