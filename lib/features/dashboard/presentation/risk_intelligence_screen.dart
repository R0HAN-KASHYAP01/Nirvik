import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_card.dart';
import '../data/assignment_engine.dart';
import '../data/risk_data_repository.dart';
import '../../../models/project.dart';
import '../../../services/ai_attendance_service.dart';

class RiskIntelligenceScreen extends StatefulWidget {
  final Project project;

  const RiskIntelligenceScreen({
    super.key,
    required this.project,
  });

  @override
  State<RiskIntelligenceScreen> createState() =>
      _RiskIntelligenceScreenState();
}

class _RiskIntelligenceScreenState
    extends State<RiskIntelligenceScreen> {
  final RiskDataRepository _riskDataRepository =
      RiskDataRepository();

  final AiAttendanceService _aiAttendanceService =
      AiAttendanceService();

  final AssignmentEngine _assignmentEngine =
      AssignmentEngine();

  bool _loading = true;
  bool _creatingAssignment = false;

  String? _error;

  Map<String, dynamic>? _riskResult;

  @override
  void initState() {
    super.initState();
    _loadRiskIntelligence();
  }

  Future<void> _loadRiskIntelligence() async {
    final profileId = widget.project.profileId?.trim();

    if (profileId == null || profileId.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error =
            'This project does not have a valid Supabase profile ID.';
      });

      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final riskInput =
          await _riskDataRepository.getProjectRiskInput(
        profileId,
      );

      if (riskInput == null) {
        throw Exception(
          'Project data could not be found in Supabase.',
        );
      }

      final attendance =
          await _aiAttendanceService.getLatestAttendance();

      final result =
          await _aiAttendanceService.calculateProjectRisk(
        attendance: attendance,
        project: riskInput['project']
            as Map<String, dynamic>,
        inspections:
            _toInspectionList(riskInput['inspections']),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _riskResult = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  List<Map<String, dynamic>> _toInspectionList(
    dynamic value,
  ) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  double get _riskScore {
    final value = _riskResult?['risk_score'];

    if (value is num) {
      return value.toDouble();
    }

    return 0;
  }

  String get _riskLevel {
    final value = _riskResult?['risk_level'];

    if (value == null) {
      return 'unknown';
    }

    return value.toString().toLowerCase();
  }

  int get _anomalyCount {
    final value = _riskResult?['anomaly_count'];

    if (value is num) {
      return value.toInt();
    }

    return 0;
  }

  List<dynamic> get _reasons {
    final value = _riskResult?['reasons'];

    if (value is List) {
      return value;
    }

    return <dynamic>[];
  }

  List<dynamic> get _anomalies {
    final value = _riskResult?['anomalies'];

    if (value is List) {
      return value;
    }

    return <dynamic>[];
  }

  Map<String, dynamic> get _componentScores {
    final value = _riskResult?['component_scores'];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  Map<String, dynamic> get _features {
    final value = _riskResult?['features'];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  Color _riskColor(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
      case 'high':
        return AppColors.error;

      case 'medium':
        return AppColors.warning;

      case 'low':
        return AppColors.success;

      default:
        return AppColors.textSecondary;
    }
  }

  String _formatRiskLevel(String level) {
    if (level.trim().isEmpty) {
      return 'Unknown';
    }

    return level[0].toUpperCase() +
        level.substring(1).toLowerCase();
  }

  String _formatScore(dynamic value) {
    if (value is num) {
      return value.toStringAsFixed(1);
    }

    return '0.0';
  }

  Future<void> _createInspectionAssignment() async {
    final profileId = widget.project.profileId?.trim();

    if (profileId == null || profileId.isEmpty) {
      _showMessage(
        'This project does not have a valid Supabase profile ID.',
      );
      return;
    }

    if (_riskResult == null) {
      _showMessage(
        'Risk intelligence is not available yet.',
      );
      return;
    }

    if (_riskLevel == 'unknown') {
      _showMessage(
        'A valid risk level is required before creating an assignment.',
      );
      return;
    }

    final scheduledDateTime =
        await _pickAssignmentDateTime();

    if (scheduledDateTime == null || !mounted) {
      return;
    }

    setState(() {
      _creatingAssignment = true;
    });

    try {
      final result =
          await _assignmentEngine.createAssignment(
        instituteProfileId: profileId,
        riskScore: _riskScore,
        riskLevel: _riskLevel,
        scheduledDateTime: scheduledDateTime,
      );

      if (!mounted) {
        return;
      }

      if (result.success) {
        final inspectorName =
            result.assignment?['inspector_profile_id']
                ?.toString();

        _showAssignmentSuccess(
          inspectorName: inspectorName,
          scheduledDateTime: scheduledDateTime,
        );
      } else {
        _showMessage(
          result.message ??
              'Assignment could not be created.',
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Assignment failed: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _creatingAssignment = false;
        });
      }
    }
  }

  Future<DateTime?> _pickAssignmentDateTime() async {
    final now = DateTime.now();

    final initialDate =
        now.add(const Duration(days: 1));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(
        const Duration(days: 90),
      ),
    );

    if (selectedDate == null || !mounted) {
      return null;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(
        hour: 10,
        minute: 0,
      ),
    );

    if (selectedTime == null || !mounted) {
      return null;
    }

    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
  }

  void _showAssignmentSuccess({
    required String? inspectorName,
    required DateTime scheduledDateTime,
  }) {
    if (!mounted) {
      return;
    }

    final scheduledText =
        MaterialLocalizations.of(context)
            .formatFullDate(scheduledDateTime);

    final timeText =
        MaterialLocalizations.of(context)
            .formatTimeOfDay(
      TimeOfDay.fromDateTime(
        scheduledDateTime,
      ),
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Inspection Assignment Created',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'The project has been assigned successfully.',
                style: Theme.of(dialogContext)
                    .textTheme
                    .bodyLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Inspector Profile: '
                '${inspectorName ?? 'Assigned inspector'}',
              ),
              const SizedBox(height: 6),
              Text(
                'Scheduled: '
                '$scheduledText at $timeText',
              ),
              const SizedBox(height: 6),
              Text(
                'Priority: '
                '${_assignmentPriorityFromRisk()}',
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  String _assignmentPriorityFromRisk() {
    if (_riskLevel == 'critical') {
      return 'High';
    }

    if (_riskLevel == 'high' ||
        _riskScore >= 70) {
      return 'High';
    }

    if (_riskLevel == 'medium' ||
        _riskScore >= 40) {
      return 'Medium';
    }

    return 'Low';
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

  Widget _buildRiskHeader(
    BuildContext context,
  ) {
    final color = _riskColor(_riskLevel);

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color:
                      color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Risk Score',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_riskScore.toStringAsFixed(1)} / 100',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                            color: color,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      color.withValues(alpha: 0.10),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                  _formatRiskLevel(
                    _riskLevel,
                  ),
                  style: TextStyle(
                    color: color,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value:
                  (_riskScore / 100)
                      .clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor:
                  AppColors.textSecondary
                      .withValues(alpha: 0.12),
              valueColor:
                  AlwaysStoppedAnimation<Color>(
                color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentScores(
    BuildContext context,
  ) {
    final entries =
        <MapEntry<String, dynamic>>[
      MapEntry(
        'Attendance',
        _componentScores['attendance'] ?? 0,
      ),
      MapEntry(
        'Project',
        _componentScores['project'] ?? 0,
      ),
      MapEntry(
        'Inspection',
        _componentScores['inspection'] ?? 0,
      ),
      MapEntry(
        'Anomalies',
        _componentScores['anomalies'] ?? 0,
      ),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Risk Components',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  fontWeight:
                      FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          ...entries.map(
            (entry) => Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 14,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium,
                    ),
                  ),
                  Text(
                    _formatScore(entry.value),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                          fontWeight:
                              FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(
    BuildContext context,
  ) {
    final totalTracked =
        _features['attendance_total_tracked'] ??
            0;

    final staff =
        _features['attendance_staff_count'] ??
            0;

    final beneficiaries =
        _features['attendance_beneficiary_count'] ??
            0;

    final unknown =
        _features['attendance_unknown_count'] ??
            0;

    final pending =
        _features['project_pending_inspections'] ??
            0;

    final findings =
        _features['project_high_risk_findings'] ??
            0;

    return AppCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Risk Data Summary',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  fontWeight:
                      FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _summaryItem(
                context,
                'Tracked',
                totalTracked,
              ),
              _summaryItem(
                context,
                'Staff',
                staff,
              ),
              _summaryItem(
                context,
                'Beneficiaries',
                beneficiaries,
              ),
              _summaryItem(
                context,
                'Unknown',
                unknown,
              ),
              _summaryItem(
                context,
                'Pending',
                pending,
              ),
              _summaryItem(
                context,
                'High-Risk Findings',
                findings,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    BuildContext context,
    String label,
    dynamic value,
  ) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(10),
        color: AppColors.background,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            value.toString(),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight:
                      FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildReasons(
    BuildContext context,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Why this project received this risk score',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  fontWeight:
                      FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          if (_reasons.isEmpty)
            Text(
              'No specific risk reasons were returned.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            )
          else
            ..._reasons.map(
              (reason) => Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 10,
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color:
                          AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        reason.toString(),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnomalies(
    BuildContext context,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Detected Anomalies',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                      ),
                ),
              ),
              Text(
                '$_anomalyCount',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                      color:
                          _anomalyCount > 0
                              ? AppColors.error
                              : AppColors.success,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_anomalies.isEmpty)
            Text(
              'No anomalies detected.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            )
          else
            ..._anomalies.map((anomaly) {
              final item = anomaly is Map
                  ? Map<String, dynamic>.from(
                      anomaly,
                    )
                  : <String, dynamic>{};

              final signal =
                  item['signal']?.toString() ??
                      'unknown';

              final severity =
                  item['severity']?.toString() ??
                      'low';

              final description =
                  item['description']
                          ?.toString() ??
                      item['message']
                          ?.toString() ??
                      signal;

              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 10,
                ),
                child: Container(
                  padding:
                      const EdgeInsets.all(12),
                  decoration:
                      BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                    border: Border.all(
                      color: _riskColor(
                        severity,
                      ).withValues(
                        alpha: 0.35,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              signal,
                              style:
                                  Theme.of(
                                context,
                              )
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                      ),
                            ),
                          ),
                          Text(
                            _formatRiskLevel(
                              severity,
                            ),
                            style: TextStyle(
                              color:
                                  _riskColor(
                                severity,
                              ),
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(
    BuildContext context,
  ) {
    final profileId =
        widget.project.profileId?.trim();

    final enabled =
        !_creatingAssignment &&
        !_loading &&
        _riskResult != null &&
        profileId != null &&
        profileId.isNotEmpty &&
        _riskLevel != 'unknown';

    return AppCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      AppColors.primary
                          .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color:
                      AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Inspection Assignment',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Use the calculated risk result to create an inspection assignment. '
            'The Assignment Engine will select an eligible inspector using '
            'availability, workload, location suitability, and weighted randomness.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: enabled
                  ? _createInspectionAssignment
                  : null,
              icon: _creatingAssignment
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.person_add_alt_1_outlined,
                    ),
              label: Text(
                _creatingAssignment
                    ? 'Creating Assignment...'
                    : 'Create Inspection Assignment',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Risk Intelligence',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh risk',
            onPressed:
                _loading ||
                        _creatingAssignment
                    ? null
                    : _loadRiskIntelligence,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : _error != null
                ? _buildErrorState(
                    context,
                  )
                : _riskResult == null
                    ? _buildEmptyState(
                        context,
                      )
                    : ListView(
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          20,
                          16,
                          20,
                          24,
                        ),
                        children: [
                          Text(
                            widget.project.name,
                            style: Theme.of(
                              context,
                            )
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            'AI-powered project risk assessment',
                            style: Theme.of(
                              context,
                            )
                                .textTheme
                                .bodyMedium,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          _buildRiskHeader(
                            context,
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          _buildComponentScores(
                            context,
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          _buildSummary(
                            context,
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          _buildReasons(
                            context,
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          _buildAnomalies(
                            context,
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          _buildAssignmentCard(
                            context,
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to load risk intelligence',
              textAlign:
                  TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign:
                  TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed:
                  _loadRiskIntelligence,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.analytics_outlined,
              size: 48,
              color:
                  AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'No risk result available.',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed:
                  _loadRiskIntelligence,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Refresh',
              ),
            ),
          ],
        ),
      ),
    );
  }
}