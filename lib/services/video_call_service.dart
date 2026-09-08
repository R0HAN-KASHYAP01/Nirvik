// lib/services/video_call_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/video_call.dart';

class VideoCallService {
  VideoCallService._();
  static final VideoCallService instance = VideoCallService._();

  final SupabaseClient _client = Supabase.instance.client;

  Future<void> setOnline(bool online) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('profiles').update({
      'is_online': online,
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('id', uid);
  }

  Future<void> heartbeat() => setOnline(true);

  /// Starts a direct call. [callType] must already be a value the
  /// `video_calls_call_type_check` constraint allows — build it via
  /// CallPermission.callTypeFor(from: ..., to: ...), never hardcode it.
  Future<VideoCall> startCall({
    required String calleeId,
    required String callType,
  }) async {
    final uid = _client.auth.currentUser!.id;
    final channelId = const Uuid().v4();

    final inserted = await _client
        .from('video_calls')
        .insert({
      'caller_profile_id': uid,
      'callee_profile_id': calleeId,
      'call_type': callType,
      'channel_id': channelId,
    })
        .select()
        .single();

    return VideoCall.fromJson(inserted);
  }

  /// Finds a random institute within [radiusKm] of the inspector's
  /// current position and starts a call to it. The inspector never
  /// picks who to call — the backend selects one at random.
  /// Returns null if no institute is within range.
  Future<VideoCall?> startRandomNearbyCall({
    required double inspectorLat,
    required double inspectorLng,
    double radiusKm = 50,
  }) async {
    final response = await _client.rpc('get_random_nearby_institute', params: {
      'p_lat': inspectorLat,
      'p_lng': inspectorLng,
      'p_radius_km': radiusKm,
    });

    final rows = response as List<dynamic>;
    if (rows.isEmpty) return null;

    final institute = rows.first as Map<String, dynamic>;
    final calleeId = institute['profile_id'] as String;

    return startCall(calleeId: calleeId, callType: 'inspector_to_institute');
  }

  Stream<List<VideoCall>> incomingCalls() {
    final uid = _client.auth.currentUser!.id;
    return _client
        .from('video_calls')
        .stream(primaryKey: ['id'])
        .eq('callee_profile_id', uid)
        .map((rows) => rows
        .where((r) => r['status'] == 'ringing')
        .map((r) => VideoCall.fromJson(r))
        .toList());
  }

  Stream<VideoCall?> watchCall(String callId) {
    return _client
        .from('video_calls')
        .stream(primaryKey: ['id'])
        .eq('id', callId)
        .map((rows) => rows.isEmpty ? null : VideoCall.fromJson(rows.first));
  }

  Future<void> accept(String callId) => _client.from('video_calls').update({
    'status': 'accepted',
    'started_at': DateTime.now().toIso8601String(),
  }).eq('id', callId);

  Future<void> reject(String callId) =>
      _client.from('video_calls').update({'status': 'rejected'}).eq('id', callId);

  /// Marks a call as missed — only if it's still 'ringing'. The
  /// `.eq('status', 'ringing')` guard prevents this from ever
  /// overwriting a call that was already accepted/rejected/ended,
  /// even if this fires slightly late due to a race.
  Future<void> markMissed(String callId) => _client
      .from('video_calls')
      .update({
    'status': 'missed',
    'ended_at': DateTime.now().toIso8601String(),
  })
      .eq('id', callId)
      .eq('status', 'ringing');

  Future<void> end(String callId, {DateTime? startedAt}) async {
    final endedAt = DateTime.now();
    final duration =
    startedAt != null ? endedAt.difference(startedAt).inSeconds : null;
    await _client.from('video_calls').update({
      'status': 'ended',
      'ended_at': endedAt.toIso8601String(),
      if (duration != null) 'duration_seconds': duration,
    }).eq('id', callId);
  }

  /// Combined call log for the current user — both calls they made
  /// and calls they received. Returns newest first.
  Future<List<CallHistoryEntry>> fetchCallHistory({int limit = 50}) async {
    final uid = _client.auth.currentUser!.id;

    final rows = await _client
        .from('video_calls')
        .select()
        .or('caller_profile_id.eq.$uid,callee_profile_id.eq.$uid')
        .order('created_at', ascending: false)
        .limit(limit);

    final calls = (rows as List)
        .map((r) => VideoCall.fromJson(r as Map<String, dynamic>))
        .toList();

    final otherIds = <String>{
      for (final c in calls)
        c.callerProfileId == uid ? c.calleeProfileId : c.callerProfileId,
    };

    final profiles = otherIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _client
        .from('profiles')
        .select('id, full_name')
        .inFilter('id', otherIds.toList());

    final nameById = {
      for (final p in profiles)
        p['id'] as String: (p['full_name'] as String?) ?? 'Unknown',
    };

    return calls.map((c) {
      final isOutgoing = c.callerProfileId == uid;
      final otherId = isOutgoing ? c.calleeProfileId : c.callerProfileId;
      return CallHistoryEntry(
        call: c,
        isOutgoing: isOutgoing,
        otherPartyName: nameById[otherId] ?? 'Unknown',
      );
    }).toList();
  }
}

class CallHistoryEntry {
  final VideoCall call;
  final bool isOutgoing;
  final String otherPartyName;

  const CallHistoryEntry({
    required this.call,
    required this.isOutgoing,
    required this.otherPartyName,
  });
}