// lib/models/district_inspector.dart
//
// Data shapes used by the District Administrator's inspector features.
// Built from the rows returned by the RPC functions in
// supabase/district_admin_inspectors.sql.

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}

/// e.g. "19 Sep, 2:30 PM"
String formatDistrictDateTime(DateTime dt) {
  final local = dt.toLocal();
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.day} ${_months[local.month - 1]}, $hour12:$minute $suffix';
}

/// e.g. "5m ago", "3h ago", "2d ago"
String timeAgoLabel(DateTime? dt) {
  if (dt == null) return 'Never';
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

class DistrictInspector {
  const DistrictInspector({
    required this.profileId,
    required this.fullName,
    this.officialEmail,
    this.mobileNumber,
    this.inspectorId,
    this.designation,
    this.department,
    this.pmuUnitName,
    this.state,
    this.district,
    this.assignedRegion,
    this.schemeCategory,
    this.schemeCode,
    this.locationUpdatedAt,
    this.onlineFlag = false,
    this.lastSeen,
    this.activeAssignments = 0,
    this.completedAssignments = 0,
    this.totalAssignments = 0,
  });

  final String profileId;
  final String fullName;
  final String? officialEmail;
  final String? mobileNumber;
  final String? inspectorId;
  final String? designation;
  final String? department;
  final String? pmuUnitName;
  final String? state;
  final String? district;
  final String? assignedRegion;
  final String? schemeCategory;
  final String? schemeCode;
  final DateTime? locationUpdatedAt;

  /// profiles.is_online as stored. Use [isOnline] for display logic.
  final bool onlineFlag;

  /// profiles.last_seen
  final DateTime? lastSeen;

  final int activeAssignments;
  final int completedAssignments;
  final int totalAssignments;

  /// Same rule AssignmentEngine uses: flagged online AND heartbeat seen
  /// within the last 2 minutes.
  static const Duration onlineWindow = Duration(minutes: 2);

  bool get isOnline {
    final seen = lastSeen;
    if (!onlineFlag || seen == null) return false;
    return DateTime.now().difference(seen) <= onlineWindow;
  }

  /// "Designation · Department", skipping whichever is missing.
  String get subtitle => [designation, department]
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .join(' · ');

  String get initial {
    final trimmed = fullName.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  factory DistrictInspector.fromJson(Map<String, dynamic> json) {
    String? text(String key) {
      final value = json[key]?.toString().trim();
      return (value == null || value.isEmpty) ? null : value;
    }

    int count(String key) => (json[key] as num?)?.toInt() ?? 0;

    return DistrictInspector(
      profileId: json['profile_id'].toString(),
      fullName: text('full_name') ?? 'Unnamed inspector',
      officialEmail: text('official_email'),
      mobileNumber: text('mobile_number'),
      inspectorId: text('inspector_id'),
      designation: text('designation'),
      department: text('department'),
      pmuUnitName: text('pmu_unit_name'),
      state: text('state'),
      district: text('district'),
      assignedRegion: text('assigned_region'),
      schemeCategory: text('scheme_category'),
      schemeCode: text('scheme_code'),
      locationUpdatedAt: _parseDate(json['location_updated_at']),
      onlineFlag: json['is_online'] == true,
      lastSeen: _parseDate(json['last_seen']),
      activeAssignments: count('active_assignments'),
      completedAssignments: count('completed_assignments'),
      totalAssignments: count('total_assignments'),
    );
  }
}

/// An assignment that is currently active for an institute in the
/// district (status assigned / in_progress and not yet expired).
class InstituteAssignmentInfo {
  const InstituteAssignmentInfo({
    required this.assignmentId,
    required this.instituteProfileId,
    required this.inspectorProfileId,
    required this.status,
    required this.priority,
    this.inspectorName,
    this.scheduledDateTime,
    this.expiresAt,
  });

  final String assignmentId;
  final String instituteProfileId;
  final String inspectorProfileId;
  final String? inspectorName;
  final String status;
  final String priority;
  final DateTime? scheduledDateTime;
  final DateTime? expiresAt;

  String get statusLabel => status == 'in_progress' ? 'In progress' : 'Assigned';

  String get priorityLabel =>
      priority.isEmpty ? '' : priority[0].toUpperCase() + priority.substring(1);

  factory InstituteAssignmentInfo.fromJson(Map<String, dynamic> json) {
    final name = json['inspector_name']?.toString().trim();
    return InstituteAssignmentInfo(
      assignmentId: json['assignment_id'].toString(),
      instituteProfileId: json['institute_profile_id'].toString(),
      inspectorProfileId: json['inspector_profile_id'].toString(),
      inspectorName: (name == null || name.isEmpty) ? null : name,
      status: (json['status'] ?? '').toString().toLowerCase(),
      priority: (json['priority'] ?? '').toString().toLowerCase(),
      scheduledDateTime: _parseDate(json['scheduled_datetime']),
      expiresAt: _parseDate(json['expires_at']),
    );
  }
}