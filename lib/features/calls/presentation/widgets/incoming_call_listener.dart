// lib/features/calls/presentation/widgets/incoming_call_listener.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/video_call.dart';
import '../../../../services/session_service.dart';
import '../../../../services/video_call_service.dart';
import '../video_call_screen.dart';
import 'incoming_call_dialog.dart';

/// Wrap a shell screen's body with this to receive ringing-call popups
/// for the currently logged-in user (Inspector or Institute).
class IncomingCallListener extends StatefulWidget {
  final Widget child;
  const IncomingCallListener({super.key, required this.child});

  @override
  State<IncomingCallListener> createState() => _IncomingCallListenerState();
}

class _IncomingCallListenerState extends State<IncomingCallListener> {
  static const _maxRingAge = Duration(seconds: 60);

  StreamSubscription<List<VideoCall>>? _sub;
  String? _dialogShownForCallId;

  @override
  void initState() {
    super.initState();
    _sub = VideoCallService.instance.incomingCalls().listen(_handleCalls);
  }

  Future<bool> _ensurePermissions() async {
    final statuses = await [Permission.camera, Permission.microphone].request();
    return statuses.values.every((s) => s.isGranted);
  }

  Future<void> _handleCalls(List<VideoCall> calls) async {
    if (calls.isEmpty) return;
    final call = calls.first;

    // Ignore/close stale rings — prevents a dead call left in the DB
    // (e.g. app killed mid-ring) from blocking the UI on next launch.
    final age = DateTime.now().toUtc().difference(call.createdAt.toUtc());
    if (age > _maxRingAge) {
      await VideoCallService.instance.end(call.id);
      return;
    }

    if (_dialogShownForCallId == call.id) return;
    _dialogShownForCallId = call.id;

    final callerProfile = await Supabase.instance.client
        .from('profiles')
        .select('full_name')
        .eq('id', call.callerProfileId)
        .maybeSingle();
    final callerName = callerProfile?['full_name'] as String? ?? 'Unknown caller';

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => IncomingCallDialog(
        call: call,
        callerName: callerName,
        onAccept: () async {
          Navigator.of(dialogContext).pop();
          final hasPermissions = await _ensurePermissions();
          if (!hasPermissions) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Camera and microphone permissions are required to join the call.'),
                ),
              );
            }
            await VideoCallService.instance.reject(call.id);
            _dialogShownForCallId = null;
            return;
          }
          await VideoCallService.instance.accept(call.id);
          _goToCallScreen(call);
        },
        onReject: () async {
          Navigator.of(dialogContext).pop();
          await VideoCallService.instance.reject(call.id);
          _dialogShownForCallId = null;
        },
      ),
    );
  }

  void _goToCallScreen(VideoCall call) {
    final user = SessionService.instance.currentUser!;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoCallScreen(
          callId: call.id,
          channelId: call.channelId,
          currentUserId: user.id,
          currentUserName: user.name,
          onCallEnded: () {
            VideoCallService.instance.end(call.id, startedAt: call.startedAt);
            Navigator.of(context).pop();
            _dialogShownForCallId = null;
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}