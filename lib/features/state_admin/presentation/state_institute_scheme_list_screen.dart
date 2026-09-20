// lib/features/state_admin/presentation/state_institute_scheme_list_screen.dart
//
// Step 3 of the State Admin "Schemes" flow: lists every scheme (label) in
// the chosen category, read from the `scheme_catalog` table, ordered by
// display_order — identical query to district_admin's
// InstituteSchemeListScreen (the catalog itself has no district/state
// scoping), just re-used here so the two flows can't drift apart.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'state_institute_list_screen.dart';

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

const LinearGradient _kPrimaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [_kPrimaryMedium, _kPrimaryBlue, _kPrimaryDark],
  stops: [0.0, 0.55, 1.0],
);

const LinearGradient _kBackgroundGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF7FAFD), Color(0xFFEFF7FD), Color(0xFFEAF4FD)],
  stops: [0.0, 0.5, 1.0],
);

const LinearGradient _kCardGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFFFFFFF), Color(0xFFFBFDFF)],
);

class StateInstituteSchemeListScreen extends StatefulWidget {
  final String categoryKey; // e.g. 'educational'
  final String categoryTitle; // e.g. 'Educational'
  final String adminState;
  final String selectedDistrict;

  const StateInstituteSchemeListScreen({
    super.key,
    required this.categoryKey,
    required this.categoryTitle,
    required this.adminState,
    required this.selectedDistrict,
  });

  @override
  State<StateInstituteSchemeListScreen> createState() =>
      _StateInstituteSchemeListScreenState();
}

class _StateInstituteSchemeListScreenState
    extends State<StateInstituteSchemeListScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await Supabase.instance.client
        .from('scheme_catalog')
        .select('code, label, display_order')
        .eq('category', widget.categoryKey)
        .order('display_order', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  void _retry() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.categoryTitle),
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
                text: 'Could not load schemes.\n${snapshot.error}',
                actionLabel: 'Retry',
                onAction: _retry,
              );
            }
            final schemes = snapshot.data ?? const [];
            if (schemes.isEmpty) {
              return const _Message(
                icon: Icons.inbox_outlined,
                text: 'No schemes found in this category.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              itemCount: schemes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final s = schemes[i];
                final code = s['code'] as String;
                final label = (s['label'] as String?) ?? code;
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
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StateInstituteListScreen(
                            categoryKey: widget.categoryKey,
                            schemeCode: code,
                            schemeLabel: label,
                            adminState: widget.adminState,
                            selectedDistrict: widget.selectedDistrict,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _kPrimaryLight,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(color: _kBorderMedium),
                              ),
                              child: const Icon(
                                Icons.description_outlined,
                                color: _kPrimaryBlue,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _kTextPrimary,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: _kTextMuted),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
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