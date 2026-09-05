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

  final _screens = const [
    OfficialHomeScreen(),
    SchemesScreen(),
    PmuMonitoringScreen(),
    OfficialProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.account_balance_outlined), selectedIcon: Icon(Icons.account_balance), label: 'Schemes'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'PMU'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}