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

      // TODO: state_admin / district_admin were added after this
      // permission matrix was designed. They currently can't call or
      // be called by anyone. Tell me the allowed pairings + the exact
      // call_type strings your video_calls CHECK constraint accepts,
      // and I'll fill these in correctly.
      case UserRole.stateAdmin:
        return null;
      case UserRole.districtAdmin:
        return null;
    }
  }
}