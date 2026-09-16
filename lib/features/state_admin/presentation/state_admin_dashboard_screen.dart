// lib/features/state_admin/presentation/state_admin_dashboard_screen.dart

import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../services/auth_service.dart';
import '../../../services/session_service.dart';

class StateAdminDashboardScreen extends StatelessWidget {
  const StateAdminDashboardScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.logout();
    SessionService.instance.clear();
    if (!context.mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('State Administrator'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Login Successful',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (user != null) ...[
                Text('Name: ${user.name}'),
                Text('Email: ${user.email}'),
                Text('Status: ${user.status}'),
              ],
              const SizedBox(height: 24),
              const Text(
                'State Admin dashboard — build state-level '
                'oversight features here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}