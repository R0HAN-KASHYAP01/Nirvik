import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'assignments_screen.dart';
import 'inspection_history_screen.dart';
import 'inspector_home_screen.dart';
import 'inspector_profile_screen.dart';
import '../../calls/presentation/widgets/incoming_call_listener.dart';

class InspectorShellScreen extends StatefulWidget {
  const InspectorShellScreen({super.key});

  @override
  State<InspectorShellScreen> createState() =>
      _InspectorShellScreenState();
}

class _InspectorShellScreenState
    extends State<InspectorShellScreen> {
  static const Color _navy = Color(0xFF123E68);
  static const Color _background = Color(0xFFEAF2F8);
  static const Color _border = Color(0xFFD1DEE7);
  static const Color _unselected = Color(0xFF667788);

  int _index = 0;

  Timer? _presenceTimer;

  final _screens = const [
    InspectorHomeScreen(),
    AssignmentsScreen(),
    InspectionHistoryScreen(),
    InspectorProfileScreen(),
  ];

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    _updatePresence();

    _presenceTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _updatePresence(),
    );
  }

  Future<void> _updatePresence() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      debugPrint('[Presence] No authenticated Supabase user.');
      return;
    }

    debugPrint('[Presence] Updating user: ${user.id}');

    try {
      final timestamp =
          DateTime.now().toUtc().toIso8601String();

      await _client.from('profiles').update({
        'is_online': true,
        'last_seen': timestamp,
      }).eq('id', user.id);

      debugPrint(
        '[Presence] SUCCESS: is_online=true, last_seen=$timestamp',
      );
    } on PostgrestException catch (error) {
      debugPrint('[Presence] POSTGRES ERROR');
      debugPrint('[Presence] message: ${error.message}');
      debugPrint('[Presence] code: ${error.code}');
      debugPrint('[Presence] details: ${error.details}');
      debugPrint('[Presence] hint: ${error.hint}');
    } catch (error) {
      debugPrint('[Presence] GENERAL ERROR: $error');
    }
  }

  Future<void> _markOffline() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final timestamp =
          DateTime.now().toUtc().toIso8601String();

      await _client.from('profiles').update({
        'is_online': false,
        'last_seen': timestamp,
      }).eq('id', user.id);

      debugPrint(
        '[Presence] OFFLINE: is_online=false, last_seen=$timestamp',
      );
    } on PostgrestException catch (error) {
      debugPrint('[Presence] OFFLINE POSTGRES ERROR');
      debugPrint('[Presence] message: ${error.message}');
      debugPrint('[Presence] code: ${error.code}');
      debugPrint('[Presence] details: ${error.details}');
      debugPrint('[Presence] hint: ${error.hint}');
    } catch (error) {
      debugPrint('[Presence] OFFLINE GENERAL ERROR: $error');
    }
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
    _markOffline();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IncomingCallListener(
      child: Scaffold(
        backgroundColor: _background,

        body: IndexedStack(
          index: _index,
          children: _screens,
        ),

        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: _background,
              border: Border(
                top: BorderSide(
                  color: _border,
                  width: 1,
                ),
              ),
            ),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: _background,
                elevation: 0,
                height: 72,

                indicatorColor:
                    _navy.withValues(alpha: 0.12),

                labelTextStyle:
                    WidgetStateProperty.resolveWith<TextStyle>(
                  (states) {
                    final selected =
                        states.contains(
                      WidgetState.selected,
                    );

                    return TextStyle(
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected
                          ? _navy
                          : _unselected,
                    );
                  },
                ),

                iconTheme:
                    WidgetStateProperty.resolveWith<IconThemeData>(
                  (states) {
                    final selected =
                        states.contains(
                      WidgetState.selected,
                    );

                    return IconThemeData(
                      size: 23,
                      color: selected
                          ? _navy
                          : _unselected,
                    );
                  },
                ),
              ),

              child: NavigationBar(
                selectedIndex: _index,

                onDestinationSelected: (index) {
                  if (!mounted) return;

                  setState(() {
                    _index = index;
                  });
                },

                destinations: const [
                  NavigationDestination(
                    icon: Icon(
                      Icons.home_outlined,
                    ),
                    selectedIcon: Icon(
                      Icons.home,
                    ),
                    label: 'Home',
                  ),

                  NavigationDestination(
                    icon: Icon(
                      Icons.assignment_outlined,
                    ),
                    selectedIcon: Icon(
                      Icons.assignment,
                    ),
                    label: 'Assignments',
                  ),

                  NavigationDestination(
                    icon: Icon(
                      Icons.fact_check_outlined,
                    ),
                    selectedIcon: Icon(
                      Icons.fact_check,
                    ),
                    label: 'Inspections',
                  ),

                  NavigationDestination(
                    icon: Icon(
                      Icons.person_outline,
                    ),
                    selectedIcon: Icon(
                      Icons.person,
                    ),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}