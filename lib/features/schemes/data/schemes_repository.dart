import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/institute.dart';
import '../../../models/scheme.dart';

/// Repository for scheme and institute data.
///
/// The scheme definitions themselves are static in MockSchemesData.
/// Supabase stores the scheme type on ngo_institutes, so this repository
/// fetches the institute counts and institute details associated with each
/// scheme.
///
/// This repository is intentionally defensive:
/// - Unknown/null scheme_type values do not crash the whole Schemes page.
/// - Nullable database fields are handled safely.
/// - Supabase errors are logged and re-thrown so the UI can show its
///   normal error/retry state.
class SchemesRepository {
  SchemesRepository();

  final SupabaseClient _client = Supabase.instance.client;

  static const Map<SchemeType, String> _schemeTypeToDatabase = {
    SchemeType.ngo: 'ngo',
    SchemeType.educational: 'educational',
    SchemeType.economicDevelopment: 'economical_development',
    SchemeType.socialEmpowerment: 'social_empowerment',
  };

  String _schemeTypeToDb(SchemeType type) {
    return _schemeTypeToDatabase[type]!;
  }

  SchemeType? _schemeTypeFromDb(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'ngo':
        return SchemeType.ngo;

      case 'educational':
        return SchemeType.educational;

      case 'economical_development':
      case 'economic_development':
      case 'economic-development':
        return SchemeType.economicDevelopment;

      case 'social_empowerment':
      case 'social-empowerment':
        return SchemeType.socialEmpowerment;

      case null:
      case '':
        return null;

      default:
        debugPrint(
          'SchemesRepository: Unknown scheme_type received from '
          'Supabase: "$value"',
        );
        return null;
    }
  }

  InstituteStatus _statusFromApproval(String? approvalStatus) {
    switch (approvalStatus?.trim().toLowerCase()) {
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

  DateTime _parseDate(
    dynamic value, {
    DateTime? fallback,
  }) {
    if (value is DateTime) {
      return value;
    }

    if (value is String && value.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(value);

      if (parsed != null) {
        return parsed;
      }
    }

    return fallback ?? DateTime.now();
  }

  double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  /// Fetches the number of institutes registered under each scheme.
  ///
  /// Unknown/null scheme_type values are ignored rather than crashing the
  /// complete page.
  Future<Map<SchemeType, int>> fetchSchemeCounts() async {
    debugPrint('========== SCHEME COUNTS DEBUG ==========');
    debugPrint('Fetching scheme counts from ngo_institutes...');
    debugPrint('Supabase Auth UID: ${_client.auth.currentUser?.id}');
    debugPrint('==========================================');

    try {
      final rows = await _client
          .from('ngo_institutes')
          .select('scheme_type');

      final counts = <SchemeType, int>{
        for (final scheme in SchemeType.values) scheme: 0,
      };

      for (final row in rows) {
        final rawValue = row['scheme_type'] as String?;
        final type = _schemeTypeFromDb(rawValue);

        if (type == null) {
          debugPrint(
            'Skipping unsupported/null scheme_type: "$rawValue"',
          );
          continue;
        }

        counts[type] = (counts[type] ?? 0) + 1;
      }

      debugPrint('Scheme counts: $counts');

      return counts;
    } on PostgrestException catch (e, stackTrace) {
      debugPrint('========== SCHEME COUNTS ERROR ==========');
      debugPrint('Message: ${e.message}');
      debugPrint('Code: ${e.code}');
      debugPrint('Details: ${e.details}');
      debugPrint('Hint: ${e.hint}');
      debugPrint('$stackTrace');
      debugPrint('==========================================');

      rethrow;
    } catch (e, stackTrace) {
      debugPrint('========== SCHEME COUNTS UNKNOWN ERROR ==========');
      debugPrint('$e');
      debugPrint('$stackTrace');
      debugPrint('==================================================');

      rethrow;
    }
  }

  /// Fetches all institutes belonging to one scheme.
  ///
  /// The data is loaded in bulk:
  /// 1. Institutes
  /// 2. Profiles
  /// 3. Latest inspections
  /// 4. Inspector profiles
  Future<List<Institute>> fetchInstitutesForScheme(
    SchemeType type,
  ) async {
    final schemeValue = _schemeTypeToDb(type);

    debugPrint('========== SCHEME INSTITUTES DEBUG ==========');
    debugPrint('Scheme: $type');
    debugPrint('Database scheme_type: $schemeValue');
    debugPrint('Supabase Auth UID: ${_client.auth.currentUser?.id}');
    debugPrint('==============================================');

    try {
      // ------------------------------------------------------------
      // 1. Institutes belonging to this scheme
      // ------------------------------------------------------------
      final instituteRows = await _client
          .from('ngo_institutes')
          .select(
            'profile_id, institute_name, category, address, '
            'registration_number, funds_allocated, funds_utilized, '
            'created_at, scheme_type',
          )
          .eq('scheme_type', schemeValue)
          .order('created_at', ascending: false);

      debugPrint(
        'Institutes returned for $schemeValue: ${instituteRows.length}',
      );

      if (instituteRows.isEmpty) {
        return [];
      }

      // Only keep rows that actually contain a profile ID.
      final validInstituteRows = instituteRows.where((row) {
        final profileId = row['profile_id'];

        return profileId is String && profileId.trim().isNotEmpty;
      }).toList();

      if (validInstituteRows.isEmpty) {
        debugPrint(
          'No valid institute profile IDs were returned.',
        );
        return [];
      }

      final instituteIds = validInstituteRows
          .map((row) => row['profile_id'] as String)
          .toList();

      // ------------------------------------------------------------
      // 2. Profile information
      // ------------------------------------------------------------
      final profileRows = await _client
          .from('profiles')
          .select('id, full_name, phone, status')
          .inFilter('id', instituteIds);

      final profilesById = <String, Map<String, dynamic>>{
        for (final profile in profileRows)
          profile['id'] as String: profile,
      };

      debugPrint(
        'Profiles returned: ${profileRows.length}',
      );

      // ------------------------------------------------------------
      // 3. Latest inspections
      // ------------------------------------------------------------
      final inspectionRows = await _client
          .from('pmu_inspection_submissions')
          .select(
            'institute_profile_id, '
            'inspector_profile_id, '
            'submitted_at, '
            'overall_status, '
            'report_summary',
          )
          .inFilter('institute_profile_id', instituteIds)
          .order('submitted_at', ascending: false);

      final latestInspectionByInstitute =
          <String, Map<String, dynamic>>{};

      for (final row in inspectionRows) {
        final instituteId = row['institute_profile_id'];

        if (instituteId is! String ||
            instituteId.trim().isEmpty) {
          continue;
        }

        latestInspectionByInstitute.putIfAbsent(
          instituteId,
          () => row,
        );
      }

      debugPrint(
        'Inspection rows returned: ${inspectionRows.length}',
      );

      // ------------------------------------------------------------
      // 4. Inspector profiles
      // ------------------------------------------------------------
      final inspectorIds = latestInspectionByInstitute.values
          .map((row) => row['inspector_profile_id'])
          .whereType<String>()
          .where((id) => id.trim().isNotEmpty)
          .toSet()
          .toList();

      var inspectorProfilesById =
          <String, Map<String, dynamic>>{};

      if (inspectorIds.isNotEmpty) {
        final inspectorRows = await _client
            .from('profiles')
            .select('id, full_name')
            .inFilter('id', inspectorIds);

        inspectorProfilesById = {
          for (final profile in inspectorRows)
            profile['id'] as String: profile,
        };
      }

      // ------------------------------------------------------------
      // 5. Build Institute objects
      // ------------------------------------------------------------
      final institutes = <Institute>[];

      for (final row in validInstituteRows) {
        final id = row['profile_id'] as String;

        final profile = profilesById[id];

        final inspectionRow =
            latestInspectionByInstitute[id];

        InstituteInspection? lastInspection;

        if (inspectionRow != null) {
          final inspectorId =
              inspectionRow['inspector_profile_id'] as String?;

          final inspectorProfile = inspectorId != null
              ? inspectorProfilesById[inspectorId]
              : null;

          lastInspection = InstituteInspection(
            dateTime: _parseDate(
              inspectionRow['submitted_at'],
            ),
            inspectorName:
                (inspectorProfile?['full_name'] as String?)
                        ?.trim()
                        .isNotEmpty ==
                    true
                    ? (inspectorProfile!['full_name'] as String)
                    : 'Unknown Inspector',
            status:
                (inspectionRow['overall_status'] as String?)
                        ?.trim()
                        .isNotEmpty ==
                    true
                    ? inspectionRow['overall_status'] as String
                    : 'Completed',
            reportSummary:
                (inspectionRow['report_summary'] as String?)
                        ?.trim()
                        .isNotEmpty ==
                    true
                    ? inspectionRow['report_summary'] as String
                    : 'No summary provided.',
          );
        }

        final dbSchemeType =
            _schemeTypeFromDb(row['scheme_type'] as String?);

        // Normally this is always the requested scheme because the
        // Supabase query already filters by scheme_type.
        // If the DB contains an unexpected value, use the requested
        // scheme rather than crashing.
        final instituteSchemeType =
            dbSchemeType ?? type;

        final instituteName =
            (row['institute_name'] as String?)?.trim();

        final profileName =
            (profile?['full_name'] as String?)?.trim();

        final category =
            (row['category'] as String?)?.trim();

        final address =
            (row['address'] as String?)?.trim();

        final phone =
            (profile?['phone'] as String?)?.trim();

        final fundsAllocated =
            _parseDouble(row['funds_allocated']);

        final fundsUtilized =
            _parseDouble(row['funds_utilized']);

        final createdAt = _parseDate(
          row['created_at'],
        );

        institutes.add(
          Institute(
            id: id,
            name: instituteName?.isNotEmpty == true
                ? instituteName!
                : profileName?.isNotEmpty == true
                    ? profileName!
                    : 'Unnamed Institute',
            schemeType: instituteSchemeType,
            category: category?.isNotEmpty == true
                ? category!
                : _defaultCategoryLabel(
                    instituteSchemeType,
                  ),
            location: address?.isNotEmpty == true
                ? address!
                : 'Location not recorded',
            status: _statusFromApproval(
              profile?['status'] as String?,
            ),
            registrationDate: createdAt,
            fundsAllocated: fundsAllocated,
            fundsUtilized: fundsUtilized,
            contactPerson: profileName?.isNotEmpty == true
                ? profileName!
                : 'Not available',
            contactPhone: phone?.isNotEmpty == true
                ? phone!
                : 'Not available',
            contactEmail: 'Not available',
            lastInspection: lastInspection,
          ),
        );
      }

      debugPrint(
        'Institutes assembled successfully: ${institutes.length}',
      );

      return institutes;
    } on PostgrestException catch (e, stackTrace) {
      debugPrint('========== SCHEME INSTITUTES ERROR ==========');
      debugPrint('Scheme: $type');
      debugPrint('Database value: $schemeValue');
      debugPrint('Message: ${e.message}');
      debugPrint('Code: ${e.code}');
      debugPrint('Details: ${e.details}');
      debugPrint('Hint: ${e.hint}');
      debugPrint('$stackTrace');
      debugPrint('==============================================');

      rethrow;
    } catch (e, stackTrace) {
      debugPrint(
        '========== SCHEME INSTITUTES UNKNOWN ERROR =========='
      );
      debugPrint('Scheme: $type');
      debugPrint('Error: $e');
      debugPrint('$stackTrace');
      debugPrint('======================================================');

      rethrow;
    }
  }
}