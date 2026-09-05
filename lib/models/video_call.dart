// lib/models/video_call.dart
class VideoCall {
  final String id;
  final String callerProfileId;
  final String calleeProfileId;
  final String callType;
  final String channelId;
  final String status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? durationSeconds;

  const VideoCall({
    required this.id,
    required this.callerProfileId,
    required this.calleeProfileId,
    required this.callType,
    required this.channelId,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.durationSeconds,
  });

  factory VideoCall.fromJson(Map<String, dynamic> json) => VideoCall(
        id: json['id'] as String,
        callerProfileId: json['caller_profile_id'] as String,
        calleeProfileId: json['callee_profile_id'] as String,
        callType: json['call_type'] as String,
        channelId: json['channel_id'] as String,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        startedAt: json['started_at'] != null
            ? DateTime.parse(json['started_at'] as String)
            : null,
        endedAt: json['ended_at'] != null
            ? DateTime.parse(json['ended_at'] as String)
            : null,
        durationSeconds: json['duration_seconds'] as int?,
      );
}