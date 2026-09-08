// FILE: lib/features/dashboard/presentation/inspector_profile_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../services/inspector_service.dart';
import '../../../widgets/map/institute_map.dart';

class InspectorProfileScreen extends StatefulWidget {
  const InspectorProfileScreen({super.key});

  @override
  State<InspectorProfileScreen> createState() => _InspectorProfileScreenState();
}

class _InspectorProfileScreenState extends State<InspectorProfileScreen> {
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
      final profile = await InspectorService.instance.fetchCurrentProfile();

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
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showError(
          'Location services are turned off. Please enable GPS and try again.',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

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
        _showError('Received an invalid location. Please try again.');
        return;
      }

      final updatedAt = await InspectorService.instance.updateLocation(
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
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
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
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
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
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _loadProfile,
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
        final isWide = constraints.maxWidth >= 900;

        final infoColumn = SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileCard(profile),
              const SizedBox(height: 16),
              _buildLocationCard(profile),
              const SizedBox(height: 16),
              _buildAccountCard(),
            ],
          ),
        );

        final mapSection = Padding(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: profile.hasLocation
                ? InstituteMap(
                    inspectorLatitude: profile.latitude,
                    inspectorLongitude: profile.longitude,
                    radiusKm: 100,
                  )
                : const EmptyState(
                    icon: Icons.location_searching,
                    title: 'Location not detected yet',
                    message:
                        'Detect your current location to see nearby institutes on the map.',
                  ),
          ),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: infoColumn,
              ),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: mapSection,
                ),
              ),
            ],
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              infoColumn,
              SizedBox(
                height: 360,
                child: mapSection,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(InspectorProfileData profile) {
    final email =
        Supabase.instance.client.auth.currentUser?.email ?? '—';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  child: Icon(
                    Icons.badge_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StatusBadge(
                        label: _statusLabel(profile.status),
                        color: _statusColor(profile.status),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
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

  Widget _buildLocationCard(InspectorProfileData profile) {
    return Card(
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
              ),
            ),
            const SizedBox(height: 12),
            if (profile.hasLocation) ...[
              _InfoRow(
                icon: Icons.my_location,
                label: 'Coordinates',
                value:
                    '${profile.latitude!.toStringAsFixed(5)}, ${profile.longitude!.toStringAsFixed(5)}',
              ),
              if (profile.locationUpdatedAt != null)
                _InfoRow(
                  icon: Icons.update,
                  label: 'Last updated',
                  value: _formatDate(profile.locationUpdatedAt!),
                ),
            ] else
              const Text(
                'Your current location has not been detected yet.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed:
                  _detectingLocation ? null : _detectLocation,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard() {
    final email =
        Supabase.instance.client.auth.currentUser?.email ?? '—';

    return Card(
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
                onPressed: _signingOut ? null : _signOut,
                icon: _signingOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.logout),
                label: Text(
                  _signingOut
                      ? 'Signing out...'
                      : 'Sign Out',
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
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
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