// lib/features/calls/presentation/widgets/incoming_call_listener.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/video_call.dart';
import '../../../../services/session_service.dart';
import '../../../../services/video_call_service.dart';
import '../video_call_screen.dart';
import 'incoming_call_banner.dart';

/// Wrap a shell screen's body with this to receive ringing-call banners
/// for the currently logged-in user (Inspector or Institute).
///
/// Uses an inline Stack banner instead of showDialog — a dialog's
/// full-screen ModalBarrier can get stuck (invisible, blocking all taps)
/// if two ringing rows race the async caller-name lookup and both try
/// to open a dialog. A banner has no barrier, so that failure mode
/// can't happen: at worst the wrong call briefly shows.
class IncomingCallListener extends StatefulWidget {
  final Widget child;
  const IncomingCallListener({super.key, required this.child});

  @override
  State<IncomingCallListener> createState() => _IncomingCallListenerState();
}

class _IncomingCallListenerState extends State<IncomingCallListener> {
  static const _maxRingAge = Duration(seconds: 60);

  StreamSubscription<List<VideoCall>>? _sub;
  VideoCall? _activeCall;
  String _callerName = '';
  bool _busy = false; // prevents double-tap / concurrent accept-reject

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
    if (calls.isEmpty) {
      if (mounted && _activeCall != null) {
        setState(() => _activeCall = null);
      }
      return;
    }

    final call = calls.first;

    // Ignore/close stale rings — prevents a dead call left in the DB
    // (e.g. app killed mid-ring) from resurfacing on next launch.
    final age = DateTime.now().toUtc().difference(call.createdAt.toUtc());
    if (age > _maxRingAge) {
      await VideoCallService.instance.end(call.id);
      return;
    }

    // Already showing this exact call — don't refetch/rebuild.
    if (_activeCall?.id == call.id) return;

    final callerProfile = await Supabase.instance.client
        .from('profiles')
        .select('full_name')
        .eq('id', call.callerProfileId)
        .maybeSingle();
    final callerName = callerProfile?['full_name'] as String? ?? 'Unknown caller';

    if (!mounted) return;
    setState(() {
      _activeCall = call;
      _callerName = callerName;
    });
  }

  Future<void> _accept() async {
    final call = _activeCall;
    if (call == null || _busy) return;
    setState(() => _busy = true);

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
      if (mounted) setState(() { _activeCall = null; _busy = false; });
      return;
    }

    await VideoCallService.instance.accept(call.id);
    if (!mounted) return;
    setState(() { _activeCall = null; _busy = false; });
    _goToCallScreen(call);
  }

  Future<void> _reject() async {
    final call = _activeCall;
    if (call == null || _busy) return;
    setState(() => _busy = true);
    await VideoCallService.instance.reject(call.id);
    if (mounted) setState(() { _activeCall = null; _busy = false; });
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
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_activeCall != null)
          Positioned(
            top: 0,
            left: 8,
            right: 8,
            child: IncomingCallBanner(
              call: _activeCall!,
              callerName: _callerName,
              onAccept: _accept,
              onReject: _reject,
            ),
          ),
      ],
    );
  }
}