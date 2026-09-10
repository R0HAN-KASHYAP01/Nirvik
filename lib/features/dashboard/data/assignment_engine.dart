import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Result returned after attempting to create an assignment.
class AssignmentEngineResult {
  const AssignmentEngineResult({
    required this.success,
    this.assignment,
    this.message,
  });

  final bool success;
  final Map<String, dynamic>? assignment;
  final String? message;
}

/// Handles inspector eligibility, workload evaluation,
/// location suitability, random selection,
/// duplicate-assignment prevention, and assignment creation.
///
/// Important:
/// - Risk is calculated by Member 1's Risk Engine.
/// - This class does NOT calculate risk.
/// - Existing Supabase RLS remains responsible for database authorization.
class AssignmentEngine {
  AssignmentEngine({
    SupabaseClient? client,
    Random? random,
  })  : _client = client ?? Supabase.instance.client,
        _random = random ?? Random();

  final SupabaseClient _client;
  final Random _random;

  /// Creates an assignment for the supplied institute.
  Future<AssignmentEngineResult> createAssignment({
    required String instituteProfileId,
    required double riskScore,
    required String riskLevel,
    required DateTime scheduledDateTime,
  }) async {
    try {
      final normalizedRiskLevel = _normalizeRiskLevel(riskLevel);

      if (normalizedRiskLevel == null) {
        return const AssignmentEngineResult(
          success: false,
          message: 'Invalid risk level received from Risk Engine.',
        );
      }

      final institute = await _getInstitute(instituteProfileId);

      if (institute == null) {
        return const AssignmentEngineResult(
          success: false,
          message: 'Institute not found.',
        );
      }

      // Prevent multiple active assignments for the same institute.
      final existingAssignment =
          await _getActiveAssignmentForInstitute(instituteProfileId);

      if (existingAssignment != null) {
        return AssignmentEngineResult(
          success: false,
          assignment: existingAssignment,
          message:
              'This institute already has an active inspection assignment.',
        );
      }

      final inspectors = await _getEligibleInspectors();

      if (inspectors.isEmpty) {
        return const AssignmentEngineResult(
          success: false,
          message: 'No eligible inspectors are currently available.',
        );
      }

      final candidates = await _buildCandidates(
        inspectors: inspectors,
        institute: institute,
      );

      if (candidates.isEmpty) {
        return const AssignmentEngineResult(
          success: false,
          message: 'No suitable inspectors are available for assignment.',
        );
      }

      final selectedInspector = _selectWeightedRandom(candidates);

      final priority = _priorityFromRisk(
        riskScore: riskScore,
        riskLevel: normalizedRiskLevel,
      );

      final assignment = await _insertAssignment(
        inspectorProfileId: selectedInspector.profileId,
        instituteProfileId: instituteProfileId,
        scheduledDateTime: scheduledDateTime,
        priority: priority,
      );

      return AssignmentEngineResult(
        success: true,
        assignment: assignment,
      );
    } on PostgrestException catch (error) {
      return AssignmentEngineResult(
        success: false,
        message: 'Database error: ${error.message}',
      );
    } catch (error) {
      return AssignmentEngineResult(
        success: false,
        message: 'Assignment failed: $error',
      );
    }
  }

  Future<Map<String, dynamic>?> _getInstitute(
    String instituteProfileId,
  ) async {
    final response = await _client
        .from('ngo_institutes')
        .select(
          'profile_id, institute_name, address, latitude, longitude',
        )
        .eq('profile_id', instituteProfileId)
        .maybeSingle();

    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  /// Find an existing active assignment for the institute.
  ///
  /// Completed assignments are excluded so the institute can be
  /// inspected again in future. Assignments past their 2-day
  /// `expires_at` are also excluded — they are released back to the
  /// pool automatically.
  Future<Map<String, dynamic>?> _getActiveAssignmentForInstitute(
    String instituteProfileId,
  ) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final response = await _client
        .from('pmu_assignments')
        .select(
          'id, inspector_profile_id, institute_profile_id, '
          'scheduled_datetime, priority, status, created_at',
        )
        .eq('institute_profile_id', instituteProfileId)
        .inFilter('status', <String>['assigned', 'in_progress'])
        .gt('expires_at', nowIso)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  /// Fetch inspectors who satisfy the existing authorization
  /// and availability requirements.
  Future<List<_InspectorCandidate>> _getEligibleInspectors() async {
    final response = await _client
        .from('profiles')
        .select(
          'id, full_name, role, status, is_online, last_seen',
        )
        .eq('role', 'pmu_inspector')
        .eq('status', 'approved')
        .eq('is_online', true);

    final rows = response as List<dynamic>;

    final now = DateTime.now().toUtc();

    final inspectors = <_InspectorCandidate>[];

    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;

      final profileId = row['id']?.toString();
      if (profileId == null || profileId.isEmpty) continue;

      final lastSeen = _parseDateTime(row['last_seen']);
      if (lastSeen == null) continue;

      final age = now.difference(lastSeen.toUtc());
      if (age.isNegative || age > const Duration(minutes: 2)) continue;

      final inspectorProfile = await _getInspectorProfile(profileId);
      if (inspectorProfile == null) continue;

      final activeAssignments = await _getActiveAssignmentCount(profileId);

      inspectors.add(
        _InspectorCandidate(
          profileId: profileId,
          fullName: row['full_name']?.toString() ?? 'Unnamed Inspector',
          latitude: _parseCoordinate(inspectorProfile['latitude']),
          longitude: _parseCoordinate(inspectorProfile['longitude']),
          activeAssignments: activeAssignments,
        ),
      );
    }

    return inspectors;
  }

  Future<Map<String, dynamic>?> _getInspectorProfile(
    String profileId,
  ) async {
    final response = await _client
        .from('pmu_inspectors')
        .select(
          'profile_id, department, designation, latitude, longitude, '
          'location_updated_at, region',
        )
        .eq('profile_id', profileId)
        .maybeSingle();

    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  /// Count only active assignments (not completed, not expired).
  Future<int> _getActiveAssignmentCount(
    String inspectorProfileId,
  ) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final response = await _client
        .from('pmu_assignments')
        .select('id')
        .eq('inspector_profile_id', inspectorProfileId)
        .inFilter('status', <String>['assigned', 'in_progress'])
        .gt('expires_at', nowIso);

    final rows = response as List<dynamic>;
    return rows.length;
  }

  Future<List<_InspectorCandidate>> _buildCandidates({
    required List<_InspectorCandidate> inspectors,
    required Map<String, dynamic> institute,
  }) async {
    final instituteLatitude = _parseCoordinate(institute['latitude']);
    final instituteLongitude = _parseCoordinate(institute['longitude']);

    final candidates = <_InspectorCandidate>[];

    for (final inspector in inspectors) {
      double? distanceKm;

      if (instituteLatitude != null &&
          instituteLongitude != null &&
          inspector.latitude != null &&
          inspector.longitude != null) {
        distanceKm = _distanceKm(
          instituteLatitude,
          instituteLongitude,
          inspector.latitude!,
          inspector.longitude!,
        );
      }

      final weight = _calculateSelectionWeight(
        activeAssignments: inspector.activeAssignments,
        distanceKm: distanceKm,
      );

      candidates.add(
        inspector.copyWith(
          distanceKm: distanceKm,
          selectionWeight: weight,
        ),
      );
    }

    return candidates;
  }

  double _calculateSelectionWeight({
    required int activeAssignments,
    required double? distanceKm,
  }) {
    final workloadFactor = 1.0 / (1.0 + activeAssignments);

    double distanceFactor = 1.0;
    if (distanceKm != null) {
      distanceFactor = 1.0 / (1.0 + distanceKm / 10.0);
    }

    return workloadFactor * distanceFactor;
  }

  _InspectorCandidate _selectWeightedRandom(
    List<_InspectorCandidate> candidates,
  ) {
    final positiveCandidates = candidates
        .where((candidate) => candidate.selectionWeight > 0)
        .toList();

    if (positiveCandidates.isEmpty) {
      return candidates[_random.nextInt(candidates.length)];
    }

    final totalWeight = positiveCandidates.fold<double>(
      0.0,
      (sum, candidate) => sum + candidate.selectionWeight,
    );

    if (totalWeight <= 0) {
      return positiveCandidates[_random.nextInt(positiveCandidates.length)];
    }

    var randomValue = _random.nextDouble() * totalWeight;

    for (final candidate in positiveCandidates) {
      randomValue -= candidate.selectionWeight;
      if (randomValue <= 0) return candidate;
    }

    return positiveCandidates.last;
  }

  String _priorityFromRisk({
    required double riskScore,
    required String riskLevel,
  }) {
    if (riskLevel == 'critical') return 'high';
    if (riskLevel == 'high' || riskScore >= 70) return 'high';
    if (riskLevel == 'medium' || riskScore >= 40) return 'medium';
    return 'low';
  }

  String? _normalizeRiskLevel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'low':
        return 'low';
      case 'medium':
        return 'medium';
      case 'high':
        return 'high';
      case 'critical':
        return 'critical';
      default:
        return null;
    }
  }

  double? _parseCoordinate(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  double _distanceKm(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) {
    const earthRadiusKm = 6371.0;

    final latitude1Radians = _toRadians(latitude1);
    final latitude2Radians = _toRadians(latitude2);
    final deltaLatitude = _toRadians(latitude2 - latitude1);
    final deltaLongitude = _toRadians(longitude2 - longitude1);

    final a = pow(sin(deltaLatitude / 2), 2) +
        cos(latitude1Radians) *
            cos(latitude2Radians) *
            pow(sin(deltaLongitude / 2), 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180.0;

  Future<Map<String, dynamic>> _insertAssignment({
    required String inspectorProfileId,
    required String instituteProfileId,
    required DateTime scheduledDateTime,
    required String priority,
  }) async {
    final response = await _client
        .from('pmu_assignments')
        .insert({
          'inspector_profile_id': inspectorProfileId,
          'institute_profile_id': instituteProfileId,
          'scheduled_datetime': scheduledDateTime.toUtc().toIso8601String(),
          'priority': priority,
          'status': 'assigned',
        })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }
}

class _InspectorCandidate {
  const _InspectorCandidate({
    required this.profileId,
    required this.fullName,
    required this.latitude,
    required this.longitude,
    required this.activeAssignments,
    this.distanceKm,
    this.selectionWeight = 0.0,
  });

  final String profileId;
  final String fullName;
  final double? latitude;
  final double? longitude;
  final int activeAssignments;
  final double? distanceKm;
  final double selectionWeight;

  _InspectorCandidate copyWith({
    double? distanceKm,
    double? selectionWeight,
  }) {
    return _InspectorCandidate(
      profileId: profileId,
      fullName: fullName,
      latitude: latitude,
      longitude: longitude,
      activeAssignments: activeAssignments,
      distanceKm: distanceKm ?? this.distanceKm,
      selectionWeight: selectionWeight ?? this.selectionWeight,
    );
  }
}