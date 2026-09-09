// lib/features/calls/presentation/widgets/incoming_call_dialog.dart
import 'package:flutter/material.dart';
import '../../../../models/video_call.dart';

class IncomingCallDialog extends StatelessWidget {
  final VideoCall call;
  final String callerName;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingCallDialog({
    super.key,
    required this.call,
    required this.callerName,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(radius: 32, child: Icon(Icons.call, size: 32)),
              const SizedBox(height: 16),
              Text(callerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(call.callType == 'audio' ? 'Incoming audio call' : 'Incoming video call'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: onReject,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    icon: const Icon(Icons.call_end, color: Colors.white),
                    label: const Text('Decline', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton.icon(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    icon: const Icon(Icons.call, color: Colors.white),
                    label: const Text('Accept', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}