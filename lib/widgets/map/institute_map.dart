// FILE: lib/widgets/map/institute_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../app/theme.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../models/institute_map_point.dart';
import '../../utils/scheme_catalog.dart';
import '../../services/ngo_institute_service.dart';
import '../../utils/geo_utils.dart';

/// Available base-map styles. All are free tile providers that work with
/// flutter_map without an API key:
/// - [standard]  OpenStreetMap street map (unchanged default)
/// - [satellite] Esri World Imagery (aerial/satellite photography)
/// - [hybrid]    Esri imagery + place/boundary labels overlaid on top
/// - [terrain]   OpenTopoMap (contour lines, elevation shading — GIS style)
enum MapViewType { standard, satellite, hybrid, terrain }

extension MapViewTypeX on MapViewType {
  String get label => switch (this) {
        MapViewType.standard => 'Standard',
        MapViewType.satellite => 'Satellite',
        MapViewType.hybrid => 'Hybrid',
        MapViewType.terrain => 'Terrain (GIS)',
      };

  IconData get icon => switch (this) {
        MapViewType.standard => Icons.map_outlined,
        MapViewType.satellite => Icons.satellite_alt_outlined,
        MapViewType.hybrid => Icons.layers_outlined,
        MapViewType.terrain => Icons.terrain_outlined,
      };
}

/// Reusable, self-contained map of NGOs/institutes fetched from Supabase.
///
/// Generic mode (no inspector coordinates): shows every institute with a
/// saved location, centered on India — used by [InstituteMapScreen] as-is.
///
/// Inspector mode: pass [inspectorLatitude]/[inspectorLongitude] to open
/// tightly zoomed in on the inspector's exact position, draw a [radiusKm]
/// circle for context, and initially filter institutes to that radius.
/// The inspector can then pan/zoom out freely to explore, e.g.:
/// ```dart
/// InstituteMap(
///   inspectorLatitude: profile.latitude,
///   inspectorLongitude: profile.longitude,
///   radiusKm: 100,
/// )
/// ```
class InstituteMap extends StatefulWidget {
  final bool showSchemes;
  final void Function(InstituteMapPoint institute)? onInstituteSelected;
  final double? inspectorLatitude;
  final double? inspectorLongitude;
  final double radiusKm;

  /// When provided, only institutes whose `profileId` is in this set are
  /// ever shown — used by the District Admin's map to restrict results to
  /// their own district without touching the generic (all-India) mode.
  final Set<String>? allowedProfileIds;

  const InstituteMap({
    super.key,
    this.showSchemes = true,
    this.onInstituteSelected,
    this.inspectorLatitude,
    this.inspectorLongitude,
    this.radiusKm = 100,
    this.allowedProfileIds,
  });

  bool get _hasInspectorLocation => inspectorLatitude != null && inspectorLongitude != null;

  @override
  State<InstituteMap> createState() => _InstituteMapState();
}

class _InstituteMapState extends State<InstituteMap> {
  static const _defaultCenter = latlng.LatLng(22.9734, 78.6569);
  static const _defaultZoom = 4.5;

  /// Initial zoom used when opening directly on the inspector's location —
  /// close enough to read street-level detail rather than the whole radius.
  static const _inspectorInitialZoom = 16.0;

  final MapController _mapController = MapController();

  bool _loading = true;
  String? _error;
  List<InstituteMapPoint> _allInstitutes = [];

  /// Starts true (radius view) only in inspector mode; has no effect
  /// in generic mode, which always shows everything.
  bool _restrictToRadius = true;
  bool _hasCenteredOnInspector = false;

  MapViewType _mapViewType = MapViewType.standard;

  @override
  void initState() {
    super.initState();
    _restrictToRadius = widget._hasInspectorLocation;
    _loadInstitutes();
  }

  @override
  void didUpdateWidget(covariant InstituteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Inspector location changed (e.g. after "Detect My Current Location")
    // — recenter tightly on the new position.
    if (widget.inspectorLatitude != oldWidget.inspectorLatitude ||
        widget.inspectorLongitude != oldWidget.inspectorLongitude) {
      _hasCenteredOnInspector = false;
      _centerOnInspector();
    }
  }

  Future<void> _loadInstitutes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final institutes = await NgoInstituteService.instance.fetchAllForMap();
      if (!mounted) return;
      setState(() {
        _allInstitutes = institutes;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnInspector());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load institutes. Please check your connection and try again.';
        _loading = false;
      });
    }
  }

  /// Opens tightly zoomed in on the inspector's saved position. Runs once
  /// per location value (guarded by [_hasCenteredOnInspector]) so it doesn't
  /// fight the user if they've already panned/zoomed elsewhere.
  void _centerOnInspector() {
    if (_hasCenteredOnInspector || !widget._hasInspectorLocation) return;

    final target = latlng.LatLng(widget.inspectorLatitude!, widget.inspectorLongitude!);

    try {
      _mapController.move(target, _inspectorInitialZoom);
      _hasCenteredOnInspector = true;
    } catch (_) {
      // Map may not be mounted/ready yet — retried on the next callback.
    }
  }

  /// Zooms out just far enough to fit the whole radius circle in view —
  /// available on demand via the "fit radius" button, so the inspector can
  /// still get the wide overview when they want it without it being forced
  /// on open.
  void _fitRadiusBounds() {
    if (!widget._hasInspectorLocation) return;

    final lat = widget.inspectorLatitude!;
    final lng = widget.inspectorLongitude!;
    final bounds = GeoUtils.boundsForRadius(lat, lng, widget.radiusKm);

    try {
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(32)),
      );
    } catch (_) {
      // Ignore — best effort only.
    }
  }

  List<InstituteMapPoint> get _visibleInstitutes {
    Iterable<InstituteMapPoint> result = _allInstitutes;

    if (widget.allowedProfileIds != null) {
      final allowed = widget.allowedProfileIds!;
      result = result.where((i) => allowed.contains(i.profileId));
    }

    if (!widget._hasInspectorLocation || !_restrictToRadius) {
      return result.toList();
    }

    final lat = widget.inspectorLatitude!;
    final lng = widget.inspectorLongitude!;
    return result
        .where((i) => GeoUtils.distanceKm(lat, lng, i.latitude, i.longitude) <= widget.radiusKm)
        .toList();
  }

  Future<void> _goToMyLocation() async {
    // Inspector mode: "my location" always re-centers tightly on the saved
    // inspector point, even if we already centered once before.
    if (widget._hasInspectorLocation) {
      final target = latlng.LatLng(widget.inspectorLatitude!, widget.inspectorLongitude!);
      _mapController.move(target, _inspectorInitialZoom);
      return;
    }
    // Generic mode: fall back to the device's live GPS position.
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      _mapController.move(latlng.LatLng(position.latitude, position.longitude), 16);
    } catch (_) {
      // Best-effort only.
    }
  }

  void _showInstituteDetails(InstituteMapPoint institute) {
    widget.onInstituteSelected?.call(institute);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _InstituteDetailsSheet(
        institute: institute,
        showScheme: widget.showSchemes,
      ),
    );
  }

  void _showMapTypeSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Map View',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              for (final type in MapViewType.values)
                ListTile(
                  leading: Icon(
                    type.icon,
                    color: type == _mapViewType ? AppColors.primary : AppColors.textSecondary,
                  ),
                  title: Text(
                    type.label,
                    style: TextStyle(
                      fontWeight: type == _mapViewType ? FontWeight.w700 : FontWeight.w500,
                      color: type == _mapViewType ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  trailing: type == _mapViewType
                      ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                      : null,
                  onTap: () {
                    setState(() => _mapViewType = type);
                    Navigator.of(context).pop();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Base tile layer(s) for the currently selected [_mapViewType]. Hybrid
  /// stacks a labels/boundaries layer on top of the satellite imagery.
  List<Widget> _buildTileLayers() {
    switch (_mapViewType) {
      case MapViewType.standard:
        return [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.smart_monitoring_app',
          ),
        ];
      case MapViewType.satellite:
        return [
          TileLayer(
            urlTemplate:
                'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
            userAgentPackageName: 'com.example.smart_monitoring_app',
          ),
        ];
      case MapViewType.hybrid:
        return [
          TileLayer(
            urlTemplate:
                'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
            userAgentPackageName: 'com.example.smart_monitoring_app',
          ),
          TileLayer(
            urlTemplate:
                'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
            userAgentPackageName: 'com.example.smart_monitoring_app',
          ),
        ];
      case MapViewType.terrain:
        return [
          TileLayer(
            urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.smart_monitoring_app',
          ),
        ];
    }
  }

  List<TextSourceAttribution> _buildAttributions() {
    switch (_mapViewType) {
      case MapViewType.standard:
        return const [TextSourceAttribution('OpenStreetMap contributors')];
      case MapViewType.satellite:
      case MapViewType.hybrid:
        return const [TextSourceAttribution('Esri, Maxar, Earthstar Geographics')];
      case MapViewType.terrain:
        return const [TextSourceAttribution('OpenTopoMap (CC-BY-SA) — data: SRTM, OpenStreetMap')];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingState(message: 'Loading map data...');
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppColors.error),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _loadInstitutes, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final visible = _visibleInstitutes;
    final restricting = widget._hasInspectorLocation && _restrictToRadius;

    if (visible.isEmpty) {
      return Column(
        children: [
          Expanded(
            child: EmptyState(
              icon: Icons.location_off_outlined,
              title: restricting
                  ? 'No institutes within ${widget.radiusKm.toStringAsFixed(0)} km'
                  : 'No NGOs or institutes found',
              message: restricting
                  ? 'No institutes were found within ${widget.radiusKm.toStringAsFixed(0)} km of your current location.'
                  : 'Institutes with a saved location will appear here.',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              children: [
                TextButton.icon(
                  onPressed: _loadInstitutes,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                ),
                if (restricting)
                  TextButton.icon(
                    onPressed: () => setState(() => _restrictToRadius = false),
                    icon: const Icon(Icons.public, size: 18),
                    label: const Text('Show All Institutes'),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    final inspectorPoint = widget._hasInspectorLocation
        ? latlng.LatLng(widget.inspectorLatitude!, widget.inspectorLongitude!)
        : null;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            // Opens directly on the inspector's exact position at a close
            // zoom; the radius circle stays visible for context and the
            // inspector can zoom/pan out from here on their own.
            initialCenter: inspectorPoint ?? _defaultCenter,
            initialZoom: inspectorPoint != null ? _inspectorInitialZoom : _defaultZoom,
            minZoom: 3,
            maxZoom: 19,
            onMapReady: _centerOnInspector,
          ),
          children: [
            ..._buildTileLayers(),
            if (inspectorPoint != null && restricting)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: inspectorPoint,
                    radius: widget.radiusKm * 1000,
                    useRadiusInMeter: true,
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderColor: AppColors.primary.withValues(alpha: 0.4),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                ...visible.map(
                  (institute) => Marker(
                    point: latlng.LatLng(institute.latitude, institute.longitude),
                    width: 42,
                    height: 42,
                    child: GestureDetector(
                      onTap: () => _showInstituteDetails(institute),
                      child: const Icon(Icons.location_on, color: AppColors.primary, size: 38),
                    ),
                  ),
                ),
                if (inspectorPoint != null)
                  Marker(
                    point: inspectorPoint,
                    width: 48,
                    height: 48,
                    child: const _InspectorMarker(),
                  ),
              ],
            ),
            RichAttributionWidget(attributions: _buildAttributions()),
          ],
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Column(
            children: [
              _MapActionButton(icon: Icons.layers_outlined, onTap: _showMapTypeSelector),
              const SizedBox(height: 8),
              _MapActionButton(icon: Icons.my_location, onTap: _goToMyLocation),
              const SizedBox(height: 8),
              if (widget._hasInspectorLocation) ...[
                _MapActionButton(icon: Icons.zoom_out_map, onTap: _fitRadiusBounds),
                const SizedBox(height: 8),
              ],
              _MapActionButton(icon: Icons.refresh, onTap: _loadInstitutes),
            ],
          ),
        ),
        if (widget._hasInspectorLocation)
          Positioned(
            left: 12,
            bottom: 12,
            child: Material(
              color: AppColors.surface,
              elevation: 2,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _restrictToRadius = !_restrictToRadius),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_restrictToRadius ? Icons.public : Icons.gps_fixed,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        _restrictToRadius
                            ? 'Show All Institutes'
                            : 'Show ${widget.radiusKm.toStringAsFixed(0)} km Only',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _InspectorMarker extends StatelessWidget {
  const _InspectorMarker();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.secondary, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      padding: const EdgeInsets.all(6),
      child: const Icon(Icons.person_pin_circle, color: AppColors.secondary, size: 26),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapActionButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _InstituteDetailsSheet extends StatelessWidget {
  final InstituteMapPoint institute;
  final bool showScheme;
  const _InstituteDetailsSheet({required this.institute, required this.showScheme});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(institute.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (institute.address != null && institute.address!.trim().isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place_outlined, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(institute.address!,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ),
                ],
              ),
            if (showScheme && institute.schemeCode != null) ...[
              const SizedBox(height: 12),
              StatusBadge(label: schemeLabel(institute.schemeCode), color: AppColors.secondary),
            ],
            if (institute.registrationNumber != null && institute.registrationNumber!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Registration No: ${institute.registrationNumber}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 16),
            Text(
              'Lat: ${institute.latitude.toStringAsFixed(5)}, Lng: ${institute.longitude.toStringAsFixed(5)}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}