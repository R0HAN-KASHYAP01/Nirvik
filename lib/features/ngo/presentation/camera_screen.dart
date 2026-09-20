import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mjpeg_view/mjpeg_view.dart';

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

  // ============================================================
  // COLOR PALETTE — Government of India / SIH theme
  // ============================================================

  static const Color _navy = Color(0xFF174A7E); // Primary Navy Blue
  static const Color _darkNavy = Color(0xFF123A63); // Dark Navy
  static const Color _background = Color(0xFFF7F8FA);
  static const Color _lightBlue = Color(0xFFEAF2F9);
  static const Color _border = Color(0xFFD5D9DE);
  static const Color _textSecondary = Color(0xFF5F6368);
  static const Color _success = Color(0xFF2E7D5B);
  static const Color _danger = Color(0xFFC0392B);

  // Muted navy tint for disabled buttons — kept close to the primary
  // rather than a generic grey, so disabled state still reads as
  // "brand" rather than "broken".
  static const Color _disabledPrimary = Color(0xFFB7C4D1);

  // ---------- Gradients ----------
  // Subtle, professional gradients from closely related shades of
  // the palette above — used only for the header, primary actions,
  // the active tab, and the live-status badge.

  static const LinearGradient _primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF174A7E), Color(0xFF123A63)],
  );

  static const LinearGradient _lightBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF4F8FC), Color(0xFFEAF2F9)],
  );

  static const LinearGradient _successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF2FAF6), Color(0xFFEAF5EF)],
  );

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
    final user =
        SessionService.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loadingFeeds = false;
        });
      }

      return;
    }

    if (mounted) {
      setState(() {
        _loadingFeeds = true;
      });
    }

    try {
      final feeds = await NgoCameraService.instance.fetchFeeds(user.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _feeds = feeds;
        _loadingFeeds = false;
      });
    } catch (error) {
      debugPrint('NGO CAMERA PAGE LOAD ERROR: $error');

      if (!mounted) return;

      setState(() {
        _loadingFeeds = false;
      });
    }
  }

  Future<void> _pickVideo() async {
    // `withData: true` forces file_picker to populate `bytes` on every
    // platform (including mobile/desktop where it's otherwise only
    // path-based) so we can upload without touching dart:io File.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        setState(() {
          _uploadError =
              'Could not read the selected video. Please try another file.';
        });
      }
      return;
    }

    setState(() {
      _videoBytes = bytes;
      _videoName = file.name;
      _uploadError = null;
    });
  }

  Future<void> _submitLiveLink() async {
    final user =
        SessionService.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _linkError =
              'You must be logged in to add a live feed.';
        });
      }

      return;
    }

    final form =
        _linkFormKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    if (mounted) {
      setState(() {
        _submittingLink = true;
        _linkError = null;
      });
    }

    try {
      await NgoCameraService.instance.addLiveLink(
        user: user,
        streamUrl:
            _linkUrlController.text.trim(),
        label:
            _linkLabelController.text.trim().isEmpty
                ? null
                : _linkLabelController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      _linkLabelController.clear();
      _linkUrlController.clear();

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Live camera added successfully.',
          ),
        ),
      );

      await _loadFeeds();
    } catch (error) {
      debugPrint('ADD LIVE CAMERA ERROR: $error');

      if (!mounted) return;

      setState(() {
        _linkError = 'Could not add camera. Please try again.';
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
    final user =
        SessionService.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _uploadError =
              'You must be logged in to upload a video.';
        });
      }

      return;
    }

    if (_videoBytes == null ||
        _videoName == null) {
      if (mounted) {
        setState(() {
          _uploadError =
              'Please select a video to upload.';
        });
      }

      return;
    }

    if (mounted) {
      setState(() {
        _submittingUpload = true;
        _uploadError = null;
      });
    }

    try {
      final path =
          await NgoStorageService.instance.uploadFile(
        folder: 'camera',
        fileName: _videoName!,
        bytes: _videoBytes!,
      );

      await NgoCameraService.instance.addUploadedVideo(
        user: user,
        videoPath: path,
        label:
            _uploadLabelController.text.trim().isEmpty
                ? null
                : _uploadLabelController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      _uploadLabelController.clear();

      setState(() {
        _videoBytes = null;
        _videoName = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Video uploaded successfully.',
          ),
        ),
      );

      await _loadFeeds();
    } catch (error) {
      debugPrint('UPLOAD VIDEO ERROR: $error');

      if (!mounted) return;

      setState(() {
        _uploadError =
            'Could not upload video. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submittingUpload = false;
        });
      }
    }
  }

  Future<void> _updateCamera(NgoCameraFeed feed) async {
    final labelController = TextEditingController(
      text: feed.label ?? '',
    );

    final urlController = TextEditingController(
      text: feed.streamUrl ?? '',
    );

    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Edit Camera',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SizedBox(
                width: 450,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: labelController,
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
                        controller: urlController,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          labelText: 'Stream URL',
                          hintText: 'http://10.0.0.1:8080/video',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        validator: (value) {
                          final url = value?.trim() ?? '';

                          if (url.isEmpty) {
                            return 'Please enter stream URL.';
                          }

                          if (!url.startsWith('http://') &&
                              !url.startsWith('https://') &&
                              !url.startsWith('rtsp://')) {
                            return 'Enter a valid http, https or rtsp URL.';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop(false);
                        },
                  child: const Text('Cancel'),
                ),
                SizedBox(
                  width: 90,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            setDialogState(() {
                              saving = true;
                            });

                            try {
                              await NgoCameraService.instance
                                  .updateLiveLink(
                                feedId: feed.id,
                                streamUrl: urlController.text.trim(),
                                label: labelController.text.trim().isEmpty
                                    ? null
                                    : labelController.text.trim(),
                              );

                              if (!context.mounted) return;

                              Navigator.of(dialogContext).pop(true);
                            } catch (error) {
                              debugPrint(
                                'UPDATE CAMERA ERROR: $error',
                              );

                              if (!context.mounted) return;

                              setDialogState(() {
                                saving = false;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not update camera.',
                                  ),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _disabledPrimary,
                    ),
                    child: Text(
                      saving ? 'Saving...' : 'Save',
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    labelController.dispose();
    urlController.dispose();

    if (shouldSave == true) {
      await _loadFeeds();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Camera updated successfully.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteCamera(NgoCameraFeed feed) async {
    final cameraName =
        feed.label?.trim().isNotEmpty == true
            ? feed.label!.trim()
            : 'this camera';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Remove Camera?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Are you sure you want to remove "$cameraName" '
            'from your camera list?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            SizedBox(
              width: 90,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _danger,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Remove'),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await NgoCameraService.instance.deleteFeed(feed.id);

      await _loadFeeds();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Camera removed successfully.',
          ),
        ),
      );
    } catch (error) {
      debugPrint('DELETE CAMERA ERROR: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not remove camera.',
          ),
        ),
      );
    }
  }

  void _openFeed(NgoCameraFeed feed) {
    final streamUrl = feed.streamUrl;

    if (streamUrl == null || streamUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No live stream URL available.',
          ),
        ),
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
                      : 'Live Camera',
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 600,
            height: 360,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.black,
                child: MjpegView(
                  uri: streamUrl,
                  width: double.infinity,
                  height: 360,
                  fit: BoxFit.contain,
                  fps: 10,
                  timeout: const Duration(seconds: 10),
                  loadingWidget: (context) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    );
                  },
                  errorWidget: (context) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Unable to load this camera feed.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                  doneWidget: (context) {
                    return const Center(
                      child: Text(
                        'Camera stream ended.',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        // Subtle primary gradient header, matching the rest of the
        // app's navy chrome.
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: _primaryGradient,
          ),
        ),
        title: const Text(
          'Camera / Video Access',
          style: TextStyle(
            fontSize: 17,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          // Very subtle blue-tinted backdrop for the whole screen.
          decoration: const BoxDecoration(
            gradient: _lightBlueGradient,
          ),
          child: RefreshIndicator(
            onRefresh: _loadFeeds,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                14,
                14,
                14,
                28,
              ),
              children: [
                _buildTabs(),
                const SizedBox(height: 14),
                if (_selectedTab == 0)
                  _buildLiveFeeds()
                else
                  _buildUploadSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 40,
      padding:
          const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _lightBlue,
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              title: 'Live Cameras',
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
              selected:
                  _selectedTab == 1,
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
        duration:
            const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? _primaryGradient : null,
          color: selected ? null : Colors.transparent,
          borderRadius:
              BorderRadius.circular(19),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight:
                FontWeight.w700,
            color: selected
                ? Colors.white
                : _textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLiveFeeds() {
    final liveFeeds = _feeds
        .where(
          (feed) =>
              feed.type ==
              NgoFeedType.liveLink,
        )
        .toList();

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Registered Cameras',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _navy,
                ),
              ),
            ),

            // Explicit width prevents the infinite-width
            // ElevatedButton layout crash inside this Row.
            SizedBox(
              width: 125,
              height: 38,
              child: _buildGradientButton(
                onTap: _showAddLiveLinkDialog,
                icon: Icons.add,
                label: 'Add Camera',
                borderRadius: 9,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loadingFeeds)
          Container(
            height: 220,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 2.5,
            ),
          )
        else if (liveFeeds.isEmpty)
          _buildEmptyLiveState()
        else
          ...liveFeeds.map(
            (feed) => Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: _buildCameraCard(feed),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // GRADIENT BUTTON HELPER
  //
  // Small navy-gradient CTA used for the primary "Add Camera" and
  // "Upload Video" actions, matching the header's brand gradient
  // instead of a flat fill.
  // ============================================================

  Widget _buildGradientButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    double borderRadius = 10,
    double fontSize = 12,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: _primaryGradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: Colors.white),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyLiveState() {
    return Container(
      padding:
          const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: _lightBlue,
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.videocam_outlined,
              color: _navy,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No cameras registered',
            style: TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w700,
              color: _darkNavy,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Add your first camera to provide live access for monitoring and inspections.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: 150,
            height: 40,
            child: _buildGradientButton(
              onTap: _showAddLiveLinkDialog,
              icon: Icons.add,
              label: 'Add Camera',
              borderRadius: 10,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraCard(
    NgoCameraFeed feed,
  ) {
    final cameraName =
        feed.label?.trim().isNotEmpty == true
            ? feed.label!.trim()
            : 'Live Camera';

    final streamUrl = feed.streamUrl?.trim() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.06,
            ),
            blurRadius: 7,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior:
          Clip.antiAlias,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 190,
            width: double.infinity,
            child: Container(
              color: Colors.black,
              child: streamUrl.isEmpty
                  ? const Center(
                      child: Text(
                        'No camera URL configured.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : MjpegView(
                      uri: streamUrl,
                      width: double.infinity,
                      height: 190,
                      fit: BoxFit.contain,
                      fps: 8,
                      timeout: const Duration(seconds: 10),
                      loadingWidget: (context) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        );
                      },
                      errorWidget: (context) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Camera feed unavailable.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                      doneWidget: (context) {
                        return const Center(
                          child: Text(
                            'Camera stream ended.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              12,
              11,
              12,
              12,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cameraName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _navy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // "LIVE" status badge — soft success gradient
                    // rather than a flat fill, as this is the kind
                    // of small but important status indicator the
                    // gradient guidance calls out.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: _successGradient,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 6,
                            color: _success,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: _success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _openFeed(feed);
                        },
                        icon: const Icon(
                          Icons.open_in_new_rounded,
                          size: 14,
                        ),
                        label: const Text(
                          'Open',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _updateCamera(feed);
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 14,
                        ),
                        label: const Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: IconButton(
                        tooltip: 'Remove camera',
                        onPressed: () {
                          _deleteCamera(feed);
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: _danger,
                          size: 21,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 7,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.video_library_rounded,
                color: _navy,
                size: 21,
              ),
              SizedBox(width: 8),
              Text(
                'Upload Video',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w800,
                  color: _navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Video label',
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.w700,
              color: _navy,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _uploadLabelController,
            decoration: InputDecoration(
              hintText: 'e.g. Main Hall Recording',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: _textSecondary,
              ),
              filled: true,
              fillColor: _background,
              contentPadding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  9,
                ),
                borderSide: const BorderSide(
                  color: _border,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _submittingUpload
                ? null
                : _pickVideo,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets
                      .symmetric(
                vertical: 18,
                horizontal: 12,
              ),
              decoration:
                  BoxDecoration(
                color: _lightBlue,
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
                border: Border.all(
                  color: _border,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons
                        .cloud_upload_outlined,
                    color: _navy,
                    size: 32,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    _videoName ??
                        'Select video file',
                    textAlign:
                        TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  const Text(
                    'Tap here to choose a video',
                    style: TextStyle(
                      fontSize: 10,
                      color: _textSecondary,
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
                color: _danger,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: _submittingUpload
                ? Container(
                    decoration: BoxDecoration(
                      color: _disabledPrimary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Uploading...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  )
                : _buildGradientButton(
                    onTap: _submitUpload,
                    icon: Icons.cloud_upload_rounded,
                    label: 'Upload Video',
                    borderRadius: 9,
                    fontSize: 12,
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddLiveLinkDialog() {
    _linkLabelController.clear();
    _linkUrlController.clear();

    if (mounted) {
      setState(() {
        _linkError = null;
      });
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Add Camera',
            style: TextStyle(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          content: SizedBox(
            width: 450,
            child: Form(
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
                      hintText: 'http://10.0.0.1:8080/video',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    validator: (value) {
                      final url = value?.trim() ?? '';

                      if (url.isEmpty) {
                        return 'Please enter stream URL.';
                      }

                      if (!url.startsWith('http://') &&
                          !url.startsWith('https://') &&
                          !url.startsWith('rtsp://')) {
                        return 'Enter a valid http, https or rtsp URL.';
                      }

                      return null;
                    },
                  ),
                  if (_linkError != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _linkError!,
                        style: const TextStyle(
                          color: _danger,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _submittingLink
                  ? null
                  : () {
                      Navigator.of(dialogContext).pop();
                    },
              child: const Text('Cancel'),
            ),
            SizedBox(
              width: 110,
              height: 40,
              child: ElevatedButton(
                onPressed: _submittingLink
                    ? null
                    : _submitLiveLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _disabledPrimary,
                ),
                child: Text(
                  _submittingLink
                      ? 'Adding...'
                      : 'Add Camera',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}