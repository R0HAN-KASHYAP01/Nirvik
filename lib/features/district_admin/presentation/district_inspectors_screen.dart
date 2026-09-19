// lib/features/district_admin/presentation/district_inspectors_screen.dart
//
// Every approved inspector registered in the District Admin's own
// district + state, with search and an "Online only" filter. Tapping a
// row opens DistrictInspectorDetailScreen (details + video call).
//
// Data comes from the district_list_inspectors RPC — see
// supabase/district_admin_inspectors.sql.

import 'package:flutter/material.dart';

import '../../../core/widgets/status_badge.dart';
import '../../../models/district_inspector.dart';
import '../../../services/session_service.dart';
import '../data/district_inspector_repository.dart';
import 'district_inspector_detail_screen.dart';

const Color _kBackground = Color(0xFFEAF2F8);
const Color _kBorder = Color(0xFFD1DEE7);
const Color _kTextGrey = Color(0xFF667788);
const Color _kOnline = Color(0xFF1E7A46);
const Color _kOffline = Color(0xFF5B6472);

class DistrictInspectorsScreen extends StatefulWidget {
  const DistrictInspectorsScreen({super.key});

  @override
  State<DistrictInspectorsScreen> createState() =>
      _DistrictInspectorsScreenState();
}

class _DistrictInspectorsScreenState extends State<DistrictInspectorsScreen> {
  final DistrictInspectorRepository _repo = DistrictInspectorRepository();

  late Future<List<DistrictInspector>> _future;
  String _query = '';
  bool _onlineOnly = false;

  String get _district =>
      SessionService.instance.currentUser?.district?.trim() ?? '';
  String get _state => SessionService.instance.currentUser?.state?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<DistrictInspector>> _load() async {
    final list = await _repo.fetchInspectors();
    list.sort((a, b) {
      if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
      return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
    });
    return list;
  }

  void _retry() => setState(() => _future = _load());

  String _friendly(Object e) => e.toString().replaceFirst('Exception: ', '');

  bool _matches(DistrictInspector i) {
    if (_onlineOnly && !i.isOnline) return false;
    if (_query.isEmpty) return true;
    final haystack = [
      i.fullName,
      i.inspectorId,
      i.designation,
      i.department,
      i.assignedRegion,
    ].whereType<String>().join(' ').toLowerCase();
    return haystack.contains(_query);
  }

  void _open(DistrictInspector inspector) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DistrictInspectorDetailScreen(inspector: inspector),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(title: const Text('Inspectors')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintText: 'Search by name, ID or department',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _kBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _kBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    label: const Text('Online only'),
                    selected: _onlineOnly,
                    onSelected: (v) => setState(() => _onlineOnly = v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<DistrictInspector>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _Message(
                    icon: Icons.error_outline,
                    text:
                        'Could not load inspectors.\n${_friendly(snapshot.error!)}',
                    actionLabel: 'Retry',
                    onAction: _retry,
                  );
                }
                final all = snapshot.data ?? const <DistrictInspector>[];
                if (all.isEmpty) {
                  return _Message(
                    icon: Icons.groups_outlined,
                    text: 'No approved inspectors found in '
                        '$_district, $_state.',
                  );
                }
                final visible = all.where(_matches).toList();
                final onlineCount = all.where((i) => i.isOnline).length;

                if (visible.isEmpty) {
                  return const _Message(
                    icon: Icons.search_off,
                    text: 'No inspectors match your search.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final next = _load();
                    setState(() => _future = next);
                    await next;
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                    itemCount: visible.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Text(
                          '${all.length} inspector'
                          '${all.length == 1 ? '' : 's'} · '
                          '$onlineCount online · $_district, $_state',
                          style: const TextStyle(
                              fontSize: 12, color: _kTextGrey),
                        );
                      }
                      final inspector = visible[i - 1];
                      return _InspectorCard(
                        inspector: inspector,
                        onTap: () => _open(inspector),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorCard extends StatelessWidget {
  final DistrictInspector inspector;
  final VoidCallback onTap;

  const _InspectorCard({required this.inspector, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final online = inspector.isOnline;
    final region = inspector.assignedRegion;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: accent.withValues(alpha: 0.1),
                child: Text(
                  inspector.initial,
                  style: TextStyle(color: accent, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inspector.fullName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    if (inspector.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        inspector.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 12, color: _kTextGrey),
                      ),
                    ],
                    if (region != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              size: 13, color: _kTextGrey),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              region,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11.5, color: _kTextGrey),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusBadge(
                          label: online ? 'Online' : 'Offline',
                          color: online ? _kOnline : _kOffline,
                        ),
                        Text(
                          '${inspector.activeAssignments} active',
                          style: const TextStyle(
                              fontSize: 11.5, color: _kTextGrey),
                        ),
                        Text(
                          '${inspector.completedAssignments} completed',
                          style: const TextStyle(
                              fontSize: 11.5, color: _kTextGrey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _kTextGrey),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Message({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: _kTextGrey),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kTextGrey),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}