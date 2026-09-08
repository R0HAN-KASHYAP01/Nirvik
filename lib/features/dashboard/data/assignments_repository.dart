import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/assignment.dart';

/// Repository responsible for loading and updating PMU inspection
/// assignments from Supabase.
///
/// Main database table:
/// pmu_assignments
///
/// Institute information is loaded from:
/// ngo_institutes
///
/// The repository converts database rows into AssignmentSummary
/// objects used by the Assignments UI.
class AssignmentsRepository {
  AssignmentsRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Fetch assignments available to the currently authenticated
  /// inspector.
  ///
  /// Supabase RLS is responsible for restricting the returned
  /// assignments to assignments the current inspector can access.
  Future<List<AssignmentSummary>> getAssignments() async {
    final assignmentResponse = await _client
        .from('pmu_assignments')
        .select()
        .order('scheduled_datetime', ascending: true);

    final instituteResponse = await _client.from('ngo_institutes').select();

    final assignments = assignmentResponse as List<dynamic>;
    final institutes = instituteResponse as List<dynamic>;

    final instituteMap = <String, Map<String, dynamic>>{};

    for (final row in institutes) {
      if (row is! Map<String, dynamic>) {
        continue;
      }

      final profileId = row['profile_id']?.toString();

      if (profileId == null || profileId.isEmpty) {
        continue;
      }

      instituteMap[profileId] = row;
    }

    return assignments
        .whereType<Map<String, dynamic>>()
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

    final instituteProfileId = assignmentResponse['institute_profile_id']
        ?.toString();

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
      assignmentResponse,
      institute == null
          ? <String, Map<String, dynamic>>{}
          : <String, Map<String, dynamic>>{instituteProfileId!: institute},
    );
  }

  /// Mark an assignment as completed after the inspection
  /// has been successfully submitted.
  Future<void> markAssignmentCompleted(String assignmentId) async {
    await _client
        .from('pmu_assignments')
        .update({'status': 'completed'})
        .eq('id', assignmentId);
  }

  /// Convert a Supabase assignment row into the existing
  /// AssignmentSummary model.
  AssignmentSummary _mapAssignmentRow(
    Map<String, dynamic> row,
    Map<String, Map<String, dynamic>> instituteMap,
  ) {
    final assignmentId = row['id']?.toString() ?? '';

    final instituteProfileId = row['institute_profile_id']?.toString() ?? '';

    final institute = instituteMap[instituteProfileId];

    final projectName = _stringValue(
      institute?['institute_name'],
      fallback: 'Unnamed Institute',
    );

    final location = _buildLocation(institute);

    final instituteLatitude = _parseCoordinate(institute?['latitude']);

    final instituteLongitude = _parseCoordinate(institute?['longitude']);

    final scheduledDateTime = _parseDateTime(row['scheduled_datetime']);

    final priority = _parsePriority(row['priority']);

    final status = _parseStatus(row['status']);

    return AssignmentSummary(
      id: assignmentId,
      instituteProfileId: instituteProfileId,
      projectName: projectName,
      location: location,
      instituteLatitude: instituteLatitude,
      instituteLongitude: instituteLongitude,
      scheduledDateTime: scheduledDateTime,
      priority: priority,
      status: status,
    );
  }

  /// Build a readable location from the institute row.
  String _buildLocation(Map<String, dynamic>? institute) {
    if (institute == null) {
      return 'Location not available';
    }

    final address = institute['address']?.toString().trim();

    if (address != null && address.isNotEmpty) {
      return address;
    }

    final latitude = institute['latitude'];
    final longitude = institute['longitude'];

    if (latitude != null && longitude != null) {
      return '$latitude, $longitude';
    }

    return 'Location not available';
  }

  /// Safely convert a database coordinate into a double.
  double? _parseCoordinate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  /// Convert database priority text into Priority enum.
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

  /// Convert database status text into AssignmentStatus.
  AssignmentStatus _parseStatus(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'in_progress':
      case 'in progress':
      case 'in-progress':
        return AssignmentStatus.inProgress;

      case 'overdue':
        return AssignmentStatus.overdue;

      case 'completed':
        return AssignmentStatus.completed;

      case 'assigned':
      default:
        return AssignmentStatus.assigned;
    }
  }

  /// Safely parse a database timestamp.
  DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    if (value != null) {
      final parsed = DateTime.tryParse(value.toString());

      if (parsed != null) {
        return parsed;
      }
    }

    return DateTime.now();
  }

  /// Convert a database value into a non-empty string.
  String _stringValue(dynamic value, {required String fallback}) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return fallback;
    }

    return text;
  }
}
