// lib/features/ngo/presentation/ngo_shell_screen.dart

import 'package:flutter/material.dart';

import 'ngo_dashboard_screen.dart';
import 'ngo_profile_screen.dart';
import '../../../core/widgets/module_placeholder_screen.dart';
import '../../calls/presentation/widgets/incoming_call_listener.dart';
import '../../../app/routes.dart';

class NgoShellScreen extends StatefulWidget {
  const NgoShellScreen({super.key});

  @override
  State<NgoShellScreen> createState() => _NgoShellScreenState();
}

class _NgoShellScreenState extends State<NgoShellScreen> {
  int _index = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = const [
      NgoDashboardScreen(),
      ModulePlaceholderScreen(
        title: 'Camera / Video',
        message: 'Opening camera / video...',
      ),
      NgoProfileScreen(),
    ];
  }

  void _onNavigationSelected(int index) {
    // Camera / Video uses the existing NGO camera route.
    if (index == 1) {
      Navigator.of(context).pushNamed(AppRoutes.ngoCamera);
      return;
    }

    setState(() {
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IncomingCallListener(
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _onNavigationSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.videocam_outlined),
              selectedIcon: Icon(Icons.videocam),
              label: 'Camera/Video',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}