import 'package:flutter/material.dart';

class LoadingState extends StatelessWidget {
  final String? message;

  const LoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(message!, style: const TextStyle(fontSize: 12, color: Colors.black45)),
            ],
          ],
        ),
      ),
    );
  }
}