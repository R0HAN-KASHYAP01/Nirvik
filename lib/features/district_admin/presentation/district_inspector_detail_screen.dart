// lib/features/district_admin/presentation/district_inspector_detail_screen.dart
//
// Full details for one inspector, plus a "Start Video Call" button that
// reuses the existing call feature (VideoCallService + VideoCallScreen).
//
// Call flow notes:
//  * The call_type comes from CallPermission.callTypeFor, never hardcoded.
//  * isCaller: true makes VideoCallScreen watch the call row, so the admin
//    is taken out of the room when the inspector declines or misses it.
//  * A 30 s ring timer marks the call 'missed' if nobody answered.
//    VideoCallService.markMissed only changes rows still in 'ringing', so
//    it can never overwrite an accepted / rejected / ended call.
//  * On hang-up the call is only marked 'ended' if it was not already
//    rejected / missed / ended, so call history keeps the right status.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/district_inspector.dart';
import '../../../models/user.dart';
import '../../../services/session_service.dart';
import '../../../services/video_call_service.dart';
import '../../../utils/call_permission.dart';
import '../../calls/presentation/video_call_screen.dart';

const Color _kBackground = Color(0xFFEAF2F8);
const Color _kBorder = Color(0xFFD1DEE7);
const Color _kTextGrey = Color(0xFF667788);
const Color _kOnline = Color(0xFF1E7A46);
const Color _kOffline = Color(0xFF5B6472);

class DistrictInspectorDetailScreen extends StatefulWidget {
  final DistrictInspector inspector;

  const DistrictInspectorDetailScreen({super.key, required this.inspector});

  @override
  State<DistrictInspectorDetailScreen> createState() =>
      _DistrictInspectorDetailScreenState();
}

class _DistrictInspectorDetailScreenState
    extends State<DistrictInspectorDetailScreen> {
  bool _calling = false;
  Timer? _ringTimer;

  DistrictInspector get inspector => widget.inspector;

  @override
  void dispose() {
    _ringTimer?.cancel();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _startCall() async {
    final me = SessionService.instance.currentUser;
    if (me == null) return;

    final callType =
        CallPermission.callTypeFor(from: me.role, to: UserRole.inspector);
    if (callType == null) {
      _snack('You are not permitted to call this inspector.');
      return;
    }

    if (!inspector.isOnline) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Inspector appears offline'),
          content: Text(
            '${inspector.fullName} was last seen '
            '${timeAgoLabel(inspector.lastSeen)}. The call may go '
            'unanswered.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Call anyway'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    setState(() => _calling = true);
    try {
      final call = await VideoCallService.instance.startCall(
        calleeId: inspector.profileId,
        callType: callType,
      );
      if (!mounted) return;

      _ringTimer?.cancel();
      _ringTimer = Timer(const Duration(seconds: 30), () {
        VideoCallService.instance.markMissed(call.id).catchError((_) {});
      });

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            callId: call.id,
            channelId: call.channelId,
            currentUserId: me.id,
            currentUserName: me.name,
            isCaller: true,
            onCallEnded: () {
              _ringTimer?.cancel();
              unawaited(_endCallSafely(call.id));
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) _snack('Could not start call: $e');
    } finally {
      _ringTimer?.cancel();
      if (mounted) setState(() => _calling = false);
    }
  }

  /// Marks the call 'ended' unless it already finished as rejected /
  /// missed / ended.
  Future<void> _endCallSafely(String callId) async {
    try {
      final current = await VideoCallService.instance
          .watchCall(callId)
          .first
          .timeout(const Duration(seconds: 5));
      final status = current?.status;
      if (status == 'rejected' || status == 'missed' || status == 'ended') {
        return;
      }
      await VideoCallService.instance.end(callId, startedAt: current?.startedAt);
    } catch (_) {
      await VideoCallService.instance.end(callId).catchError((_) {});
    }
  }

  static String _v(String? value) =>
      (value == null || value.trim().isEmpty) ? '—' : value.trim();

  static String _titleCase(String? key) {
    if (key == null || key.trim().isEmpty) return '—';
    return key
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final online = inspector.isOnline;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(title: Text(inspector.fullName)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        children: [
          // ---------------- header ----------------
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: accent.withValues(alpha: 0.12),
                  child: Text(
                    inspector.initial,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inspector.fullName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      if (inspector.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          inspector.subtitle,
                          style: const TextStyle(
                              fontSize: 12.5, color: _kTextGrey),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StatusBadge(
                            label: online ? 'Online' : 'Offline',
                            color: online ? _kOnline : _kOffline,
                          ),
                          Text(
                            'Last seen ${timeAgoLabel(inspector.lastSeen)}',
                            style: const TextStyle(
                                fontSize: 11.5, color: _kTextGrey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ---------------- stats ----------------
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Active',
                  value: '${inspector.activeAssignments}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatBox(
                  label: 'Completed',
                  value: '${inspector.completedAssignments}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatBox(
                  label: 'All assignments',
                  value: '${inspector.totalAssignments}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ---------------- service details ----------------
          const SectionHeader(title: 'Service Details'),
          const SizedBox(height: 8),
          _InfoCard(
            rows: [
              _DetailRow('Inspector ID', _v(inspector.inspectorId)),
              _DetailRow('Designation', _v(inspector.designation)),
              _DetailRow('Department', _v(inspector.department)),
              _DetailRow('PMU unit', _v(inspector.pmuUnitName)),
              _DetailRow('Assigned region', _v(inspector.assignedRegion)),
              _DetailRow(
                'District',
                '${_v(inspector.district)}, ${_v(inspector.state)}',
              ),
              _DetailRow('Scheme category', _titleCase(inspector.schemeCategory)),
              _DetailRow('Scheme code', _v(inspector.schemeCode)),
            ],
          ),

          const SizedBox(height: 18),

          // ---------------- contact ----------------
          const SectionHeader(title: 'Contact'),
          const SizedBox(height: 8),
          _InfoCard(
            rows: [
              _DetailRow('Official email', _v(inspector.officialEmail)),
              _DetailRow('Mobile', _v(inspector.mobileNumber)),
              _DetailRow(
                'Location updated',
                inspector.locationUpdatedAt == null
                    ? '—'
                    : timeAgoLabel(inspector.locationUpdatedAt),
              ),
            ],
          ),
        ],
      ),

      // Always visible, so the call is one tap away however long the page is.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: FilledButton.icon(
            onPressed: _calling ? null : _startCall,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            icon: _calling
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.video_call_outlined),
            label: Text(_calling ? 'Calling...' : 'Start Video Call'),
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, color: _kTextGrey),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> rows;

  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(children: rows),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: _kTextGrey),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}