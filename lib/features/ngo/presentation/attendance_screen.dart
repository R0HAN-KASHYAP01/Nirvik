// FILE: lib/features/ngo/presentation/attendance_screen.dart

import 'dart:async';
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

  final AiAttendanceService _aiAttendanceService =
      AiAttendanceService();

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
  bool _aiBlockedBySubmission = false;

  Map<String, dynamic>? _aiSummary;
  Map<String, dynamic>? _aiRoleStatistics;
  Map<String, dynamic>? _aiLatestSession;

  // ============================================================
  // LIVE AI MONITORING STATE
  // ============================================================

  int _aiCurrentCount = 0;
  bool _aiMonitoringRunning = false;
  bool _aiMonitoringLoopAlive = false;
  String? _aiCurrentSessionId;

  Timer? _aiPollingTimer;

  // Number of most-recent days to show inline under
  // "Recent Submissions".
  static const int _recentDaysWindow = 3;

  @override
  void initState() {
    super.initState();

    _initializeAttendanceScreen();
  }

  Future<void> _initializeAttendanceScreen() async {
    await _loadHistory();

    if (!mounted) return;

    await _loadAiAttendance();

    if (!mounted) return;

    /*
     * If today's beneficiary and staff attendance have already
     * been submitted, make sure AI monitoring is running.
     *
     * IMPORTANT:
     * This only happens when the Attendance screen is initialized.
     *
     * Manual attendance submission itself NEVER restarts or resets
     * the current AI session.
     */
    if (_hasSubmittedToday) {
      try {
        final current =
            await _aiAttendanceService.getCurrentAiAttendance();

        final running = current['running'] == true;
        final loopAlive = current['loop_alive'] == true;

        if (!running || !loopAlive) {
          await _aiAttendanceService.startAiAttendance();
        }

        await _loadLiveAiAttendance();
      } catch (_) {
        // Keep the Attendance screen usable if the AI backend
        // or camera is temporarily unavailable.
      }
    }

    if (!mounted) return;

    _startAiPolling();
  }

  @override
  void dispose() {
    _stopAiPolling();

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
  // RECENT HISTORY
  // ============================================================

  List<AttendanceRecord> get _recentHistory {
    if (_history.isEmpty) {
      return _history;
    }

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final cutoff = today.subtract(
      const Duration(
        days: _recentDaysWindow - 1,
      ),
    );

    return _history.where((record) {
      final recordDate = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );

      return !recordDate.isBefore(cutoff);
    }).toList();
  }

  // ============================================================
  // TODAY'S SUBMISSION CHECK
  // ============================================================

  bool _isSubmittedToday(AttendanceType type) {
    final now = DateTime.now();

    return _history.any(
      (record) =>
          record.type == type &&
          record.date.year == now.year &&
          record.date.month == now.month &&
          record.date.day == now.day,
    );
  }

  bool get _hasSubmittedToday {
    return _isSubmittedToday(AttendanceType.beneficiary) &&
        _isSubmittedToday(AttendanceType.staff);
  }

  // ============================================================
  // AI ATTENDANCE HISTORY
  // ============================================================

  Future<void> _loadAiAttendance() async {
    if (!mounted) return;

    if (!_hasSubmittedToday) {
      setState(() {
        _loadingAiAttendance = false;
        _aiBlockedBySubmission = true;
        _aiAttendanceError =
            "Submit today's beneficiary and staff attendance first "
            "to use AI attendance monitoring.";
      });

      return;
    }

    setState(() {
      _loadingAiAttendance = true;
      _aiBlockedBySubmission = false;
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
        _aiBlockedBySubmission = false;
        _aiAttendanceError =
            'Unable to connect to the AI attendance server.';
      });
    }
  }

  // ============================================================
  // LIVE AI ATTENDANCE
  // ============================================================

  /// Fetches the current AI monitoring state and live attendance.
  ///
  /// FastAPI endpoints:
  ///
  /// GET /api/v1/attendance/ai/status
  /// GET /api/v1/attendance/ai/current
  Future<void> _loadLiveAiAttendance() async {
    try {
      /*
       * The current endpoint already contains:
       *
       * active_count
       * running
       * loop_alive
       * session_id
       *
       * Therefore it is sufficient for the live UI.
       */
      final current =
          await _aiAttendanceService.getCurrentAiAttendance();

      if (!mounted) return;

      final running = current['running'] == true;
      final loopAlive = current['loop_alive'] == true;

      /*
       * A valid live state requires BOTH:
       *
       * running == true
       * loop_alive == true
       *
       * If the backend is inactive, show zero because there is
       * no currently active AI monitoring session.
       */
      final isLive = running && loopAlive;

      setState(() {
        _aiMonitoringRunning = running;
        _aiMonitoringLoopAlive = loopAlive;

        _aiCurrentCount = isLive
            ? _toInt(current['active_count'])
            : 0;

        _aiCurrentSessionId = isLive
            ? current['session_id']?.toString()
            : null;
      });
    } catch (_) {
      /*
       * Keep the last known value if a polling request
       * temporarily fails.
       */
    }
  }

  // ============================================================
  // AI POLLING
  // ============================================================

  /// Starts polling the FastAPI AI attendance endpoint.
  void _startAiPolling() {
    _aiPollingTimer?.cancel();

    _loadLiveAiAttendance();

    _aiPollingTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        _loadLiveAiAttendance();
      },
    );
  }

  /// Stops live AI polling.
  void _stopAiPolling() {
    _aiPollingTimer?.cancel();
    _aiPollingTimer = null;
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshAll() async {
    await _loadHistory();

    if (!mounted) return;

    await _loadAiAttendance();

    if (!mounted) return;

    await _loadLiveAiAttendance();
  }

  // ============================================================
  // VIDEO PICKER
  // ============================================================

  Future<void> _pickVideo({
    required bool isBeneficiary,
  }) async {
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
      return;
    }

    if (!mounted) return;

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

  Future<void> _submit({
    required bool isBeneficiary,
  }) async {
    final user = SessionService.instance.currentUser;

    if (user == null) {
      _showError(
        'User session not found. Please login again.',
      );
      return;
    }

    final formKey = isBeneficiary
        ? _beneficiaryFormKey
        : _staffFormKey;

    if (formKey.currentState == null ||
        !formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return;

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
        '${isBeneficiary ? 'Beneficiary' : 'Staff'} '
        'attendance submitted.',
      );

      // ========================================================
      // IMPORTANT:
      //
      // Manual attendance submission does NOT:
      //
      // - stop AI monitoring
      // - reset AI attendance
      // - create a new AI session
      // - call restartAiAttendance()
      //
      // The current AI monitoring session continues running.
      // ========================================================

      await _loadHistory();

      if (!mounted) return;

      /*
       * Refresh historical AI information only.
       *
       * This does NOT affect the currently running AI session.
       */
      await _loadAiAttendance();

      if (!mounted) return;

      /*
       * Refresh the live AI state.
       *
       * If AI was already running, its current count and
       * current session ID are preserved.
       */
      await _loadLiveAiAttendance();
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
  // DATE HELPERS
  // ============================================================

  /// Returns true only if [isoString] represents today's
  /// calendar date in local time.
  bool _isToday(String? isoString) {
    if (isoString == null || isoString.isEmpty) {
      return false;
    }

    final parsed = DateTime.tryParse(isoString);

    if (parsed == null) {
      return false;
    }

    final local = parsed.toLocal();
    final now = DateTime.now();

    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  // ============================================================
  // ROLE DATA
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

        if (itemRole != null &&
            itemRole.toLowerCase() == role.toLowerCase()) {
          return Map<String, dynamic>.from(item);
        }
      }
    }

    return {};
  }

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
                "Submit today's headcount for beneficiaries "
                "and staff separately.",
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 20),

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
                countController:
                    _beneficiaryCountController,
                videoName: _beneficiaryVideoName,
                onPickVideo: () {
                  _pickVideo(
                    isBeneficiary: true,
                  );
                },
                onSubmit: () {
                  _submit(
                    isBeneficiary: true,
                  );
                },
                isSubmitting: _submittingBeneficiary,
                error: _beneficiaryError,
              ),

              const SizedBox(height: 16),

              _buildAttendanceCard(
                title: 'Staff Attendance',
                icon: Icons.badge_outlined,
                formKey: _staffFormKey,
                countController:
                    _staffCountController,
                videoName: _staffVideoName,
                onPickVideo: () {
                  _pickVideo(
                    isBeneficiary: false,
                  );
                },
                onSubmit: () {
                  _submit(
                    isBeneficiary: false,
                  );
                },
                isSubmitting: _submittingStaff,
                error: _staffError,
              ),

              const SizedBox(height: 24),

              // ==================================================
              // AI ATTENDANCE
              // ==================================================

              _buildAiAttendanceSection(),

              const SizedBox(height: 24),

              // ==================================================
              // HISTORY
              // ==================================================

              _buildHistorySectionHeader(),

              const SizedBox(height: 12),

              if (_loadingHistory)
                const LoadingState(
                  message:
                      'Loading attendance history...',
                )
              else if (_history.isEmpty)
                const EmptyState(
                  icon: Icons.event_busy_outlined,
                  title:
                      'No attendance submitted yet',
                  message:
                      'Submitted records will appear here.',
                )
              else if (_recentHistory.isEmpty)
                const EmptyState(
                  icon: Icons.event_busy_outlined,
                  title:
                      'No submissions in the last 3 days',
                  message:
                      'Tap "View all" to see older records.',
                )
              else
                ..._recentHistory.map(
                  (record) =>
                      _buildHistoryRow(record),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HISTORY SECTION HEADER
  // ============================================================

  Widget _buildHistorySectionHeader() {
    final hasOlderRecords =
        _history.length > _recentHistory.length;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: SectionHeader(
            title: 'Recent Submissions',
          ),
        ),
        if (hasOlderRecords)
          TextButton(
            onPressed: _showAllHistory,
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 8,
              ),
              minimumSize:
                  const Size(0, 0),
              tapTargetSize:
                  MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'View all',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight:
                    FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // VIEW ALL HISTORY
  // ============================================================

  void _showAllHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (
            context,
            scrollController,
          ) {
            return Container(
              decoration:
                  const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin:
                          const EdgeInsets.only(
                        bottom: 14,
                      ),
                      decoration: BoxDecoration(
                        color:
                            AppColors.border,
                        borderRadius:
                            BorderRadius.circular(
                          2,
                        ),
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'All Submissions',
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w700,
                            color:
                                AppColors
                                    .textPrimary,
                          ),
                        ),
                      ),

                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                        ),
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pop();
                        },
                        splashRadius: 20,
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Expanded(
                    child: _history.isEmpty
                        ? const EmptyState(
                            icon:
                                Icons.event_busy_outlined,
                            title:
                                'No attendance submitted yet',
                            message:
                                'Submitted records will '
                                'appear here.',
                          )
                        : ListView.builder(
                            controller:
                                scrollController,
                            itemCount:
                                _history.length,
                            itemBuilder:
                                (context, index) {
                              return _buildHistoryRow(
                                _history[index],
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // AI ATTENDANCE SECTION
  // ============================================================

  Widget _buildAiAttendanceSection() {
    if (_loadingAiAttendance) {
      return AppCard(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildAiSectionHeader(),

            const SizedBox(height: 18),

            const LoadingState(
              message:
                  'Loading AI attendance...',
            ),
          ],
        ),
      );
    }

    if (_aiAttendanceError != null) {
      return AppCard(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildAiSectionHeader(),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(14),
              decoration:
                  BoxDecoration(
                color:
                    AppColors.background,
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
                border: Border.all(
                  color:
                      AppColors.border,
                ),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    _aiBlockedBySubmission
                        ? Icons.lock_outline
                        : Icons
                            .cloud_off_outlined,
                    color:
                        AppColors.warning,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      _aiAttendanceError!,
                      style:
                          const TextStyle(
                        fontSize: 12.5,
                        color: AppColors
                            .textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (!_aiBlockedBySubmission) ...[
              const SizedBox(height: 14),

              SecondaryButton(
                label:
                    'Retry AI Connection',
                icon: Icons.refresh,
                onPressed:
                    _loadAiAttendance,
              ),
            ],
          ],
        ),
      );
    }

    final summary = _aiSummary ?? {};
    final rawLatest =
        _aiLatestSession ?? {};

    final latestIsToday = _isToday(
      rawLatest['session_started_at']
          ?.toString(),
    );

    /*
     * Do not show yesterday's/latest historical
     * session as today's latest session.
     */
    final latest = latestIsToday
        ? rawLatest
        : <String, dynamic>{};

    // ==========================================================
    // SUMMARY DATA
    // ==========================================================

    final totalTracked =
        _toInt(summary['total_tracked']);

    final sessionCount =
        _toInt(summary['total_sessions']);

    final observedSeconds =
        _toDouble(
      summary['total_observed_seconds'],
    );

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
        roleTotal > 0
            ? roleTotal
            : totalTracked;

    final isLive =
        _aiMonitoringRunning &&
            _aiMonitoringLoopAlive;

    // ==========================================================
    // UI
    // ==========================================================

    return AppCard(
      padding:
          const EdgeInsets.all(18),
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildAiSectionHeader(),

          const SizedBox(height: 6),

          const Text(
            'Live data received from the Sentinal AI '
            'attendance backend.',
            style: TextStyle(
              fontSize: 12,
              color:
                  AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 18),

          // ====================================================
          // TOP STATISTICS
          // ====================================================

          IntrinsicHeight(
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildAiStatCard(
                    title:
                        'AI Attendance',
                    value: isLive
                        ? '$_aiCurrentCount'
                        : '0',
                    icon:
                        Icons.people_outline,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _buildAiStatCard(
                    title: 'Staff',
                    value: '$staff',
                    icon:
                        Icons.badge_outlined,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          IntrinsicHeight(
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildAiStatCard(
                    title:
                        'Beneficiary',
                    value:
                        '$beneficiary',
                    icon: Icons
                        .diversity_3_outlined,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _buildAiStatCard(
                    title: 'Unknown',
                    value:
                        '$unknown',
                    icon:
                        Icons.help_outline,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ====================================================
          // LIVE MONITORING STATUS
          // ====================================================

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(14),
            decoration:
                BoxDecoration(
              color:
                  AppColors.background,
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
              border: Border.all(
                color:
                    AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isLive
                          ? Icons.circle
                          : Icons
                              .circle_outlined,
                      size: 12,
                      color: isLive
                          ? AppColors
                              .success
                          : AppColors
                              .textSecondary,
                    ),

                    const SizedBox(width: 8),

                    const Expanded(
                      child: Text(
                        'AI Monitoring Status',
                        style:
                            TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              AppColors
                                  .textPrimary,
                        ),
                      ),
                    ),

                    Text(
                      isLive
                          ? 'LIVE'
                          : 'INACTIVE',
                      style:
                          TextStyle(
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w700,
                        color: isLive
                            ? AppColors
                                .success
                            : AppColors
                                .textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                _buildInfoRow(
                  'Current AI attendance',
                  isLive
                      ? '$_aiCurrentCount'
                      : '0',
                ),

                const SizedBox(height: 8),

                _buildInfoRow(
                  'Session',
                  _aiCurrentSessionId ??
                      'No active session',
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ====================================================
          // SESSION INFORMATION
          // ====================================================

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(14),
            decoration:
                BoxDecoration(
              color:
                  AppColors.background,
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
              border: Border.all(
                color:
                    AppColors.border,
              ),
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Session Information',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        AppColors
                            .textPrimary,
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

          // ====================================================
          // LATEST AI SESSION
          // ====================================================

          _buildLatestSessionCard(
            latest,
          ),

          const SizedBox(height: 18),

          // ====================================================
          // ROLE DISTRIBUTION
          // ====================================================

          const Text(
            'Role Distribution',
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style:
                TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
              color:
                  AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 10),

          _buildRoleDistribution(
            label: 'Staff',
            value: staff,
            total: distributionTotal,
            icon:
                Icons.badge_outlined,
          ),

          const SizedBox(height: 10),

          _buildRoleDistribution(
            label: 'Beneficiary',
            value: beneficiary,
            total: distributionTotal,
            icon: Icons
                .diversity_3_outlined,
          ),

          const SizedBox(height: 10),

          _buildRoleDistribution(
            label: 'Unknown',
            value: unknown,
            total: distributionTotal,
            icon:
                Icons.help_outline,
          ),

          const SizedBox(height: 14),

          const Text(
            'Role statistics received from the AI API.',
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style:
                TextStyle(
              fontSize: 11,
              color:
                  AppColors
                      .textSecondary,
            ),
          ),

          const SizedBox(height: 16),

          SecondaryButton(
            label:
                'Refresh AI Attendance',
            icon: Icons.refresh,
            onPressed:
                _loadAiAttendance,
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
        padding:
            const EdgeInsets.all(14),
        decoration:
            BoxDecoration(
          color:
              AppColors.background,
          borderRadius:
              BorderRadius.circular(
            10,
          ),
          border: Border.all(
            color:
                AppColors.border,
          ),
        ),
        child: const Text(
          'No camera-based attendance recorded today. '
          'Run the camera pipeline to update today\'s '
          'AI attendance.',
          maxLines: 3,
          overflow:
              TextOverflow.ellipsis,
          style:
              TextStyle(
            fontSize: 12,
            color:
                AppColors
                    .textSecondary,
          ),
        ),
      );
    }

    final sessionId =
        latest['session_id']
                ?.toString() ??
            'Unknown';

    final tracked =
        _toInt(
      latest['total_tracked'],
    );

    final staff =
        _toInt(
      latest['staff'],
    );

    final beneficiary =
        _toInt(
      latest['beneficiary'],
    );

    final unknown =
        _toInt(
      latest['unknown'],
    );

    final startedAt =
        latest['session_started_at']
                ?.toString() ??
            'Unknown';

    final endedAt =
        latest['session_ended_at']
                ?.toString() ??
            'Unknown';

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        color:
            AppColors.background,
        borderRadius:
            BorderRadius.circular(
          10,
        ),
        border: Border.all(
          color:
              AppColors.border,
        ),
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration:
                    BoxDecoration(
                  color: AppColors
                      .primary
                      .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    9,
                  ),
                ),
                child:
                    const Icon(
                  Icons
                      .video_camera_back_outlined,
                  color:
                      AppColors.primary,
                  size: 19,
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Text(
                  'Latest AI Session',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        AppColors
                            .textPrimary,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 7,
                  vertical: 4,
                ),
                decoration:
                    BoxDecoration(
                  color: AppColors
                      .secondary
                      .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child:
                    const Text(
                  'LATEST',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      TextStyle(
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        AppColors.secondary,
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
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration:
              BoxDecoration(
            color: AppColors
                .primary
                .withValues(
              alpha: 0.10,
            ),
            borderRadius:
                BorderRadius.circular(
              10,
            ),
          ),
          child: const Icon(
            Icons.smart_toy_outlined,
            color:
                AppColors.primary,
            size: 22,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: const [
              Text(
                'AI Attendance Monitoring',
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      AppColors
                          .textPrimary,
                ),
              ),

              SizedBox(height: 2),

              Text(
                'YOLO + ByteTrack + Attendance Engine',
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    TextStyle(
                  fontSize: 11.5,
                  color:
                      AppColors
                          .textSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        Container(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 8,
            vertical: 5,
          ),
          decoration:
              BoxDecoration(
            color: AppColors
                .warning
                .withValues(
              alpha: 0.10,
            ),
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),
          child:
              const Text(
            'AI',
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style:
                TextStyle(
              fontSize: 10,
              fontWeight:
                  FontWeight.w700,
              color:
                  AppColors.warning,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // AI STAT CARD
  // ============================================================

  Widget _buildAiStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(13),
      decoration:
          BoxDecoration(
        color:
            AppColors.background,
        borderRadius:
            BorderRadius.circular(
          10,
        ),
        border: Border.all(
          color:
              AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color:
                AppColors.primary,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: FittedBox(
                    fit:
                        BoxFit.scaleDown,
                    alignment:
                        Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            AppColors
                                .textPrimary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 10.5,
                    color:
                        AppColors
                            .textSecondary,
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
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              fontSize: 12,
              color:
                  AppColors
                      .textSecondary,
            ),
          ),
        ),

        const SizedBox(width: 8),

        Flexible(
          child: Text(
            value,
            textAlign:
                TextAlign.right,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
              color:
                  AppColors
                      .textPrimary,
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
    final double ratio =
        total > 0
            ? (value / total)
                .clamp(0.0, 1.0)
                .toDouble()
            : 0.0;

    return Column(
      mainAxisSize:
          MainAxisSize.min,
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment:
              CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color:
                  AppColors.secondary,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  fontSize: 12,
                  color:
                      AppColors
                          .textPrimary,
                ),
              ),
            ),

            const SizedBox(width: 8),

            Flexible(
              child: FittedBox(
                fit:
                    BoxFit.scaleDown,
                alignment:
                    Alignment.centerRight,
                child: Text(
                  '$value',
                  maxLines: 1,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        AppColors
                            .textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        ClipRRect(
          borderRadius:
              BorderRadius.circular(
            10,
          ),
          child:
              LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor:
                AppColors.background,
            valueColor:
                const AlwaysStoppedAnimation<
                    Color>(
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
    required TextEditingController
        countController,
    required String? videoName,
    required VoidCallback onPickVideo,
    required VoidCallback onSubmit,
    required bool isSubmitting,
    required String? error,
  }) {
    return AppCard(
      padding:
          const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color:
                      AppColors.primary,
                  size: 22,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            AppTextField(
              label:
                  'Number present today',
              controller:
                  countController,
              keyboardType:
                  TextInputType.number,
              validator:
                  _countValidator,
            ),

            const SizedBox(height: 12),

            SecondaryButton(
              label: videoName ??
                  'Attach video evidence (optional)',
              icon:
                  Icons.videocam_outlined,
              onPressed:
                  onPickVideo,
            ),

            if (error != null) ...[
              const SizedBox(height: 10),

              Text(
                error,
                maxLines: 3,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  color:
                      AppColors.error,
                  fontSize: 12,
                ),
              ),
            ],

            const SizedBox(height: 14),

            PrimaryButton(
              label: isSubmitting
                  ? 'Submitting...'
                  : 'Submit',
              onPressed: isSubmitting
                  ? () {}
                  : onSubmit,
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
        record.type ==
            AttendanceType.beneficiary;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: AppCard(
        padding:
            const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center,
          children: [
            Icon(
              isBeneficiary
                  ? Icons
                      .diversity_3_outlined
                  : Icons
                      .badge_outlined,
              color:
                  AppColors.secondary,
              size: 20,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    isBeneficiary
                        ? 'Beneficiary Attendance'
                        : 'Staff Attendance',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  Text(
                    dateStr,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 11.5,
                      color:
                          AppColors
                              .textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 64,
              ),
              child: FittedBox(
                fit:
                    BoxFit.scaleDown,
                alignment:
                    Alignment.centerRight,
                child: Text(
                  '${record.presentCount}',
                  maxLines: 1,
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppColors.primary,
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