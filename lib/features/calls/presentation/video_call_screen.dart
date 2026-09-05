// lib/features/calls/presentation/video_call_screen.dart
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../../../core/config/zego_config.dart';

/// Video-only for now — the DB's call_type encodes caller/callee direction,
/// not media type, so there's no audio/video distinction to read from it.
class VideoCallScreen extends StatelessWidget {
  final String callId;
  final String channelId;
  final String currentUserId;
  final String currentUserName;
  final VoidCallback onCallEnded;

  const VideoCallScreen({
    super.key,
    required this.callId,
    required this.channelId,
    required this.currentUserId,
    required this.currentUserName,
    required this.onCallEnded,
  });

  @override
  Widget build(BuildContext context) {
    final config = ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall();

    return ZegoUIKitPrebuiltCall(
      appID: ZegoConfig.appID,
      appSign: ZegoConfig.appSign,
      userID: currentUserId,
      userName: currentUserName,
      callID: channelId,
      config: config,
      events: ZegoUIKitPrebuiltCallEvents(
        onCallEnd: (event, defaultAction) {
          onCallEnded();
          defaultAction.call();
        },
      ),
    );
  }
}