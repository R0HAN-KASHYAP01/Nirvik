// lib/features/district_admin/presentation/assign_inspector_sheet.dart
//
// "Assign Inspector" bottom sheet, opened from an institute card.
//
// Lists the approved inspectors in the district (online first, then least
// busy), lets the admin pick a priority and visit time, and creates the
// assignment through DistrictInspectorRepository.assignInspector (server
// side RPC — see supabase/district_admin_inspectors.sql).
//
// Resolves to true when an assignment was created, otherwise null/false.

import 'package:flutter/material.dart';

import '../../../core/widgets/status_badge.dart';
import '../../../models/district_inspector.dart';
import '../data/district_inspector_repository.dart';

const Color _kBackground = Color(0xFFEAF2F8);
const Color _kBorder = Color(0xFFD1DEE7);
const Color _kTextGrey = Color(0xFF667788);
const Color _kOnline = Color(0xFF1E7A46);
const Color _kOffline = Color(0xFF5B6472);
const Color _kError = Color(0xFFB3261E);

const List<(String, String)> _priorities = [
  ('low', 'Low'),
  ('medium', 'Medium'),
  ('high', 'High'),
];

Future<bool?> showAssignInspectorSheet(
  BuildContext context, {
  required String instituteProfileId,
  required String instituteName,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: _kBackground,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.9,
      child: _AssignInspectorSheet(
        instituteProfileId: instituteProfileId,
        instituteName: instituteName,
      ),
    ),
  );
}

class _AssignInspectorSheet extends StatefulWidget {
  final String instituteProfileId;
  final String instituteName;

  const _AssignInspectorSheet({
    required this.instituteProfileId,
    required this.instituteName,
  });

  @override
  State<_AssignInspectorSheet> createState() => _AssignInspectorSheetState();
}

class _AssignInspectorSheetState extends State<_AssignInspectorSheet> {
  final DistrictInspectorRepository _repo = DistrictInspectorRepository();

  late Future<List<DistrictInspector>> _future;
  String _priority = 'medium';

  /// null means "now" — resolved at the moment the admin confirms, so a
  /// sheet left open for a while never submits a stale time.
  DateTime? _scheduled;

  String? _submittingId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<DistrictInspector>> _load() async {
    final list = await _repo.fetchInspectors();
    list.sort((a, b) {
      if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
      final byLoad = a.activeAssignments.compareTo(b.activeAssignments);
      if (byLoad != 0) return byLoad;
      return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
    });
    return list;
  }

  void _reload() => setState(() => _future = _load());

  String _friendly(Object e) => e.toString().replaceFirst('Exception: ', '');

  String get _priorityLabel =>
      _priorities.firstWhere((p) => p.$1 == _priority).$2;

  String get _visitLabel =>
      _scheduled == null ? 'Now' : formatDistrictDateTime(_scheduled!);

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = _scheduled ?? now;

    // Assignments expire 2 days after creation, so only today and
    // tomorrow are offered.
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: today,
      lastDate: today.add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    var picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (picked.isBefore(now)) picked = now;
    setState(() => _scheduled = picked);
  }

  Future<void> _confirmAndAssign(DistrictInspector inspector) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Inspector'),
        content: Text(
          'Assign ${inspector.fullName} to ${widget.instituteName}?\n\n'
          'Priority: $_priorityLabel\n'
          'Visit: $_visitLabel',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Assign'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _submit(inspector);
  }

  Future<void> _submit(DistrictInspector inspector) async {
    setState(() {
      _submittingId = inspector.profileId;
      _error = null;
    });
    try {
      await _repo.assignInspector(
        instituteProfileId: widget.instituteProfileId,
        inspectorProfileId: inspector.profileId,
        scheduledDateTime: _scheduled ?? DateTime.now(),
        priority: _priority,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submittingId = null;
        _error = _friendly(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitting = _submittingId != null;

    return PopScope(
      canPop: !submitting,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assign Inspector',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.instituteName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: _kTextGrey),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Priority',
                  style: TextStyle(fontSize: 12.5, color: _kTextGrey),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final (value, label) in _priorities)
                      ChoiceChip(
                        label: Text(label),
                        selected: _priority == value,
                        onSelected: submitting
                            ? null
                            : (_) => setState(() => _priority = value),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: submitting ? null : _pickSchedule,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, size: 18, color: _kTextGrey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Visit: $_visitLabel',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDECEC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF3C0C0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 18, color: _kError),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                                fontSize: 12.5, color: _kError),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          Expanded(
            child: FutureBuilder<List<DistrictInspector>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _SheetMessage(
                    icon: Icons.error_outline,
                    text:
                        'Could not load inspectors.\n${_friendly(snapshot.error!)}',
                    actionLabel: 'Retry',
                    onAction: _reload,
                  );
                }
                final inspectors = snapshot.data ?? const <DistrictInspector>[];
                if (inspectors.isEmpty) {
                  return const _SheetMessage(
                    icon: Icons.groups_outlined,
                    text: 'No approved inspectors found in your district.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                  itemCount: inspectors.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final inspector = inspectors[i];
                    return _InspectorPickTile(
                      inspector: inspector,
                      busy: _submittingId == inspector.profileId,
                      disabled: submitting,
                      onAssign: () => _confirmAndAssign(inspector),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorPickTile extends StatelessWidget {
  final DistrictInspector inspector;
  final bool busy;
  final bool disabled;
  final VoidCallback onAssign;

  const _InspectorPickTile({
    required this.inspector,
    required this.busy,
    required this.disabled,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final online = inspector.isOnline;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
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
                    style: const TextStyle(fontSize: 12, color: _kTextGrey),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(
                      label: online ? 'Online' : 'Offline',
                      color: online ? _kOnline : _kOffline,
                    ),
                    Text(
                      '${inspector.activeAssignments} active',
                      style:
                          const TextStyle(fontSize: 11.5, color: _kTextGrey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: disabled ? null : onAssign,
            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
            child: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Assign'),
          ),
        ],
      ),
    );
  }
}

class _SheetMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SheetMessage({
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