// lib/features/state_admin/presentation/state_institute_list_screen.dart
//
// Step 4 (final) of the State Admin "Schemes" flow: approved institutes
// registered under the chosen category + scheme, scoped to the logged-in
// State Admin's own state and the district chosen back in step 1
// (StateDistrictSelectionScreen) — or every district of the state if
// "All Districts" was chosen there. The district is fixed by the time we
// get here, so there is no filter control on this screen; to change it,
// the admin goes back to the start of the flow.
//
// Source table + approval rule are identical to district_admin's
// InstituteListScreen: institute_reps, "approved" = reviewed_at IS NOT
// NULL AND rejection_reason IS NULL.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------- NIRIKSHA UI COLOR SYSTEM ----------
const Color _kPrimaryBlue = Color(0xFF084482);
const Color _kPrimaryMedium = Color(0xFF0B5AA0);
const Color _kPrimaryDark = Color(0xFF063A77);
const Color _kPrimaryLight = Color(0xFFEAF4FD);

const Color _kCardBackground = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFDCE8F2);
const Color _kBorderMedium = Color(0xFFC8D9E8);

const Color _kTextPrimary = Color(0xFF173B63);
const Color _kTextGrey = Color(0xFF5F7285);
const Color _kTextMuted = Color(0xFF8191A1);

/// Deep government blue — app bars, primary elements.
const LinearGradient _kPrimaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [_kPrimaryMedium, _kPrimaryBlue, _kPrimaryDark],
  stops: [0.0, 0.55, 1.0],
);

/// Soft blue-tinted screen background instead of a flat colour.
const LinearGradient _kBackgroundGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF7FAFD), Color(0xFFEFF7FD), Color(0xFFEAF4FD)],
  stops: [0.0, 0.5, 1.0],
);

/// Almost-white cards with a very subtle gradient.
const LinearGradient _kCardGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFFFFFFF), Color(0xFFFBFDFF)],
);

const String _kAllDistricts = 'All Districts';

class StateInstituteListScreen extends StatefulWidget {
  final String categoryKey;
  final String schemeCode;
  final String schemeLabel;
  final String adminState;
  final String selectedDistrict;

  const StateInstituteListScreen({
    super.key,
    required this.categoryKey,
    required this.schemeCode,
    required this.schemeLabel,
    required this.adminState,
    required this.selectedDistrict,
  });

  @override
  State<StateInstituteListScreen> createState() =>
      _StateInstituteListScreenState();
}

class _StateInstituteListScreenState extends State<StateInstituteListScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  String get _state => widget.adminState.trim();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  /// Makes ilike behave as a case-insensitive "equals" by escaping the
  /// LIKE wildcard characters — same helper as the district admin screen.
  static String _escapeLike(String v) => v
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');

  Future<List<Map<String, dynamic>>> _load() async {
    // Never run an unscoped query: a state admin must only ever see their
    // own state, whatever district (or all of them) was picked in step 1.
    if (_state.isEmpty) {
      throw Exception(
        'Your profile has no state set, so institutes cannot be listed.',
      );
    }

    var query = Supabase.instance.client
        .from('institute_reps')
        .select('profile_id, organization_name, registration_number, '
            'organization_type, complete_address, district, state, '
            'pin_code, representative_name, designation, mobile_number, '
            'official_email')
        .eq('scheme_category', widget.categoryKey)
        .eq('scheme_code', widget.schemeCode)
        .ilike('state', _escapeLike(_state));

    if (widget.selectedDistrict != _kAllDistricts) {
      query = query.ilike('district', _escapeLike(widget.selectedDistrict));
    }

    final rows = await query
        .not('reviewed_at', 'is', null)
        .isFilter('rejection_reason', null)
        .order('district', ascending: true)
        .order('organization_name', ascending: true);

    return List<Map<String, dynamic>>.from(rows);
  }

  void _retry() => setState(() => _future = _load());

  String _friendly(Object e) => e.toString().replaceFirst('Exception: ', '');

  String get _scopeLabel => widget.selectedDistrict == _kAllDistricts
      ? _state
      : '${widget.selectedDistrict}, $_state';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text(widget.schemeLabel),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: _kPrimaryGradient),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: _kBackgroundGradient),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: _kPrimaryBlue),
              );
            }
            if (snapshot.hasError) {
              return _Message(
                icon: Icons.error_outline,
                text:
                    'Could not load institutes.\n${_friendly(snapshot.error!)}',
                actionLabel: 'Retry',
                onAction: _retry,
              );
            }
            final institutes = snapshot.data ?? const [];
            if (institutes.isEmpty) {
              return _Message(
                icon: Icons.apartment_outlined,
                text: 'No approved institutes found for this scheme in '
                    '$_scopeLabel.',
              );
            }
            return RefreshIndicator(
              color: _kPrimaryBlue,
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
                      '$_scopeLabel',
                      style: const TextStyle(fontSize: 12, color: _kTextGrey),
                    );
                  }
                  final inst = institutes[i - 1];
                  return _InstituteCard(
                    data: inst,
                    onTap: () => _showDetails(context, inst),
                  );
                },
              ),
            );
          },
        ),
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
      backgroundColor: _kCardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                v('organization_name'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: _kBorder, height: 16),
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
  final VoidCallback onTap;

  const _InstituteCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = (data['organization_name'] as String?) ?? 'Unnamed institute';
    final type = (data['organization_type'] as String?) ?? '';
    final district = (data['district'] as String?) ?? '';
    final address = (data['complete_address'] as String?) ?? '';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          gradient: _kCardGradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: _kPrimaryBlue.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _kPrimaryLight,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: _kBorderMedium),
                  ),
                  child: const Icon(
                    Icons.apartment_outlined,
                    color: _kPrimaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _kTextPrimary,
                              ),
                            ),
                          ),
                          // Only worth tagging each card with its district
                          // when the list can span more than one (i.e. "All
                          // Districts" was chosen back in step 1).
                          if (district.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _kPrimaryLight,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: _kBorderMedium),
                              ),
                              child: Text(
                                district,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _kPrimaryBlue,
                                ),
                              ),
                            ),
                        ],
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
                              fontSize: 11.5, color: _kTextMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: _kTextMuted),
              ],
            ),
          ),
        ),
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
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: _kTextPrimary),
            ),
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
            Icon(icon, size: 40, color: _kTextMuted),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kTextGrey),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimaryBlue,
                  side: const BorderSide(color: _kBorderMedium),
                  backgroundColor: _kCardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}