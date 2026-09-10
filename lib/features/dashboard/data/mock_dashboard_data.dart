import '../../../models/inspection.dart';
import '../../../models/assignment.dart';

class MockDashboardData {
  MockDashboardData._();

  static final List<InspectionSummary> recentInspections = [
    InspectionSummary(
      projectName: 'Sunrise Child Care Centre',
      inspectorName: 'R. Sharma',
      dateTime: DateTime.now().subtract(const Duration(hours: 3)),
      status: InspectionStatus.underReview,
      risk: RiskLevel.medium,
    ),
    InspectionSummary(
      projectName: 'Government Skill Development Institute',
      inspectorName: 'A. Mehta',
      dateTime: DateTime.now().subtract(const Duration(hours: 6)),
      status: InspectionStatus.submitted,
      risk: RiskLevel.low,
    ),
    // Note: InspectionStatus.overdue is unrelated to AssignmentStatus and
    // was NOT removed from the model — it's still a valid inspection state,
    // so this entry is unchanged.
    InspectionSummary(
      projectName: 'Community Rehabilitation Centre',
      inspectorName: 'K. Nair',
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      status: InspectionStatus.overdue,
      risk: RiskLevel.high,
    ),
    InspectionSummary(
      projectName: 'District Old Age Home',
      inspectorName: 'S. Verma',
      dateTime: DateTime.now().subtract(const Duration(days: 2)),
      status: InspectionStatus.approved,
      risk: RiskLevel.low,
    ),
  ];

  /// All mock assignments are freshly "created" relative to now, so none
  /// of them are past their 2-day lifetime and none get filtered out by
  /// `.isActive` when a screen displays this list. The previous entry
  /// that used `AssignmentStatus.overdue` has been replaced — that status
  /// no longer exists, and an assignment that old would be expired (and
  /// therefore invisible) anyway, so it made no sense to keep as "today's".
  static final List<AssignmentSummary> todaysAssignments = [
    AssignmentSummary(
      id: 'mock-assignment-001',
      instituteProfileId: 'mock-institute-001',
      instituteName: 'Sunrise Child Care Centre',
      fullAddress: 'Plot 14, Sector 12, Dwarka, New Delhi',
      area: 'Sector 12, Dwarka',
      instituteLatitude: null,
      instituteLongitude: null,
      scheduledDateTime: DateTime.now().add(const Duration(hours: 2)),
      priority: Priority.high,
      status: AssignmentStatus.assigned,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(kAssignmentLifetime),
    ),
    AssignmentSummary(
      id: 'mock-assignment-002',
      instituteProfileId: 'mock-institute-002',
      instituteName: 'Community Rehabilitation Centre',
      fullAddress: 'Block C, Rohini Phase 3, New Delhi',
      area: 'Rohini, Phase 3',
      instituteLatitude: null,
      instituteLongitude: null,
      scheduledDateTime: DateTime.now().add(const Duration(hours: 5)),
      priority: Priority.medium,
      status: AssignmentStatus.assigned,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(kAssignmentLifetime),
    ),
    AssignmentSummary(
      id: 'mock-assignment-003',
      instituteProfileId: 'mock-institute-003',
      instituteName: 'Government Skill Development Institute',
      fullAddress: 'Karol Bagh Main Road, New Delhi',
      area: 'Karol Bagh',
      instituteLatitude: null,
      instituteLongitude: null,
      scheduledDateTime: DateTime.now().subtract(const Duration(hours: 1)),
      priority: Priority.low,
      status: AssignmentStatus.inProgress,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      expiresAt: DateTime.now()
          .subtract(const Duration(hours: 3))
          .add(kAssignmentLifetime),
      startedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];
}