import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/assignment.dart';
import '../data/assignments_repository.dart';
import 'official_institute_info_screen.dart';

/// Read-only list of institutes assigned for today's inspections, shown to
/// the Official role from the homepage "Today's Inspections" tile.
///
/// Unlike [AssignmentsScreen] (used by PMU Inspectors), tapping an item here
/// never opens the inspection workflow — it only opens a basic-info view.
/// Officials always see the real institute name.
class OfficialTodayInstitutesScreen extends StatefulWidget {
  const OfficialTodayInstitutesScreen({super.key});

  @override
  State<OfficialTodayInstitutesScreen> createState() =>
      _OfficialTodayInstitutesScreenState();
}

class _OfficialTodayInstitutesScreenState
    extends State<OfficialTodayInstitutesScreen> {
  final AssignmentsRepository _repository = AssignmentsRepository();

  List<AssignmentSummary> _assignments = [];
  bool _isLoading = true;
  String? _errorMessage;

  // ---------------------------------------------------------------------------
  // Theme
  // ---------------------------------------------------------------------------

  static const Color _navy = Color(0xFF123E68);
  static const Color _darkNavy = Color(0xFF0B3154);
  static const Color _primaryBlue = Color(0xFF14568A);
  static const Color _background = Color(0xFFEAF2F8);
  static const Color _cardBackground = Color(0xFFE1ECF3);
  static const Color _borderColor = Color(0xFFD1DEE7);
  static const Color _textDark = Color(0xFF17324D);
  static const Color _textGrey = Color(0xFF667788);

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final assignments = await _repository.getAssignments();

      if (!mounted) return;

      setState(() {
        _assignments = assignments;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load institutes.';
      });

      debugPrint("Failed to load today's institutes: $error");
    }
  }

  List<AssignmentSummary> get _todaysInstitutes {
    final now = DateTime.now();

    return _assignments
        .where(
          (assignment) =>
              _isSameDay(assignment.scheduledDateTime, now),
        )
        .toList();
  }

  Color _statusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.assigned:
        return Colors.blueGrey;
      case AssignmentStatus.inProgress:
        return Colors.indigo;
      case AssignmentStatus.expired:
        return Colors.red;
      case AssignmentStatus.completed:
        return Colors.green;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} · '
        '$hour:$minute $period';
  }

  // ---------------------------------------------------------------------------
  // Small reusable information row
  // ---------------------------------------------------------------------------

  Widget _detailRow({
    required IconData icon,
    required String text,
    int maxLines = 2,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: _textGrey,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: const TextStyle(
              fontSize: 13,
              color: _textGrey,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Institute Card
  // ---------------------------------------------------------------------------

  Widget _buildInstituteCard(AssignmentSummary assignment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OfficialInstituteInfoScreen(
                  assignment: assignment,
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _borderColor,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // -------------------------------------------------------------
                // Institute name + status
                // -------------------------------------------------------------

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 340;

                    if (isSmall) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            assignment.instituteName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          StatusBadge(
                            label: assignment.status.label,
                            color: _statusColor(assignment.status),
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            assignment.instituteName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Align(
                            alignment: Alignment.topRight,
                            child: StatusBadge(
                              label: assignment.status.label,
                              color: _statusColor(assignment.status),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                // -------------------------------------------------------------
                // Address
                // -------------------------------------------------------------

                _detailRow(
                  icon: Icons.location_on_outlined,
                  text: assignment.fullAddress,
                  maxLines: 3,
                ),

                const SizedBox(height: 10),

                // -------------------------------------------------------------
                // Assignment / Area
                //
                // AssignmentSummary does not contain inspectorName.
                // Use the available area field instead.
                // -------------------------------------------------------------

                _detailRow(
                  icon: Icons.location_city_outlined,
                  text: assignment.area,
                  maxLines: 2,
                ),

                const SizedBox(height: 10),

                // -------------------------------------------------------------
                // Date + Arrow
                // -------------------------------------------------------------

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: _textGrey,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        _formatDateTime(
                          assignment.scheduledDateTime,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textGrey,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 13,
                      color: _textGrey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _primaryBlue,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _borderColor,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 44,
                  color: _textGrey,
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _textGrey,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _loadAssignments,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy,
                    side: const BorderSide(
                      color: _navy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final institutes = _todaysInstitutes;

    if (institutes.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.apartment_outlined,
          title: 'No institutes scheduled today',
          message:
              'Institutes assigned for inspection today will appear here.',
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryBlue,
      onRefresh: _loadAssignments,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24,
        ),
        children: institutes.map(_buildInstituteCard).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Screen
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: const Text(
          "Today's Inspections",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }
}