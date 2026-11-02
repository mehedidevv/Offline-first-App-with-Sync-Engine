import 'package:flutter/material.dart';

class SyncStatusIndicator extends StatelessWidget {
  final bool isSyncing;
  final VoidCallback? onSyncPressed;

  const SyncStatusIndicator({
    super.key,
    required this.isSyncing,
    this.onSyncPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSyncing)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        else
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.white),
            tooltip: 'Sync Now',
            onPressed: onSyncPressed,
          ),
      ],
    );
  }
}
