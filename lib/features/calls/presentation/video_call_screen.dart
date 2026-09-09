// lib/features/calls/presentation/video_call_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../../../core/config/zego_config.dart';
import '../../../models/video_call.dart';
import '../../../services/video_call_service.dart';

/// Video-only for now — the DB's call_type encodes caller/callee direction,
/// not media type, so there's no audio/video distinction to read from it.
class VideoCallScreen extends StatefulWidget {
  final String callId;
  final String channelId;
  final String currentUserId;
  final String currentUserName;
  final bool isCaller;
  final VoidCallback onCallEnded;

  const VideoCallScreen({
    super.key,
    required this.callId,
    required this.channelId,
    required this.currentUserId,
    required this.currentUserName,
    this.isCaller = false,
    required this.onCallEnded,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  StreamSubscription<VideoCall?>? _statusSub;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    // Only the caller needs this: if the callee never accepts (30s
    // timeout -> 'missed') or declines ('rejected'), no Zego event
    // ever fires because the callee's app never opened the room —
    // so we have to watch the DB row directly to know when to leave.
    if (widget.isCaller) {
      _statusSub =
          VideoCallService.instance.watchCall(widget.callId).listen(_onStatusChange);
    }
  }

  void _onStatusChange(VideoCall? call) {
    if (_finished || !mounted || call == null) return;
    if (call.status == 'missed' || call.status == 'rejected') {
      _finishFromStatus(call.status == 'rejected' ? 'Call declined' : 'No answer');
    }
  }

  /// Ends the call from an out-of-band status change (no Zego event
  /// involved), so this is the one path responsible for its own pop.
  void _finishFromStatus(String message) {
    if (_finished) return;
    _finished = true;
    _statusSub?.cancel();
    widget.onCallEnded();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall();

    return ZegoUIKitPrebuiltCall(
      appID: ZegoConfig.appID,
      appSign: ZegoConfig.appSign,
      userID: widget.currentUserId,
      userName: widget.currentUserName,
      callID: widget.channelId,
      config: config,
      events: ZegoUIKitPrebuiltCallEvents(
        onCallEnd: (event, defaultAction) {
          // Zego already ended its own room — run our cleanup once,
          // then let Zego's default action be the ONLY thing that pops.
          if (!_finished) {
            _finished = true;
            _statusSub?.cancel();
            widget.onCallEnded();
          }
          defaultAction.call();
        },
      ),
    );
  }
}