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
        // ==========================================================
        // BOTTOM NAVIGATION
        //
        // NavigationBar lays its label out inside a fixed internal
        // height. That's chrome the user can't scroll, so it never
        // gets a chance to "grow into" extra space the way a normal
        // Column in a ListView can — which makes it exactly the kind
        // of fixed-size container this pattern overflows on: it's
        // fine on an emulator's default 1.0x font scale, but on a
        // real device with a larger accessibility text size (or a
        // narrow 3-tab layout), a label like "Camera/Video" can wrap
        // to two lines and throw a bottom RenderFlex overflow.
        //
        // NavigationDestination.label only accepts a String, so we
        // can't hang a maxLines/FittedBox directly off it. Instead
        // the fix clamps (not disables) the text scale used just for
        // this bar: labels still grow a bit for accessibility, but
        // can't outgrow the space the bar reserves for them. The
        // rest of the app keeps the user's real system font scale.
        // ==========================================================
        bottomNavigationBar: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.textScalerOf(context).clamp(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.3,
            ),
          ),
          child: NavigationBar(
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
      ),
    );
  }
}