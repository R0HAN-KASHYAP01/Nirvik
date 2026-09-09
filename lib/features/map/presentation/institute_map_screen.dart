import 'package:flutter/material.dart';

import '../../../core/widgets/loading_state.dart';
import '../../../services/inspector_service.dart';
import '../../../widgets/map/institute_map.dart';

/// Full-screen wrapper around [InstituteMap].
///
/// Tries to load the current inspector's saved location first so the map
/// opens the same way it does on the inspector profile screen — tightly
/// zoomed on their position with a radius circle, initially filtered to
/// nearby institutes but free to pan/zoom/"Show All" from there.
///
/// If there's no inspector profile (e.g. a different role) or no saved
/// location yet, this falls back to generic mode — every institute shown,
/// centered on India — exactly like before.
class InstituteMapScreen extends StatefulWidget {
  const InstituteMapScreen({super.key});

  @override
  State<InstituteMapScreen> createState() => _InstituteMapScreenState();
}

class _InstituteMapScreenState extends State<InstituteMapScreen> {
  bool _loadingProfile = true;
  double? _inspectorLatitude;
  double? _inspectorLongitude;

  static const double _radiusKm = 100;

  @override
  void initState() {
    super.initState();
    _loadInspectorLocation();
  }

  Future<void> _loadInspectorLocation() async {
    try {
      final profile = await InspectorService.instance.fetchCurrentProfile();

      if (!mounted) return;

      setState(() {
        if (profile != null && profile.hasLocation) {
          _inspectorLatitude = profile.latitude;
          _inspectorLongitude = profile.longitude;
        }
        _loadingProfile = false;
      });
    } catch (_) {
      // Not an inspector, not signed in as one, or the lookup failed —
      // fall back to generic mode rather than blocking the map.
      if (!mounted) return;

      setState(() => _loadingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Institute Map')),
      body: SafeArea(
        child: _loadingProfile
            ? const LoadingState(message: 'Loading map data...')
            : InstituteMap(
                inspectorLatitude: _inspectorLatitude,
                inspectorLongitude: _inspectorLongitude,
                radiusKm: _radiusKm,
              ),
      ),
    );
  }
}