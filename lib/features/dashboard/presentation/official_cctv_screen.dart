import 'package:flutter/material.dart';
import 'package:mjpeg_view/mjpeg_view.dart';
import 'package:video_player/video_player.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/assignment.dart';
import '../../../services/ngo_camera_service.dart';
import '../../../services/ngo_storage_service.dart';
import '../data/assignments_repository.dart';

class OfficialCctvScreen extends StatefulWidget {
  const OfficialCctvScreen({super.key});

  @override
  State<OfficialCctvScreen> createState() => _OfficialCctvScreenState();
}

class _OfficialCctvScreenState extends State<OfficialCctvScreen> {
  static const Color _navy = Color(0xFF123E68);
  static const Color _background = Color(0xFFEAF2F8);
  static const Color _cardBackground = Color(0xFFE1ECF3);
  static const Color _softBlue = Color(0xFFD7E5EE);
  static const Color _textDark = Color(0xFF17324D);
  static const Color _textGrey = Color(0xFF667788);
  static const Color _border = Color(0xFFD1DEE7);
  static const Color _green = Color(0xFF168A45);

  final AssignmentsRepository _assignmentsRepository =
      AssignmentsRepository();

  List<AssignmentSummary> _assignments = [];
  bool _isLoading = true;
  String? _errorMessage;

  String? _selectedInstituteProfileId;
  String? _selectedInstituteName;

  List<NgoCameraFeed> _cameraFeeds = [];
  bool _isLoadingCameras = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _loadInstitutes();
  }

  Future<void> _loadInstitutes() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final assignments = await _assignmentsRepository.getAssignments();

      if (!mounted) return;

      final uniqueAssignments = <String, AssignmentSummary>{};

      for (final assignment in assignments) {
        final profileId = assignment.instituteProfileId;

        if (profileId.isEmpty) {
          continue;
        }

        uniqueAssignments.putIfAbsent(
          profileId,
          () => assignment,
        );
      }

      setState(() {
        _assignments = uniqueAssignments.values.toList();
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Failed to load official CCTV institutes: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load institutes.';
      });
    }
  }

  Future<void> _loadCameras(AssignmentSummary assignment) async {
    final profileId = assignment.instituteProfileId;

    if (profileId.isEmpty) {
      setState(() {
        _selectedInstituteProfileId = null;
        _selectedInstituteName = null;
        _cameraFeeds = [];
        _cameraError = 'This institute does not have a valid profile ID.';
      });
      return;
    }

    setState(() {
      _selectedInstituteProfileId = profileId;
      _selectedInstituteName = assignment.displayName;
      _isLoadingCameras = true;
      _cameraError = null;
      _cameraFeeds = [];
    });

    try {
      final feeds =
          await NgoCameraService.instance.fetchFeeds(profileId);

      if (!mounted) return;

      setState(() {
        _cameraFeeds = feeds;
        _isLoadingCameras = false;
      });
    } catch (error) {
      debugPrint(
        'Failed to load cameras for institute $profileId: $error',
      );

      if (!mounted) return;

      setState(() {
        _isLoadingCameras = false;
        _cameraError = 'Unable to load cameras for this institute.';
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedInstituteProfileId = null;
      _selectedInstituteName = null;
      _cameraFeeds = [];
      _cameraError = null;
    });
  }

  Widget _buildInstituteList() {
    if (_assignments.isEmpty) {
      return const EmptyState(
        icon: Icons.apartment_outlined,
        title: 'No institutes available',
        message:
            'Institutes with inspection assignments will appear here.',
      );
    }

    return Column(
      children: _assignments.map((assignment) {
        final isSelected =
            assignment.instituteProfileId ==
                _selectedInstituteProfileId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            padding: EdgeInsets.zero,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _loadCameras(assignment),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _softBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.apartment_outlined,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            assignment.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            assignment.displayLocation,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 6),

                    Icon(
                      isSelected
                          ? Icons.visibility
                          : Icons.chevron_right,
                      color: _navy,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLiveCameraViewer(NgoCameraFeed feed) {
    final streamUrl = feed.streamUrl?.trim();

    if (streamUrl == null || streamUrl.isEmpty) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F5F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Live camera URL is not available.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: _textGrey,
              ),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 220,
        color: Colors.black,
        child: MjpegView(
          uri: streamUrl,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildCameraViewer(NgoCameraFeed feed) {
    if (feed.type == NgoFeedType.liveLink) {
      return _buildLiveCameraViewer(feed);
    }

    final videoPath = feed.videoPath?.trim();

    if (videoPath == null || videoPath.isEmpty) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F5F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Uploaded video path is not available.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: _textGrey,
              ),
            ),
          ),
        ),
      );
    }

    return OfficialUploadedVideoPlayer(
      key: ValueKey(feed.id),
      videoPath: videoPath,
    );
  }

  Widget _buildCameraCard(NgoCameraFeed feed) {
    final label = feed.label?.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _softBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        feed.type == NgoFeedType.liveLink
                            ? Icons.videocam_outlined
                            : Icons.video_library_outlined,
                        color: _navy,
                        size: 20,
                      ),
                    ),

                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth > 360
                            ? constraints.maxWidth - 110
                            : constraints.maxWidth - 20,
                      ),
                      child: Text(
                        label == null || label.isEmpty
                            ? 'Camera'
                            : label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: feed.type == NgoFeedType.liveLink
                            ? const Color(0xFFE8F6EE)
                            : const Color(0xFFF1F3F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        feed.type == NgoFeedType.liveLink
                            ? 'LIVE'
                            : 'VIDEO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: feed.type == NgoFeedType.liveLink
                              ? _green
                              : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 12),

            _buildCameraViewer(feed),

            if (feed.type == NgoFeedType.liveLink &&
                feed.streamUrl != null) ...[
              const SizedBox(height: 8),
              Text(
                feed.streamUrl!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedCameras() {
    if (_selectedInstituteProfileId == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),

        Row(
          children: [
            IconButton(
              onPressed: _clearSelection,
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to institutes',
              color: _navy,
            ),
            const SizedBox(width: 2),

            Expanded(
              child: Text(
                _selectedInstituteName ?? 'Institute Cameras',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        const Text(
          'Registered cameras',
          style: TextStyle(
            fontSize: 13,
            color: _textGrey,
          ),
        ),

        const SizedBox(height: 12),

        if (_isLoadingCameras)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 35),
            child: Center(
              child: CircularProgressIndicator(
                color: _navy,
              ),
            ),
          )
        else if (_cameraError != null)
          AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 40,
                  color: Colors.black45,
                ),
                const SizedBox(height: 10),

                Text(
                  _cameraError!,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textGrey,
                  ),
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: () {
                    final matchingAssignments =
                        _assignments.where(
                      (item) =>
                          item.instituteProfileId ==
                          _selectedInstituteProfileId,
                    );

                    if (matchingAssignments.isNotEmpty) {
                      _loadCameras(matchingAssignments.first);
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy,
                    side: const BorderSide(
                      color: _border,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (_cameraFeeds.isEmpty)
          const EmptyState(
            icon: Icons.videocam_off_outlined,
            title: 'No cameras registered',
            message:
                'This NGO/Institute has not registered any camera feeds.',
          )
        else
          Column(
            children: _cameraFeeds
                .map(_buildCameraCard)
                .toList(),
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _navy,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 44,
                  color: Colors.black45,
                ),
                const SizedBox(height: 12),

                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _textGrey,
                  ),
                ),

                const SizedBox(height: 14),

                OutlinedButton.icon(
                  onPressed: _loadInstitutes,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy,
                    side: const BorderSide(
                      color: _border,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _navy,
      onRefresh: _loadInstitutes,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          30,
        ),
        children: [
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _softBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.videocam_outlined,
                    color: _navy,
                    size: 26,
                  ),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Official CCTV Monitoring',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _navy,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'View cameras registered by NGOs and institutes.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 12,
                          color: _textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          if (_selectedInstituteProfileId == null) ...[
            const Text(
              'Select Institute',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'Choose an institute to view its registered camera feeds.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: TextStyle(
                fontSize: 12,
                color: _textGrey,
              ),
            ),

            const SizedBox(height: 12),

            _buildInstituteList(),
          ],

          _buildSelectedCameras(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _navy,
        elevation: 0,
        title: const Text(
          'Official CCTV',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }
}

/// Plays a video uploaded by an NGO from the private Supabase bucket.
class OfficialUploadedVideoPlayer extends StatefulWidget {
  final String videoPath;

  const OfficialUploadedVideoPlayer({
    super.key,
    required this.videoPath,
  });

  @override
  State<OfficialUploadedVideoPlayer> createState() =>
      _OfficialUploadedVideoPlayerState();
}

class _OfficialUploadedVideoPlayerState
    extends State<OfficialUploadedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final signedUrl =
          await NgoStorageService.instance.getSignedUrl(
        widget.videoPath,
        expiresInSeconds: 3600,
      );

      if (!mounted) return;

      final controller =
          VideoPlayerController.networkUrl(
        Uri.parse(signedUrl),
      );

      _controller = controller;

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to initialize official uploaded video: $error',
      );

      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Unable to play this uploaded video.';
      });
    }
  }

  Future<void> _retry() async {
    final oldController = _controller;

    _controller = null;

    if (oldController != null) {
      await oldController.dispose();
    }

    await _initializeVideo();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null || _controller == null) {
      return Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F5F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.video_library_outlined,
                  size: 42,
                  color: Colors.black38,
                ),

                const SizedBox(height: 8),

                Text(
                  _errorMessage ??
                      'Unable to load video.',
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 10),

                OutlinedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final controller = _controller!;

    if (!controller.value.isInitialized) {
      return Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio > 0
              ? controller.value.aspectRatio
              : 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(controller),

              if (!controller.value.isPlaying)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () {
                      controller.play();
                      setState(() {});
                    },
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: 0.65,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                ),

              Positioned(
                left: 8,
                right: 8,
                bottom: 4,
                child: VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                  ),
                ),
              ),

              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  tooltip: 'Play / Pause',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(
                      alpha: 0.55,
                    ),
                  ),
                  onPressed: () {
                    if (controller.value.isPlaying) {
                      controller.pause();
                    } else {
                      controller.play();
                    }

                    setState(() {});
                  },
                  icon: Icon(
                    controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}