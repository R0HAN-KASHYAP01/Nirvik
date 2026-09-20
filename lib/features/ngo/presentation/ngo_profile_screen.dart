import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../models/ngo_institute_profile.dart';
import '../../../services/ngo_institute_service.dart';
import '../../../services/session_service.dart';
import '../../../services/auth_service.dart';
import '../../../app/routes.dart';
import '../../../utils/scheme_catalog.dart';

class NgoProfileScreen extends StatefulWidget {
  const NgoProfileScreen({super.key});

  @override
  State<NgoProfileScreen> createState() => _NgoProfileScreenState();
}

class _NgoProfileScreenState extends State<NgoProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _registrationController = TextEditingController();
  final _addressController = TextEditingController();

  String? _schemeCategory;
  String? _schemeCode;
  String? _organizationName;

  double? _latitude;
  double? _longitude;

  bool _loadingProfile = true;
  bool _saving = false;
  bool _detectingLocation = false;

  String? _locationError;

  static const Color primaryBlue = Color(0xFF174A7E); // Primary Navy Blue
  static const Color darkBlue = Color(0xFF123A63); // Dark Navy
  static const Color lightBlue = Color(0xFFEAF2F9); // Light Blue
  static const Color background = Color(0xFFF7F8FA);
  static const Color textDark = Color(0xFF202124); // Primary Text
  static const Color textGrey = Color(0xFF5F6368); // Secondary Text
  static const Color borderColor = Color(0xFFD5D9DE);
  static const Color green = Color(0xFF2E7D5B); // Success
  static const Color greenLight = Color(0xFFEAF5EF); // Success Background
  static const Color red = Color(0xFFC0392B); // Danger
  static const Color redLight = Color(0xFFFCEBE9); // Danger Background
  static const Color redBorder = Color(0xFFF3C6C2);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, darkBlue],
  );

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

      final scheme = await NgoInstituteService.instance
          .fetchRegisteredScheme(user.id);

      final orgName = await NgoInstituteService.instance
          .fetchOrganizationName(user.id);

      if (!mounted) return;

      if (profile != null) {
        _registrationController.text =
            profile.registrationNumber ?? '';

        _addressController.text =
            profile.address ?? '';

        setState(() {
          _latitude = profile.latitude;
          _longitude = profile.longitude;
        });
      }

      setState(() {
        _schemeCategory = scheme?['scheme_category'];
        _schemeCode = scheme?['scheme_code'];
        _organizationName = orgName;
      });
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

debugPrint('========== LOCATION DETECTED ==========');
debugPrint('Latitude: $_latitude');
debugPrint('Longitude: $_longitude');
debugPrint('========================================');
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

  final user = SessionService.instance.currentUser;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User session not found.'),
      ),
    );
    return;
  }

  // Make sure we know exactly what Flutter is about to send.
  debugPrint('========== NGO PROFILE SAVE ==========');
  debugPrint('Profile ID: ${user.id}');
  debugPrint('Registration: ${_registrationController.text.trim()}');
  debugPrint('Address: ${_addressController.text.trim()}');
  debugPrint('Latitude: $_latitude');
  debugPrint('Longitude: $_longitude');
  debugPrint('======================================');

  setState(() => _saving = true);

  try {
    final profile = NgoInstituteProfile(
      profileId: user.id,
      registrationNumber:
          _registrationController.text.trim().isEmpty
              ? null
              : _registrationController.text.trim(),
      address:
          _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
    );

    final savedProfile =
        await NgoInstituteService.instance.upsertProfile(profile);

    debugPrint('========== NGO PROFILE SAVED ==========');
    debugPrint('Saved Profile ID: ${savedProfile.profileId}');
    debugPrint('Saved Latitude: ${savedProfile.latitude}');
    debugPrint('Saved Longitude: ${savedProfile.longitude}');
    debugPrint('=======================================');

    if (!mounted) return;

    // Keep the UI state synchronized with what Supabase returned.
    setState(() {
      _latitude = savedProfile.latitude;
      _longitude = savedProfile.longitude;
      _registrationController.text =
          savedProfile.registrationNumber ?? '';
      _addressController.text =
          savedProfile.address ?? '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Profile saved successfully.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('========== NGO PROFILE SAVE ERROR ==========');
    debugPrint('$e');
    debugPrint('$stackTrace');
    debugPrint('============================================');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Could not save profile: $e',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
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
    if (_organizationName != null && _organizationName!.trim().isNotEmpty) {
      return _organizationName!;
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
        backgroundColor: Colors.transparent,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: primaryGradient),
        ),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
                'Category and scheme this institute is registered under',
              ),

              const SizedBox(height: 10),

              _buildSchemeDisplay(),

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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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
        gradient: primaryGradient,
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      size: 14,
                      color: Colors.white70,
                    ),

                    const SizedBox(width: 5),

                    const Text(
                      'Registration:',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(width: 5),

                    Expanded(
                      child: Text(
                        _registrationText(),
                        maxLines: 1,
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
  //
  // NOTE: the prefix icon uses a fixed `Padding(bottom: 35)` to sit
  // near the top of the multi-line field. That's a cosmetic
  // alignment offset (not an overflow risk, since the field itself
  // has no fixed height — minLines/maxLines let it grow), but it
  // will drift out of alignment if the field grows taller under a
  // large system font scale. A more robust version pins the icon to
  // the top instead of guessing a pixel offset.
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
          prefixIcon: Align(
            alignment: Alignment.topCenter,
            heightFactor: 1,
            child: Padding(
              padding: EdgeInsets.only(top: 14),
              child: Icon(
                Icons.location_on_outlined,
                color: primaryBlue,
                size: 21,
              ),
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
  //
  // Was `SizedBox(height: 44)` around a button whose label text
  // ("Detecting location..." / "Detect My Location") can need more
  // vertical space at larger system font scales. A tight SizedBox
  // forces exactly 44px regardless of that content, so on a device
  // with a bigger font scale the button's internal Row could exceed
  // 44px and throw a RenderFlex overflow. Swapped to a minHeight
  // constraint so the button can grow if it truly needs to, and
  // capped the label to one line with ellipsis so it never tries to
  // wrap in the first place.
  // ============================================================

  Widget _buildLocationButton() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed:
          _detectingLocation ? null : _detectLocation,
          style: OutlinedButton.styleFrom(
            backgroundColor: lightBlue,
            foregroundColor: primaryBlue,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            side: const BorderSide(
              color: Color(0xFFC9DCEC),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
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
        color: redLight,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: redBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: red,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              _locationError!,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                color: red,
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
              ? const Color(0xFFBFE0CE)
              : borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  hasLocation
                      ? 'Location Coordinates'
                      : 'Location',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  _coordinatesText(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          if (hasLocation) ...[
            const SizedBox(width: 8),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: green,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // SCHEME DROPDOWN
  // ============================================================

  Widget _buildSchemeDisplay() {
    final hasScheme = _schemeCode != null && _schemeCode!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.account_balance_outlined,
            color: primaryBlue,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasScheme ? categoryLabel(_schemeCategory) : 'Not set',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasScheme ? schemeLabel(_schemeCode) : 'No scheme on record',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Set at registration and approved by admin — not editable here.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SAVE PROFILE BUTTON
  //
  // Same fixed-height risk as the location button: `SizedBox(height:
  // 50)` was forcing an exact height around a Row(icon, text) whose
  // text can need more vertical room at larger font scales. Swapped
  // to a minHeight constraint, and the label is now wrapped in
  // Flexible + capped to one line so it shrinks/ellipsizes instead
  // of forcing the Row wider or taller than the button allows.
  // ============================================================

  Widget _buildSaveButton() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 50),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _saving ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
            primaryBlue.withValues(alpha: 0.60),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
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
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Icon(
                Icons.save_rounded,
                size: 19,
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Save Profile',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGOUT BUTTON
  // ============================================================

  Widget _buildLogoutButton() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 46),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _handleLogout,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: red,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            side: const BorderSide(
              color: redBorder,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}