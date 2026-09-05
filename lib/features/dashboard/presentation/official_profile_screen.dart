// FILE: lib/features/dashboard/presentation/official_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../services/auth_service.dart';
import '../../../services/official_service.dart';
import '../../../services/session_service.dart';

class OfficialProfileScreen extends StatefulWidget {
  const OfficialProfileScreen({super.key});

  @override
  State<OfficialProfileScreen> createState() => _OfficialProfileScreenState();
}

class _OfficialProfileScreenState extends State<OfficialProfileScreen> {
  bool _loading = true;
  String? _loadError;
  OfficialProfileData? _profile;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final profile = await OfficialService.instance.fetchCurrentProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
        _loadError = profile == null ? 'Official profile not found.' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Could not load your profile. Please check your connection and try again.';
      });
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) _logout();
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      await AuthService.instance.logout();
      SessionService.instance.clear();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not log out. Please try again.'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
        ),
      );
    }

    if (_loadError != null || _profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                _loadError ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _loadProfile, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final profile = _profile!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final maxContentWidth = isWide ? 560.0 : double.infinity;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileCard(profile),
                  const SizedBox(height: 16),
                  _buildAccountCard(profile),
                  const SizedBox(height: 16),
                  _buildLogoutButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(OfficialProfileData profile) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '—';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.account_balance_outlined, color: Colors.white, size: 28),
                    ),
                    if (profile.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.fullName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          StatusBadge(label: _statusLabel(profile.status), color: _statusColor(profile.status)),
                          const SizedBox(width: 8),
                          if (profile.designation != null && profile.designation!.trim().isNotEmpty)
                            Text(
                              profile.designation!,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            _InfoRow(icon: Icons.email_outlined, label: 'Email', value: email),
            if (profile.phone != null && profile.phone!.trim().isNotEmpty)
              _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: profile.phone!),
            _InfoRow(icon: Icons.apartment_outlined, label: 'Department', value: profile.department),
            if (profile.designation != null && profile.designation!.trim().isNotEmpty)
              _InfoRow(icon: Icons.work_outline, label: 'Designation', value: profile.designation!),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(OfficialProfileData profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.calendar_today_outlined, label: 'Joined', value: _formatDate(profile.createdAt)),
            _InfoRow(
              icon: profile.isOnline ? Icons.circle : Icons.circle_outlined,
              label: 'Status',
              value: profile.isOnline
                  ? 'Online now'
                  : (profile.lastSeen != null ? 'Last seen ${_formatDate(profile.lastSeen!)}' : 'Offline'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return OutlinedButton.icon(
      onPressed: _loggingOut ? null : _confirmLogout,
      icon: _loggingOut
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
            )
          : const Icon(Icons.logout, size: 18, color: AppColors.error),
      label: Text(
        _loggingOut ? 'Logging out...' : 'Log Out',
        style: const TextStyle(color: AppColors.error),
      ),
      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
    );
  }

  String _statusLabel(String status) => switch (status) {
        'approved' => 'Approved',
        'rejected' => 'Rejected',
        _ => 'Pending',
      };

  Color _statusColor(String status) => switch (status) {
        'approved' => AppColors.success,
        'rejected' => AppColors.error,
        _ => AppColors.warning,
      };

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}