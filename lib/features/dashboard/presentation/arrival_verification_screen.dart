import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'inspection_checklist_screen.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/assignment.dart';
import '../../../utils/geo_utils.dart';
import '../data/arrival_verification_repository.dart';

class ArrivalVerificationScreen extends StatefulWidget {
  final AssignmentSummary assignment;

  const ArrivalVerificationScreen({super.key, required this.assignment});

  @override
  State<ArrivalVerificationScreen> createState() =>
      _ArrivalVerificationScreenState();
}

class _ArrivalVerificationScreenState extends State<ArrivalVerificationScreen> {
  static const double verificationRadiusKm = 0.5;

  final ArrivalVerificationRepository _repository =
      ArrivalVerificationRepository();

  bool _isChecking = false;
  bool _isVerified = false;

  String? _message;
  double? _distanceKm;

  Future<void> _verifyArrival() async {
    if (_isChecking || _isVerified) {
      return;
    }

    setState(() {
      _isChecking = true;
      _message = null;
    });

    try {
      final latitude = widget.assignment.instituteLatitude;
      final longitude = widget.assignment.instituteLongitude;

      if (latitude == null || longitude == null) {
        setState(() {
          _message = 'Institute location coordinates are not available for this assignment.';
        });
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        setState(() {
          _message = 'Location services are disabled. Please enable GPS and try again.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _message =
              'Location permission was denied. Please allow location access.';
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _message = 'Location permission is permanently denied. Please enable it from device settings.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final distance = GeoUtils.distanceKm(
        position.latitude,
        position.longitude,
        latitude,
        longitude,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _distanceKm = distance;
      });

      if (distance > verificationRadiusKm) {
        setState(() {
          _isVerified = false;
          _message = 'You are outside the allowed verification radius. Move closer to the institute and try again.';
        });
        return;
      }

      final inspectorProfileId = _repository.getCurrentUserId();

      if (inspectorProfileId == null) {
        setState(() {
          _message =
              'No authenticated inspector was found. Please sign in again.';
        });
        return;
      }

      await _repository.saveArrivalVerification(
        assignmentId: widget.assignment.id,
        inspectorProfileId: inspectorProfileId,
        instituteProfileId: widget.assignment.instituteProfileId,
        verifiedAt: DateTime.now(),
        inspectorLatitude: position.latitude,
        inspectorLongitude: position.longitude,
        distanceKm: distance,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isVerified = true;
        _message =
            'Arrival verified successfully. Your verification has been saved.';
      });
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _message =
            'Arrival was verified, but could not be saved to Supabase: ${error.message}';
      });

      debugPrint('Arrival verification Supabase error: $error');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _message = 'Unable to verify your location. Please try again.';
      });

      debugPrint('Arrival verification error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  void _continueToChecklist() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            InspectionChecklistScreen(assignment: widget.assignment),
      ),
    );
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      final meters = (distanceKm * 1000).round();
      return '$meters m';
    }

    return '${distanceKm.toStringAsFixed(2)} km';
  }

  Widget _buildAssignmentCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assigned Institute',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            widget.assignment.projectName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Colors.black54,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.assignment.location,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatus() {
    final isVerified = _isVerified;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Icon(
            isVerified ? Icons.location_on : Icons.location_searching,
            size: 48,
            color: isVerified ? Colors.green : Colors.indigo,
          ),
          const SizedBox(height: 12),
          Text(
            isVerified ? 'Arrival Verified' : 'Arrival Not Verified',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isVerified ? Colors.green : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _distanceKm == null
                ? 'Tap the button below to check your current location.'
                : 'Current distance: ${_formatDistance(_distanceKm!)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationInformation() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verification Requirement',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          _buildRequirement(
            icon: Icons.my_location,
            title: 'GPS Location',
            description: 'Your device location will be checked against the assigned institute.',
          ),
          const SizedBox(height: 14),
          _buildRequirement(
            icon: Icons.social_distance_outlined,
            title: 'Maximum Distance',
            description:
                'You must be within 500 meters of the assigned institute.',
          ),
          const SizedBox(height: 14),
          _buildRequirement(
            icon: Icons.verified_outlined,
            title: 'Successful Verification',
            description:
                'Once verified, your arrival record will be saved to Supabase.',
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Colors.black54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessage() {
    if (_message == null) {
      return const SizedBox.shrink();
    }

    final isSuccess = _isVerified;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline : Icons.info_outline,
            color: isSuccess ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _message!,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton() {
    return PrimaryButton(
      label: _isChecking ? 'Checking Location...' : 'Verify Arrival',
      onPressed: _verifyArrival,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arrival Verification')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text(
            'Verify Your Arrival',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Confirm that you are physically present at the assigned institute before starting the inspection.',
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 20),
          _buildAssignmentCard(),
          const SizedBox(height: 12),
          _buildVerificationStatus(),
          const SizedBox(height: 12),
          _buildVerificationInformation(),
          const SizedBox(height: 12),
          _buildMessage(),
          const SizedBox(height: 20),
          if (!_isVerified)
            _buildVerifyButton()
          else
            PrimaryButton(
              label: 'Continue to Checklist',
              onPressed: _continueToChecklist,
            ),
        ],
      ),
    );
  }
}
