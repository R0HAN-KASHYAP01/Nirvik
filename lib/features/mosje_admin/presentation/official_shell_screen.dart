import 'package:flutter/material.dart';

import 'official_home_screen.dart';
import 'official_profile_screen.dart';
import 'official_scheme_state_screen.dart';

class OfficialShellScreen extends StatefulWidget {
  const OfficialShellScreen({super.key});

  @override
  State<OfficialShellScreen> createState() => _OfficialShellScreenState();
}

class _OfficialShellScreenState extends State<OfficialShellScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    const OfficialHomeScreen(),
    const OfficialSchemeStateScreen(),
    const OfficialProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance),
            label: 'Schemes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}