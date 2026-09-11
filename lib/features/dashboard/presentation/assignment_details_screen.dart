import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mjpeg_view/mjpeg_view.dart';
import 'package:video_player/video_player.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/assignment.dart';
import '../../../services/ngo_camera_service.dart';
import '../../../services/ngo_storage_service.dart';
import '../../../utils/geo_utils.dart';
import '../data/assignments_repository.dart';
import 'arrival_verification_screen.dart';

class AssignmentDetailsScreen extends StatefulWidget {
  final AssignmentSummary assignment;

  const AssignmentDetailsScreen({
    super.key,
    required this.assignment,
  });

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

  bool _loadingFeeds = true;
  String? _feedError;
  List<NgoCameraFeed> _cameraFeeds = [];

  @override
  void initState() {
    super.initState();
    _assignment = widget.assignment;

    _tickTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });

    _loadCameraFeeds();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCameraFeeds() async {
    if (mounted) {
      setState(() {
        _loadingFeeds = true;
        _feedError = null;
      });
    }

    debugPrint('========== CAMERA FEED DEBUG ==========');
    debugPrint('Assignment ID: ${_assignment.id}');
    debugPrint('Institute Profile ID: ${_assignment.instituteProfileId}');
    debugPrint('=======================================');

    try {
      final feeds = await NgoCameraService.instance.fetchFeeds(
        _assignment.instituteProfileId,
      );

      debugPrint('Camera feeds returned: ${feeds.length}');

      if (!mounted) {
        return;
      }

      setState(() {
        _cameraFeeds = feeds;
        _loadingFeeds = false;
      });
    } catch (error) {
      debugPrint('Camera feed loading error: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _loadingFeeds = false;
        _feedError = 'Unable to load camera feeds.';
      });
    }
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
    if (remaining.isNegative) {
      return '0m';
    }

    final minutes = remaining.inMinutes % 60;
    final hours = remaining.inHours;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    return '${minutes}m';
  }

  Future<void> _startAssignment() async {
    if (_isStarting) {
      return;
    }

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

      if (!mounted) {
        return;
      }

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
      if (!mounted) {
        return;
      }

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
        builder: (_) => ArrivalVerificationScreen(
          assignment: _assignment,
        ),
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
          Icon(
            icon,
            size: 20,
            color: Colors.black54,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  softWrap: true,
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              StatusBadge(
                label: _assignment.status.label,
                color: _statusColor(_assignment.status),
              ),
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
          const Icon(
            Icons.lock_outline,
            color: Colors.indigo,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Institute details are hidden',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
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

  Widget _buildInspectionWorkflowCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inspection',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Review the assignment information before starting the inspection.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.fact_check_outlined,
                size: 20,
                color: Colors.black54,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inspection Workflow',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Arrival verification → Checklist → Evidence → Findings → Summary → Submission',
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationWindowCard() {
    final deadline = _assignment.verificationDeadline;

    if (deadline == null) {
      return const SizedBox.shrink();
    }

    final remaining = deadline.difference(DateTime.now());
    final expired = _assignment.isVerificationWindowExpired;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  softWrap: true,
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

  Widget _buildCameraSection() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.videocam_outlined,
                color: Colors.indigo,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Camera / CCTV Feeds',
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh feeds',
                onPressed: _loadingFeeds ? null : _loadCameraFeeds,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Camera feeds registered by the assigned institute.',
            softWrap: true,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          _buildCameraFeedContent(),
        ],
      ),
    );
  }

  Widget _buildCameraFeedContent() {
    if (_loadingFeeds) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_feedError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _feedError!,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_cameraFeeds.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.18),
          ),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.videocam_off_outlined,
              size: 34,
              color: Colors.black38,
            ),
            SizedBox(height: 8),
            Text(
              'No camera feeds are registered for this institute.',
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _cameraFeeds.map(_buildCameraFeedCard).toList(),
    );
  }

  Widget _buildCameraFeedCard(NgoCameraFeed feed) {
    final isLive = feed.type == NgoFeedType.liveLink;

    final title = (feed.label != null && feed.label!.trim().isNotEmpty)
        ? feed.label!.trim()
        : isLive
            ? 'Live Camera Feed'
            : 'Uploaded Video';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 340;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 40 : 44,
                height: compact ? 40 : 44,
                decoration: BoxDecoration(
                  color: isLive
                      ? Colors.red.withValues(alpha: 0.08)
                      : Colors.indigo.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isLive
                      ? Icons.live_tv_outlined
                      : Icons.video_library_outlined,
                  size: compact ? 21 : 24,
                  color: isLive ? Colors.red : Colors.indigo,
                ),
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: compact ? 13.5 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isLive ? 'Live link' : 'Uploaded video',
                      style: TextStyle(
                        fontSize: compact ? 11.5 : 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: OutlinedButton.icon(
                        onPressed: () => _openCameraFeed(feed),
                        icon: Icon(
                          isLive
                              ? Icons.visibility_outlined
                              : Icons.play_circle_outline,
                          size: 17,
                        ),
                        label: Text(
                          isLive ? 'Open Feed' : 'Play Video',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openCameraFeed(NgoCameraFeed feed) {
    final isLive = feed.type == NgoFeedType.liveLink;

    if (isLive) {
      _showLiveFeedDialog(feed);
      return;
    }

    _showUploadedVideoDialog(feed);
  }

  Future<void> _showUploadedVideoDialog(NgoCameraFeed feed) async {
    final videoPath = feed.videoPath;

    if (videoPath == null || videoPath.trim().isEmpty) {
      _showFeedMessage(
        'This uploaded video does not have a storage path.',
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return const AlertDialog(
          content: SizedBox(
            width: 260,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Preparing video...',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      final signedUrl = await NgoStorageService.instance.getSignedUrl(
        videoPath,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return _UploadedVideoDialog(
            title: feed.label?.trim().isNotEmpty == true
                ? feed.label!.trim()
                : 'Uploaded Video',
            videoUrl: signedUrl,
          );
        },
      );
    } catch (error, stackTrace) {
      debugPrint('UPLOADED VIDEO SIGNED URL ERROR: $error');
      debugPrint('StackTrace: $stackTrace');

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      _showFeedMessage(
        'Unable to open the uploaded video.',
      );
    }
  }

  void _showFeedMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _showLiveFeedDialog(NgoCameraFeed feed) {
    final streamUrl = feed.streamUrl;

    if (streamUrl == null || streamUrl.trim().isEmpty) {
      _showFeedMessage(
        'This camera feed does not have a stream URL.',
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final screenSize = MediaQuery.sizeOf(context);

        final dialogWidth = (screenSize.width - 32).clamp(
          280.0,
          700.0,
        );

        final videoWidth = dialogWidth.toDouble();

        final videoHeight = (videoWidth * 9 / 16).clamp(
          160.0,
          390.0,
        );

        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.live_tv,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  feed.label?.trim().isNotEmpty == true
                      ? feed.label!.trim()
                      : 'Live Camera Feed',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: videoWidth,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      height: videoHeight.toDouble(),
                      color: Colors.black,
                      child: MjpegView(
                        uri: streamUrl,
                        width: double.infinity,
                        height: videoHeight.toDouble(),
                        fit: BoxFit.contain,
                        fps: 10,
                        timeout: const Duration(seconds: 10),
                        loadingWidget: (context) => const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                        errorWidget: (context) => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Unable to load the live camera feed.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        doneWidget: (context) => const Center(
                          child: Text(
                            'Camera stream ended.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Stream URL',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 5),
                  SelectableText(
                    streamUrl,
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessage() {
    if (_message == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Text(
          _message!,
          softWrap: true,
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
          ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.green,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'This assignment has already been completed.',
                softWrap: true,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.event_busy_outlined,
              color: Colors.grey,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'This assignment has expired. It has been released back '
                'to the assignment pool.',
                softWrap: true,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.timer_off_outlined,
              color: Colors.red,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'The 1-hour geo verification window has closed. Contact '
                'PMU staff for guidance.',
                softWrap: true,
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
      appBar: AppBar(
        title: const Text('Assignment Details'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding =
              constraints.maxWidth < 360 ? 12.0 : 20.0;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              16,
              horizontalPadding,
              24,
            ),
            children: [
              Text(
                assignment.displayName,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: TextStyle(
                  fontSize: constraints.maxWidth < 360 ? 20 : 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                assignment.displayLocation,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
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
              _buildCameraSection(),
              const SizedBox(height: 12),
              _buildInspectionWorkflowCard(),
              const SizedBox(height: 12),
              if (assignment.isStarted) ...[
                _buildVerificationWindowCard(),
                const SizedBox(height: 12),
              ],
              _buildMessage(),
              const SizedBox(height: 8),
              _buildActionArea(),
            ],
          );
        },
      ),
    );
  }
}

class _UploadedVideoDialog extends StatefulWidget {
  final String title;
  final String videoUrl;

  const _UploadedVideoDialog({
    required this.title,
    required this.videoUrl,
  });

  @override
  State<_UploadedVideoDialog> createState() =>
      _UploadedVideoDialogState();
}

class _UploadedVideoDialogState extends State<_UploadedVideoDialog> {
  late final VideoPlayerController _controller;
  late final Future<void> _initializeFuture;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    _initializeFuture = _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    await _controller.initialize();

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    final dialogWidth = (screenSize.width - 32).clamp(
      280.0,
      700.0,
    );

    final availableVideoWidth = dialogWidth.toDouble();

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.video_library_outlined,
            color: Colors.indigo,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: availableVideoWidth,
        child: FutureBuilder<void>(
          future: _initializeFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError ||
                !_controller.value.isInitialized) {
              return const SizedBox(
                height: 220,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Unable to play this uploaded video.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            final videoSize = _controller.value.size;

            final aspectRatio =
                videoSize.width > 0 && videoSize.height > 0
                    ? videoSize.width / videoSize.height
                    : 16 / 9;

            final videoHeight = (availableVideoWidth / aspectRatio)
                .clamp(160.0, 390.0)
                .toDouble();

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    height: videoHeight,
                    color: Colors.black,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: videoSize.width,
                        height: videoSize.height,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      IconButton(
                        tooltip: _controller.value.isPlaying
                            ? 'Pause'
                            : 'Play',
                        icon: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause_circle
                              : Icons.play_circle,
                          size: 38,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_controller.value.isPlaying) {
                              _controller.pause();
                            } else {
                              _controller.play();
                            }
                          });
                        },
                      ),
                      IconButton(
                        tooltip: 'Restart',
                        icon: const Icon(
                          Icons.replay,
                        ),
                        onPressed: () {
                          _controller.seekTo(Duration.zero);
                          _controller.play();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}