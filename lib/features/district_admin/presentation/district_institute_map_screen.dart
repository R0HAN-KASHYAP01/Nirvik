// FILE: lib/features/district_admin/presentation/district_institute_map_screen.dart
//
// District-scoped wrapper around the shared InstituteMap widget. Fetches
// the set of institute profile ids in this admin's own district + state
// (via district_scoped_institute_ids(), scoped server-side) and passes it
// down as InstituteMap.allowedProfileIds, so only this district's
// institutes are ever rendered.

import 'package:flutter/material.dart';

import '../../../core/widgets/loading_state.dart';
import '../../../widgets/map/institute_map.dart';
import '../data/district_inspector_repository.dart';

class DistrictInstituteMapScreen extends StatefulWidget {
  const DistrictInstituteMapScreen({super.key});

  @override
  State<DistrictInstituteMapScreen> createState() =>
      _DistrictInstituteMapScreenState();
}

class _DistrictInstituteMapScreenState
    extends State<DistrictInstituteMapScreen> {
  final DistrictInspectorRepository _repository =
  DistrictInspectorRepository();

  bool _loading = true;
  String? _error;
  Set<String> _allowedProfileIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ids = await _repository.fetchScopedInstituteProfileIds();
      if (!mounted) return;
      setState(() {
        _allowedProfileIds = ids;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('District Map')),
      body: SafeArea(
        child: _loading
            ? const LoadingState(message: 'Loading map data...')
            : _error != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 40, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        )
            : InstituteMap(allowedProfileIds: _allowedProfileIds),
      ),
    );
  }
}