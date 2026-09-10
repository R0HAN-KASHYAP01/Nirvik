import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/assignment.dart';
import '../../../utils/geo_utils.dart';
import '../data/assignments_repository.dart';
import 'arrival_verification_screen.dart';

class AssignmentDetailsScreen extends StatefulWidget {
  final AssignmentSummary assignment;

  const AssignmentDetailsScreen({super.key, required this.assignment});

  @override
  State<AssignmentDetailsScreen> createState() =>
      _AssignmentDetailsScreenState();
}

class _AssignmentDetailsScreenState extends State<AssignmentDetailsScreen> {
  final AssignmentsRepository _repository = AssignmentsRepository();

  late AssignmentSummary _assignment;
  bool _isStarting = false;
  String? _message;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _assignment = widget.assignment;

    // Rebuild every 30s so the verification countdown and any expiry
    // banners stay accurate without user interaction.
    _tickTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  Color _statusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.assigned:
        return Colors.blueGrey;
      case AssignmentStatus.inProgress:
        return Colors.indigo;
      case AssignmentStatus.completed:
        return Colors.green;
      case AssignmentStatus.expired:
        return Colors.grey;
    }
  }

  Color _priorityColor(Priority priority) {
    switch (priority) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.orange;
      case Priority.high:
        return Colors.red;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} · '
        '$hour:$minute $period';
  }

  String _formatRemaining(Duration remaining) {
    if (remaining.isNegative) return '0m';
    final minutes = remaining.inMinutes % 60;
    final hours = remaining.inHours;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  Future<void> _startAssignment() async {
    if (_isStarting) return;

    setState(() {
      _isStarting = true;
      _message = null;
    });

    try {
      final latitude = _assignment.instituteLatitude;
      final longitude = _assignment.instituteLongitude;

      if (latitude == null || longitude == null) {
        setState(() {
          _message =
              'Institute location is not available for this assignment. '
              'Contact PMU staff.';
        });
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _message =
              'Location services are disabled. Please enable GPS and try again.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _message =
              'Location permission was denied. Please allow location access.';
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _message =
              'Location permission is permanently denied. Please enable it from device settings.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final distanceKm = GeoUtils.distanceKm(
        position.latitude,
        position.longitude,
        latitude,
        longitude,
      );

      final result = await _repository.startAssignment(
        assignment: _assignment,
        distanceKm: distanceKm,
      );

      if (!mounted) return;

      if (!result.success) {
        setState(() {
          _message = result.message ?? 'Unable to start this assignment.';
        });
        return;
      }

      setState(() {
        _assignment = result.assignment!;
        _message = 'Assignment started. You have 1 hour to complete geo '
            'verification at the institute.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = 'Unable to start this assignment. Please try again.';
      });
      debugPrint('Start assignment error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
      }
    }
  }

  void _continueToVerification() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArrivalVerificationScreen(assignment: _assignment),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assignment Status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              StatusBadge(
                label: _assignment.status.label,
                color: _statusColor(_assignment.status),
              ),
              const SizedBox(width: 10),
              StatusBadge(
                label: '${_assignment.priority.label} priority',
                color: _priorityColor(_assignment.priority),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLockedNotice() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, color: Colors.indigo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Institute details are hidden',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'The institute name and exact address unlock once you are '
                  'within ${kAssignmentStartRadiusKm.toStringAsFixed(0)} km '
                  'and press "Start Assignment". Only the general area is '
                  'shown until then.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentInformation() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assignment Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),
          _buildInfoRow(
            icon: Icons.business_outlined,
            label: 'Project / Institute',
            value: _assignment.displayName,
          ),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: _assignment.isStarted ? 'Address' : 'Area',
            value: _assignment.displayLocation,
          ),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Scheduled Date & Time',
            value: _formatDateTime(_assignment.scheduledDateTime),
          ),
          _buildInfoRow(
            icon: Icons.event_busy_outlined,
            label: 'Assignment Expires',
            value: _formatDateTime(_assignment.expiresAt),
          ),
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: 'Assignment ID',
            value: _assignment.id,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationWindowCard() {
    final deadline = _assignment.verificationDeadline;
    if (deadline == null) return const SizedBox.shrink();

    final remaining = deadline.difference(DateTime.now());
    final expired = _assignment.isVerificationWindowExpired;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            expired ? Icons.timer_off_outlined : Icons.timer_outlined,
            color: expired ? Colors.red : Colors.indigo,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expired
                      ? 'Geo verification window has closed'
                      : 'Time left to complete geo verification',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  expired
                      ? 'Contact PMU staff for assistance.'
                      : _formatRemaining(remaining),
                  style: TextStyle(
                    fontSize: 12,
                    color: expired ? Colors.red : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage() {
    if (_message == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Text(
          _message!,
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
      ),
    );
  }

  Widget _buildActionArea() {
    final assignment = _assignment;

    if (assignment.status == AssignmentStatus.completed) {
      return const AppCard(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'This assignment has already been completed.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    if (assignment.status == AssignmentStatus.expired ||
        assignment.isPastLifetime) {
      return const AppCard(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.event_busy_outlined, color: Colors.grey),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'This assignment has expired. It has been released back '
                'to the assignment pool.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    if (!assignment.isStarted) {
      return PrimaryButton(
        label: _isStarting ? 'Checking location...' : 'Start Assignment',
        onPressed: _isStarting ? () {} : _startAssignment,
      );
    }

    if (assignment.isVerificationWindowExpired) {
      return const AppCard(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.timer_off_outlined, color: Colors.red),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'The 1-hour geo verification window has closed. Contact '
                'PMU staff for guidance.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    return PrimaryButton(
      label: 'Continue to Geo Verification',
      onPressed: _continueToVerification,
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignment = _assignment;

    return Scaffold(
      appBar: AppBar(title: const Text('Assignment Details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            assignment.displayName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            assignment.displayLocation,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          _buildStatusSection(),
          const SizedBox(height: 12),
          if (!assignment.isStarted) ...[
            _buildLockedNotice(),
            const SizedBox(height: 12),
          ],
          _buildAssignmentInformation(),
          const SizedBox(height: 12),
          if (assignment.isStarted) ...[
            _buildVerificationWindowCard(),
            const SizedBox(height: 12),
          ],
          _buildMessage(),
          const SizedBox(height: 8),
          _buildActionArea(),
        ],
      ),
    );
  }
}