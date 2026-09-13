import 'package:flutter/material.dart';
import 'app_card.dart';

class SummaryStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final String? subtitle;
  final Color? accentColor;
  final VoidCallback? onTap;

  const SummaryStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    this.subtitle,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            // FittedBox: this card is typically placed as one of 3 equal
            // Expanded siblings in a Row (see InspectorHomeScreen), so its
            // width is narrow and fixed. The count string has no natural
            // length limit (loading placeholder, single digit, or a large
            // number), so let it scale down instead of overflowing rather
            // than relying on the number always being short.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                count,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: Colors.black54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 1),
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 10.5, color: Colors.black38),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}