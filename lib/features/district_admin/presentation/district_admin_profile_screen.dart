// lib/features/district_admin/presentation/district_admin_profile_screen.dart
//
// District Administrator PROFILE tab — real data from
// public.district_administrators (the admin's own row, readable under the
// existing district_admins_select_own RLS policy). Replaces
// ProfilePlaceholderScreen, which showed hard-coded demo values.
//
//   * Official details / jurisdiction / contact / account dates
//   * Notifications   -> the existing notifications screen (per user)
//   * Change password -> Supabase auth (signed-in user)
//   * Log out         -> lives here now; always available, even if the
//                        profile details fail to load

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/session_service.dart';
import '../../ngo/presentation/ngo_notifications_screen.dart';
import 'district_admin_theme.dart';

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String? _text(dynamic value) {
  final s = value?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

String? _date(dynamic value) {
  final d = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (d == null) return null;
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

class DistrictAdminProfileScreen extends StatefulWidget {
  const DistrictAdminProfileScreen({super.key});

  @override
  State<DistrictAdminProfileScreen> createState() =>
      _DistrictAdminProfileScreenState();
}

class _DistrictAdminProfileScreenState
    extends State<DistrictAdminProfileScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final user = SessionService.instance.currentUser;
    if (user == null) {
      throw Exception('Your session was not found. Please log in again.');
    }

    final row = await Supabase.instance.client
        .from('district_administrators')
        .select('profile_id, full_name, official_email, mobile_number, '
            'employee_id, designation, department, division_section, '
            'office_name, state, district, block_subdivision, office_address, '
            'reviewed_at, created_at')
        .eq('profile_id', user.id)
        .maybeSingle();

    if (row == null) {
      throw Exception('Your district administrator record was not found.');
    }
    return row;
  }

  void _reload() => setState(() => _future = _load());

  String _friendly(Object e) => e.toString().replaceFirst('Exception: ', '');

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NgoNotificationsScreen()),
    );
  }

  Future<void> _openChangePassword() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: DistrictColors.card,
      builder: (_) => const _ChangePasswordSheet(),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated.')),
      );
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Log out',
              style: TextStyle(color: DistrictColors.dangerDark),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await AuthService.instance.logout();
    SessionService.instance.clear();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser;

    return Scaffold(
      backgroundColor: DistrictColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState != ConnectionState.done;
          final error = snapshot.hasError ? snapshot.error : null;
          final row = snapshot.data;

          final name = _text(row?['full_name']) ?? user?.name ?? 'District Admin';
          final designation =
              _text(row?['designation']) ?? _text(user?.designation);
          final employeeId = _text(row?['employee_id']);
          final status = (user?.status ?? '').toLowerCase();

          return RefreshIndicator(
            color: DistrictColors.primary,
            onRefresh: () async {
              final next = _load();
              setState(() => _future = next);
              try {
                await next;
              } catch (_) {
                // The error is shown in the page itself.
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              children: [
                _HeaderCard(
                  name: name,
                  designation: designation,
                  employeeId: employeeId,
                  status: status,
                ),
                const SizedBox(height: 12),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (error != null)
                  _ErrorCard(message: _friendly(error), onRetry: _reload),
                if (row != null) ...[
                  _SectionCard(
                    title: 'Official details',
                    rows: [
                      ('Employee ID', _text(row['employee_id'])),
                      ('Designation', _text(row['designation'])),
                      ('Department', _text(row['department'])),
                      ('Division / Section', _text(row['division_section'])),
                      ('Office', _text(row['office_name'])),
                    ],
                  ),
                  _SectionCard(
                    title: 'Jurisdiction',
                    rows: [
                      ('State', _text(row['state'])),
                      ('District', _text(row['district'])),
                      ('Block / Subdivision', _text(row['block_subdivision'])),
                      ('Office address', _text(row['office_address'])),
                    ],
                  ),
                  _SectionCard(
                    title: 'Contact',
                    rows: [
                      ('Official email', _text(row['official_email'])),
                      ('Mobile number', _text(row['mobile_number'])),
                    ],
                  ),
                  _SectionCard(
                    title: 'Account',
                    rows: [
                      ('Registered on', _date(row['created_at'])),
                      ('Approved on', _date(row['reviewed_at'])),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                _ActionTile(
                  icon: Icons.notifications_none,
                  label: 'Notifications',
                  onTap: _openNotifications,
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.lock_outline,
                  label: 'Change Password',
                  onTap: _openChangePassword,
                ),
                const SizedBox(height: 16),
                _LogoutButton(onTap: _confirmLogout),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String name;
  final String? designation;
  final String? employeeId;
  final String status;

  const _HeaderCard({
    required this.name,
    required this.designation,
    required this.employeeId,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final approved = status == 'approved';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: DistrictColors.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: DistrictColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: DistrictColors.textPrimary,
                  ),
                ),
                if (designation != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    designation!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: DistrictColors.textSecondary,
                    ),
                  ),
                ],
                if (employeeId != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Employee ID: $employeeId',
                    style: const TextStyle(
                      fontSize: 12,
                      color: DistrictColors.textSecondary,
                    ),
                  ),
                ],
                if (status.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: approved
                          ? DistrictColors.successLight
                          : DistrictColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: approved
                            ? DistrictColors.successDark
                            : DistrictColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<(String, String?)> rows;

  const _SectionCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final visible = rows.where((r) => r.$2 != null).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: DistrictColors.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: DistrictColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            for (final r in visible)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 125,
                      child: Text(
                        r.$1,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: DistrictColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r.$2!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: DistrictColors.textPrimary,
                        ),
                      ),
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

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF7F7), Color(0xFFFDE5E5)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF2BDBD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline,
              size: 18, color: DistrictColors.dangerDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Could not load your profile details.\n$message',
              style: const TextStyle(
                fontSize: 12,
                color: DistrictColors.dangerDark,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: DistrictColors.cardDecoration(),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            child: Row(
              children: [
                Icon(icon, size: 20, color: DistrictColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: DistrictColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: DistrictColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF7F7), Color(0xFFFDE5E5)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF2BDBD)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            child: Row(
              children: [
                Icon(Icons.logout, size: 20, color: DistrictColors.dangerDark),
                SizedBox(width: 12),
                Text(
                  'Log out',
                  style: TextStyle(
                    fontSize: 14,
                    color: DistrictColors.dangerDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  static const int _minLength = 8;

  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final password = _password.text;

    if (password.length < _minLength) {
      setState(() => _error = 'Use at least $_minLength characters.');
      return;
    }
    if (password != _confirm.text) {
      setState(() => _error = 'The two passwords do not match.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth
          .updateUser(UserAttributes(password: password));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not update the password. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Change password',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: DistrictColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _password,
            obscureText: true,
            enabled: !_saving,
            decoration: const InputDecoration(
              labelText: 'New password',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirm,
            obscureText: true,
            enabled: !_saving,
            decoration: const InputDecoration(
              labelText: 'Confirm new password',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 12.5,
                color: DistrictColors.dangerDark,
              ),
            ),
          ],
          const SizedBox(height: 16),
          DistrictGradientButton(
            label: 'Update password',
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}