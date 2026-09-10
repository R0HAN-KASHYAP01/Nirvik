import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/assignment.dart';
import '../../../models/inspection.dart';
import '../../../models/pmu_officer_summary.dart';

/// Fetches PMU/inspection officer data from Supabase.
///
/// [fetchOfficers] runs a small, fixed number of bulk queries — never one
/// query per officer — so cost stays flat regardless of how many officers
/// or assignments exist. Callers must fetch once (e.g. in initState) and
/// re-fetch only via explicit pull-to-refresh/retry, never on a timer.
class PmuMonitoringRepository {
  final SupabaseClient _client = Supabase.instance.client;

  RiskLevel _riskFromDb(String? value) {
    switch (value) {
      case 'high':
        return RiskLevel.high;
      case 'medium':
        return RiskLevel.medium;
      default:
        return RiskLevel.low;
    }
  }

  /// `overdue` is no longer a first-class AssignmentStatus. Any legacy
  /// 'overdue' value still sitting in the database is treated the same
  /// as 'expired' so old rows don't crash mapping.
  AssignmentStatus _assignmentStatusFromDb(String value) {
    switch (value) {
      case 'in_progress':
        return AssignmentStatus.inProgress;
      case 'completed':
        return AssignmentStatus.completed;
      case 'expired':
      case 'overdue':
        return AssignmentStatus.expired;
      case 'assigned':
      default:
        return AssignmentStatus.assigned;
    }
  }

  Priority _priorityFromDb(String? value) {
    switch (value) {
      case 'high':
        return Priority.high;
      case 'low':
        return Priority.low;
      default:
        return Priority.medium;
    }
  }

  /// Converts a database coordinate value into a nullable double.
  double? _parseCoordinate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  /// Splits a full address into a coarse, non-identifying "area" string
  /// (e.g. "Sector 12, Dwarka" from "H.No. 4, Sector 12, Dwarka, Delhi").
  /// There is no dedicated "area" column in ngo_institutes yet, so this
  /// is derived. If you add a real `area` column later, read it directly
  /// instead of calling this.
  String _deriveArea(String fullAddress) {
    final parts = fullAddress.split(',').map((p) => p.trim()).toList();
    if (parts.length <= 2) return fullAddress;
    return parts.sublist(parts.length - 2).join(', ');
  }

  /// Derived from current assignments rather than stored, so it can never
  /// drift out of sync. No online/offline presence tracking exists yet, so
  /// this only distinguishes by current workload — everyone with no active
  /// assignment shows as "Available".
  OfficerAvailability _deriveAvailability(
    List<Map<String, dynamic>> myAssignments,
  ) {
    final hasInProgress = myAssignments.any(
      (a) => a['status'] == 'in_progress',
    );

    if (hasInProgress) {
      return OfficerAvailability.inInspection;
    }

    final hasAssigned = myAssignments.any((a) => a['status'] == 'assigned');

    if (hasAssigned) {
      return OfficerAvailability.assigned;
    }

    return OfficerAvailability.available;
  }

  Future<List<PmuOfficerSummary>> fetchOfficers() async {
    // 1) Base officer rows.
    final inspectorRows = await _client
        .from('pmu_inspectors')
        .select('profile_id, department, designation, region');

    if (inspectorRows.isEmpty) {
      return [];
    }

    final officerIds = inspectorRows
        .map((r) => r['profile_id'] as String)
        .toList();

    // 2) Officer display names.
    final profileRows = await _client
        .from('profiles')
        .select('id, full_name')
        .inFilter('id', officerIds);

    final profilesById = {for (final p in profileRows) p['id'] as String: p};

    // 3) All assignments for these officers, in one bulk query.
    // `created_at` is now required to compute each assignment's 2-day
    // expiry window.
    final assignmentRows = await _client
        .from('pmu_assignments')
        .select(
          'id, inspector_profile_id, institute_profile_id, '
          'scheduled_datetime, priority, status, created_at',
        )
        .inFilter('inspector_profile_id', officerIds)
        .order('scheduled_datetime', ascending: true);

    // 4) Institute information referenced above, in one bulk query.
    //
    // We now fetch latitude, longitude and address as well because the
    // AssignmentSummary model carries the real institute location.
    final instituteIds = <String>{
      ...assignmentRows.map((r) => r['institute_profile_id'] as String),
    }.toList();

    var institutesById = <String, Map<String, dynamic>>{};

    if (instituteIds.isNotEmpty) {
      final instituteRows = await _client
          .from('ngo_institutes')
          .select('profile_id, institute_name, address, latitude, longitude')
          .inFilter('profile_id', instituteIds);

      final missingNameIds = instituteRows
          .where((r) => r['institute_name'] == null)
          .map((r) => r['profile_id'] as String)
          .toList();

      var fallbackNamesById = <String, String>{};

      if (missingNameIds.isNotEmpty) {
        final fallbackProfiles = await _client
            .from('profiles')
            .select('id, full_name')
            .inFilter('id', missingNameIds);

        fallbackNamesById = {
          for (final p in fallbackProfiles)
            p['id'] as String:
                (p['full_name'] as String?) ?? 'Unnamed Institute',
        };
      }

      institutesById = {
        for (final r in instituteRows)
          r['profile_id'] as String: {
            'institute_name':
                (r['institute_name'] as String?) ??
                fallbackNamesById[r['profile_id']] ??
                'Unnamed Institute',
            'address': (r['address'] as String?) ?? 'Address not available',
            'latitude': _parseCoordinate(r['latitude']),
            'longitude': _parseCoordinate(r['longitude']),
          },
      };
    }

    String instituteName(String id) {
      return institutesById[id]?['institute_name'] as String? ??
          'Unnamed Institute';
    }

    String instituteAddress(String id) {
      return institutesById[id]?['address'] as String? ??
          'Address not available';
    }

    double? instituteLatitude(String id) {
      return institutesById[id]?['latitude'] as double?;
    }

    double? instituteLongitude(String id) {
      return institutesById[id]?['longitude'] as double?;
    }

    // 6) Assemble one PmuOfficerSummary per officer — pure in-memory work.
    return inspectorRows.map((row) {
      final id = row['profile_id'] as String;

      final profile = profilesById[id];

      final officerName =
          (profile?['full_name'] as String?) ?? 'Unknown Officer';

      final myAssignments = assignmentRows
          .where((a) => a['inspector_profile_id'] == id)
          .toList();

      final myInspections = myAssignments
          .where((a) => a['status'] == 'completed')
          .toList();

      final assignments = myAssignments
          .map((a) {
            final instituteId = a['institute_profile_id'] as String;
            final createdAt = DateTime.parse(a['created_at'] as String);
            final fullAddress = instituteAddress(instituteId);
            final status = _assignmentStatusFromDb(a['status'] as String);

            // TODO: pmu_assignments has no started_at column yet. Until
            // one is added, we approximate "started" as any status past
            // 'assigned' — good enough to unlock displayName/displayLocation
            // for PMU staff, but not a substitute for a real timestamp.
            final startedAt =
                status == AssignmentStatus.inProgress ||
                    status == AssignmentStatus.completed
                ? createdAt
                : null;

            return AssignmentSummary(
              id: a['id'] as String,
              instituteProfileId: instituteId,
              instituteName: instituteName(instituteId),
              fullAddress: fullAddress,
              area: _deriveArea(fullAddress),
              instituteLatitude: instituteLatitude(instituteId),
              instituteLongitude: instituteLongitude(instituteId),
              scheduledDateTime: DateTime.parse(
                a['scheduled_datetime'] as String,
              ),
              priority: _priorityFromDb(a['priority'] as String?),
              status: status,
              createdAt: createdAt,
              expiresAt: createdAt.add(kAssignmentLifetime),
              startedAt: startedAt,
            );
          })
          // Expired assignments never surface anywhere in the UI —
          // filtered out right here so every screen that consumes
          // PmuOfficerSummary.assignments gets them for free.
          .where((a) => a.isActive)
          .toList();

      final inspections = myInspections
          .map(
            (a) => InspectionSummary(
              projectName: instituteName(a['institute_profile_id'] as String),
              inspectorName: officerName,
              dateTime: DateTime.parse(a['scheduled_datetime'] as String),
              status: InspectionStatus.approved,
              risk: _riskFromDb(null),
            ),
          )
          .toList();

      DateTime? lastActivity;

      if (myInspections.isNotEmpty) {
        final dates =
            myInspections
                .map((a) => DateTime.parse(a['scheduled_datetime'] as String))
                .toList()
              ..sort((a, b) => b.compareTo(a));

        lastActivity = dates.first;
      }

      return PmuOfficerSummary(
        id: id,
        name: officerName,
        department: row['department'] as String?,
        designation: row['designation'] as String?,
        region: row['region'] as String?,
        assignments: assignments,
        inspections: inspections,
        availability: _deriveAvailability(myAssignments),
        lastActivity: lastActivity,
      );
    }).toList();
  }
}