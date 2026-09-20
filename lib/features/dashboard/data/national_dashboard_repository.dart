import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A single approved institute displayed on the national dashboard.
class DashboardInstitute {
  final String profileId;
  final String organizationName;
  final String address;
  final String district;
  final String state;
  final String schemeCategory;
  final String schemeCode;

  const DashboardInstitute({
    required this.profileId,
    required this.organizationName,
    required this.address,
    required this.district,
    required this.state,
    required this.schemeCategory,
    required this.schemeCode,
  });
}

/// All data required by the combined national dashboard.
class NationalDashboardData {
  final int totalInstitutes;

  final int educationalInstitutes;
  final int socialEmpowermentInstitutes;
  final int economicDevelopmentInstitutes;

  final List<DashboardInstitute> approvedInstitutes;

  final int totalAssignedInspections;
  final int completedInspections;
  final int inProgressInspections;
  final int pendingInspections;
  final int overdueInspections;

  final int openCriticalFindingsCount;

  /// Metrics that could not be loaded.
  final List<String> unavailableMetrics;

  const NationalDashboardData({
    required this.totalInstitutes,
    required this.educationalInstitutes,
    required this.socialEmpowermentInstitutes,
    required this.economicDevelopmentInstitutes,
    required this.approvedInstitutes,
    required this.totalAssignedInspections,
    required this.completedInspections,
    required this.inProgressInspections,
    required this.pendingInspections,
    required this.overdueInspections,
    required this.openCriticalFindingsCount,
    required this.unavailableMetrics,
  });

  double get complianceRate {
    if (totalAssignedInspections <= 0) {
      return 0;
    }

    return (completedInspections / totalAssignedInspections)
        .clamp(0.0, 1.0);
  }
}

class NationalDashboardRepository {
  NationalDashboardRepository({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  // ---------------------------------------------------------------------------
  // MAIN DASHBOARD LOAD
  // ---------------------------------------------------------------------------

  Future<NationalDashboardData> loadDashboard() async {
    final unavailableMetrics = <String>[];

    // -------------------------------------------------------------------------
    // 1. APPROVED INSTITUTES
    // -------------------------------------------------------------------------

    var approvedInstitutes = <DashboardInstitute>[];

    try {
      /*
       * APPROVED INSTITUTE LOGIC
       *
       * Same logic used by InstituteListScreen:
       *
       * reviewed_at IS NOT NULL
       * AND
       * rejection_reason IS NULL
       *
       * IMPORTANT:
       * No district filter.
       * No state filter.
       * This is the national dashboard.
       */
      final instituteRows = await _client
          .from('institute_reps')
          .select(
            'profile_id, '
            'organization_name, '
            'complete_address, '
            'district, '
            'state, '
            'scheme_category, '
            'scheme_code, '
            'reviewed_at, '
            'rejection_reason',
          )
          .not('reviewed_at', 'is', null)
          .isFilter('rejection_reason', null);

      debugPrint(
        '==================================================',
      );
      debugPrint(
        'NATIONAL DASHBOARD - APPROVED INSTITUTES',
      );
      debugPrint(
        'Rows returned: ${instituteRows.length}',
      );
      debugPrint(
        'Raw data: $instituteRows',
      );
      debugPrint(
        '==================================================',
      );

      for (final row in instituteRows) {
        approvedInstitutes.add(
          DashboardInstitute(
            profileId:
                row['profile_id']?.toString() ?? '',
            organizationName:
                row['organization_name']?.toString() ??
                    'Unknown Institute',
            address:
                row['complete_address']?.toString() ?? '',
            district:
                row['district']?.toString() ?? '',
            state:
                row['state']?.toString() ?? '',
            schemeCategory:
                row['scheme_category']?.toString() ?? '',
            schemeCode:
                row['scheme_code']?.toString() ?? '',
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint(
        'NATIONAL DASHBOARD - INSTITUTE ERROR: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      unavailableMetrics.add(
        'Approved institute data could not be loaded.',
      );
    }

    final totalInstitutes =
        approvedInstitutes.length;

    var educationalInstitutes = 0;
    var socialEmpowermentInstitutes = 0;
    var economicDevelopmentInstitutes = 0;

    for (final institute in approvedInstitutes) {
      switch (
          institute.schemeCategory.trim().toLowerCase()) {
        case 'educational':
          educationalInstitutes++;
          break;

        case 'social_empowerment':
          socialEmpowermentInstitutes++;
          break;

        case 'economic_development':
          economicDevelopmentInstitutes++;
          break;
      }
    }

    // -------------------------------------------------------------------------
    // 2. INSPECTION ASSIGNMENTS
    // -------------------------------------------------------------------------

    var totalAssignedInspections = 0;
    var completedInspections = 0;
    var inProgressInspections = 0;
    var pendingInspections = 0;
    var overdueInspections = 0;

    try {
      final assignmentRows = await _client
          .from('pmu_assignments')
          .select('status');

      debugPrint(
        'NATIONAL DASHBOARD - INSPECTION ROWS: '
        '${assignmentRows.length}',
      );

      for (final row in assignmentRows) {
        totalAssignedInspections++;

        final status = row['status']
                ?.toString()
                .trim()
                .toLowerCase()
                .replaceAll('-', '_')
                .replaceAll(' ', '_') ??
            '';

        switch (status) {
          case 'completed':
          case 'complete':
            completedInspections++;
            break;

          case 'in_progress':
          case 'inprogress':
          case 'ongoing':
            inProgressInspections++;
            break;

          case 'overdue':
            overdueInspections++;
            break;

          case 'pending':
          case 'assigned':
          case 'scheduled':
          case 'not_started':
          default:
            pendingInspections++;
            break;
        }
      }
    } catch (e, stackTrace) {
      debugPrint(
        'NATIONAL DASHBOARD - INSPECTION ERROR: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      unavailableMetrics.add(
        'Inspection assignment data could not be loaded.',
      );
    }

    // -------------------------------------------------------------------------
    // 3. CRITICAL INSPECTION FINDINGS
    // -------------------------------------------------------------------------

    var criticalFindings = 0;

    try {
      final findingRows = await _client
          .from('pmu_inspection_findings')
          .select('severity');

      debugPrint(
        'NATIONAL DASHBOARD - FINDING ROWS: '
        '${findingRows.length}',
      );

      for (final row in findingRows) {
        final severity = row['severity']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

        if (severity == 'high' ||
            severity == 'critical' ||
            severity == 'severe') {
          criticalFindings++;
        }
      }
    } catch (e, stackTrace) {
      debugPrint(
        'NATIONAL DASHBOARD - FINDINGS ERROR: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      unavailableMetrics.add(
        'Inspection finding data could not be loaded.',
      );
    }

    // -------------------------------------------------------------------------
    // FINAL RESULT
    // -------------------------------------------------------------------------

    debugPrint(
      '==================================================',
    );
    debugPrint(
      'NATIONAL DASHBOARD SUMMARY',
    );
    debugPrint(
      'Approved institutes: $totalInstitutes',
    );
    debugPrint(
      'Educational: $educationalInstitutes',
    );
    debugPrint(
      'Social empowerment: $socialEmpowermentInstitutes',
    );
    debugPrint(
      'Economic development: $economicDevelopmentInstitutes',
    );
    debugPrint(
      'Total inspections: $totalAssignedInspections',
    );
    debugPrint(
      'Completed: $completedInspections',
    );
    debugPrint(
      'In progress: $inProgressInspections',
    );
    debugPrint(
      'Pending: $pendingInspections',
    );
    debugPrint(
      'Overdue: $overdueInspections',
    );
    debugPrint(
      'Critical findings: $criticalFindings',
    );
    debugPrint(
      '==================================================',
    );

    return NationalDashboardData(
      totalInstitutes: totalInstitutes,
      educationalInstitutes:
          educationalInstitutes,
      socialEmpowermentInstitutes:
          socialEmpowermentInstitutes,
      economicDevelopmentInstitutes:
          economicDevelopmentInstitutes,
      approvedInstitutes:
          approvedInstitutes,
      totalAssignedInspections:
          totalAssignedInspections,
      completedInspections:
          completedInspections,
      inProgressInspections:
          inProgressInspections,
      pendingInspections:
          pendingInspections,
      overdueInspections:
          overdueInspections,
      openCriticalFindingsCount:
          criticalFindings,
      unavailableMetrics:
          unavailableMetrics,
    );
  }
}