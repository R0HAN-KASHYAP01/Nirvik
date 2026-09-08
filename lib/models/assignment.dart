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

enum AssignmentStatus { assigned, inProgress, overdue, completed }

extension AssignmentStatusLabel on AssignmentStatus {
  String get label {
    switch (this) {
      case AssignmentStatus.assigned:
        return 'Assigned';
      case AssignmentStatus.inProgress:
        return 'In Progress';
      case AssignmentStatus.overdue:
        return 'Overdue';
      case AssignmentStatus.completed:
        return 'Completed';
    }
  }
}

class AssignmentSummary {
  /// Supabase pmu_assignments.id
  final String id;

  /// Supabase ngo_institutes.profile_id
  final String instituteProfileId;

  final String projectName;
  final String location;

  /// Latitude of the assigned institute from ngo_institutes.
  final double? instituteLatitude;

  /// Longitude of the assigned institute from ngo_institutes.
  final double? instituteLongitude;

  final DateTime scheduledDateTime;
  final Priority priority;
  final AssignmentStatus status;

  const AssignmentSummary({
    required this.id,
    required this.instituteProfileId,
    required this.projectName,
    required this.location,
    required this.instituteLatitude,
    required this.instituteLongitude,
    required this.scheduledDateTime,
    required this.priority,
    required this.status,
  });
}
