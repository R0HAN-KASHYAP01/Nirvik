import 'package:flutter/material.dart';

import '../screens/splash/splash_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/auth/presentation/role_selection_screen.dart';
import '../features/ngo/presentation/ngo_shell_screen.dart';
import '../features/dashboard/presentation/official_shell_screen.dart';
import '../features/dashboard/presentation/inspector_shell_screen.dart';
import '../features/dashboard/presentation/inspector_profile_screen.dart';
import '../features/dashboard/presentation/official_profile_screen.dart';
import '../features/dashboard/presentation/pmu_monitoring_screen.dart';
import '../features/dashboard/presentation/assignments_screen.dart';
import '../features/ngo/presentation/ngo_profile_screen.dart';
import '../features/ngo/presentation/attendance_screen.dart';
import '../features/ngo/presentation/reports_screen.dart';
import '../features/ngo/presentation/camera_screen.dart';
import '../features/map/presentation/institute_map_screen.dart';
import '../core/widgets/module_placeholder_screen.dart';
import '../features/projects/presentation/project_list_screen.dart';
import '../features/schemes/presentation/schemes_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String roleSelection = '/role-selection';

  static const String officialDashboard = '/official-dashboard';

  static const String inspectorDashboard = '/inspector-dashboard';
  static const String inspectorProfile = '/inspector-profile';
  static const String officialProfile = '/official-profile';

  static const String ngoDashboard = '/ngo-dashboard';
  static const String ngoProfile = '/ngo-profile';
  static const String ngoAttendance = '/ngo-attendance';
  static const String ngoReports = '/ngo-reports';
  static const String ngoCamera = '/ngo-camera';

  static const String instituteMap = '/institute-map';

  static const String projectsPlaceholder = '/projects';
  static const String inspectionsPlaceholder = '/inspections';
  static const String cctvPlaceholder = '/cctv';
  static const String analyticsPlaceholder = '/analytics';

  static const String assignmentsPlaceholder = '/assignments';
  static const String inspectionWorkflowPlaceholder = '/inspection-workflow';

  static const String schemes = '/schemes';
  static const String pmuMonitoring = '/pmu-monitoring';
  static const String rvcPlaceholder = '/rvc';

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    signup: (context) => const SignupScreen(),
    roleSelection: (context) => const RoleSelectionScreen(),

    officialDashboard: (context) => const OfficialShellScreen(),

    inspectorDashboard: (context) => const InspectorShellScreen(),
    inspectorProfile: (context) => const InspectorProfileScreen(),
    officialProfile: (context) => const OfficialProfileScreen(),

    ngoDashboard: (context) => const NgoShellScreen(),
    ngoProfile: (context) => const NgoProfileScreen(),
    ngoAttendance: (context) => const AttendanceScreen(),
    ngoReports: (context) => const ReportsScreen(),
    ngoCamera: (context) => const CameraScreen(),

    instituteMap: (context) => const InstituteMapScreen(),

    projectsPlaceholder: (context) => const ProjectListScreen(),

    inspectionsPlaceholder: (context) => const ModulePlaceholderScreen(
      title: 'Inspections',
      message: 'Inspections module will be implemented in a later phase.',
    ),

    cctvPlaceholder: (context) => const ModulePlaceholderScreen(
      title: 'CCTV',
      message: 'CCTV module will be implemented in a later phase.',
    ),

    analyticsPlaceholder: (context) => const ModulePlaceholderScreen(
      title: 'Analytics',
      message: 'Analytics module will be implemented in a later phase.',
    ),

    // REAL ASSIGNMENTS SCREEN
    assignmentsPlaceholder: (context) => const AssignmentsScreen(),

    inspectionWorkflowPlaceholder: (context) => const ModulePlaceholderScreen(
      title: 'Inspection Workflow',
      message: 'Inspection Workflow — coming in the next phase.',
    ),

    schemes: (context) => const SchemesScreen(),

    pmuMonitoring: (context) => const PmuMonitoringScreen(),

    rvcPlaceholder: (context) => const ModulePlaceholderScreen(
      title: 'RVC',
      message:
          'Remote Video Conferencing will be implemented in a later phase.',
    ),
  };
}