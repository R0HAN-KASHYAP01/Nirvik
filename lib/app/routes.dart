import 'package:flutter/material.dart';

import '../screens/splash/splash_screen.dart';
import '../features/state_admin/presentation/state_admin_dashboard_screen.dart';
import '../features/district_admin/presentation/district_admin_dashboard_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/auth/presentation/role_selection_screen.dart';
import '../features/district_admin/presentation/institute_category_screen.dart';
import '../features/district_admin/presentation/district_admin_shell_screen.dart';
import '../features/ngo/presentation/ngo_shell_screen.dart';

import '../features/mosje_admin/presentation/official_shell_screen.dart';
import '../features/dashboard/presentation/inspector_shell_screen.dart';
import '../features/dashboard/presentation/inspector_profile_screen.dart';
import '../features/mosje_admin/presentation/official_profile_screen.dart';

import '../features/dashboard/presentation/assignments_screen.dart';

import '../features/ngo/presentation/ngo_profile_screen.dart';
import '../features/ngo/presentation/attendance_screen.dart';
import '../features/ngo/presentation/reports_screen.dart';
import '../features/ngo/presentation/camera_screen.dart';

import '../features/map/presentation/institute_map_screen.dart';

import '../core/widgets/module_placeholder_screen.dart';

import '../features/projects/presentation/project_list_screen.dart';

import '../features/schemes/presentation/schemes_screen.dart';

import '../features/mosje_admin/presentation/official_cctv_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String roleSelection = '/role-selection';

  static const String officialDashboard = '/official-dashboard';
  static const String inspectorDashboard = '/inspector-dashboard';
  static const String districtInstitutes = '/district-institutes';

  static const String inspectorProfile = '/inspector-profile';
  static const String officialProfile = '/official-profile';

  static const String ngoDashboard = '/ngo-dashboard';
  static const String ngoProfile = '/ngo-profile';
  static const String ngoAttendance = '/ngo-attendance';
  static const String ngoReports = '/ngo-reports';
  static const String ngoCamera = '/ngo-camera';
    static const String stateAdminDashboard = '/state-admin-dashboard';
  static const String districtAdminDashboard = '/district-admin-dashboard';
  static const String instituteMap = '/institute-map';

  static const String projectsPlaceholder = '/projects';
  static const String inspectionsPlaceholder = '/inspections';
  static const String cctvPlaceholder = '/cctv';

  static const String assignmentsPlaceholder = '/assignments';
  static const String inspectionWorkflowPlaceholder =
      '/inspection-workflow';

  static const String schemes = '/schemes';

  static const String rvcPlaceholder = '/rvc';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),

        login: (context) => const LoginScreen(),

        signup: (context) => const SignupScreen(),

        roleSelection: (context) => const RoleSelectionScreen(),

        // ============================================================
        // OFFICIAL
        // ============================================================

        officialDashboard: (context) => const OfficialShellScreen(),

        officialProfile: (context) => const OfficialProfileScreen(),

        // Official CCTV opens actual CCTV monitoring page.
        cctvPlaceholder: (context) => const OfficialCctvScreen(),
            // ============================================================
        // STATE ADMIN
        // ============================================================

        stateAdminDashboard: (context) => const StateAdminDashboardScreen(),

        // ============================================================
        // DISTRICT ADMIN
        // ============================================================

           districtAdminDashboard: (context) => const DistrictAdminShellScreen(),
        districtInstitutes: (context) => const InstituteCategoryScreen(),
        // ============================================================
        // INSPECTOR
        // ============================================================

        inspectorDashboard: (context) => const InspectorShellScreen(),

        inspectorProfile: (context) => const InspectorProfileScreen(),

        // ============================================================
        // NGO / INSTITUTE
        // ============================================================

        ngoDashboard: (context) => const NgoShellScreen(),

        ngoProfile: (context) => const NgoProfileScreen(),

        ngoAttendance: (context) => const AttendanceScreen(),

        ngoReports: (context) => const ReportsScreen(),

        ngoCamera: (context) => const CameraScreen(),

        // ============================================================
        // MAP
        // ============================================================

        instituteMap: (context) => const InstituteMapScreen(),

        // ============================================================
        // PROJECTS
        // ============================================================

        projectsPlaceholder: (context) => const ProjectListScreen(),

        // ============================================================
        // INSPECTIONS
        // ============================================================

        inspectionsPlaceholder: (context) =>
            const ModulePlaceholderScreen(
          title: 'Inspections',
          message:
              'Inspections module will be implemented in a later phase.',
        ),

        // ============================================================
        // ANALYTICS
        // ============================================================


        // ============================================================
        // ASSIGNMENTS
        // ============================================================

        assignmentsPlaceholder: (context) => const AssignmentsScreen(),

        // ============================================================
        // INSPECTION WORKFLOW
        // ============================================================

        inspectionWorkflowPlaceholder: (context) =>
            const ModulePlaceholderScreen(
          title: 'Inspection Workflow',
          message:
              'Inspection Workflow — coming in the next phase.',
        ),

        // ============================================================
        // SCHEMES
        // ============================================================

        schemes: (context) => const SchemesScreen(),

        // ============================================================
        // PMU MONITORING
        // ============================================================

      

        // ============================================================
        // RVC
        // ============================================================

        rvcPlaceholder: (context) =>
            const ModulePlaceholderScreen(
          title: 'RVC',
          message:
              'Remote Video Conferencing will be implemented in a later phase.',
        ),
      };
}

// ====================================================================
// ANALYTICS SCREEN
// ====================================================================
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}


class _AnalyticsScreenState extends State<AnalyticsScreen> {
  static const Color navy = Color(0xFF123E68);
  static const Color primaryBlue = Color(0xFF14568A);

  static const Color background = Color(0xFFEAF2F8);
  static const Color cardBackground = Color(0xFFF8FBFD);
  static const Color softBlue = Color(0xFFD7E5EE);
  static const Color borderColor = Color(0xFFBFD2E0);

  static const Color textDark = Color(0xFF17324D);
  static const Color textGrey = Color(0xFF667788);

  static const Color green = Color(0xFF20A77A);
  static const Color orange = Color(0xFFFF9D2E);
  static const Color red = Color(0xFFE63E4D);

  String _selectedPeriod = '30 Days';

  // Values change according to selected period.
  final Map<String, Map<String, String>> _periodData = {
    '7 Days': {
      'inspections': '4',
      'completed': '2',
      'underReview': '1',
      'pending': '1',
    },
    '30 Days': {
      'inspections': '12',
      'completed': '8',
      'underReview': '2',
      'pending': '2',
    },
    '6 Months': {
      'inspections': '42',
      'completed': '31',
      'underReview': '7',
      'pending': '4',
    },
    '1 Year': {
      'inspections': '86',
      'completed': '67',
      'underReview': '12',
      'pending': '7',
    },
  };

  Map<String, String> get _currentData =>
      _periodData[_selectedPeriod]!;

  void _openProjects() {
    Navigator.of(context).pushNamed(
      AppRoutes.projectsPlaceholder,
    );
  }

  void _openHighRiskProjects() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProjectListScreen(
          initialHighRiskFilter: true,
        ),
      ),
    );
  }

  void _openAssignments() {
    Navigator.of(context).pushNamed(
      AppRoutes.assignmentsPlaceholder,
    );
  }

  

  void _openCctv() {
    Navigator.of(context).pushNamed(
      AppRoutes.cctvPlaceholder,
    );
  }

  void _showUnderReviewAction() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.rate_review_outlined,
                      color: orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Under Review',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'There are currently 2 inspections under review.',
                style: TextStyle(
                  color: textGrey,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(this.context).pushNamed(
                      AppRoutes.assignmentsPlaceholder,
                    );
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Assignments'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPeriodSelector() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Period',
                style: TextStyle(
                  color: textDark,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose the period for analytics data.',
                style: TextStyle(
                  color: textGrey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              ...[
                '7 Days',
                '30 Days',
                '6 Months',
                '1 Year',
              ].map(
                (period) {
                  final selected = period == _selectedPeriod;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _selectedPeriod = period;
                        });

                        Navigator.pop(sheetContext);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? softBlue
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? primaryBlue
                                : borderColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: selected
                                  ? primaryBlue
                                  : textGrey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                period,
                                style: TextStyle(
                                  color: selected
                                      ? navy
                                      : textDark,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(
                                Icons.check_circle,
                                color: primaryBlue,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _currentData;

    return Scaffold(
      backgroundColor: background,

      // ============================================================
      // APP BAR
      // ============================================================

      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Analytics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _showPeriodSelector,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedPeriod,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 15,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ============================================================
      // BODY
      // ============================================================

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                16,
                18,
                16,
                28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // OVERVIEW
                  // ==================================================

                  const Text(
                    'Overview',
                    style: TextStyle(
                      color: navy,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 14),

                  LayoutBuilder(
                    builder: (context, box) {
                      final twoColumns = box.maxWidth >= 520;

                      final width = twoColumns
                          ? (box.maxWidth - 12) / 2
                          : box.maxWidth;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _overviewCard(
                            width: width,
                            icon: Icons.apartment_rounded,
                            iconColor: primaryBlue,
                            title: 'Total Projects / Institutes',
                            value: '6',
                            onTap: _openProjects,
                          ),

                          _overviewCard(
                            width: width,
                            icon: Icons.assignment_rounded,
                            iconColor: green,
                            title: 'Total Inspections',
                            value: data['inspections']!,
                            onTap: _openAssignments,
                          ),

                          _overviewCard(
                            width: width,
                            icon: Icons.schedule_rounded,
                            iconColor: orange,
                            title: 'Under Review',
                            value: '3',
                            onTap: _showUnderReviewAction,
                          ),

                          _overviewCard(
                            width: width,
                            icon: Icons.warning_amber_rounded,
                            iconColor: red,
                            title: 'High Risk',
                            value: '1',
                            danger: true,
                            onTap: _openHighRiskProjects,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 22),

                  // ==================================================
                  // INSPECTION OVERVIEW + RISK DISTRIBUTION
                  // ==================================================

                  LayoutBuilder(
                    builder: (context, box) {
                      final wide = box.maxWidth >= 700;

                      if (wide) {
                        return Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _inspectionOverviewCard(
                                data,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _riskDistributionCard(),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          _inspectionOverviewCard(data),
                          const SizedBox(height: 14),
                          _riskDistributionCard(),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 22),

                  // ==================================================
                  // INSPECTION TREND
                  // ==================================================

                  _sectionHeading(
                    'Inspection Trend',
                    trailing: _selectedPeriod,
                  ),

                  const SizedBox(height: 10),

                  _analyticsCard(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 145,
                                child: CustomPaint(
                                  painter: _TrendPainter(
                                    period: _selectedPeriod,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Container(
                              width: 1,
                              height: 130,
                              color: borderColor,
                            ),
                            const SizedBox(width: 14),
                            SizedBox(
                              width: 82,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.bar_chart_rounded,
                                    color: primaryBlue,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    data['inspections']!,
                                    style: const TextStyle(
                                      color: navy,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'inspections\nin $_selectedPeriod',
                                    style: const TextStyle(
                                      color: textGrey,
                                      fontSize: 10,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceAround,
                          children: [
                            _periodLabel(
                              '7 Days',
                            ),
                            _periodLabel(
                              '30 Days',
                              selected: _selectedPeriod ==
                                  '30 Days',
                            ),
                            _periodLabel(
                              '6 Months',
                            ),
                            _periodLabel(
                              '1 Year',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                 
                  // ==================================================
                  // INSTITUTE + INSPECTOR
                  // ==================================================

                  LayoutBuilder(
                    builder: (context, box) {
                      final wide = box.maxWidth >= 720;

                      if (wide) {
                        return Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _instituteMonitoringCard(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _inspectorPerformanceCard(),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          _instituteMonitoringCard(),
                          const SizedBox(height: 14),
                          _inspectorPerformanceCard(),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 22),

                  // ==================================================
                  // CCTV MONITORING
                  // ==================================================

                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _openCctv,
                    child: _analyticsCard(
                      child: Row(
                        children: [
                          _coloredIconBox(
                            Icons.videocam_rounded,
                            primaryBlue,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'CCTV Monitoring',
                              style: TextStyle(
                                color: navy,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _cctvStat(
                            color: green,
                            label: 'Online',
                            value: '5',
                          ),
                          const SizedBox(width: 18),
                          _verticalDivider(),
                          const SizedBox(width: 18),
                          _cctvStat(
                            color: red,
                            label: 'Offline',
                            value: '1',
                          ),
                          const SizedBox(width: 18),
                          _verticalDivider(),
                          const SizedBox(width: 18),
                          _cctvStat(
                            color: orange,
                            label: 'Alerts',
                            value: '2',
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: navy,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ==================================================
                  // ATTENTION REQUIRED
                  // ==================================================

                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _openHighRiskProjects,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFFFD5A5),
                        ),
                      ),
                      child: Row(
                        children: [
                          _coloredIconBox(
                            Icons.warning_amber_rounded,
                            orange,
                            backgroundColor:
                                const Color(0xFFFFE8C8),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Attention Required',
                                  style: TextStyle(
                                    color: Color(0xFFA7351D),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  '2 High-risk institutes  •  3 Overdue inspections  •  1 CCTV offline',
                                  style: TextStyle(
                                    color: textGrey,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: navy,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // QUICK NAVIGATION
                  // ==================================================

                  _sectionHeading('Quick Navigation'),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _quickAction(
                          icon: Icons.home_rounded,
                          label: 'Home',
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              AppRoutes.officialDashboard,
                            );
                          },
                        ),
                      ),
                      
                    
                      const SizedBox(width: 10),
                      Expanded(
                        child: _quickAction(
                          icon: Icons.person_outline_rounded,
                          label: 'Profile',
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              AppRoutes.officialProfile,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ==================================================================
  // OVERVIEW CARD
  // ==================================================================

  Widget _overviewCard({
    required double width,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: danger
                  ? red.withValues(alpha: 0.35)
                  : borderColor,
            ),
          ),
          child: Row(
            children: [
              _coloredIconBox(
                icon,
                iconColor,
                backgroundColor: danger
                    ? const Color(0xFFFFE5E8)
                    : const Color(0xFFE6F1F9),
                size: 56,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      value,
                      style: TextStyle(
                        color: danger ? red : navy,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.bar_chart_rounded,
                color: iconColor,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================================================================
  // INSPECTION OVERVIEW
  // ==================================================================

  Widget _inspectionOverviewCard(
    Map<String, String> data,
  ) {
    return _analyticsCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Inspection Overview',
            style: TextStyle(
              color: navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _DonutPainter(),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '12',
                          style: TextStyle(
                            color: navy,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Total',
                          style: TextStyle(
                            color: textGrey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _legendRow(
                      green,
                      'Completed',
                      data['completed']!,
                    ),
                    const SizedBox(height: 12),
                    _legendRow(
                      orange,
                      'Under Review',
                      data['underReview']!,
                    ),
                    const SizedBox(height: 12),
                    _legendRow(
                      primaryBlue,
                      'In Progress',
                      '1',
                    ),
                    const SizedBox(height: 12),
                    _legendRow(
                      const Color(0xFF7890A5),
                      'Assigned',
                      '0',
                    ),
                    const SizedBox(height: 12),
                    _legendRow(
                      red,
                      'Overdue',
                      '1',
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

  // ==================================================================
  // RISK DISTRIBUTION
  // ==================================================================

  Widget _riskDistributionCard() {
    return _analyticsCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Risk Distribution',
            style: TextStyle(
              color: navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _riskRow(
            color: red,
            title: 'High Risk',
            value: '1',
            percentage: '17%',
            progress: 0.17,
          ),
          const SizedBox(height: 16),
          _riskRow(
            color: orange,
            title: 'Medium Risk',
            value: '3',
            percentage: '50%',
            progress: 0.50,
          ),
          const SizedBox(height: 16),
          _riskRow(
            color: green,
            title: 'Low Risk',
            value: '2',
            percentage: '33%',
            progress: 0.33,
          ),
        ],
      ),
    );
  }

  // ==================================================================
  // RISK ROW
  // ==================================================================

  Widget _riskRow({
    required Color color,
    required String title,
    required String value,
    required String percentage,
    required double progress,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: navy,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 18),
            Text(
              '($percentage)',
              style: const TextStyle(
                color: textGrey,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: background,
            valueColor:
                AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ==================================================================
  // LEGEND
  // ==================================================================

  Widget _legendRow(
    Color color,
    String title,
    String value,
  ) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: textDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: navy,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ==================================================================
  // SECTION HEADING
  // ==================================================================

  Widget _sectionHeading(
    String title, {
    String? trailing,
    VoidCallback? onTrailingTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null)
          InkWell(
            onTap: onTrailingTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  Text(
                    trailing,
                    style: const TextStyle(
                      color: primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (onTrailingTap != null)
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: primaryBlue,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ==================================================================
  // ANALYTICS CARD
  // ==================================================================

  Widget _analyticsCard({
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: child,
    );
  }

  // ==================================================================
  // SCHEME HEADER
  // ==================================================================

  Widget _schemeHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: softBlue.withValues(alpha: 0.65),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(14),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              'Scheme',
              style: TextStyle(
                color: navy,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Institutes',
              style: TextStyle(
                color: navy,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Inspections',
              style: TextStyle(
                color: navy,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: 20),
        ],
      ),
    );
  }

  // ==================================================================
  // SCHEME ROW
  // ==================================================================

  Widget _schemeRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String institutes,
    required String inspections,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: borderColor,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                institutes,
                style: const TextStyle(
                  color: navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                inspections,
                style: const TextStyle(
                  color: navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: navy,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================================
  // INSTITUTE MONITORING
  // ==================================================================

  Widget _instituteMonitoringCard() {
    return _analyticsCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Institute Monitoring',
            style: TextStyle(
              color: navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 105,
                height: 105,
                child: CustomPaint(
                  painter: _InstituteDonutPainter(),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '6',
                          style: TextStyle(
                            color: navy,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Total',
                          style: TextStyle(
                            color: textGrey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  children: [
                    _legendRow(
                      green,
                      'Inspected',
                      '4',
                    ),
                    const SizedBox(height: 10),
                    _legendRow(
                      orange,
                      'Under Review',
                      '1',
                    ),
                    const SizedBox(height: 10),
                    _legendRow(
                      red,
                      'High Risk',
                      '1',
                    ),
                    const SizedBox(height: 10),
                    _legendRow(
                      const Color(0xFF7890A5),
                      'Not Inspected',
                      '0',
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

  // ==================================================================
  // INSPECTOR PERFORMANCE
  // ==================================================================

  Widget _inspectorPerformanceCard() {
    return _analyticsCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            'Inspector Performance',
            trailing: 'View all',
            onTrailingTap: _openAssignments,
          ),
          const SizedBox(height: 12),
          _inspectorHeader(),
          _inspectorRow(
            'Inspector A',
            '8',
            '6',
            '75%',
            0.75,
          ),
          _inspectorRow(
            'Inspector B',
            '5',
            '5',
            '100%',
            1.0,
          ),
          _inspectorRow(
            'Inspector C',
            '4',
            '2',
            '50%',
            0.50,
          ),
        ],
      ),
    );
  }

  Widget _inspectorHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 8,
      ),
      color: softBlue.withValues(alpha: 0.65),
      child: const Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'Inspector',
              style: TextStyle(
                color: navy,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Assigned',
              style: TextStyle(
                color: navy,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Completed',
              style: TextStyle(
                color: navy,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Rate',
              style: TextStyle(
                color: navy,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inspectorRow(
    String name,
    String assigned,
    String completed,
    String rate,
    double progress,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 9,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: borderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              name,
              style: const TextStyle(
                color: textDark,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              assigned,
              style: const TextStyle(
                color: navy,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              completed,
              style: const TextStyle(
                color: navy,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  rate,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: background,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(
                        green,
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

  // ==================================================================
  // PERIOD LABEL
  // ==================================================================

  Widget _periodLabel(
    String text, {
    bool selected = false,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPeriod = text;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected ? navy : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : textGrey,
            fontSize: 10,
            fontWeight: selected
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ==================================================================
  // COLORED ICON
  // ==================================================================

  Widget _coloredIconBox(
    IconData icon,
    Color color, {
    Color? backgroundColor,
    double size = 42,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ??
            color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.48,
      ),
    );
  }

  // ==================================================================
  // CCTV STAT
  // ==================================================================

  Widget _cctvStat({
    required Color color,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 9,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: navy,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ==================================================================
  // VERTICAL DIVIDER
  // ==================================================================

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 30,
      color: borderColor,
    );
  }

  // ==================================================================
  // QUICK ACTION
  // ==================================================================

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 13,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: navy,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: textGrey,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// INSPECTION DONUT
// ====================================================================

class _DonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width / 2 - 8;

    final values = [
      8.0,
      2.0,
      1.0,
      0.0,
      1.0,
    ];

    final colors = [
      const Color(0xFF20A77A),
      const Color(0xFFFF9D2E),
      const Color(0xFF1674D1),
      const Color(0xFF7890A5),
      const Color(0xFFE63E4D),
    ];

    final total =
        values.reduce((a, b) => a + b);

    double startAngle = -1.5708;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.butt;

    for (int i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;

      final sweep =
          (values[i] / total) * 6.283185;

      paint.color = colors[i];

      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        startAngle,
        sweep,
        false,
        paint,
      );

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

// ====================================================================
// INSTITUTE DONUT
// ====================================================================

class _InstituteDonutPainter
    extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width / 2 - 8;

    final values = [
      4.0,
      1.0,
      1.0,
    ];

    final colors = [
      const Color(0xFF20A77A),
      const Color(0xFFFF9D2E),
      const Color(0xFFE63E4D),
    ];

    final total =
        values.reduce((a, b) => a + b);

    double startAngle = -1.5708;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;

    for (int i = 0; i < values.length; i++) {
      final sweep =
          (values[i] / total) * 6.283185;

      paint.color = colors[i];

      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        startAngle,
        sweep,
        false,
        paint,
      );

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

// ====================================================================
// TREND PAINTER
// ====================================================================

class _TrendPainter extends CustomPainter {
  final String period;

  _TrendPainter({
    required this.period,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartLeft = 24.0;
    final chartRight = size.width - 5;
    final chartTop = 15.0;
    final chartBottom = size.height - 25;

    final gridPaint = Paint()
      ..color = const Color(0xFFD7E5EE)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = chartTop +
          ((chartBottom - chartTop) / 4) * i;

      canvas.drawLine(
        Offset(chartLeft, y),
        Offset(chartRight, y),
        gridPaint,
      );
    }

    final points = _pointsForPeriod();

    final linePaint = Paint()
      ..color = const Color(0xFF1674D1)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    for (int i = 0; i < points.length; i++) {
      final x = chartLeft +
          ((chartRight - chartLeft) /
                  (points.length - 1)) *
              i;

      final y = chartBottom -
          (points[i] / 15) *
              (chartBottom - chartTop);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()
      ..color = const Color(0xFF1674D1);

    for (int i = 0; i < points.length; i++) {
      final x = chartLeft +
          ((chartRight - chartLeft) /
                  (points.length - 1)) *
              i;

      final y = chartBottom -
          (points[i] / 15) *
              (chartBottom - chartTop);

      canvas.drawCircle(
        Offset(x, y),
        3.5,
        dotPaint,
      );

      final innerPaint = Paint()
        ..color = Colors.white;

      canvas.drawCircle(
        Offset(x, y),
        1.5,
        innerPaint,
      );
    }
  }

  List<double> _pointsForPeriod() {
    switch (period) {
      case '7 Days':
        return [
          2,
          3,
          2,
          4,
          3,
          4,
          5,
        ];

      case '6 Months':
        return [
          4,
          6,
          5,
          8,
          7,
          10,
          9,
        ];

      case '1 Year':
        return [
          3,
          5,
          4,
          7,
          8,
          10,
          12,
        ];

      case '30 Days':
      default:
        return [
          3,
          5,
          4,
          6,
          7,
          4,
          7,
          6,
          8,
          12,
        ];
    }
  }

  @override
  bool shouldRepaint(
    covariant _TrendPainter oldDelegate,
  ) {
    return oldDelegate.period != period;
  }
}
