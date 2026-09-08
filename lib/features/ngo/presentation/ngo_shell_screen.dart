// lib/features/ngo/presentation/ngo_shell_screen.dart
import 'package:flutter/material.dart';
import 'ngo_dashboard_screen.dart';
import 'ngo_profile_screen.dart';
import '../../../core/widgets/module_placeholder_screen.dart';
import '../../calls/presentation/widgets/incoming_call_listener.dart';

class NgoShellScreen extends StatefulWidget {
  const NgoShellScreen({super.key});

  @override
  State<NgoShellScreen> createState() => _NgoShellScreenState();
}

class _NgoShellScreenState extends State<NgoShellScreen> {
  int _index = 0;

  final _screens = const [
    NgoDashboardScreen(),
    ModulePlaceholderScreen(
      title: 'Tasks',
      message: 'Task list will be implemented in a later phase.',
    ),
    NgoProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return IncomingCallListener(
      child: Scaffold(
        body: IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Tasks'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}