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

  static final List<AssignmentSummary> todaysAssignments = [
    AssignmentSummary(
      id: 'mock-assignment-001',
      instituteProfileId: 'mock-institute-001',
      projectName: 'Sunrise Child Care Centre',
      location: 'Sector 12, Dwarka',
      instituteLatitude: null,
      instituteLongitude: null,
      scheduledDateTime: DateTime.now().add(const Duration(hours: 2)),
      priority: Priority.high,
      status: AssignmentStatus.assigned,
    ),
    AssignmentSummary(
      id: 'mock-assignment-002',
      instituteProfileId: 'mock-institute-002',
      projectName: 'Community Rehabilitation Centre',
      location: 'Rohini, Phase 3',
      instituteLatitude: null,
      instituteLongitude: null,
      scheduledDateTime: DateTime.now().add(const Duration(hours: 5)),
      priority: Priority.medium,
      status: AssignmentStatus.assigned,
    ),
    AssignmentSummary(
      id: 'mock-assignment-003',
      instituteProfileId: 'mock-institute-003',
      projectName: 'Government Skill Development Institute',
      location: 'Karol Bagh',
      instituteLatitude: null,
      instituteLongitude: null,
      scheduledDateTime: DateTime.now().subtract(const Duration(hours: 1)),
      priority: Priority.low,
      status: AssignmentStatus.overdue,
    ),
  ];
}
