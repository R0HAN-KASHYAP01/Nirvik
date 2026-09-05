// lib/features/calls/presentation/widgets/call_button.dart
import 'package:flutter/material.dart';
import '../../../../models/user.dart';
import '../../../../services/session_service.dart';
import '../../../../services/video_call_service.dart';
import '../../../../utils/call_permission.dart';
import '../video_call_screen.dart';

class CallButton extends StatelessWidget {
  final String calleeId;
  final String calleeName;
  final UserRole calleeRole;

  const CallButton({
    super.key,
    required this.calleeId,
    required this.calleeName,
    required this.calleeRole,
  });

  @override
  Widget build(BuildContext context) {
    final me = SessionService.instance.currentUser!;
    final callType = CallPermission.callTypeFor(from: me.role, to: calleeRole);
    if (callType == null) return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.video_call),
      tooltip: 'Call $calleeName',
      onPressed: () async {
        final call = await VideoCallService.instance.startCall(
          calleeId: calleeId,
          callType: callType,
        );
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VideoCallScreen(
              callId: call.id,
              channelId: call.channelId,
              currentUserId: me.id,
              currentUserName: me.name,
              onCallEnded: () {
                VideoCallService.instance.end(call.id);
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }
}