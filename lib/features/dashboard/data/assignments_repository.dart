import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/assignment.dart';

/// Result of an assignment lifecycle action (currently: starting one).
class AssignmentActionResult {
  const AssignmentActionResult._({
    required this.success,
    this.assignment,
    this.message,
  });

  final bool success;
  final AssignmentSummary? assignment;
  final String? message;

  factory AssignmentActionResult.success(AssignmentSummary assignment) =>
      AssignmentActionResult._(success: true, assignment: assignment);

  factory AssignmentActionResult.failure(String message) =>
      AssignmentActionResult._(success: false, message: message);
}

/// Repository responsible for loading and updating PMU inspection
/// assignments from Supabase.
///
/// Main database table: pmu_assignments
/// Institute information is loaded from: ngo_institutes
///
/// IMPORTANT — masking model:
/// The institute's real name/address are still fetched here (the
/// inspector's SELECT policy already grants row-level access), but
/// AssignmentSummary exposes them only through `displayName` /
/// `displayLocation`, which stay masked until `startedAt` is set. UI
/// code must always use those getters, never `instituteName` /
/// `fullAddress` directly.
class AssignmentsRepository {
  AssignmentsRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Fetch assignments available to the currently authenticated
  /// inspector. Also lazily expires any assignment past its 2-day
  /// lifetime (except completed ones) before returning results.
  Future<List<AssignmentSummary>> getAssignments() async {
    final assignmentResponse = await _client
        .from('pmu_assignments')
        .select()
        .order('scheduled_datetime', ascending: true);

    final instituteResponse = await _client.from('ngo_institutes').select();

    var assignments = (assignmentResponse as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();

    assignments = await _expireStaleAssignments(assignments);

    final institutes = instituteResponse as List<dynamic>;
    final instituteMap = <String, Map<String, dynamic>>{};

    for (final row in institutes) {
      if (row is! Map<String, dynamic>) continue;

      final profileId = row['profile_id']?.toString();
      if (profileId == null || profileId.isEmpty) continue;

      instituteMap[profileId] = row;
    }

    return assignments
        .map((row) => _mapAssignmentRow(row, instituteMap))
        .toList();
  }

  /// Fetch one assignment by its database ID.
  Future<AssignmentSummary?> getAssignmentById(String assignmentId) async {
    final assignmentResponse = await _client
        .from('pmu_assignments')
        .select()
        .eq('id', assignmentId)
        .maybeSingle();

    if (assignmentResponse == null) {
      return null;
    }

    var row = Map<String, dynamic>.from(assignmentResponse);
    final expired = await _expireStaleAssignments([row]);
    row = expired.first;

    final instituteProfileId = row['institute_profile_id']?.toString();

    Map<String, dynamic>? institute;

    if (instituteProfileId != null && instituteProfileId.isNotEmpty) {
      final instituteResponse = await _client
          .from('ngo_institutes')
          .select()
          .eq('profile_id', instituteProfileId)
          .maybeSingle();

      institute = instituteResponse;
    }

    return _mapAssignmentRow(
      row,
      institute == null
          ? <String, Map<String, dynamic>>{}
          : <String, Map<String, dynamic>>{instituteProfileId!: institute},
    );
  }

  /// Start an assignment: gates on the 2 km radius, records
  /// `started_at` + `start_distance_km`, and flips status to
  /// 'in_progress'. This is what unlocks the real institute name and
  /// address, and kicks off the 1-hour geo-verification window.
  Future<AssignmentActionResult> startAssignment({
    required AssignmentSummary assignment,
    required double distanceKm,
  }) async {
    if (assignment.status == AssignmentStatus.completed) {
      return AssignmentActionResult.failure(
        'This assignment has already been completed.',
      );
    }

    if (assignment.status == AssignmentStatus.expired ||
        assignment.isPastLifetime) {
      return AssignmentActionResult.failure(
        'This assignment has expired and can no longer be started.',
      );
    }

    if (assignment.isStarted) {
      // Already started earlier (e.g. app was closed/reopened) — just
      // return the current state instead of erroring.
      final refreshed = await getAssignmentById(assignment.id);
      if (refreshed != null) {
        return AssignmentActionResult.success(refreshed);
      }
    }

    if (distanceKm > kAssignmentStartRadiusKm) {
      return AssignmentActionResult.failure(
        'You must be within ${kAssignmentStartRadiusKm.toStringAsFixed(0)} km '
        'of the institute to start this assignment. Current distance: '
        '${distanceKm.toStringAsFixed(2)} km.',
      );
    }

    final now = DateTime.now().toUtc();

    await _client
        .from('pmu_assignments')
        .update({
          'status': 'in_progress',
          'started_at': now.toIso8601String(),
          'start_distance_km': distanceKm,
        })
        .eq('id', assignment.id);

    final refreshed = await getAssignmentById(assignment.id);

    if (refreshed == null) {
      return AssignmentActionResult.failure(
        'Assignment was started but could not be reloaded. Please refresh.',
      );
    }

    return AssignmentActionResult.success(refreshed);
  }

  /// Mark an assignment as completed after the inspection has been
  /// successfully submitted.
  Future<void> markAssignmentCompleted(String assignmentId) async {
    await _client
        .from('pmu_assignments')
        .update({'status': 'completed'})
        .eq('id', assignmentId);
  }

  /// Lazily expire any non-completed, non-already-expired row whose
  /// 2-day lifetime has passed. Mutates the in-memory rows so the
  /// caller reflects 'expired' immediately, and best-effort persists
  /// the same change to Supabase.
  Future<List<Map<String, dynamic>>> _expireStaleAssignments(
    List<Map<String, dynamic>> rows,
  ) async {
    final nowUtc = DateTime.now().toUtc();
    final staleIds = <String>[];

    for (final row in rows) {
      final status = row['status']?.toString().toLowerCase();
      if (status == 'completed' || status == 'expired') continue;

      final expiresAt = _resolveExpiresAt(row);

      if (nowUtc.isAfter(expiresAt)) {
        final id = row['id']?.toString();
        if (id != null && id.isNotEmpty) {
          staleIds.add(id);
          row['status'] = 'expired';
        }
      }
    }

    if (staleIds.isNotEmpty) {
      try {
        await _client
            .from('pmu_assignments')
            .update({'status': 'expired'})
            .inFilter('id', staleIds);
      } catch (error) {
        // Non-fatal: UI already reflects 'expired' locally; a future
        // successful sync will persist it.
      }
    }

    return rows;
  }

  DateTime _resolveExpiresAt(Map<String, dynamic> row) {
    final rawExpiresAt = row['expires_at'];

    if (rawExpiresAt != null) {
      final parsed = DateTime.tryParse(rawExpiresAt.toString());
      if (parsed != null) return parsed.toUtc();
    }

    // Fallback for rows fetched before the migration runs.
    final createdAt = _parseDateTime(row['created_at']);
    return createdAt.toUtc().add(kAssignmentLifetime);
  }

  /// Convert a Supabase assignment row into the AssignmentSummary model.
  AssignmentSummary _mapAssignmentRow(
    Map<String, dynamic> row,
    Map<String, Map<String, dynamic>> instituteMap,
  ) {
    final assignmentId = row['id']?.toString() ?? '';
    final instituteProfileId = row['institute_profile_id']?.toString() ?? '';
    final institute = instituteMap[instituteProfileId];

    final instituteName = _stringValue(
      institute?['institute_name'],
      fallback: 'Unnamed Institute',
    );

    final fullAddress = _buildFullAddress(institute);
    final area = _buildArea(institute);

    final instituteLatitude = _parseCoordinate(institute?['latitude']);
    final instituteLongitude = _parseCoordinate(institute?['longitude']);

    final scheduledDateTime = _parseDateTime(row['scheduled_datetime']);
    final createdAt = _parseDateTime(row['created_at']);
    final startedAt = _parseNullableDateTime(row['started_at']);
    final expiresAt = _resolveExpiresAt(row);

    final priority = _parsePriority(row['priority']);
    final status = _parseStatus(row['status']);

    return AssignmentSummary(
      id: assignmentId,
      instituteProfileId: instituteProfileId,
      instituteName: instituteName,
      fullAddress: fullAddress,
      area: area,
      instituteLatitude: instituteLatitude,
      instituteLongitude: instituteLongitude,
      scheduledDateTime: scheduledDateTime,
      priority: priority,
      status: status,
      createdAt: createdAt,
      expiresAt: expiresAt,
      startedAt: startedAt,
    );
  }

  /// Full street address — only ever shown post-start.
  String _buildFullAddress(Map<String, dynamic>? institute) {
    if (institute == null) return 'Location not available';

    final address = institute['address']?.toString().trim();
    if (address != null && address.isNotEmpty) return address;

    final latitude = institute['latitude'];
    final longitude = institute['longitude'];
    if (latitude != null && longitude != null) return '$latitude, $longitude';

    return 'Location not available';
  }

  /// Coarse locality — safe to show pre-start. Prefers the dedicated
  /// `ngo_institutes.area` column; falls back to deriving the last 1-2
  /// comma-separated segments of the address for institutes that
  /// haven't had `area` backfilled yet.
  String _buildArea(Map<String, dynamic>? institute) {
    if (institute == null) return 'Area not available';

    final explicitArea = institute['area']?.toString().trim();
    if (explicitArea != null && explicitArea.isNotEmpty) return explicitArea;

    final address = institute['address']?.toString().trim();
    if (address != null && address.isNotEmpty) {
      final segments = address
          .split(',')
          .map((segment) => segment.trim())
          .where((segment) => segment.isNotEmpty)
          .toList();

      if (segments.length >= 2) {
        return segments.sublist(segments.length - 2).join(', ');
      }
      if (segments.isNotEmpty) return segments.last;
    }

    return 'Area not available';
  }

  double? _parseCoordinate(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Priority _parsePriority(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'high':
        return Priority.high;
      case 'medium':
        return Priority.medium;
      case 'low':
      default:
        return Priority.low;
    }
  }

  AssignmentStatus _parseStatus(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'in_progress':
      case 'in progress':
      case 'in-progress':
        return AssignmentStatus.inProgress;
      case 'expired':
        return AssignmentStatus.expired;
      case 'completed':
        return AssignmentStatus.completed;
      case 'assigned':
      default:
        return AssignmentStatus.assigned;
    }
  }

  DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;

    if (value != null) {
      final parsed = DateTime.tryParse(value.toString());
      if (parsed != null) return parsed;
    }

    return DateTime.now();
  }

  DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  String _stringValue(dynamic value, {required String fallback}) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return fallback;
    return text;
  }
}