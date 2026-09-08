import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/summary_stat_card.dart';
import '../../../services/session_service.dart';
import '../../../services/ngo_reports_service.dart';
import '../../../services/ngo_camera_service.dart';
import '../../../app/routes.dart';
import '../../calls/presentation/call_history_screen.dart';

class NgoDashboardScreen extends StatefulWidget {
  const NgoDashboardScreen({super.key});

  @override
  State<NgoDashboardScreen> createState() => _NgoDashboardScreenState();
}

class _NgoDashboardScreenState extends State<NgoDashboardScreen> {
  int? _reportsCount;
  int? _feedsCount;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = SessionService.instance.currentUser;
    if (user == null) return;

    try {
      final reports = await NgoReportsService.instance.fetchReports(user.id);
      final feeds = await NgoCameraService.instance.fetchFeeds(user.id);
      if (!mounted) return;
      setState(() {
        _reportsCount = reports.length;
        _feedsCount = feeds.length;
        _loadingStats = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingStats = false);
    }
  }

  String get _todayLabel {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser;
    final firstName = (user?.name ?? 'there').split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _GreetingHeader(name: firstName, role: 'Field Inspector'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _InfoBanner(),
                  const SizedBox(height: 24),

                  _SectionTitle(title: "Today's Status", subtitle: _todayLabel, actionLabel: 'View all', onAction: () {}),
                  const SizedBox(height: 12),
                  _loadingStats
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
                  )
                      : Row(
                    children: [
                      Expanded(
                        child: _StatusTile(
                          icon: Icons.groups_outlined,
                          color: AppColors.success,
                          label: 'Attendance',
                          status: 'Submitted',
                          statusIcon: Icons.check_circle,
                          onTap: () => Navigator.of(context).pushNamed(AppRoutes.ngoAttendance),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatusTile(
                          icon: Icons.description_outlined,
                          color: AppColors.info,
                          label: 'Reports',
                          status: '${_reportsCount ?? 0} Submitted',
                          statusIcon: Icons.check_circle,
                          onTap: () => Navigator.of(context).pushNamed(AppRoutes.ngoReports),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatusTile(
                          icon: Icons.videocam_outlined,
                          color: AppColors.warning,
                          label: 'Camera Feeds',
                          status: '${_feedsCount ?? 0} Online',
                          statusIcon: Icons.circle,
                          onTap: () => Navigator.of(context).pushNamed(AppRoutes.ngoCamera),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),
                  const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.7,
                    children: [
                      _QuickActionTile(
                        icon: Icons.groups_outlined,
                        label: 'Daily Attendance',
                        color: AppColors.primary,
                        onTap: () => Navigator.of(context).pushNamed(AppRoutes.ngoAttendance),
                      ),
                      _QuickActionTile(
                        icon: Icons.description_outlined,
                        label: 'Reports',
                        color: AppColors.primary,
                        onTap: () => Navigator.of(context).pushNamed(AppRoutes.ngoReports),
                      ),
                      _QuickActionTile(
                        icon: Icons.videocam_outlined,
                        label: 'Camera / Video',
                        color: AppColors.primary,
                        onTap: () => Navigator.of(context).pushNamed(AppRoutes.ngoCamera),
                      ),
                      _QuickActionTile(
                        icon: Icons.apartment_outlined,
                        label: 'Institute Profile',
                        color: AppColors.primary,
                        onTap: () => Navigator.of(context).pushNamed(AppRoutes.ngoProfile),
                      ),
                      _QuickActionTile(
                        icon: Icons.history,
                        label: 'Call History',
                        color: AppColors.primary,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CallHistoryScreen()),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),
                  const Text("Today's Overview", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: SummaryStatCard(
                          icon: Icons.groups,
                          label: 'Beneficiaries present',
                          count: '45',
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: SummaryStatCard(
                          icon: Icons.badge_outlined,
                          label: 'Staff present',
                          count: '10',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SummaryStatCard(
                          icon: Icons.description_outlined,
                          label: 'Reports submitted',
                          count: '${_reportsCount ?? 0}',
                        ),
                      ),
                    ],
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

/// Dark navy header with rounded bottom, matching the mock's greeting card.
class _GreetingHeader extends StatelessWidget {
  final String name;
  final String role;
  const _GreetingHeader({required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Good morning,', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                  Text(role, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none, color: Colors.white, size: 26),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Announcement banner with a tricolor accent stripe.
class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Let's build a stronger,\nmore inclusive society",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text('Government', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    Text('for a Brighter', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    Text('Tomorrow', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF9933), Colors.white, Color(0xFF138808)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionTitle({required this.title, this.subtitle, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(subtitle!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  final IconData icon;
  final IconData statusIcon;
  final Color color;
  final String label;
  final String status;
  final VoidCallback onTap;

  const _StatusTile({
    required this.icon,
    required this.statusIcon,
    required this.color,
    required this.label,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            CircleAvatar(radius: 18, backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color, size: 18)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 12, color: color),
                const SizedBox(width: 3),
                Text(status, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}