// FILE: lib/features/ngo/presentation/attendance_screen.dart

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../services/ai_attendance_service.dart';
import '../../../services/ngo_attendance_service.dart';
import '../../../services/ngo_storage_service.dart';
import '../../../services/session_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _beneficiaryFormKey = GlobalKey<FormState>();
  final _staffFormKey = GlobalKey<FormState>();

  final _beneficiaryCountController =
  TextEditingController(text: '45');

  final _staffCountController =
  TextEditingController(text: '10');

  final AiAttendanceService _aiAttendanceService = AiAttendanceService();

  Uint8List? _beneficiaryVideoBytes;
  String? _beneficiaryVideoName;

  Uint8List? _staffVideoBytes;
  String? _staffVideoName;

  bool _submittingBeneficiary = false;
  bool _submittingStaff = false;

  String? _beneficiaryError;
  String? _staffError;

  bool _loadingHistory = true;

  List<AttendanceRecord> _history = [];

  bool _loadingAiAttendance = true;
  String? _aiAttendanceError;

  Map<String, dynamic>? _aiSummary;
  Map<String, dynamic>? _aiRoleStatistics;
  Map<String, dynamic>? _aiLatestSession;

  @override
  void initState() {
    super.initState();

    _loadHistory();
    _loadAiAttendance();
  }

  @override
  void dispose() {
    _beneficiaryCountController.dispose();
    _staffCountController.dispose();

    super.dispose();
  }

  // ============================================================
  // MANUAL ATTENDANCE HISTORY
  // ============================================================

  Future<void> _loadHistory() async {
    final user = SessionService.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _loadingHistory = false;
      });

      return;
    }

    if (mounted) {
      setState(() {
        _loadingHistory = true;
      });
    }

    try {
      final records =
      await NgoAttendanceService.instance.fetchHistory(user.id);

      if (!mounted) return;

      setState(() {
        _history = records;
        _loadingHistory = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingHistory = false;
      });
    }
  }

  // ============================================================
  // AI ATTENDANCE
  // ============================================================

  Future<void> _loadAiAttendance() async {
    if (!mounted) return;

    setState(() {
      _loadingAiAttendance = true;
      _aiAttendanceError = null;
    });

    try {
      final results = await Future.wait([
        _aiAttendanceService.getAttendanceSummary(),
        _aiAttendanceService.getRoleStatistics(),
        _aiAttendanceService.getLatestAttendance(),
      ]);

      if (!mounted) return;

      setState(() {
        _aiSummary = results[0];
        _aiRoleStatistics = results[1];
        _aiLatestSession = results[2];
        _loadingAiAttendance = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingAiAttendance = false;
        _aiAttendanceError =
        'Unable to connect to the AI attendance server.';
      });
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadHistory(),
      _loadAiAttendance(),
    ]);
  }

  // ============================================================
  // VIDEO PICKER
  // ============================================================

  Future<void> _pickVideo({required bool isBeneficiary}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) return;

    setState(() {
      if (isBeneficiary) {
        _beneficiaryVideoBytes = bytes;
        _beneficiaryVideoName = file.name;
      } else {
        _staffVideoBytes = bytes;
        _staffVideoName = file.name;
      }
    });
  }

  // ============================================================
  // MANUAL ATTENDANCE SUBMISSION
  // ============================================================

  Future<void> _submit({required bool isBeneficiary}) async {
    final user = SessionService.instance.currentUser;

    if (user == null) {
      _showError('User session not found. Please login again.');
      return;
    }

    final formKey =
    isBeneficiary ? _beneficiaryFormKey : _staffFormKey;

    if (!formKey.currentState!.validate()) return;

    setState(() {
      if (isBeneficiary) {
        _submittingBeneficiary = true;
        _beneficiaryError = null;
      } else {
        _submittingStaff = true;
        _staffError = null;
      }
    });

    try {
      final countText = isBeneficiary
          ? _beneficiaryCountController.text
          : _staffCountController.text;

      final count = int.parse(countText.trim());

      String? videoPath;

      final bytes = isBeneficiary
          ? _beneficiaryVideoBytes
          : _staffVideoBytes;

      final name = isBeneficiary
          ? _beneficiaryVideoName
          : _staffVideoName;

      if (bytes != null && name != null) {
        videoPath =
        await NgoStorageService.instance.uploadFile(
          folder: 'attendance',
          fileName: name,
          bytes: bytes,
        );
      }

      await NgoAttendanceService.instance.submitAttendance(
        user: user,
        type: isBeneficiary
            ? AttendanceType.beneficiary
            : AttendanceType.staff,
        presentCount: count,
        videoEvidencePath: videoPath,
      );

      if (!mounted) return;

      setState(() {
        if (isBeneficiary) {
          _beneficiaryVideoBytes = null;
          _beneficiaryVideoName = null;
        } else {
          _staffVideoBytes = null;
          _staffVideoName = null;
        }
      });

      _showSuccess(
        '${isBeneficiary ? 'Beneficiary' : 'Staff'} attendance submitted.',
      );

      await _loadHistory();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        if (isBeneficiary) {
          _beneficiaryError =
          'Could not submit attendance. Please try again.';
        } else {
          _staffError =
          'Could not submit attendance. Please try again.';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _submittingBeneficiary = false;
          _submittingStaff = false;
        });
      }
    }
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  String? _countValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a count.';
    }

    final parsed = int.tryParse(value.trim());

    if (parsed == null || parsed < 0) {
      return 'Enter a valid number.';
    }

    return null;
  }

  // ============================================================
  // FEEDBACK MESSAGES
  // ============================================================

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // SAFE DATA CONVERSION
  // ============================================================

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  // ============================================================
  // EXTRACT ROLE DATA
  //
  // The role-statistics endpoint returns:
  //
  // {
  //   "statistics": [
  //     {
  //       "role": "Staff",
  //       "people": 7,
  //       "observed_seconds": 460.57,
  //       "percentage_of_people": 20.59
  //     }
  //   ]
  // }
  // ============================================================

  Map<String, dynamic> _getRoleData(String role) {
    final data = _aiRoleStatistics;

    if (data == null) {
      return {};
    }

    final statistics = data['statistics'];

    if (statistics is! List) {
      return {};
    }

    for (final item in statistics) {
      if (item is Map) {
        final itemRole = item['role']?.toString();

        if (itemRole?.toLowerCase() == role.toLowerCase()) {
          return Map<String, dynamic>.from(item);
        }
      }
    }

    return {};
  }

  // ============================================================
  // ROLE COUNT
  //
  // The API uses the "people" field for each role.
  // ============================================================

  int _getRoleCount(String role) {
    final data = _getRoleData(role);

    return _toInt(data['people']);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daily Attendance',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                "Submit today's headcount for beneficiaries and staff separately.",
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // AI ATTENDANCE
              // ==================================================

              _buildAiAttendanceSection(),

              const SizedBox(height: 24),

              // ==================================================
              // MANUAL ATTENDANCE
              // ==================================================

              const SectionHeader(
                title: 'Manual Attendance',
              ),

              const SizedBox(height: 12),

              _buildAttendanceCard(
                title: 'Beneficiary Attendance',
                icon: Icons.diversity_3_outlined,
                formKey: _beneficiaryFormKey,
                countController: _beneficiaryCountController,
                videoName: _beneficiaryVideoName,
                onPickVideo: () =>
                    _pickVideo(isBeneficiary: true),
                onSubmit: () =>
                    _submit(isBeneficiary: true),
                isSubmitting: _submittingBeneficiary,
                error: _beneficiaryError,
              ),

              const SizedBox(height: 16),

              _buildAttendanceCard(
                title: 'Staff Attendance',
                icon: Icons.badge_outlined,
                formKey: _staffFormKey,
                countController: _staffCountController,
                videoName: _staffVideoName,
                onPickVideo: () =>
                    _pickVideo(isBeneficiary: false),
                onSubmit: () =>
                    _submit(isBeneficiary: false),
                isSubmitting: _submittingStaff,
                error: _staffError,
              ),

              const SizedBox(height: 24),

              // ==================================================
              // HISTORY
              // ==================================================

              const SectionHeader(
                title: 'Recent Submissions',
              ),

              const SizedBox(height: 12),

              if (_loadingHistory)
                const LoadingState(
                  message: 'Loading attendance history...',
                )
              else if (_history.isEmpty)
                const EmptyState(
                  icon: Icons.event_busy_outlined,
                  title: 'No attendance submitted yet',
                  message: 'Submitted records will appear here.',
                )
              else
                ..._history.map(
                      (record) => _buildHistoryRow(record),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // AI ATTENDANCE SECTION
  // ============================================================

  Widget _buildAiAttendanceSection() {
    if (_loadingAiAttendance) {
      return AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAiSectionHeader(),

            const SizedBox(height: 18),

            const LoadingState(
              message: 'Loading AI attendance...',
            ),
          ],
        ),
      );
    }

    if (_aiAttendanceError != null) {
      return AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAiSectionHeader(),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    color: AppColors.warning,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      _aiAttendanceError!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            SecondaryButton(
              label: 'Retry AI Connection',
              icon: Icons.refresh,
              onPressed: _loadAiAttendance,
            ),
          ],
        ),
      );
    }

    final summary = _aiSummary ?? {};
    final latest = _aiLatestSession ?? {};

    // ==========================================================
    // SUMMARY DATA
    // ==========================================================

    final totalTracked =
    _toInt(summary['total_tracked']);

    final sessionCount =
    _toInt(summary['total_sessions']);

    final observedSeconds =
    _toDouble(summary['total_observed_seconds']);

    // ==========================================================
    // ROLE DATA
    // ==========================================================

    final staff =
    _getRoleCount('Staff');

    final beneficiary =
    _getRoleCount('Beneficiary');

    final unknown =
    _getRoleCount('Unknown');

    final roleTotal =
        staff + beneficiary + unknown;

    final distributionTotal =
    roleTotal > 0 ? roleTotal : totalTracked;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAiSectionHeader(),

          const SizedBox(height: 6),

          const Text(
            'Live data received from the Sentinal AI attendance backend.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 18),

          // ======================================================
          // TOP STATISTICS
          //
          // Uses IntrinsicHeight so the two stat cards in each row
          // stay the same height as each other even though their
          // content (large numbers, scaled fonts) can vary.
          // ======================================================

          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildAiStatCard(
                    title: 'Tracked',
                    value: '$totalTracked',
                    icon: Icons.people_outline,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _buildAiStatCard(
                    title: 'Staff',
                    value: '$staff',
                    icon: Icons.badge_outlined,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildAiStatCard(
                    title: 'Beneficiary',
                    value: '$beneficiary',
                    icon: Icons.diversity_3_outlined,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _buildAiStatCard(
                    title: 'Unknown',
                    value: '$unknown',
                    icon: Icons.help_outline,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ======================================================
          // SESSION INFORMATION
          // ======================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Session Information',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                _buildInfoRow(
                  'Sessions available',
                  '$sessionCount',
                ),

                const SizedBox(height: 8),

                _buildInfoRow(
                  'Observed time',
                  '${observedSeconds.toStringAsFixed(1)} sec',
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ======================================================
          // LATEST AI SESSION
          // ======================================================

          _buildLatestSessionCard(latest),

          const SizedBox(height: 18),

          // ======================================================
          // ROLE DISTRIBUTION
          // ======================================================

          const Text(
            'Role Distribution',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 10),

          _buildRoleDistribution(
            label: 'Staff',
            value: staff,
            total: distributionTotal,
            icon: Icons.badge_outlined,
          ),

          const SizedBox(height: 10),

          _buildRoleDistribution(
            label: 'Beneficiary',
            value: beneficiary,
            total: distributionTotal,
            icon: Icons.diversity_3_outlined,
          ),

          const SizedBox(height: 10),

          _buildRoleDistribution(
            label: 'Unknown',
            value: unknown,
            total: distributionTotal,
            icon: Icons.help_outline,
          ),

          const SizedBox(height: 14),

          const Text(
            'Role statistics received from the AI API.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 16),

          // ======================================================
          // REFRESH
          // ======================================================

          SecondaryButton(
            label: 'Refresh AI Attendance',
            icon: Icons.refresh,
            onPressed: _loadAiAttendance,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LATEST AI SESSION CARD
  // ============================================================

  Widget _buildLatestSessionCard(
      Map<String, dynamic> latest,
      ) {
    if (latest.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: const Text(
          'No AI attendance session available.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final sessionId =
        latest['session_id']?.toString() ?? 'Unknown';

    final tracked =
    _toInt(latest['total_tracked']);

    final staff =
    _toInt(latest['staff']);

    final beneficiary =
    _toInt(latest['beneficiary']);

    final unknown =
    _toInt(latest['unknown']);

    final startedAt =
        latest['session_started_at']?.toString() ?? 'Unknown';

    final endedAt =
        latest['session_ended_at']?.toString() ?? 'Unknown';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.video_camera_back_outlined,
                  color: AppColors.primary,
                  size: 19,
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Text(
                  'Latest AI Session',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: const Text(
                  'LATEST',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _buildInfoRow(
            'Session ID',
            sessionId,
          ),

          const SizedBox(height: 8),

          _buildInfoRow(
            'Tracked',
            '$tracked',
          ),

          const SizedBox(height: 8),

          _buildInfoRow(
            'Staff',
            '$staff',
          ),

          const SizedBox(height: 8),

          _buildInfoRow(
            'Beneficiary',
            '$beneficiary',
          ),

          const SizedBox(height: 8),

          _buildInfoRow(
            'Unknown',
            '$unknown',
          ),

          const SizedBox(height: 12),

          const Divider(
            height: 1,
          ),

          const SizedBox(height: 12),

          _buildInfoRow(
            'Started',
            startedAt,
          ),

          const SizedBox(height: 8),

          _buildInfoRow(
            'Ended',
            endedAt,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AI HEADER
  // ============================================================

  Widget _buildAiSectionHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.smart_toy_outlined,
            color: AppColors.primary,
            size: 22,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: const [
              Text(
                'AI Attendance Monitoring',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              SizedBox(height: 2),

              Text(
                'YOLO + ByteTrack + Attendance Engine',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'AI',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.warning,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // AI STAT CARD
  //
  // The numeric value can grow arbitrarily (large headcounts) and
  // the device font scale can be larger than 1.0, so the value is
  // wrapped in Flexible + FittedBox to shrink instead of
  // overflowing, and the title is capped to one line.
  // ============================================================

  Widget _buildAiStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFORMATION ROW
  // ============================================================

  Widget _buildInfoRow(
      String label,
      String value,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),

        const SizedBox(width: 8),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ROLE DISTRIBUTION
  // ============================================================

  Widget _buildRoleDistribution({
    required String label,
    required int value,
    required int total,
    required IconData icon,
  }) {
    final ratio = total > 0
        ? (value / total).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: AppColors.secondary,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(width: 8),

            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '$value',
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: AppColors.background,
            valueColor:
            const AlwaysStoppedAnimation<Color>(
              AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MANUAL ATTENDANCE CARD
  // ============================================================

  Widget _buildAttendanceCard({
    required String title,
    required IconData icon,
    required GlobalKey<FormState> formKey,
    required TextEditingController countController,
    required String? videoName,
    required VoidCallback onPickVideo,
    required VoidCallback onSubmit,
    required bool isSubmitting,
    required String? error,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: AppColors.primary,
                  size: 22,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            AppTextField(
              label: 'Number present today',
              controller: countController,
              keyboardType: TextInputType.number,
              validator: _countValidator,
            ),

            const SizedBox(height: 12),

            SecondaryButton(
              label: videoName ??
                  'Attach video evidence (optional)',
              icon: Icons.videocam_outlined,
              onPressed: onPickVideo,
            ),

            if (error != null) ...[
              const SizedBox(height: 10),

              Text(
                error,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                ),
              ),
            ],

            const SizedBox(height: 14),

            PrimaryButton(
              label: isSubmitting
                  ? 'Submitting...'
                  : 'Submit',
              onPressed:
              isSubmitting ? () {} : onSubmit,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HISTORY ROW
  // ============================================================

  Widget _buildHistoryRow(
      AttendanceRecord record,
      ) {
    final dateStr =
        '${record.date.day.toString().padLeft(2, '0')}/'
        '${record.date.month.toString().padLeft(2, '0')}/'
        '${record.date.year}';

    final isBeneficiary =
        record.type == AttendanceType.beneficiary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isBeneficiary
                  ? Icons.diversity_3_outlined
                  : Icons.badge_outlined,
              color: AppColors.secondary,
              size: 20,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    isBeneficiary
                        ? 'Beneficiary Attendance'
                        : 'Staff Attendance',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  Text(
                    dateStr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 64),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '${record.presentCount}',
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}