// lib/features/district_admin/presentation/institute_scheme_list_screen.dart
//
// Step 2: lists every scheme (label) in the chosen category,
// read from the `scheme_catalog` table, ordered by display_order.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'institute_list_screen.dart';

class InstituteSchemeListScreen extends StatefulWidget {
  final String categoryKey; // e.g. 'educational'
  final String categoryTitle; // e.g. 'Educational'

  const InstituteSchemeListScreen({
    super.key,
    required this.categoryKey,
    required this.categoryTitle,
  });

  @override
  State<InstituteSchemeListScreen> createState() =>
      _InstituteSchemeListScreenState();
}

class _InstituteSchemeListScreenState extends State<InstituteSchemeListScreen> {
  static const Color _background = Color(0xFFEAF2F8);
  static const Color _border = Color(0xFFD1DEE7);
  static const Color _textGrey = Color(0xFF667788);

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
      backgroundColor: _background,
      appBar: AppBar(title: Text(widget.categoryTitle)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => InstituteListScreen(
                        categoryKey: widget.categoryKey,
                        schemeCode: code,
                        schemeLabel: label,
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: _textGrey),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
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
            Icon(icon, size: 40, color: const Color(0xFF667788)),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF667788)),
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