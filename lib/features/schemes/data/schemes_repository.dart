import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/institute.dart';
import '../../../models/scheme.dart';

/// Fetches scheme + institute data from Supabase.
///
/// Every method here performs exactly one fixed, small set of network
/// calls and returns — nothing here polls, subscribes, or re-triggers
/// itself. Callers must fetch once (e.g. in initState) and store the
/// resulting Future on their State object; re-fetch only in response to
/// an explicit user action (pull-to-refresh, retry button).
class SchemesRepository {
  final SupabaseClient _client = Supabase.instance.client;

  String _schemeTypeToDb(SchemeType type) {
    switch (type) {
      case SchemeType.ngo:
        return 'ngo';
      case SchemeType.educational:
        return 'educational';
      case SchemeType.economicDevelopment:
        return 'economical_development';
      case SchemeType.socialEmpowerment:
        return 'social_empowerment';
    }
  }

  SchemeType _schemeTypeFromDb(String value) {
    switch (value) {
      case 'ngo':
        return SchemeType.ngo;
      case 'educational':
        return SchemeType.educational;
      case 'economical_development':
        return SchemeType.economicDevelopment;
      case 'social_empowerment':
        return SchemeType.socialEmpowerment;
      default:
        throw Exception('Unknown scheme_type from database: $value');
    }
  }

  InstituteStatus _statusFromApproval(String? approvalStatus) {
    switch (approvalStatus) {
      case 'approved':
        return InstituteStatus.active;
      case 'pending':
        return InstituteStatus.underReview;
      case 'rejected':
        return InstituteStatus.suspended;
      default:
        return InstituteStatus.underReview;
    }
  }

  String _defaultCategoryLabel(SchemeType type) {
    switch (type) {
      case SchemeType.ngo:
        return 'NGO';
      case SchemeType.educational:
        return 'Educational Institute';
      case SchemeType.economicDevelopment:
        return 'Economic Development Institute';
      case SchemeType.socialEmpowerment:
        return 'Social Empowerment Institute';
    }
  }

  /// A single lightweight query — just `scheme_type` per institute row —
  /// used to show institute counts on the Schemes list screen without
  /// pulling full institute records.
  Future<Map<SchemeType, int>> fetchSchemeCounts() async {
    final rows = await _client.from('ngo_institutes').select('scheme_type');

    final counts = <SchemeType, int>{for (final s in SchemeType.values) s: 0};
    for (final row in rows) {
      final raw = row['scheme_type'] as String?;
      if (raw == null) continue;
      final type = _schemeTypeFromDb(raw);
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  /// Full institute list for a single scheme, each with its most recent
  /// inspection attached (if any). Performs 4 bulk queries at most,
  /// regardless of how many institutes exist — never one query per row.
  Future<List<Institute>> fetchInstitutesForScheme(SchemeType type) async {
    final schemeValue = _schemeTypeToDb(type);

    // 1) Institute rows for this scheme.
    final instituteRows = await _client
        .from('ngo_institutes')
        .select(
          'profile_id, institute_name, category, address, registration_number, '
          'funds_allocated, funds_utilized, created_at',
        )
        .eq('scheme_type', schemeValue)
        .order('created_at', ascending: false);

    if (instituteRows.isEmpty) return [];

    final instituteIds = instituteRows.map((r) => r['profile_id'] as String).toList();

    // 2) Profile info (display name, phone, approval status) for those institutes.
    final profileRows = await _client
        .from('profiles')
        .select('id, full_name, phone, status')
        .inFilter('id', instituteIds);
    final profilesById = {for (final p in profileRows) p['id'] as String: p};

    // 3) Most recent inspection per institute, in one bulk query
    //    (rows come back newest-first; we keep only the first per institute).
    final inspectionRows = await _client
        .from('pmu_inspection_submissions')
        .select('institute_profile_id, inspector_profile_id, submitted_at, overall_status, report_summary')
        .inFilter('institute_profile_id', instituteIds)
        .order('submitted_at', ascending: false);

    final latestInspectionByInstitute = <String, Map<String, dynamic>>{};
    for (final row in inspectionRows) {
      final id = row['institute_profile_id'] as String;
      latestInspectionByInstitute.putIfAbsent(id, () => row);
    }

    // 4) Inspector names for those latest inspections, in one bulk query.
    final inspectorIds = latestInspectionByInstitute.values
        .map((r) => r['inspector_profile_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    var inspectorProfilesById = <String, Map<String, dynamic>>{};
    if (inspectorIds.isNotEmpty) {
      final inspectorRows = await _client
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', inspectorIds);
      inspectorProfilesById = {for (final p in inspectorRows) p['id'] as String: p};
    }

    // 5) Assemble Institute objects — pure in-memory work from here on.
    return instituteRows.map((row) {
      final id = row['profile_id'] as String;
      final profile = profilesById[id];
      final inspectionRow = latestInspectionByInstitute[id];

      InstituteInspection? lastInspection;
      if (inspectionRow != null) {
        final inspectorId = inspectionRow['inspector_profile_id'] as String?;
        final inspectorProfile = inspectorId != null ? inspectorProfilesById[inspectorId] : null;
        lastInspection = InstituteInspection(
          dateTime: DateTime.parse(inspectionRow['submitted_at'] as String),
          inspectorName: (inspectorProfile?['full_name'] as String?) ?? 'Unknown Inspector',
          status: (inspectionRow['overall_status'] as String?) ?? 'Completed',
          reportSummary: (inspectionRow['report_summary'] as String?) ?? 'No summary provided.',
        );
      }

      return Institute(
        id: id,
        name: (row['institute_name'] as String?) ??
            (profile?['full_name'] as String?) ??
            'Unnamed Institute',
        schemeType: type,
        category: (row['category'] as String?) ?? _defaultCategoryLabel(type),
        location: (row['address'] as String?) ?? 'Location not recorded',
        status: _statusFromApproval(profile?['status'] as String?),
        registrationDate: row['created_at'] != null
            ? DateTime.parse(row['created_at'] as String)
            : DateTime.now(),
        fundsAllocated: (row['funds_allocated'] as num?)?.toDouble() ?? 0,
        fundsUtilized: (row['funds_utilized'] as num?)?.toDouble() ?? 0,
        contactPerson: (profile?['full_name'] as String?) ?? 'Not available',
        contactPhone: (profile?['phone'] as String?) ?? 'Not available',
        contactEmail: 'Not available',
        lastInspection: lastInspection,
      );
    }).toList();
  }
}