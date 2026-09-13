import 'package:flutter/material.dart';

import 'official_home_screen.dart';
import 'pmu_monitoring_screen.dart';
import 'official_profile_screen.dart';
import '../../schemes/presentation/schemes_screen.dart';

class OfficialShellScreen extends StatefulWidget {
  const OfficialShellScreen({super.key});

  @override
  State<OfficialShellScreen> createState() => _OfficialShellScreenState();
}

class _OfficialShellScreenState extends State<OfficialShellScreen> {
  int _index = 0;

  static const Color _navy = Color(0xFF123E68);
  static const Color _background = Color(0xFFEAF2F8);
  static const Color _border = Color(0xFFD1DEE7);
  static const Color _textGrey = Color(0xFF667788);

  final _screens = const [
    OfficialHomeScreen(),
    SchemesScreen(),
    PmuMonitoringScreen(),
    OfficialProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              height: 70,
              indicatorColor: _navy.withValues(alpha: 0.12),

              labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
                (states) {
                  if (states.contains(WidgetState.selected)) {
                    return const TextStyle(
                      color: _navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    );
                  }

                  return const TextStyle(
                    color: _textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  );
                },
              ),

              iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
                (states) {
                  if (states.contains(WidgetState.selected)) {
                    return const IconThemeData(
                      color: _navy,
                      size: 24,
                    );
                  }

                  return const IconThemeData(
                    color: _textGrey,
                    size: 23,
                  );
                },
              ),
            ),

            child: NavigationBar(
              selectedIndex: _index,

              onDestinationSelected: (i) {
                if (_index == i) return;

                setState(() {
                  _index = i;
                });
              },

              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_outlined),
                  selectedIcon: Icon(Icons.account_balance),
                  label: 'Schemes',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups),
                  label: 'PMU',
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
    );
  }
}