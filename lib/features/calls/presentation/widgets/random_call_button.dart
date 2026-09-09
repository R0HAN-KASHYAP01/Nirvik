// lib/features/calls/presentation/widgets/random_call_button.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../services/session_service.dart';
import '../../../../services/video_call_service.dart';
import '../video_call_screen.dart';

/// Button that starts a video call to a random institute within
/// [radiusKm] of the inspector's current GPS location. The inspector
/// never chooses which institute — the backend picks one at random.
class RandomVideoCallButton extends StatefulWidget {
  final double radiusKm;
  const RandomVideoCallButton({super.key, this.radiusKm = 50});

  @override
  State<RandomVideoCallButton> createState() => _RandomVideoCallButtonState();
}

class _RandomVideoCallButtonState extends State<RandomVideoCallButton> {
  static const _ringTimeout = Duration(seconds: 30);

  bool _loading = false;

  Future<bool> _ensureCallPermissions() async {
    final statuses = await [Permission.camera, Permission.microphone].request();
    return statuses.values.every((s) => s.isGranted);
  }

  Future<Position?> _getCurrentLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      return null;
    }
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _startRandomCall() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final hasCallPermissions = await _ensureCallPermissions();
      if (!hasCallPermissions) {
        _showMessage('Camera and microphone permissions are required to make a call.');
        return;
      }

      final position = await _getCurrentLocation();
      if (position == null) {
        _showMessage('Location access is required to find nearby institutes.');
        return;
      }

      final call = await VideoCallService.instance.startRandomNearbyCall(
        inspectorLat: position.latitude,
        inspectorLng: position.longitude,
        radiusKm: widget.radiusKm,
      );

      if (call == null) {
        _showMessage('No institutes found within ${widget.radiusKm.toInt()} km.');
        return;
      }

      Future.delayed(_ringTimeout, () {
        VideoCallService.instance.markMissed(call.id);
      });

      if (!mounted) return;
      final me = SessionService.instance.currentUser!;
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
    } catch (e) {
      _showMessage('Could not start the call. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _loading ? null : _startRandomCall,
      icon: _loading
          ? const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      )
          : const Icon(Icons.shuffle),
      label: Text(_loading ? 'Finding institute...' : 'Random Video Call'),
    );
  }
}