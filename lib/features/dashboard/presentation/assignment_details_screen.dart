import 'package:flutter/material.dart';
import 'package:mjpeg_view/mjpeg_view.dart';
import 'package:video_player/video_player.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/assignment.dart';
import '../../../services/ngo_camera_service.dart';
import '../../../services/ngo_storage_service.dart';
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

class _AssignmentDetailsScreenState
    extends State<AssignmentDetailsScreen> {
  bool _loadingFeeds = true;
  String? _feedError;
  List<NgoCameraFeed> _cameraFeeds = [];

  AssignmentSummary get assignment => widget.assignment;

  @override
  void initState() {
    super.initState();
    _loadCameraFeeds();
  }

  Future<void> _loadCameraFeeds() async {
    if (mounted) {
      setState(() {
        _loadingFeeds = true;
        _feedError = null;
      });
    }

    debugPrint('========== CAMERA FEED DEBUG ==========');
    debugPrint('Assignment ID: ${assignment.id}');
    debugPrint(
      'Institute Profile ID: ${assignment.instituteProfileId}',
    );
    debugPrint('=======================================');

    try {
      final feeds = await NgoCameraService.instance.fetchFeeds(
        assignment.instituteProfileId,
      );

      debugPrint(
        'Camera feeds returned: ${feeds.length}',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _cameraFeeds = feeds;
        _loadingFeeds = false;
      });
    } catch (error) {
      debugPrint(
        'Camera feed loading error: $error',
      );

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
      case AssignmentStatus.overdue:
        return Colors.red;
      case AssignmentStatus.completed:
        return Colors.green;
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
    final hour =
        dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute =
        dateTime.minute.toString().padLeft(2, '0');

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} · '
        '$hour:$minute $period';
  }

  void _startInspection(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArrivalVerificationScreen(
          assignment: assignment,
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
          Row(
            children: [
              StatusBadge(
                label: assignment.status.label,
                color: _statusColor(assignment.status),
              ),
              const SizedBox(width: 10),
              StatusBadge(
                label:
                    '${assignment.priority.label} priority',
                color: _priorityColor(assignment.priority),
              ),
            ],
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
            value: assignment.projectName,
          ),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: assignment.location,
          ),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Scheduled Date & Time',
            value: _formatDateTime(
              assignment.scheduledDateTime,
            ),
          ),
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: 'Assignment ID',
            value: assignment.id,
          ),
          _buildInfoRow(
            icon: Icons.account_balance_outlined,
            label: 'Institute Profile ID',
            value: assignment.instituteProfileId,
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionInformation() {
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
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: const [
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

  Widget _buildCameraSection() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.videocam_outlined,
                color: Colors.indigo,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Camera / CCTV Feeds',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh feeds',
                onPressed:
                    _loadingFeeds ? null : _loadCameraFeeds,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Camera feeds registered by the assigned institute.',
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
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _feedError!,
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
      children:
          _cameraFeeds.map(_buildCameraFeedCard).toList(),
    );
  }

  Widget _buildCameraFeedCard(NgoCameraFeed feed) {
    final isLive = feed.type == NgoFeedType.liveLink;

    final title =
        (feed.label != null &&
                feed.label!.trim().isNotEmpty)
            ? feed.label!.trim()
            : isLive
                ? 'Live Camera Feed'
                : 'Uploaded Video';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
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
              color:
                  isLive ? Colors.red : Colors.indigo,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isLive
                      ? 'Live link'
                      : 'Uploaded video',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _openCameraFeed(feed),
                    icon: Icon(
                      isLive
                          ? Icons.visibility_outlined
                          : Icons.play_circle_outline,
                      size: 17,
                    ),
                    label: Text(
                      isLive
                          ? 'Open Feed'
                          : 'Play Video',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Future<void> _showUploadedVideoDialog(
    NgoCameraFeed feed,
  ) async {
    final videoPath = feed.videoPath;

    if (videoPath == null ||
        videoPath.trim().isEmpty) {
      _showMessage(
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
      final signedUrl =
          await NgoStorageService.instance.getSignedUrl(
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
            title:
                feed.label?.trim().isNotEmpty == true
                    ? feed.label!.trim()
                    : 'Uploaded Video',
            videoUrl: signedUrl,
          );
        },
      );
    } catch (error, stackTrace) {
      debugPrint(
        'UPLOADED VIDEO SIGNED URL ERROR: $error',
      );
      debugPrint(
        'StackTrace: $stackTrace',
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      _showMessage(
        'Unable to open the uploaded video.',
      );
    }
  }

  void _showMessage(String message) {
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

    if (streamUrl == null ||
        streamUrl.trim().isEmpty) {
      _showMessage(
        'This camera feed does not have a stream URL.',
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
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
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    height: 300,
                    color: Colors.black,
                    child: MjpegView(
                      uri: streamUrl,
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.contain,
                      fps: 10,
                      timeout:
                          const Duration(seconds: 10),
                      loadingWidget: (context) =>
                          const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context) =>
                          const Center(
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
                      doneWidget: (context) =>
                          const Center(
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
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canStartInspection =
        assignment.status ==
                AssignmentStatus.assigned ||
            assignment.status ==
                AssignmentStatus.inProgress ||
            assignment.status ==
                AssignmentStatus.overdue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          16,
          20,
          24,
        ),
        children: [
          Text(
            assignment.projectName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            assignment.location,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
          _buildStatusSection(),
          const SizedBox(height: 12),
          _buildAssignmentInformation(),
          const SizedBox(height: 12),
          _buildCameraSection(),
          const SizedBox(height: 12),
          _buildInspectionInformation(),
          const SizedBox(height: 20),
          if (canStartInspection)
            PrimaryButton(
              label: 'Start Inspection',
              onPressed: () =>
                  _startInspection(context),
            )
          else
            const AppCard(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This assignment has already been completed.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
        ],
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

class _UploadedVideoDialogState
    extends State<_UploadedVideoDialog> {
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
    return AlertDialog(
      title: Row(
        children: [
          const Icon(
            Icons.video_library_outlined,
            color: Colors.indigo,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(widget.title),
          ),
        ],
      ),
      content: SizedBox(
        width: 650,
        child: FutureBuilder<void>(
          future: _initializeFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const SizedBox(
                height: 320,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError ||
                !_controller.value.isInitialized) {
              return const SizedBox(
                height: 320,
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

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
  width: double.infinity,
  height: 320,
  color: Colors.black,
  child: FittedBox(
    fit: BoxFit.contain,
    clipBehavior: Clip.hardEdge,
    child: SizedBox(
      width: _controller.value.size.width,
      height: _controller.value.size.height,
      child: VideoPlayer(_controller),
    ),
  ),
),
                const SizedBox(height: 12),
                VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
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
                        _controller.seekTo(
                          Duration.zero,
                        );
                        _controller.play();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}