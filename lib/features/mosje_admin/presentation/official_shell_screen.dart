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

  // NIRIKSHA palette
  static const Color _primary = Color(0xFF084482);
  static const Color _primaryLight = Color(0xFFEAF4FD);
  static const Color _textSecondary = Color(0xFF5F7285);
  static const Color _border = Color(0xFFDCE8F2);

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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: _border),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x14084482),
              blurRadius: 12,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            indicatorColor: _primaryLight,
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                size: 24,
                color: selected ? _primary : _textSecondary,
              );
            }),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? _primary : _textSecondary,
              );
            }),
          ),
          child: NavigationBar(
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
        ),
      ),
    );
  }
}