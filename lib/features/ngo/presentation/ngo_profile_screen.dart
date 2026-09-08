import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../models/ngo_institute_profile.dart';
import '../../../services/ngo_institute_service.dart';
import '../../../services/session_service.dart';
import '../../../services/auth_service.dart';
import '../../../app/routes.dart';

class NgoProfileScreen extends StatefulWidget {
  const NgoProfileScreen({super.key});

  @override
  State<NgoProfileScreen> createState() => _NgoProfileScreenState();
}

class _NgoProfileScreenState extends State<NgoProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _registrationController = TextEditingController();
  final _addressController = TextEditingController();

  NgoSchemeType? _selectedScheme;

  double? _latitude;
  double? _longitude;

  bool _loadingProfile = true;
  bool _saving = false;
  bool _detectingLocation = false;

  String? _locationError;

  static const Color primaryBlue = Color(0xFF0B4A7F);
  static const Color darkBlue = Color(0xFF083B66);
  static const Color lightBlue = Color(0xFFEAF3FA);
  static const Color background = Color(0xFFF4F8FB);
  static const Color textDark = Color(0xFF243447);
  static const Color textGrey = Color(0xFF687684);
  static const Color borderColor = Color(0xFFD9E2EA);
  static const Color green = Color(0xFF2AA876);
  static const Color greenLight = Color(0xFFE4F6EE);

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _registrationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfile() async {
    final user = SessionService.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
      return;
    }

    try {
      final profile =
          await NgoInstituteService.instance.fetchProfile(user.id);

      if (!mounted) return;

      if (profile != null) {
        _registrationController.text =
            profile.registrationNumber ?? '';

        _addressController.text =
            profile.address ?? '';

        setState(() {
          _selectedScheme = profile.schemeType;
          _latitude = profile.latitude;
          _longitude = profile.longitude;
        });
      }
    } catch (_) {
      // First-time institute ke liye profile na hona normal hai.
    } finally {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
    }
  }

  Future<void> _detectLocation() async {
    setState(() {
      _detectingLocation = true;
      _locationError = null;
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Location services are turned off on this device.',
        );
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission permanently denied. '
          'Enable it from app settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      // Reverse geocoding — Geocoding() is constructed lazily, right here,
      // instead of as an eager field. The geocoding package has no
      // registered platform implementation on web, so constructing it
      // eagerly (as a field initializer) threw "Unexpected null value"
      // the instant this screen's State was created — even just from
      // sitting inactive in the shell's IndexedStack. Building it here
      // keeps that failure contained to this already-existing try/catch,
      // exactly like the comment below always intended.
      try {
        final placemarks = await Geocoding().placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty && mounted) {
          final p = placemarks.first;

          final parts = [
            p.street,
            p.subLocality,
            p.locality,
            p.administrativeArea,
            p.postalCode,
            p.country,
          ]
              .where(
                (e) => e != null && e.trim().isNotEmpty,
              )
              .join(', ');

          if (parts.isNotEmpty) {
            _addressController.text = parts;
          }
        }
      } catch (_) {
        // Coordinates mil gaye to address fail hone par bhi okay.
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _locationError =
            e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _detectingLocation = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedScheme == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a scheme.'),
        ),
      );
      return;
    }

    final user = SessionService.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User session not found.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final profile = NgoInstituteProfile(
        profileId: user.id,
        registrationNumber:
            _registrationController.text.trim().isEmpty
                ? null
                : _registrationController.text.trim(),
        schemeType: _selectedScheme,
        address:
            _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );

      await NgoInstituteService.instance.upsertProfile(profile);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save profile: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _handleLogout() async {
    try {
      await AuthService.instance.logout();
    } catch (_) {
      // Supabase logout fail hone par bhi
      // local session clear karke login page par jayenge.
    }

    SessionService.instance.clear();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  // ============================================================
  // BACK TO HOME
  // ============================================================

  void _goBackToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.ngoDashboard,
      (route) => false,
    );
  }

  String _instituteName() {
    if (_selectedScheme != null) {
      return _selectedScheme!.label;
    }

    return 'NGO / Institute';
  }

  String _registrationText() {
    final value = _registrationController.text.trim();

    if (value.isEmpty) {
      return 'Not provided';
    }

    return value;
  }

  String _coordinatesText() {
    if (_latitude == null || _longitude == null) {
      return 'Location not detected';
    }

    return 'Lat: ${_latitude!.toStringAsFixed(6)}, '
        'Lng: ${_longitude!.toStringAsFixed(6)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // IMPORTANT:
      // Profile page ka apna bottom navigation nahi hai.
      // Sirf top AppBar rahega.
      appBar: AppBar(
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        // TOP LEFT BACK BUTTON
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 19,
          ),
          onPressed: _goBackToHome,
        ),

        title: const Text(
          'Institute Profile',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: _loadingProfile
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryBlue,
              ),
            )
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    32,
                  ),
                  children: [
                    _buildInstituteCard(),

                    const SizedBox(height: 22),

                    _buildSectionTitle(
                      'Institute Details',
                      'Manage your registered institute information',
                    ),

                    const SizedBox(height: 12),

                    _buildRegistrationField(),

                    const SizedBox(height: 18),

                    _buildSectionTitle(
                      'Address',
                      'Registered office / operating location',
                    ),

                    const SizedBox(height: 10),

                    _buildAddressField(),

                    const SizedBox(height: 10),

                    _buildLocationButton(),

                    if (_locationError != null) ...[
                      const SizedBox(height: 10),
                      _buildLocationError(),
                    ],

                    const SizedBox(height: 8),

                    _buildCoordinatesCard(),

                    const SizedBox(height: 22),

                    _buildSectionTitle(
                      'Scheme',
                      'Select the scheme applicable to your institute',
                    ),

                    const SizedBox(height: 10),

                    _buildSchemeDropdown(),

                    const SizedBox(height: 26),

                    _buildSaveButton(),

                    const SizedBox(height: 12),

                    _buildLogoutButton(),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11.5,
            color: textGrey,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INSTITUTE CARD
  // ============================================================

  Widget _buildInstituteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B4A7F),
            Color(0xFF083B66),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.20),
              ),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              size: 30,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _instituteName(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: greenLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 12,
                            color: green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                const Text(
                  'Registered Institute',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      size: 14,
                      color: Colors.white70,
                    ),

                    const SizedBox(width: 5),

                    const Text(
                      'Registration:',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(width: 5),

                    Expanded(
                      child: Text(
                        _registrationText(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REGISTRATION FIELD
  // ============================================================

  Widget _buildRegistrationField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: TextFormField(
        controller: _registrationController,
        style: const TextStyle(
          fontSize: 13,
          color: textDark,
          fontWeight: FontWeight.w500,
        ),
        decoration: const InputDecoration(
          prefixIcon: Icon(
            Icons.badge_outlined,
            color: primaryBlue,
            size: 21,
          ),
          hintText: 'Enter registration number',
          hintStyle: TextStyle(
            fontSize: 12,
            color: textGrey,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter registration number';
          }

          return null;
        },
      ),
    );
  }

  // ============================================================
  // ADDRESS FIELD
  // ============================================================

  Widget _buildAddressField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: TextFormField(
        controller: _addressController,
        maxLines: 3,
        minLines: 2,
        style: const TextStyle(
          fontSize: 13,
          color: textDark,
          fontWeight: FontWeight.w500,
        ),
        decoration: const InputDecoration(
          prefixIcon: Padding(
            padding: EdgeInsets.only(bottom: 35),
            child: Icon(
              Icons.location_on_outlined,
              color: primaryBlue,
              size: 21,
            ),
          ),
          hintText: 'Registered office / operating address',
          hintStyle: TextStyle(
            fontSize: 12,
            color: textGrey,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOCATION BUTTON
  // ============================================================

  Widget _buildLocationButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed:
            _detectingLocation ? null : _detectLocation,
        style: OutlinedButton.styleFrom(
          backgroundColor: lightBlue,
          foregroundColor: primaryBlue,
          side: const BorderSide(
            color: Color(0xFFC7DCEA),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: _detectingLocation
            ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primaryBlue,
                ),
              )
            : const Icon(
                Icons.my_location_rounded,
                size: 19,
              ),
        label: Text(
          _detectingLocation
              ? 'Detecting location...'
              : 'Detect My Location',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOCATION ERROR
  // ============================================================

  Widget _buildLocationError() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: Colors.red.shade100,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: Colors.red.shade700,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              _locationError!,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COORDINATES CARD
  // ============================================================

  Widget _buildCoordinatesCard() {
    final hasLocation =
        _latitude != null && _longitude != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasLocation
            ? greenLight
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasLocation
              ? const Color(0xFFBFE8D4)
              : borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: hasLocation
                  ? Colors.white
                  : lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasLocation
                  ? Icons.location_on_rounded
                  : Icons.location_off_outlined,
              size: 18,
              color: hasLocation
                  ? green
                  : primaryBlue,
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  hasLocation
                      ? 'Location Coordinates'
                      : 'Location',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  _coordinatesText(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          if (hasLocation)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                'Updated',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: green,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SCHEME DROPDOWN
  // ============================================================

  Widget _buildSchemeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: DropdownButtonFormField<NgoSchemeType>(
        initialValue: _selectedScheme,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: primaryBlue,
        ),
        decoration: const InputDecoration(
          prefixIcon: Icon(
            Icons.account_balance_outlined,
            color: primaryBlue,
            size: 20,
          ),
          hintText: 'Select Scheme',
          hintStyle: TextStyle(
            fontSize: 12,
            color: textGrey,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 4,
          ),
        ),
        items: NgoSchemeType.values.map(
          (scheme) {
            return DropdownMenuItem<NgoSchemeType>(
              value: scheme,
              child: Text(
                scheme.label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
              ),
            );
          },
        ).toList(),
        onChanged: (value) {
          setState(() {
            _selectedScheme = value;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Please select a scheme';
          }

          return null;
        },
      ),
    );
  }

  // ============================================================
  // SAVE PROFILE BUTTON
  // ============================================================

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              primaryBlue.withValues(alpha: 0.60),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.save_rounded,
                    size: 19,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Save Profile',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ============================================================
  // LOGOUT BUTTON
  // ============================================================

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: _handleLogout,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFD64545),
          side: const BorderSide(
            color: Color(0xFFE3B8B8),
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        icon: const Icon(
          Icons.logout_rounded,
          size: 19,
        ),
        label: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}