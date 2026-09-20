// lib/features/district_admin/presentation/institute_list_screen.dart
//
// Step 3: approved institutes registered under the chosen category +
// scheme, limited to the logged-in District Admin's own district AND state.
//
// Source table: institute_reps (columns used: scheme_category, scheme_code,
// district, state, reviewed_at, rejection_reason, ...).
// "Approved" = reviewed_at IS NOT NULL AND rejection_reason IS NULL.
//
// Requires district_admin_institutes_rls.sql, otherwise the list is empty.
//
// Each institute card has an "Assign Inspector" button. If the institute
// already has an active assignment, the card shows who it is assigned to
// instead. Assigning goes through the RPC functions in
// supabase/district_admin_inspectors.sql.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/district_inspector.dart';
import '../../../services/session_service.dart';
import '../data/district_inspector_repository.dart';
import 'assign_inspector_sheet.dart';

const Color _kBackground = Color(0xFFEAF2F8);
const Color _kBorder = Color(0xFFD1DEE7);
const Color _kTextGrey = Color(0xFF667788);
const Color _kAssignedGreen = Color(0xFF1E7A46);

class InstituteListScreen extends StatefulWidget {
  final String categoryKey;
  final String schemeCode;
  final String schemeLabel;

  const InstituteListScreen({
    super.key,
    required this.categoryKey,
    required this.schemeCode,
    required this.schemeLabel,
  });

  @override
  State<InstituteListScreen> createState() => _InstituteListScreenState();
}

/// Institutes plus the active assignments that belong to them.
class _ListData {
  final List<Map<String, dynamic>> institutes;
  final Map<String, InstituteAssignmentInfo> assignments;

  const _ListData(this.institutes, this.assignments);
}

class _InstituteListScreenState extends State<InstituteListScreen> {
  final DistrictInspectorRepository _inspectorRepo =
      DistrictInspectorRepository();

  late Future<_ListData> _future;

  String get _district =>
      SessionService.instance.currentUser?.district?.trim() ?? '';
  String get _state =>
      SessionService.instance.currentUser?.state?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  /// Makes ilike behave as a case-insensitive "equals" by escaping the
  /// LIKE wildcard characters.
  static String _escapeLike(String v) => v
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');

  Future<_ListData> _load() async {
    // Never run an unscoped query: a district admin must only ever see
    // their own district and state.
    if (_district.isEmpty || _state.isEmpty) {
      throw Exception(
        'Your profile has no district/state set, so institutes cannot be '
            'listed.',
      );
    }

    final rows = await Supabase.instance.client
        .from('institute_reps')
        .select('profile_id, organization_name, registration_number, '
        'organization_type, complete_address, district, state, pin_code, '
        'representative_name, designation, mobile_number, official_email')
        .eq('scheme_category', widget.categoryKey)
        .eq('scheme_code', widget.schemeCode)
        .ilike('district', _escapeLike(_district))
        .ilike('state', _escapeLike(_state))
        .not('reviewed_at', 'is', null)
        .isFilter('rejection_reason', null)
        .order('organization_name', ascending: true);

    final institutes = List<Map<String, dynamic>>.from(rows);

    // Assignment info is a nice-to-have: if it cannot be loaded (for
    // example the SQL has not been applied yet) the institutes still show,
    // and the real error surfaces when the admin taps "Assign Inspector".
    var assignments = const <String, InstituteAssignmentInfo>{};
    try {
      assignments = await _inspectorRepo.fetchActiveAssignments();
    } catch (_) {}

    return _ListData(institutes, assignments);
  }

  void _retry() => setState(() => _future = _load());

  String _friendly(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> _assign(Map<String, dynamic> institute) async {
    final id = institute['profile_id']?.toString();
    if (id == null || id.isEmpty) return;

    final rawName = (institute['organization_name'] as String?)?.trim();
    final name = (rawName == null || rawName.isEmpty)
        ? 'this institute'
        : rawName;

    final assigned = await showAssignInspectorSheet(
      context,
      instituteProfileId: id,
      instituteName: name,
    );
    if (assigned != true || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inspector assigned.')),
    );
    _retry();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(title: Text(widget.schemeLabel)),
      body: FutureBuilder<_ListData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _Message(
              icon: Icons.error_outline,
              text: 'Could not load institutes.\n${_friendly(snapshot.error!)}',
              actionLabel: 'Retry',
              onAction: _retry,
            );
          }
          final data = snapshot.data;
          final institutes = data?.institutes ?? const <Map<String, dynamic>>[];
          if (institutes.isEmpty) {
            return _Message(
              icon: Icons.apartment_outlined,
              text: 'No approved institutes found for this scheme in '
                  '$_district, $_state.',
            );
          }
          final assignments =
              data?.assignments ?? const <String, InstituteAssignmentInfo>{};

          return RefreshIndicator(
            onRefresh: () async {
              final next = _load();
              setState(() => _future = next);
              await next;
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              itemCount: institutes.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Text(
                    '${institutes.length} institute'
                        '${institutes.length == 1 ? '' : 's'} · '
                        '$_district, $_state',
                    style: const TextStyle(fontSize: 12, color: _kTextGrey),
                  );
                }
                final inst = institutes[i - 1];
                return _InstituteCard(
                  data: inst,
                  assignment: assignments[inst['profile_id']?.toString()],
                  onTap: () => _showDetails(context, inst),
                  onAssign: () => _assign(inst),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showDetails(BuildContext context, Map<String, dynamic> d) {
    String v(String key) {
      final value = (d[key] as String?)?.trim();
      return (value == null || value.isEmpty) ? '—' : value;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                v('organization_name'),
                style:
                const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _DetailRow('Scheme', widget.schemeLabel),
              _DetailRow('Type', v('organization_type')),
              _DetailRow('Registration No.', v('registration_number')),
              _DetailRow(
                'Address',
                '${v('complete_address')}, ${v('district')}, '
                    '${v('state')} - ${v('pin_code')}',
              ),
              _DetailRow('Representative', v('representative_name')),
              _DetailRow('Designation', v('designation')),
              _DetailRow('Mobile', v('mobile_number')),
              _DetailRow('Email', v('official_email')),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstituteCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final InstituteAssignmentInfo? assignment;
  final VoidCallback onTap;
  final VoidCallback onAssign;

  const _InstituteCard({
    required this.data,
    required this.assignment,
    required this.onTap,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final name = (data['organization_name'] as String?) ?? 'Unnamed institute';
    final type = (data['organization_type'] as String?) ?? '';
    final address = (data['complete_address'] as String?) ?? '';
    final accent = Theme.of(context).colorScheme.primary;
    final info = assignment;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.apartment_outlined,
                        color: accent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        if (type.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            type,
                            style: const TextStyle(
                                fontSize: 12, color: _kTextGrey),
                          ),
                        ],
                        if (address.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11.5, color: _kTextGrey),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: _kTextGrey),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: _kBorder),
              const SizedBox(height: 10),
              if (info != null)
                _AssignedBanner(info: info)
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onAssign,
                    icon: const Icon(Icons.assignment_ind_outlined, size: 18),
                    label: const Text('Assign Inspector'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignedBanner extends StatelessWidget {
  final InstituteAssignmentInfo info;

  const _AssignedBanner({required this.info});

  @override
  Widget build(BuildContext context) {
    final who = info.inspectorName ?? 'an inspector';
    final visit = info.scheduledDateTime;

    final parts = <String>[
      info.statusLabel,
      if (visit != null) 'Visit ${formatDistrictDateTime(visit)}',
      if (info.priorityLabel.isNotEmpty) '${info.priorityLabel} priority',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFE0CD)),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_turned_in_outlined,
              size: 18, color: _kAssignedGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assigned to $who',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  parts.join(' · '),
                  style: const TextStyle(fontSize: 11.5, color: _kTextGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: _kTextGrey),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
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