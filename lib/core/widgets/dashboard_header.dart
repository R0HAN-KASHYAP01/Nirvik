import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  final String greeting;
  final String userName;
  final VoidCallback onNotificationTap;
  final VoidCallback onLogoutTap;
  final List<Widget>? trailingActions;

  const DashboardHeader({
    super.key,
    required this.greeting,
    required this.userName,
    required this.onNotificationTap,
    required this.onLogoutTap,
    this.trailingActions,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: primary.withValues(alpha: 0.12),
          child: Icon(Icons.person, color: primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              Text(
                userName,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        ...?trailingActions,
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: onNotificationTap,
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: onLogoutTap,
        ),
      ],
    );
  }
}