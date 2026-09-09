// lib/features/calls/presentation/call_history_screen.dart
import 'package:flutter/material.dart';
import '../../../services/video_call_service.dart';
import '../../../models/video_call.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  late Future<List<CallHistoryEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = VideoCallService.instance.fetchCallHistory();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = VideoCallService.instance.fetchCallHistory();
    });
    await _future;
  }

  IconData _statusIcon(CallHistoryEntry entry) {
    switch (entry.call.status) {
      case 'accepted':
      case 'ended':
        return entry.isOutgoing ? Icons.call_made : Icons.call_received;
      case 'rejected':
        return Icons.call_end;
      case 'missed':
        return entry.isOutgoing ? Icons.call_missed_outgoing : Icons.call_missed;
      default:
        return Icons.call;
    }
  }

  Color _statusColor(CallHistoryEntry entry) {
    switch (entry.call.status) {
      case 'rejected':
      case 'missed':
        return Colors.red;
      case 'accepted':
      case 'ended':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(CallHistoryEntry entry) {
    switch (entry.call.status) {
      case 'ringing':
        return 'Ringing';
      case 'accepted':
        return 'In progress';
      case 'rejected':
        return entry.isOutgoing ? 'Declined' : 'You declined';
      case 'missed':
        return entry.isOutgoing ? 'No answer' : 'Missed';
      case 'ended':
        final d = entry.call.durationSeconds;
        if (d == null) return 'Ended';
        final m = d ~/ 60;
        final s = d % 60;
        return 'Ended · ${m > 0 ? '${m}m ' : ''}${s}s';
      default:
        return entry.call.status;
    }
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final isToday = local.year == now.year && local.month == now.month && local.day == now.day;
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    if (isToday) return '$hh:$mm';
    return '${local.day}/${local.month} $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Call History')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<CallHistoryEntry>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Could not load call history.')),
                  ),
                ],
              );
            }
            final entries = snapshot.data ?? [];
            if (entries.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No calls yet.')),
                  ),
                ],
              );
            }
            return ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final entry = entries[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _statusColor(entry).withValues(alpha: 0.15),
                    child: Icon(_statusIcon(entry), color: _statusColor(entry)),
                  ),
                  title: Text(
                    entry.isOutgoing ? 'To ${entry.otherPartyName}' : 'From ${entry.otherPartyName}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(_statusLabel(entry)),
                  trailing: Text(
                    _formatTime(entry.call.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}