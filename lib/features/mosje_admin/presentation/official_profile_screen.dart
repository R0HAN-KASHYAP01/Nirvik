import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../services/auth_service.dart';
import '../data/official_service.dart';
import '../../../services/session_service.dart';

class OfficialProfileScreen extends StatefulWidget {
  const OfficialProfileScreen({super.key});

  @override
  State<OfficialProfileScreen> createState() =>
      _OfficialProfileScreenState();
}

class _OfficialProfileScreenState
    extends State<OfficialProfileScreen> {
  bool _loading = true;
  String? _loadError;
  OfficialProfileData? _profile;
  bool _loggingOut = false;

  // ---------------------------------------------------------------------------
  // NIRIKSHA Government Blue Theme
  // ---------------------------------------------------------------------------

  static const Color _background = Color(0xFFF1F7FC);
  static const Color _cardBackground = Color(0xFFFFFFFF);

  static const Color _primary = Color(0xFF084482);
  static const Color _primaryDark = Color(0xFF063A77);
  static const Color _secondary = Color(0xFF0B5AA0);

  static const Color _textPrimary = Color(0xFF173B63);
  static const Color _textSecondary = Color(0xFF5F7285);

  static const Color _border = Color(0xFFDCE8F2);
  static const Color _borderMedium = Color(0xFFC8D9E8);

  static const Color _green = Color(0xFF20A866);
  static const Color _greenDark = Color(0xFF16834D);

  static const Color _saffron = Color(0xFFF2A51A);
  static const Color _saffronDark = Color(0xFFC77B00);

  static const Color _red = Color(0xFFC93636);

  // ---- Gradients ----

  static const LinearGradient _primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0B5AA0),
      Color(0xFF084482),
      Color(0xFF063A77),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient _backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF7FAFD),
      Color(0xFFEAF4FD),
    ],
  );

  static const LinearGradient _cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF7FAFD),
      Color(0xFFEFF7FD),
      Color(0xFFEAF4FD),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient _warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFBF2),
      Color(0xFFFFF0D0),
    ],
  );

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ---------------------------------------------------------------------------
  // Load Profile
  // ---------------------------------------------------------------------------

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final profile =
          await OfficialService.instance.fetchCurrentProfile();

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _loading = false;
        _loadError =
            profile == null ? 'Official profile not found.' : null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadError =
            'Could not load your profile. Please check your connection and try again.';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Log out',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(
            color: _textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: _primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text(
              'Log out',
              style: TextStyle(
                color: _saffronDark,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _logout();
    }
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);

    try {
      await AuthService.instance.logout();
      SessionService.instance.clear();

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;

      setState(() => _loggingOut = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not log out. Please try again.',
          ),
          backgroundColor: _saffronDark,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Main Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleSpacing: 16,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: _primaryGradient,
          ),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: _backgroundGradient,
        ),
        child: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 32,
          ),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: _primary,
            ),
          ),
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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: _warningGradient,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF2D69A),
                  ),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: _saffronDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _loadError ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: _textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _loadProfile,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: const BorderSide(
                    color: _primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _profile!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? 560 : double.infinity,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                28,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
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

  // ---------------------------------------------------------------------------
  // Profile Card
  // ---------------------------------------------------------------------------

  Widget _buildProfileCard(
    OfficialProfileData profile,
  ) {
    final email =
        Supabase.instance.client.auth.currentUser?.email ?? '—';

    return Container(
      decoration: BoxDecoration(
        gradient: _cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _border,
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ---------------------------------------------------------------
          // Profile Header
          // ---------------------------------------------------------------

          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 340;

              final avatar = Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: _primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              _primary.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  if (profile.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              );

              final details = Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildStatusDesignation(profile),
                ],
              );

              if (isSmall) {
                return Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        avatar,
                        const SizedBox(width: 14),
                        Expanded(
                          child: details,
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  avatar,
                  const SizedBox(width: 14),
                  Expanded(
                    child: details,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 18),

          Container(
            height: 1,
            color: _borderMedium.withValues(alpha: 0.7),
          ),

          const SizedBox(height: 12),

          // ---------------------------------------------------------------
          // Profile Information
          // ---------------------------------------------------------------

          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: email,
          ),

          if (profile.phone != null &&
              profile.phone!.trim().isNotEmpty)
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: profile.phone!,
            ),

          _InfoRow(
            icon: Icons.apartment_outlined,
            label: 'Department',
            value: profile.department,
          ),

          if (profile.designation != null &&
              profile.designation!.trim().isNotEmpty)
            _InfoRow(
              icon: Icons.work_outline,
              label: 'Designation',
              value: profile.designation!,
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Status + Designation
  // ---------------------------------------------------------------------------

  Widget _buildStatusDesignation(
    OfficialProfileData profile,
  ) {
    final hasDesignation =
        profile.designation != null &&
            profile.designation!.trim().isNotEmpty;

    if (!hasDesignation) {
      return StatusBadge(
        label: _statusLabel(profile.status),
        color: _statusColor(profile.status),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        StatusBadge(
          label: _statusLabel(profile.status),
          color: _statusColor(profile.status),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 220,
          ),
          child: Text(
            profile.designation!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: _textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Account Card
  // ---------------------------------------------------------------------------

  Widget _buildAccountCard(
    OfficialProfileData profile,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: _cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _border,
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Account',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),

          const SizedBox(height: 12),

          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Joined',
            value: _formatDate(profile.createdAt),
          ),

          _InfoRow(
            icon: profile.isOnline
                ? Icons.circle
                : Icons.circle_outlined,
            label: 'Status',
            value: profile.isOnline
                ? 'Online now'
                : (profile.lastSeen != null
                    ? 'Last seen ${_formatDate(profile.lastSeen!)}'
                    : 'Offline'),
            iconColor:
                profile.isOnline
                    ? _green
                    : _textSecondary,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Logout Button
  // ---------------------------------------------------------------------------

  Widget _buildLogoutButton() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: _warningGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: OutlinedButton.icon(
        onPressed:
            _loggingOut ? null : _confirmLogout,
        icon: _loggingOut
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _saffronDark,
                ),
              )
            : const Icon(
                Icons.logout,
                size: 18,
                color: _saffronDark,
              ),
        label: Text(
          _loggingOut
              ? 'Logging out...'
              : 'Log Out',
          style: const TextStyle(
            color: _saffronDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            double.infinity,
            48,
          ),
          side: const BorderSide(
            color: _saffron,
          ),
          backgroundColor: Colors.transparent,
          disabledForegroundColor: _saffronDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _statusLabel(String status) =>
      switch (status) {
        'approved' => 'Approved',
        'rejected' => 'Rejected',
        _ => 'Pending',
      };

  Color _statusColor(String status) =>
      switch (status) {
        'approved' => _greenDark,
        'rejected' => _red,
        _ => _saffronDark,
      };

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }
}

// =============================================================================
// INFO ROW
// =============================================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: const Color(0xFFDCE8F2),
              ),
            ),
            child: Icon(
              icon,
              size: 17,
              color:
                  iconColor ??
                  const Color(0xFF084482),
            ),
          ),

          const SizedBox(width: 10),

          // Responsive label
          LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: 92,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 8,
                  ),
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5F7285),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 8,
              ),
              child: Text(
                value,
                softWrap: true,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: Color(0xFF173B63),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}