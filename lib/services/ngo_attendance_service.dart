import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user.dart';

enum AttendanceType {
  beneficiary,
  staff,
}

class AttendanceRecord {
  final String id;
  final AttendanceType type;
  final DateTime date;
  final int presentCount;
  final String? notes;
  final String? videoEvidencePath;

  AttendanceRecord({
    required this.id,
    required this.type,
    required this.date,
    required this.presentCount,
    this.notes,
    this.videoEvidencePath,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as String,
      type: (map['attendance_type'] as String) == 'beneficiary'
          ? AttendanceType.beneficiary
          : AttendanceType.staff,
      date: DateTime.parse(map['attendance_date'] as String),
      presentCount: map['present_count'] as int,
      notes: map['notes'] as String?,
      videoEvidencePath: map['video_evidence_path'] as String?,
    );
  }
}

class NgoAttendanceService {
  NgoAttendanceService._();

  static final NgoAttendanceService instance = NgoAttendanceService._();

  final SupabaseClient _client = Supabase.instance.client;

  Future<void> submitAttendance({
    required AppUser user,
    required AttendanceType type,
    required int presentCount,
    String? notes,
    String? videoEvidencePath,
    DateTime? date,
  }) async {
    final attendanceDate = date ?? DateTime.now();

    final dateOnly =
        '${attendanceDate.year.toString().padLeft(4, '0')}-'
        '${attendanceDate.month.toString().padLeft(2, '0')}-'
        '${attendanceDate.day.toString().padLeft(2, '0')}';

    await _client.from('ngo_attendance').upsert(
      {
        'profile_id': user.id,
        'organization_id': user.organizationId,
        'attendance_type':
            type == AttendanceType.beneficiary
                ? 'beneficiary'
                : 'staff',
        'attendance_date': dateOnly,
        'present_count': presentCount,
        'notes': notes,
        'video_evidence_path': videoEvidencePath,
      },
      onConflict: 'profile_id,attendance_type,attendance_date',
    );
  }

  Future<List<AttendanceRecord>> fetchHistory(
    String profileId,
  ) async {
    final rows = await _client
        .from('ngo_attendance')
        .select()
        .eq('profile_id', profileId)
        .order('attendance_date', ascending: false);

    return (rows as List)
        .map(
          (r) => AttendanceRecord.fromMap(
            r as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// Returns only today's attendance records.
  Future<List<AttendanceRecord>> fetchToday(
    String profileId,
  ) async {
    final now = DateTime.now();

    final today =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    final rows = await _client
        .from('ngo_attendance')
        .select()
        .eq('profile_id', profileId)
        .eq('attendance_date', today)
        .order('attendance_type');

    return (rows as List)
        .map(
          (r) => AttendanceRecord.fromMap(
            r as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// Returns today's beneficiary attendance count.
  Future<int> fetchTodayBeneficiaryCount(
    String profileId,
  ) async {
    final records = await fetchToday(profileId);

    for (final record in records) {
      if (record.type == AttendanceType.beneficiary) {
        return record.presentCount;
      }
    }

    return 0;
  }

  /// Returns today's staff attendance count.
  Future<int> fetchTodayStaffCount(
    String profileId,
  ) async {
    final records = await fetchToday(profileId);

    for (final record in records) {
      if (record.type == AttendanceType.staff) {
        return record.presentCount;
      }
    }

    return 0;
  }

  /// Whether attendance has been submitted today.
  Future<bool> hasSubmittedToday(
    String profileId,
  ) async {
    final records = await fetchToday(profileId);
    return records.isNotEmpty;
  }
}