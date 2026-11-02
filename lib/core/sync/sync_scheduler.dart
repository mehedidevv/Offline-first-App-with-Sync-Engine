import 'dart:async';
import 'package:flutter/widgets.dart';
import 'sync_engine.dart';

class SyncScheduler with WidgetsBindingObserver {
  final SyncEngine _syncEngine;
  Timer? _periodicTimer;
  static SyncScheduler? _instance;

  SyncScheduler._(this._syncEngine) {
    WidgetsBinding.instance.addObserver(this);
  }

  static Future<void> init(SyncEngine syncEngine) async {
    _instance ??= SyncScheduler._(syncEngine);
    _instance?.startPeriodicSync();
  }

  void startPeriodicSync() {
    _periodicTimer?.cancel();
    // Periodic sync every 15 minutes
    _periodicTimer = Timer.periodic(const Duration(minutes: 15), (timer) async {
      await _syncEngine.sync();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Trigger sync immediately when app comes to foreground
      _syncEngine.sync();
    }
  }

  static void cancelAll() {
    _instance?._periodicTimer?.cancel();
    if (_instance != null) {
      WidgetsBinding.instance.removeObserver(_instance!);
      _instance = null;
    }
  }
}
