import 'package:flutter/material.dart';

import '../data/inspection_history_repository.dart';

class InspectionHistoryScreen extends StatefulWidget {
  const InspectionHistoryScreen({super.key});

  @override
  State<InspectionHistoryScreen> createState() =>
      _InspectionHistoryScreenState();
}

class _InspectionHistoryScreenState extends State<InspectionHistoryScreen> {
  final InspectionHistoryRepository _repository =
      InspectionHistoryRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _inspections = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final inspections = await _repository.getInspectionHistory();

      if (!mounted) return;

      setState(() {
        _inspections = inspections;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Date unavailable';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return value.toString();

    final localDate = date.toLocal();

    String twoDigits(int number) {
      return number.toString().padLeft(2, '0');
    }

    return '${twoDigits(localDate.day)}/'
        '${twoDigits(localDate.month)}/'
        '${localDate.year} '
        '${twoDigits(localDate.hour)}:'
        '${twoDigits(localDate.minute)}';
  }

  Color _riskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _stringValue(dynamic value, {String fallback = 'Not available'}) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return fallback;
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection History'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to load inspection history.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadHistory,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_inspections.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 160),
            Icon(
              Icons.history,
              size: 64,
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'No inspection history found.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Completed inspections will appear here.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _inspections.length,
        itemBuilder: (context, index) {
          final inspection = _inspections[index];

          final riskLevel = _stringValue(
            inspection['risk_level'],
            fallback: 'low',
          );

          final overallStatus = _stringValue(
            inspection['overall_status'],
            fallback: 'submitted',
          );

          final assignment =
              inspection['pmu_assignments'] as Map<String, dynamic>?;

          final scheduledDateTime =
              assignment?['scheduled_datetime'];

          final priority = _stringValue(
            assignment?['priority'],
            fallback: 'low',
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _showInspectionDetails(inspection);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Inspection #${index + 1}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _riskColor(riskLevel).withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${riskLevel.toUpperCase()} RISK',
                            style: TextStyle(
                              color: _riskColor(riskLevel),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Submitted',
                      value: _formatDate(inspection['submitted_at']),
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.assignment_outlined,
                      label: 'Status',
                      value: overallStatus,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.schedule_outlined,
                      label: 'Scheduled',
                      value: _formatDate(scheduledDateTime),
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.flag_outlined,
                      label: 'Priority',
                      value: priority,
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'View Details →',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showInspectionDetails(Map<String, dynamic> inspection) {
    final riskLevel = _stringValue(
      inspection['risk_level'],
      fallback: 'low',
    );

    final assignment =
        inspection['pmu_assignments'] as Map<String, dynamic>?;

    final scheduledDateTime =
        assignment?['scheduled_datetime'];

    final priority = _stringValue(
      assignment?['priority'],
      fallback: 'low',
    );

    final remarks = _stringValue(
      inspection['inspector_remarks'],
      fallback: 'No remarks provided.',
    );

    final summary = _stringValue(
      inspection['report_summary'],
      fallback: 'No report summary available.',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inspection Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                _DetailSection(
                  title: 'Submission',
                  children: [
                    _DetailRow(
                      label: 'Submitted At',
                      value: _formatDate(
                        inspection['submitted_at'],
                      ),
                    ),
                    _DetailRow(
                      label: 'Overall Status',
                      value: _stringValue(
                        inspection['overall_status'],
                      ),
                    ),
                    _DetailRow(
                      label: 'Risk Level',
                      value: riskLevel.toUpperCase(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailSection(
                  title: 'Assignment',
                  children: [
                    _DetailRow(
                      label: 'Assignment ID',
                      value: _stringValue(
                        inspection['assignment_id'],
                      ),
                    ),
                    _DetailRow(
                      label: 'Scheduled',
                      value: _formatDate(
                        scheduledDateTime,
                      ),
                    ),
                    _DetailRow(
                      label: 'Priority',
                      value: priority,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailSection(
                  title: 'Inspector Remarks',
                  children: [
                    Text(
                      remarks,
                      style: const TextStyle(
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailSection(
                  title: 'Report Summary',
                  children: [
                    Text(
                      summary,
                      style: const TextStyle(
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
        ),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}