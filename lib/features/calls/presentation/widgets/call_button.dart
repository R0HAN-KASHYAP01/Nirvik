// lib/features/calls/presentation/widgets/call_button.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../models/user.dart';
import '../../../../services/session_service.dart';
import '../../../../services/video_call_service.dart';
import '../../../../utils/call_permission.dart';
import '../video_call_screen.dart';

class CallButton extends StatelessWidget {
  static const _ringTimeout = Duration(seconds: 30);

  final String calleeId;
  final String calleeName;
  final UserRole calleeRole;

  const CallButton({
    super.key,
    required this.calleeId,
    required this.calleeName,
    required this.calleeRole,
  });

  Future<bool> _ensurePermissions(BuildContext context) async {
    final statuses = await [Permission.camera, Permission.microphone].request();
    final granted = statuses.values.every((s) => s.isGranted);
    if (!granted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera and microphone permissions are required to make a call.'),
        ),
      );
    }
    return granted;
  }

  @override
  Widget build(BuildContext context) {
    final me = SessionService.instance.currentUser!;
    final callType = CallPermission.callTypeFor(from: me.role, to: calleeRole);
    if (callType == null) return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.video_call),
      tooltip: 'Call $calleeName',
      onPressed: () async {
        final hasPermissions = await _ensurePermissions(context);
        if (!hasPermissions) return;

        final call = await VideoCallService.instance.startCall(
          calleeId: calleeId,
          callType: callType,
        );

        // Auto-mark missed if still ringing after the timeout — safe
        // no-op if the callee already accepted/rejected by then.
        Future.delayed(_ringTimeout, () {
          VideoCallService.instance.markMissed(call.id);
        });

        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VideoCallScreen(
              callId: call.id,
              channelId: call.channelId,
              currentUserId: me.id,
              currentUserName: me.name,
              isCaller: true,
              onCallEnded: () {
                VideoCallService.instance.end(call.id);
                
              },
            ),
          ),
        );
      },
    );
  }
}