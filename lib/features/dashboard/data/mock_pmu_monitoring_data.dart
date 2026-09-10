import '../../../models/assignment.dart';
import '../../../models/pmu_officer_summary.dart';

/// Helper to keep the mock data below readable: builds the pair of
/// [AssignmentSummary.createdAt] / [AssignmentSummary.expiresAt] from a
/// scheduled time, using the same [kAssignmentLifetime] window the real
/// app enforces (2 days).
({DateTime createdAt, DateTime expiresAt}) _lifetimeFor(
  DateTime scheduledDateTime,
) {
  final createdAt = scheduledDateTime.subtract(const Duration(days: 1));
  return (createdAt: createdAt, expiresAt: createdAt.add(kAssignmentLifetime));
}

final List<PmuOfficerSummary> mockPmuOfficerSummaries = [
  PmuOfficerSummary(
    id: 'mock-officer-001',
    name: 'Rohan Kumar',
    department: 'PMU',
    designation: 'PMU Inspector',
    region: 'Meerut',
    availability: OfficerAvailability.assigned,
    lastActivity: DateTime(2026, 8, 31, 16, 30),
    assignments: [
      () {
        final scheduled = DateTime(2026, 9, 1, 10, 30);
        final lifetime = _lifetimeFor(scheduled);
        return AssignmentSummary(
          id: 'PMU-001',
          instituteProfileId: 'mock-institute-001',
          instituteName: 'Government Skill Development Centre',
          fullAddress:
              'Government Skill Development Centre, Meerut, Uttar Pradesh',
          area: 'Meerut, Uttar Pradesh',
          instituteLatitude: null,
          instituteLongitude: null,
          scheduledDateTime: scheduled,
          priority: Priority.high,
          status: AssignmentStatus.assigned,
          createdAt: lifetime.createdAt,
          expiresAt: lifetime.expiresAt,
        );
      }(),
      () {
        final scheduled = DateTime(2026, 9, 2, 11, 0);
        final lifetime = _lifetimeFor(scheduled);
        return AssignmentSummary(
          id: 'PMU-002',
          instituteProfileId: 'mock-institute-002',
          instituteName: 'Women Empowerment Centre',
          fullAddress: 'Women Empowerment Centre, Ghaziabad, Uttar Pradesh',
          area: 'Ghaziabad, Uttar Pradesh',
          instituteLatitude: null,
          instituteLongitude: null,
          scheduledDateTime: scheduled,
          priority: Priority.medium,
          status: AssignmentStatus.inProgress,
          createdAt: lifetime.createdAt,
          expiresAt: lifetime.expiresAt,
        );
      }(),
    ],
  ),
  PmuOfficerSummary(
    id: 'mock-officer-002',
    name: 'Kunal Gupta',
    department: 'PMU',
    designation: 'PMU Inspector',
    region: 'Ghaziabad',
    availability: OfficerAvailability.inInspection,
    lastActivity: DateTime(2026, 8, 30, 14, 15),
    assignments: [
      () {
        final scheduled = DateTime(2026, 9, 3, 9, 30);
        final lifetime = _lifetimeFor(scheduled);
        return AssignmentSummary(
          id: 'PMU-003',
          instituteProfileId: 'mock-institute-003',
          instituteName: 'Community Development Institute',
          fullAddress: 'Community Development Institute, Delhi',
          area: 'Delhi',
          instituteLatitude: null,
          instituteLongitude: null,
          scheduledDateTime: scheduled,
          priority: Priority.low,
          status: AssignmentStatus.inProgress,
          createdAt: lifetime.createdAt,
          expiresAt: lifetime.expiresAt,
        );
      }(),
    ],
  ),
  PmuOfficerSummary(
    id: 'mock-officer-003',
    name: 'Aryan Yadav',
    department: 'PMU',
    designation: 'PMU Inspector',
    region: 'Delhi',
    availability: OfficerAvailability.available,
    lastActivity: DateTime(2026, 8, 29, 11, 45),
    assignments: [
      () {
        final scheduled = DateTime(2026, 9, 6, 10, 0);
        final lifetime = _lifetimeFor(scheduled);
        return AssignmentSummary(
          id: 'PMU-004',
          instituteProfileId: 'mock-institute-004',
          instituteName: 'Youth Development Centre',
          fullAddress: 'Youth Development Centre, Noida, Uttar Pradesh',
          area: 'Noida, Uttar Pradesh',
          instituteLatitude: null,
          instituteLongitude: null,
          scheduledDateTime: scheduled,
          priority: Priority.high,
          status: AssignmentStatus.completed,
          createdAt: lifetime.createdAt,
          expiresAt: lifetime.expiresAt,
        );
      }(),
    ],
  ),
];

final List<AssignmentSummary> mockPmuAssignments = [
  () {
    final scheduled = DateTime(2026, 9, 1, 10, 30);
    final lifetime = _lifetimeFor(scheduled);
    return AssignmentSummary(
      id: 'PMU-001',
      instituteProfileId: 'mock-institute-001',
      instituteName: 'Government Skill Development Centre',
      fullAddress:
          'Government Skill Development Centre, Meerut, Uttar Pradesh',
      area: 'Meerut, Uttar Pradesh',
      instituteLatitude: null,
      instituteLongitude: null,
      scheduledDateTime: scheduled,
      priority: Priority.high,
      status: AssignmentStatus.assigned,
      createdAt: lifetime.createdAt,
      expiresAt: lifetime.expiresAt,
    );
  }(),
  () {
    final scheduled = DateTime(2026, 9, 2, 11, 0);
    final lifetime = _lifetimeFor(scheduled);
    return AssignmentSummary(
      id: 'PMU-002',
      instituteProfileId: 'mock-institute-002',
      instituteName: 'Women Empowerment Centre',
      fullAddress: 'Women Empowerment Centre, Ghaziabad, Uttar Pradesh',
      area: 'Ghaziabad, Uttar Pradesh',
      instituteLatitude: null,
      instituteLongitude: null,
      scheduledDateTime: scheduled,
      priority: Priority.medium,
      status: AssignmentStatus.inProgress,
      createdAt: lifetime.createdAt,
      expiresAt: lifetime.expiresAt,
    );
  }(),
  () {
    final scheduled = DateTime(2026, 9, 3, 9, 30);
    final lifetime = _lifetimeFor(scheduled);
    return AssignmentSummary(
      id: 'PMU-003',
      instituteProfileId: 'mock-institute-003',
      instituteName: 'Community Development Institute',
      fullAddress: 'Community Development Institute, Delhi',
      area: 'Delhi',
      instituteLatitude: null,
      instituteLongitude: null,
      scheduledDateTime: scheduled,
      priority: Priority.low,
      status: AssignmentStatus.completed,
      createdAt: lifetime.createdAt,
      expiresAt: lifetime.expiresAt,
    );
  }(),
];

final List<AssignmentSummary> mockUpcomingPmuAssignments = [
  () {
    final scheduled = DateTime(2026, 9, 6, 10, 0);
    final lifetime = _lifetimeFor(scheduled);
    return AssignmentSummary(
      id: 'PMU-004',
      instituteProfileId: 'mock-institute-004',
      instituteName: 'Youth Development Centre',
      fullAddress: 'Youth Development Centre, Noida, Uttar Pradesh',
      area: 'Noida, Uttar Pradesh',
      instituteLatitude: null,
      instituteLongitude: null,
      scheduledDateTime: scheduled,
      priority: Priority.high,
      status: AssignmentStatus.assigned,
      createdAt: lifetime.createdAt,
      expiresAt: lifetime.expiresAt,
    );
  }(),
  () {
    final scheduled = DateTime(2026, 9, 7, 11, 30);
    final lifetime = _lifetimeFor(scheduled);
    return AssignmentSummary(
      id: 'PMU-005',
      instituteProfileId: 'mock-institute-005',
      instituteName: 'Skill Training Institute',
      fullAddress: 'Skill Training Institute, Faridabad, Haryana',
      area: 'Faridabad, Haryana',
      instituteLatitude: null,
      instituteLongitude: null,
      scheduledDateTime: scheduled,
      priority: Priority.medium,
      status: AssignmentStatus.assigned,
      createdAt: lifetime.createdAt,
      expiresAt: lifetime.expiresAt,
    );
  }(),
  () {
    final scheduled = DateTime(2026, 9, 8, 14, 0);
    final lifetime = _lifetimeFor(scheduled);
    return AssignmentSummary(
      id: 'PMU-006',
      instituteProfileId: 'mock-institute-006',
      instituteName: 'Community Support Centre',
      fullAddress: 'Community Support Centre, Delhi',
      area: 'Delhi',
      instituteLatitude: null,
      instituteLongitude: null,
      scheduledDateTime: scheduled,
      priority: Priority.low,
      status: AssignmentStatus.assigned,
      createdAt: lifetime.createdAt,
      expiresAt: lifetime.expiresAt,
    );
  }(),
];