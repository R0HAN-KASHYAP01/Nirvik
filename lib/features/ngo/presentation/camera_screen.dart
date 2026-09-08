import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../services/session_service.dart';
import '../../../services/ngo_storage_service.dart';
import '../../../services/ngo_camera_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _linkFormKey = GlobalKey<FormState>();

  final _linkLabelController = TextEditingController();
  final _linkUrlController = TextEditingController();
  final _uploadLabelController = TextEditingController();

  Uint8List? _videoBytes;
  String? _videoName;

  bool _submittingLink = false;
  bool _submittingUpload = false;
  bool _loadingFeeds = true;

  String? _linkError;
  String? _uploadError;

  List<NgoCameraFeed> _feeds = [];

  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  @override
  void dispose() {
    _linkLabelController.dispose();
    _linkUrlController.dispose();
    _uploadLabelController.dispose();
    super.dispose();
  }

  Future<void> _loadFeeds() async {
    final user = SessionService.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loadingFeeds = false;
        });
      }
      return;
    }

    setState(() {
      _loadingFeeds = true;
    });

    try {
      final feeds =
          await NgoCameraService.instance.fetchFeeds(user.id);

      if (!mounted) return;

      setState(() {
        _feeds = feeds;
        _loadingFeeds = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingFeeds = false;
      });
    }
  }

  Future<void> _pickVideo() async {
  final files = await FilePicker.pickFiles(
    type: FileType.video,
  );

  if (files.isEmpty) return;

  final file = files.first;
  final bytes = await file.readAsBytes();

  if (bytes.isEmpty) return;

  setState(() {
    _videoBytes = bytes;
    _videoName = file.name;
    _uploadError = null;
  });
}

  Future<void> _submitLiveLink() async {
    final user = SessionService.instance.currentUser;

    if (user == null) return;

    if (!_linkFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submittingLink = true;
      _linkError = null;
    });

    try {
      await NgoCameraService.instance.addLiveLink(
        user: user,
        streamUrl: _linkUrlController.text.trim(),
        label: _linkLabelController.text.trim().isEmpty
            ? null
            : _linkLabelController.text.trim(),
      );

      if (!mounted) return;

      _linkLabelController.clear();
      _linkUrlController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Live stream link added successfully.'),
        ),
      );

      await _loadFeeds();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _linkError = 'Could not add link. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submittingLink = false;
        });
      }
    }
  }

  Future<void> _submitUpload() async {
    final user = SessionService.instance.currentUser;

    if (user == null) return;

    if (_videoBytes == null || _videoName == null) {
      setState(() {
        _uploadError = 'Please select a video to upload.';
      });
      return;
    }

    setState(() {
      _submittingUpload = true;
      _uploadError = null;
    });

    try {
      final path = await NgoStorageService.instance.uploadFile(
        folder: 'camera',
        fileName: _videoName!,
        bytes: _videoBytes!,
      );

      await NgoCameraService.instance.addUploadedVideo(
        user: user,
        videoPath: path,
        label: _uploadLabelController.text.trim().isEmpty
            ? null
            : _uploadLabelController.text.trim(),
      );

      if (!mounted) return;

      _uploadLabelController.clear();

      setState(() {
        _videoBytes = null;
        _videoName = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video uploaded successfully.'),
        ),
      );

      await _loadFeeds();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _uploadError = 'Could not upload video. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submittingUpload = false;
        });
      }
    }
  }

  void _openFeed(NgoCameraFeed feed) {
    if (feed.streamUrl == null || feed.streamUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No live stream URL available.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            feed.label ?? 'Live Feed',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 170,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF17202A),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(
                    Icons.videocam_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Live stream link',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                feed.streamUrl!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Camera / Video Access',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFeeds,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
            children: [
              _buildTabs(),
              const SizedBox(height: 14),

              if (_selectedTab == 0)
                _buildLiveFeeds()
              else
                _buildUploadSection(),

              const SizedBox(height: 22),

              _buildOtherFeeds(),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TOP TABS
  // ------------------------------------------------------------

  Widget _buildTabs() {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE6EEF6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              title: 'Live Feeds',
              selected: _selectedTab == 0,
              onTap: () {
                setState(() {
                  _selectedTab = 0;
                });
              },
            ),
          ),
          Expanded(
            child: _buildTabButton(
              title: 'Upload Video',
              selected: _selectedTab == 1,
              onTap: () {
                setState(() {
                  _selectedTab = 1;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(19),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: selected
                ? Colors.white
                : const Color(0xFF526477),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // LIVE FEEDS
  // ------------------------------------------------------------

  Widget _buildLiveFeeds() {
    final liveFeeds = _feeds
        .where(
          (feed) => feed.type == NgoFeedType.liveLink,
        )
        .toList();

    if (_loadingFeeds) {
      return Container(
        height: 240,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const CircularProgressIndicator(
          strokeWidth: 2.5,
        ),
      );
    }

    if (liveFeeds.isEmpty) {
      return _buildEmptyLiveState();
    }

    final mainFeed = liveFeeds.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMainFeedCard(mainFeed),
        const SizedBox(height: 12),
        _buildOpenLiveButton(mainFeed),
      ],
    );
  }

  Widget _buildEmptyLiveState() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE0E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FA),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.videocam_outlined,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No live feeds yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF16385C),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Add a live stream link to see your camera here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: () {
                _showAddLiveLinkDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Add Live Feed',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainFeedCard(NgoCameraFeed feed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 170,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF4B4E4D),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CameraPreviewPainter(),
                      ),
                    ),

                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          feed.label ?? 'Main Hall Camera',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF29A96A),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 6,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Text(
                        _currentDateTime(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(
                          Icons.fullscreen_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              12,
              10,
              12,
              10,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Main Hall Camera',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF173C61),
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 7,
                            color: Color(0xFF27A76B),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Online',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF27A76B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: () => _openFeed(feed),
                    icon: const Icon(
                      Icons.open_in_new_rounded,
                      size: 13,
                    ),
                    label: const Text(
                      'Open Live Feed',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE4F1FC),
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
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

  Widget _buildOpenLiveButton(NgoCameraFeed feed) {
    return SizedBox(
      height: 42,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _openFeed(feed),
        icon: const Icon(
          Icons.videocam_rounded,
          size: 17,
        ),
        label: const Text(
          'Open Live Feed',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // UPLOAD VIDEO
  // ------------------------------------------------------------

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.video_library_rounded,
                color: AppColors.primary,
                size: 21,
              ),
              SizedBox(width: 8),
              Text(
                'Upload Video',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF173C61),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Text(
            'Video label',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF43566B),
            ),
          ),

          const SizedBox(height: 6),

          TextField(
            controller: _uploadLabelController,
            decoration: InputDecoration(
              hintText: 'e.g. Main Hall Camera',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9BA8B5),
              ),
              filled: true,
              fillColor: const Color(0xFFF7FAFD),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(
                  color: Color(0xFFDCE5ED),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(
                  color: Color(0xFFDCE5ED),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: _pickVideo,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F6FB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFD5E2ED),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    color: AppColors.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _videoName ?? 'Select video file',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF274C70),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap here to choose a video',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_uploadError != null) ...[
            const SizedBox(height: 8),
            Text(
              _uploadError!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 11,
              ),
            ),
          ],

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed:
                  _submittingUpload ? null : _submitUpload,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                disabledBackgroundColor:
                    const Color(0xFF9BB5CC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: Text(
                _submittingUpload
                    ? 'Uploading...'
                    : 'Upload Video',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // OTHER FEEDS
  // ------------------------------------------------------------

  Widget _buildOtherFeeds() {
    final otherFeeds = _feeds
        .where(
          (feed) => feed.type == NgoFeedType.liveLink,
        )
        .skip(1)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Other Feeds',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF173C61),
          ),
        ),
        const SizedBox(height: 9),

        if (otherFeeds.isEmpty)
          Column(
            children: [
              _buildDemoFeed(
                icon: Icons.campaign_rounded,
                iconBackground: const Color(0xFFFFE9EA),
                iconColor: const Color(0xFFE94D59),
                title: 'Entrance Camera',
                online: false,
                lastActive: 'Last seen: 09:51 AM',
              ),
              const SizedBox(height: 7),
              _buildDemoFeed(
                icon: Icons.videocam_rounded,
                iconBackground: const Color(0xFFE3F6EB),
                iconColor: const Color(0xFF27A76B),
                title: 'Playground Camera',
                online: true,
                lastActive: 'Last active: 10:40 AM',
              ),
            ],
          )
        else
          ...otherFeeds.map(
            (feed) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: _buildRealFeedRow(feed),
            ),
          ),
      ],
    );
  }

  Widget _buildRealFeedRow(NgoCameraFeed feed) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFFE1E9F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: const Color(0xFFE4F2FC),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.videocam_rounded,
              color: AppColors.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feed.label ?? 'Camera Feed',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF173C61),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 6,
                      color: Color(0xFF27A76B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Online',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF27A76B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF647789),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildDemoFeed({
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    required bool online,
    required String lastActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFFE1E9F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 19,
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF173C61),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 6,
                      color: online
                          ? const Color(0xFF27A76B)
                          : const Color(0xFFE94D59),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      online ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 9,
                        color: online
                            ? const Color(0xFF27A76B)
                            : const Color(0xFFE94D59),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  lastActive,
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: Color(0xFF8A98A6),
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF647789),
            size: 20,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ADD LIVE LINK DIALOG
  // ------------------------------------------------------------

  void _showAddLiveLinkDialog() {
    _linkLabelController.clear();
    _linkUrlController.clear();
    _linkError = null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Add Live Feed',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Form(
            key: _linkFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _linkLabelController,
                  decoration: InputDecoration(
                    labelText: 'Camera name',
                    hintText: 'Main Hall Camera',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _linkUrlController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: 'Stream URL',
                    hintText: 'https://...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter stream URL.';
                    }

                    if (!value.trim().startsWith('http') &&
                        !value.trim().startsWith('rtsp')) {
                      return 'Enter valid http/https/rtsp URL.';
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _submittingLink
                  ? null
                  : () async {
                      await _submitLiveLink();

                      if (mounted &&
                          _linkError == null) {
                        Navigator.pop(dialogContext);
                      }
                    },
          
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(
                _submittingLink
                    ? 'Adding...'
                    : 'Add Feed',
              ),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // DATE / TIME
  // ------------------------------------------------------------

  String _currentDateTime() {
    final now = DateTime.now();

    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();

    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');

    return '$day/$month/$year  $hour:$minute:$second';
  }
}

// ------------------------------------------------------------
// SIMPLE CAMERA PREVIEW PAINTER
// ------------------------------------------------------------

class _CameraPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    paint.color = const Color(0xFF565957);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        size.width,
        size.height,
      ),
      paint,
    );

    // Wall
    paint.color = const Color(0xFF777975);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        size.width,
        size.height * 0.58,
      ),
      paint,
    );

    // Floor
    paint.color = const Color(0xFF3D403F);
    final floorPath = Path()
      ..moveTo(0, size.height * 0.58)
      ..lineTo(size.width, size.height * 0.58)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(floorPath, paint);

    // Window
    paint.color = const Color(0xFFD6D8D4);

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.72,
        size.height * 0.15,
        size.width * 0.15,
        size.height * 0.25,
      ),
      paint,
    );

    paint.color = const Color(0xFF7E8581);

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.79,
        size.height * 0.15,
        2,
        size.height * 0.25,
      ),
      paint,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.72,
        size.height * 0.27,
        size.width * 0.15,
        2,
      ),
      paint,
    );

    // Door
    paint.color = const Color(0xFF454846);

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.09,
        size.height * 0.20,
        size.width * 0.13,
        size.height * 0.38,
      ),
      paint,
    );

    // Tables / benches
    paint.color = const Color(0xFF292D2C);

    for (int i = 0; i < 3; i++) {
      final y = size.height * (0.60 + i * 0.10);

      canvas.drawRect(
        Rect.fromLTWH(
          size.width * 0.28,
          y,
          size.width * 0.42,
          5,
        ),
        paint,
      );
    }

    // People-like silhouettes
    paint.color = const Color(0xFF313635);

    for (int i = 0; i < 4; i++) {
      final x = size.width * (0.28 + i * 0.12);

      canvas.drawCircle(
        Offset(x, size.height * 0.48),
        6,
        paint,
      );

      canvas.drawRect(
        Rect.fromLTWH(
          x - 5,
          size.height * 0.50,
          10,
          22,
        ),
        paint,
      );
    }

    // Camera overlay lines
    paint.color = Colors.white.withValues(alpha: 0.12);
    paint.strokeWidth = 1;

    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    for (int i = 1; i < 4; i++) {
      final x = size.width * i / 4;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}