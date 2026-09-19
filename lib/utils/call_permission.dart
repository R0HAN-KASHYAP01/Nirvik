// lib/utils/call_permission.dart
import '../models/user.dart';

/// Encodes who is allowed to initiate a call to whom, and the exact
/// `video_calls.call_type` string Postgres' CHECK constraint requires
/// for that pairing.
class CallPermission {
  CallPermission._();

  static bool canCall({required UserRole from, required UserRole to}) {
    return callTypeFor(from: from, to: to) != null;
  }

  /// Returns the DB value for `video_calls.call_type`, or null if this
  /// caller/callee role pairing isn't allowed.
  static String? callTypeFor({required UserRole from, required UserRole to}) {
    switch (from) {
      case UserRole.official:
        if (to == UserRole.inspector) return 'official_to_inspector';
        if (to == UserRole.ngoInstitute) return 'official_to_institute';
        return null;
      case UserRole.inspector:
        if (to == UserRole.ngoInstitute) return 'inspector_to_institute';
        return null;
      case UserRole.ngoInstitute:
        return null; // institutes never initiate calls
      case UserRole.stateAdmin:
        // NEW: lets a State Admin call the district admin of a district
        // in their state from the State Admin dashboard. Requires a
        // matching 'state_admin_to_district_admin' value to be added to
        // the `video_calls_call_type_check` constraint in Supabase —
        // this Dart-side change alone does not add it.
        if (to == UserRole.districtAdmin) {
          return 'state_admin_to_district_admin';
        }
        return null;
      case UserRole.districtAdmin:
        return null;
    }
  }
}