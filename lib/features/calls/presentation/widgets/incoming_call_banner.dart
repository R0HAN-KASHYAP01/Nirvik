// lib/features/calls/presentation/widgets/incoming_call_banner.dart
import 'package:flutter/material.dart';
import '../../../../models/video_call.dart';

class IncomingCallBanner extends StatelessWidget {
  final VideoCall call;
  final String callerName;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingCallBanner({
    super.key,
    required this.call,
    required this.callerName,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircleAvatar(radius: 24, child: Icon(Icons.call, size: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      callerName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      call.callType == 'audio' ? 'Incoming audio call' : 'Incoming video call',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: onReject,
                style: IconButton.styleFrom(backgroundColor: Colors.red),
                icon: const Icon(Icons.call_end, color: Colors.white),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: onAccept,
                style: IconButton.styleFrom(backgroundColor: Colors.green),
                icon: const Icon(Icons.call, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}