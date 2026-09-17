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
  static const Color _navy = Color(0xFF123E68);
  static const Color _background = Color(0xFFEAF2F8);
  static const Color _cardBackground = Color(0xFFE1ECF3);
  static const Color _softBlue = Color(0xFFD7E5EE);
  static const Color _textDark = Color(0xFF17324D);
  static const Color _textGrey = Color(0xFF667788);
  static const Color _border = Color(0xFFD1DEE7);

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
          title: const Text('Sign out?'),
          content: const Text(
            'Are you sure you want to sign out of your inspector account?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(true),
              child: const Text('Sign Out'),
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
        backgroundColor: AppColors.error,
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
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _navy,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
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
          child: Card(
            color: _cardBackground,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(
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
                    color: AppColors.error,
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
                      foregroundColor: _navy,
                      side: const BorderSide(
                        color: _navy,
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
    return Card(
      color: _cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
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
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: _navy,
                      child: Icon(
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
    return Card(
      color: _cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
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
              _InfoRow(
                icon: Icons.my_location,
                label: 'Coordinates',
                value:
                    '${profile.latitude!.toStringAsFixed(5)}, '
                    '${profile.longitude!.toStringAsFixed(5)}',
              ),

              if (profile.locationUpdatedAt != null)
                _InfoRow(
                  icon: Icons.update,
                  label: 'Last updated',
                  value:
                      _formatDate(profile.locationUpdatedAt!),
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
              child: ElevatedButton.icon(
                onPressed: _detectingLocation
                    ? null
                    : _detectLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      _navy.withValues(alpha: 0.55),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: _detectingLocation
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
                      ),
                label: Text(
                  _detectingLocation
                      ? 'Detecting location...'
                      : 'Detect My Current Location',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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

    return Card(
      color: _cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
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
                          color: AppColors.error,
                        ),
                      )
                    : const Icon(
                        Icons.logout,
                        color: AppColors.error,
                      ),
                label: Text(
                  _signingOut
                      ? 'Signing out...'
                      : 'Sign Out',
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(
                    color: AppColors.error,
                  ),
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

  Color _statusColor(String status) => switch (status) {
        'approved' => AppColors.success,
        'rejected' => AppColors.error,
        _ => AppColors.warning,
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

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
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
            color: AppColors.textSecondary,
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