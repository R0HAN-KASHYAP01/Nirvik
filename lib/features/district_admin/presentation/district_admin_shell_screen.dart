// lib/features/district_admin/presentation/district_admin_shell_screen.dart
//
// District Administrator shell: a bottom navigation bar with four tabs —
// Home, Institutes, Inspectors, Profile — in the same style as
// InspectorShellScreen, using the district-admin colour palette.
//
//   * Tabs are built the first time they are opened and then kept alive, so
//     switching tabs does not reload them or lose scroll position.
//   * System back on any other tab returns to Home first; back on Home exits.
//   * IncomingCallListener wraps the whole shell, so incoming video calls
//     ring on every tab (the Home screen no longer wraps its own).
//   * Returning to the Home tab refreshes its counts (for example after
//     assigning an inspector from another tab).

import 'package:flutter/material.dart';

import '../../calls/presentation/widgets/incoming_call_listener.dart';
import 'district_admin_dashboard_screen.dart';
import 'district_admin_profile_screen.dart';
import 'district_admin_theme.dart';
import 'district_inspectors_screen.dart';
import 'institute_category_screen.dart';

class DistrictAdminShellScreen extends StatefulWidget {
  const DistrictAdminShellScreen({super.key});

  @override
  State<DistrictAdminShellScreen> createState() =>
      _DistrictAdminShellScreenState();
}

class _DistrictAdminShellScreenState extends State<DistrictAdminShellScreen> {
  int _index = 0;

  /// Which tabs have been opened at least once (built lazily).
  final List<bool> _visited = [true, false, false, false];

  /// Bumped every time the user comes back to the Home tab.
  final ValueNotifier<int> _homeRefresh = ValueNotifier<int>(0);

  @override
  void dispose() {
    _homeRefresh.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index == _index) return;

    setState(() {
      _index = index;
      _visited[index] = true;
    });

    if (index == 0) _homeRefresh.value++;
  }

  Widget _page(int index) {
    switch (index) {
      case 0:
        return DistrictAdminDashboardScreen(refreshSignal: _homeRefresh);
      case 1:
        return const InstituteCategoryScreen();
      case 2:
        return const DistrictInspectorsScreen();
      default:
        return const DistrictAdminProfileScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IncomingCallListener(
      child: PopScope(
        canPop: _index == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _select(0);
        },
        child: Scaffold(
          backgroundColor: DistrictColors.background,
          body: IndexedStack(
            index: _index,
            children: [
              for (var i = 0; i < _visited.length; i++)
                _visited[i] ? _page(i) : const SizedBox.shrink(),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: DistrictColors.card,
                border: Border(
                  top: BorderSide(color: DistrictColors.borderLight, width: 1),
                ),
              ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  backgroundColor: DistrictColors.card,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  height: 72,
                  indicatorColor:
                      DistrictColors.primary.withValues(alpha: 0.12),
                  labelTextStyle:
                      WidgetStateProperty.resolveWith<TextStyle>((states) {
                    final selected = states.contains(WidgetState.selected);
                    return TextStyle(
                      fontSize: 12,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? DistrictColors.primary
                          : DistrictColors.textSecondary,
                    );
                  }),
                  iconTheme:
                      WidgetStateProperty.resolveWith<IconThemeData>((states) {
                    final selected = states.contains(WidgetState.selected);
                    return IconThemeData(
                      size: 23,
                      color: selected
                          ? DistrictColors.primary
                          : DistrictColors.textSecondary,
                    );
                  }),
                ),
                child: NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.apartment_outlined),
                      selectedIcon: Icon(Icons.apartment),
                      label: 'Institutes',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.groups_outlined),
                      selectedIcon: Icon(Icons.groups),
                      label: 'Inspectors',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}