// lib/features/dashboard/presentation/inspector_home_screen.dart
import 'package:flutter/material.dart';
import '../../../services/session_service.dart';
import '../../../app/routes.dart';
import '../../../core/widgets/dashboard_header.dart';
import '../../../core/widgets/summary_stat_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/mock_dashboard_data.dart';
import 'widgets/assignment_card.dart';
import '../../calls/presentation/widgets/random_call_button.dart';

class InspectorHomeScreen extends StatelessWidget {
  const InspectorHomeScreen({super.key});

  void _logout(BuildContext context) {
    SessionService.instance.clear();
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser;
    final assignments = MockDashboardData.todaysAssignments;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            DashboardHeader(
              greeting: 'Welcome back,',
              userName: user?.name ?? 'PMU Inspector',
              onNotificationTap: () {},
              onLogoutTap: () => _logout(context),
              trailingActions: [
                IconButton(
                  icon: const Icon(Icons.map_outlined),
                  tooltip: 'Institute Map',
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.instituteMap),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Primary action first — this is what the field inspector needs fastest.
            PrimaryButton(
              label: 'Start Assigned Inspection',
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.inspectionWorkflowPlaceholder),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: RandomVideoCallButton(),
            ),

            const SizedBox(height: 24),

            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.78,
              children: [
                SummaryStatCard(
                  icon: Icons.today,
                  label: 'Today',
                  count: '3',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.assignmentsPlaceholder),
                ),
                SummaryStatCard(
                  icon: Icons.error_outline,
                  label: 'Overdue',
                  count: '1',
                  accentColor: Colors.red,
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.assignmentsPlaceholder),
                ),
                SummaryStatCard(
                  icon: Icons.upcoming_outlined,
                  label: 'Upcoming',
                  count: '5',
                  accentColor: Colors.orange,
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.assignmentsPlaceholder),
                ),
                SummaryStatCard(
                  icon: Icons.check_circle_outline,
                  label: 'Done',
                  count: '18',
                  accentColor: Colors.green,
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.assignmentsPlaceholder),
                ),
              ],
            ),

            const SizedBox(height: 26),
            SectionHeader(
              title: "Today's Assignments",
              actionLabel: 'View all',
              onActionTap: () => Navigator.of(context).pushNamed(AppRoutes.assignmentsPlaceholder),
            ),
            const SizedBox(height: 10),

            if (assignments.isEmpty)
              const EmptyState(
                icon: Icons.assignment_outlined,
                title: 'No assignments today',
                message: 'New assignments will appear here once scheduled.',
              )
            else
              Column(
                children: assignments
                    .map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AssignmentCard(assignment: a),
                        ))
                    .toList(),
              ),

            const SizedBox(height: 16),

            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.map_outlined, size: 24, color: Colors.black54),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Nearby assignments on map',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.assignmentsPlaceholder),
                    child: const Text('View'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}