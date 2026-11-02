import 'package:flutter/material.dart';
import 'core/database/hive_service.dart';
import 'core/di/service_locator.dart';
import 'core/sync/sync_engine.dart';
import 'core/sync/sync_scheduler.dart';
import 'features/tasks/view/task_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local database & adapters
  await HiveService.init();

  // Setup Dependency Injection
  setupServiceLocator();

  // Initialize Background Sync Scheduler
  await SyncScheduler.init(sl<SyncEngine>());

  runApp(const SyncNestApp());
}

class SyncNestApp extends StatelessWidget {
  const SyncNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SyncNest - Offline-First App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const TaskPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
