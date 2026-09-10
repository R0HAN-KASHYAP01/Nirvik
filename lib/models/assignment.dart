enum Priority { low, medium, high }

extension PriorityLabel on Priority {
  String get label {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
    }
  }
}

/// `overdue` has been removed per product requirement — assignments no
/// longer surface an "overdue" state anywhere in the UI. `expired`
/// replaces it: an assignment not completed within its 2-day lifetime
/// is marked expired and released back to the assignment pool.
enum AssignmentStatus { assigned, inProgress, completed, expired }

extension AssignmentStatusLabel on AssignmentStatus {
  String get label {
    switch (this) {
      case AssignmentStatus.assigned:
        return 'Assigned';
      case AssignmentStatus.inProgress:
        return 'In Progress';
      case AssignmentStatus.completed:
        return 'Completed';
      case AssignmentStatus.expired:
        return 'Expired';
    }
  }
}

/// Radius (km) the inspector must be within to press "Start Assignment".
/// Distinct from the tighter 500 m arrival-verification radius enforced
/// later in ArrivalVerificationScreen.
const double kAssignmentStartRadiusKm = 2.0;

/// Time window an inspector has, after starting an assignment, to
/// complete geo (arrival) verification and move on to the checklist.
const Duration kVerificationWindow = Duration(hours: 1);

/// Total lifetime an assignment stays valid with an inspector before it
/// expires and is released back to the pool.
const Duration kAssignmentLifetime = Duration(days: 2);

class AssignmentSummary {
  /// Supabase pmu_assignments.id
  final String id;

  /// Supabase ngo_institutes.profile_id
  final String instituteProfileId;

  /// Real institute name. Never render directly before the assignment
  /// has been started — use [displayName].
  final String instituteName;

  /// Full street address. Never render directly before the assignment
  /// has been started — use [displayLocation].
  final String fullAddress;

  /// Coarse, non-identifying locality (e.g. "Sector 5, New Delhi").
  /// Always safe to display, even before starting.
  final String area;

  /// Institute latitude — needed internally (pre-start) to compute the
  /// 2 km start-radius check even though the address stays hidden.
  final double? instituteLatitude;
  final double? instituteLongitude;

  final DateTime scheduledDateTime;
  final Priority priority;
  final AssignmentStatus status;

  /// When the assignment was created. Used to compute [expiresAt].
  final DateTime createdAt;

  /// When the inspector passed the 2 km check and pressed "Start
  /// Assignment". Null until then.
  final DateTime? startedAt;

  /// Hard expiry: 2 days after [createdAt].
  final DateTime expiresAt;

  const AssignmentSummary({
    required this.id,
    required this.instituteProfileId,
    required this.instituteName,
    required this.fullAddress,
    required this.area,
    required this.instituteLatitude,
    required this.instituteLongitude,
    required this.scheduledDateTime,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.startedAt,
  });

  bool get isStarted => startedAt != null;

  DateTime? get verificationDeadline => startedAt?.add(kVerificationWindow);

  bool get isVerificationWindowExpired {
    final deadline = verificationDeadline;
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline);
  }

  /// True once 2 days have passed since creation, regardless of the
  /// [status] currently recorded (covers the gap before lazy-expiry
  /// sync writes 'expired' back to the DB).
  bool get isPastLifetime => DateTime.now().isAfter(expiresAt);

  bool get isActive =>
      status != AssignmentStatus.completed &&
      status != AssignmentStatus.expired &&
      !isPastLifetime;

  /// Institute name to render. Hidden until started.
  String get displayName => isStarted ? instituteName : 'Assigned Institute';

  /// Location text to render. Only the coarse area is shown until
  /// started; the full address is revealed afterwards.
  String get displayLocation => isStarted ? fullAddress : area;
}