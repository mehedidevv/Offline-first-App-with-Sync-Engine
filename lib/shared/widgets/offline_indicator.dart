import 'package:flutter/material.dart';

class OfflineIndicator extends StatelessWidget {
  final bool hasConnection;

  const OfflineIndicator({super.key, required this.hasConnection});

  @override
  Widget build(BuildContext context) {
    if (hasConnection) return const SizedBox.shrink();

    return Container(
      color: Colors.orange.shade800,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.offline_bolt, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'Offline Mode - Changes will sync when online',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
