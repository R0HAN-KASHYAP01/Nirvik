import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/routes.dart';
import '../../../utils/scheme_catalog.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../services/inspector_service.dart';

class InspectorProfileScreen extends StatefulWidget {
  const InspectorProfileScreen({super.key});

  @override
  State<InspectorProfileScreen> createState() =>
      _InspectorProfileScreenState();
}

class _InspectorProfileScreenState
    extends State<InspectorProfileScreen> {
  // =========================================
  // SIH / GOVERNMENT OF INDIA — UI COLOR SYSTEM
  // Applied inline throughout this screen.
  // =========================================

  // Primary
  static const Color _primaryNavy = Color(0xFF174A7E);
  static const Color _darkNavy = Color(0xFF123A63);
  static const Color _lightBlue = Color(0xFFEAF2F9);

  // Backgrounds
  static const Color _background = Color(0xFFF7F8FA);
  static const Color _sectionBackground = Color(0xFFF4F8FC);
  static const Color _surface = Color(0xFFFFFFFF);

  // Text
  static const Color _textDark = Color(0xFF202124);
  static const Color _textGrey = Color(0xFF5F6368);

  // Border
  static const Color _border = Color(0xFFD5D9DE);

  // Success
  static const Color _success = Color(0xFF2E7D5B);
  static const Color _successBg = Color(0xFFEAF5EF);

  // Warning
  static const Color _warning = Color(0xFFB7791F);
  static const Color _warningBg = Color(0xFFFFF4DC);

  // Danger
  static const Color _danger = Color(0xFFC0392B);
  static const Color _dangerBg = Color(0xFFFCEBE9);

  // Info
  static const Color _info = Color(0xFF2468A8);
  static const Color _infoBg = Color(0xFFEAF3FB);

  // Gradients
  static const LinearGradient _primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_primaryNavy, _darkNavy],
  );

  static const LinearGradient _primaryGradientHover = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D5690), Color(0xFF143F6C)],
  );

  static const LinearGradient _lightBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_sectionBackground, _lightBlue],
  );

  static const LinearGradient _appBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_background, _sectionBackground, _lightBlue],
  );

  static const LinearGradient _cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_surface, Color(0xFFFBFDFF)],
  );

  bool _loadingProfile = true;
  String? _loadError;
  InspectorProfileData? _profile;
  bool _detectingLocation = false;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loadingProfile = true;
      _loadError = null;
    });

    try {
      final profile =
          await InspectorService.instance.fetchCurrentProfile();

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _loadingProfile = false;
        _loadError =
            profile == null ? 'Inspector profile not found.' : null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingProfile = false;
        _loadError =
            'Could not load your profile. Please check your connection and try again.';
      });
    }
  }

  Future<void> _detectLocation() async {
    if (_detectingLocation) return;

    setState(() => _detectingLocation = true);

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showError(
          'Location services are turned off. Please enable GPS and try again.',
        );
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showError(
          'Location permission denied. Please allow location access to continue.',
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showError(
          'Location permission is permanently denied. Please enable it from your device settings.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (position.latitude.abs() > 90 ||
          position.longitude.abs() > 180) {
        _showError(
          'Received an invalid location. Please try again.',
        );
        return;
      }

      final updatedAt =
          await InspectorService.instance.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _profile = _profile?.copyWithLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          locationUpdatedAt: updatedAt,
        );
      });

      _showSuccess('Location updated successfully.');
    } on TimeoutException {
      _showError(
        'Timed out while getting your location. Please try again.',
      );
    } on LocationServiceDisabledException {
      _showError(
        'Location services are turned off. Please enable GPS and try again.',
      );
    } on PostgrestException {
      _showError(
        'Could not save your location. Please try again.',
      );
    } catch (_) {
      _showError(
        'Something went wrong while detecting your location.',
      );
    } finally {
      if (mounted) {
        setState(() => _detectingLocation = false);
      }
    }
  }

  Future<void> _signOut() async {
    if (_signingOut) return;

    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _surface,
          title: const Text(
            'Sign out?',
            style: TextStyle(color: _textDark),
          ),
          content: const Text(
            'Are you sure you want to sign out of your inspector account?',
            style: TextStyle(color: _textGrey),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: _textGrey,
              ),
              child: const Text('Cancel'),
            ),
            // Primary SIH gradient on the confirming action.
            Container(
              decoration: BoxDecoration(
                gradient: _primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sign Out'),
              ),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true || !mounted) return;

    setState(() => _signingOut = true);

    try {
      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      setState(() => _signingOut = false);

      _showError(
        error.message.isNotEmpty
            ? error.message
            : 'Could not sign out. Please try again.',
      );
    } catch (_) {
      if (!mounted) return;

      setState(() => _signingOut = false);

      _showError(
        'Could not sign out. Please try again.',
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          softWrap: true,
        ),
        backgroundColor: _danger,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          softWrap: true,
        ),
        backgroundColor: _success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        // Primary SIH gradient app bar instead of a flat fill.
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: _primaryGradient,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        // Subtle SIH light-blue gradient behind the whole screen.
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: _appBackgroundGradient,
          ),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingProfile) {
      return const LoadingState(
        message: 'Loading your profile...',
      );
    }

    if (_loadError != null || _profile == null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: _cardGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _border,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 40,
                    color: _danger,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _loadError ?? 'Something went wrong.',
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _textGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _loadProfile,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryNavy,
                      side: const BorderSide(
                        color: _primaryNavy,
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final profile = _profile!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfileCard(profile),
          const SizedBox(height: 16),
          _buildLocationCard(profile),
          const SizedBox(height: 16),
          _buildAccountCard(profile),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
    InspectorProfileData profile,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: _cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Primary SIH gradient avatar badge.
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        gradient: _primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.badge_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.fullName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              StatusBadge(
                                label:
                                    _statusLabel(profile.status),
                                color:
                                    _statusColor(profile.status),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const Divider(
              height: 28,
              color: _border,
            ),

            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: profile.officialEmail,
            ),

            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: profile.mobileNumber,
            ),

            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'Inspector ID',
              value: profile.inspectorId,
            ),

            _InfoRow(
              icon: Icons.apartment_outlined,
              label: 'PMU Unit',
              value: profile.pmuUnitName,
            ),

            _InfoRow(
              icon: Icons.work_outline,
              label: 'Designation',
              value: profile.designation,
            ),

            _InfoRow(
              icon: Icons.account_balance_outlined,
              label: 'Department',
              value: profile.department,
            ),

            _InfoRow(
              icon: Icons.map_outlined,
              label: 'State',
              value: profile.state,
            ),

            _InfoRow(
              icon: Icons.location_city_outlined,
              label: 'District',
              value: profile.district,
            ),

            _InfoRow(
              icon: Icons.explore_outlined,
              label: 'Assigned Region',
              value: profile.assignedRegion,
            ),

            _InfoRow(
              icon: Icons.category_outlined,
              label: 'Category',
              value: categoryLabel(profile.schemeCategory),
            ),

            _InfoRow(
              icon: Icons.assignment_outlined,
              label: 'Scheme',
              value: schemeLabel(profile.schemeCode),
            ),

            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Joined',
              value: _formatDate(profile.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(
    InspectorProfileData profile,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: _cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Location',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),

            const SizedBox(height: 12),

            if (profile.hasLocation) ...[
              // Info-tinted gradient panel for the current coordinates.
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_infoBg, Color(0xFFDDEBF8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFC9DFF0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      icon: Icons.my_location,
                      label: 'Coordinates',
                      value:
                          '${profile.latitude!.toStringAsFixed(5)}, '
                          '${profile.longitude!.toStringAsFixed(5)}',
                      iconColor: _info,
                    ),

                    if (profile.locationUpdatedAt != null)
                      _InfoRow(
                        icon: Icons.update,
                        label: 'Last updated',
                        value:
                            _formatDate(profile.locationUpdatedAt!),
                        iconColor: _info,
                      ),
                  ],
                ),
              ),
            ] else
              const Text(
                'Your current location has not been detected yet.',
                softWrap: true,
                style: TextStyle(
                  fontSize: 13,
                  color: _textGrey,
                ),
              ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              // Primary SIH gradient button (wrapped, since ElevatedButton
              // doesn't accept a gradient background directly).
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _detectingLocation
                      ? null
                      : _primaryGradient,
                  color: _detectingLocation
                      ? _primaryNavy.withValues(alpha: 0.55)
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _detectingLocation
                        ? null
                        : _detectLocation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          _detectingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.gps_fixed,
                                  size: 18,
                                  color: Colors.white,
                                ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _detectingLocation
                                  ? 'Detecting location...'
                                  : 'Detect My Current Location',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(InspectorProfileData profile) {
    final email = profile.officialEmail;

    return Container(
      decoration: BoxDecoration(
        gradient: _cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),

            const SizedBox(height: 12),

            _InfoRow(
              icon: Icons.alternate_email,
              label: 'Signed in as',
              value: email,
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    _signingOut ? null : _signOut,
                icon: _signingOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _danger,
                        ),
                      )
                    : const Icon(
                        Icons.logout,
                        color: _danger,
                      ),
                label: Text(
                  _signingOut
                      ? 'Signing out...'
                      : 'Sign Out',
                  style: const TextStyle(
                    color: _danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _danger,
                  side: const BorderSide(
                    color: _danger,
                  ),
                  backgroundColor: _dangerBg,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
        'approved' => 'Approved',
        'rejected' => 'Rejected',
        _ => 'Pending',
      };

  // Status badge colors mapped onto the SIH success / danger / warning
  // semantic palette.
  Color _statusColor(String status) => switch (status) {
        'approved' => _success,
        'rejected' => _danger,
        _ => _warning,
      };

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }
}

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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: iconColor ?? AppColors.textSecondary,
          ),

          const SizedBox(width: 10),

          SizedBox(
            width: 92,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              value,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}