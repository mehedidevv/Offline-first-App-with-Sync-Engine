import 'package:hive_flutter/hive_flutter.dart';
import '../../features/tasks/model/task_model.dart';
import '../../features/tasks/model/sync_operation_model.dart';

class HiveService {
  static const String tasksBoxName = 'tasks_box';
  static const String syncQueueBoxName = 'sync_queue_box';
  static const String metadataBoxName = 'metadata_box';

  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SyncOperationModelAdapter());
    }

    // Open required boxes
    await Hive.openBox<TaskModel>(tasksBoxName);
    await Hive.openBox<SyncOperationModel>(syncQueueBoxName);
    await Hive.openBox(metadataBoxName);

    _isInitialized = true;
  }

  static Box<TaskModel> getTasksBox() => Hive.box<TaskModel>(tasksBoxName);
  static Box<SyncOperationModel> getSyncQueueBox() => Hive.box<SyncOperationModel>(syncQueueBoxName);
  static Box getMetadataBox() => Hive.box(metadataBoxName);

  static Future<void> clearAll() async {
    await getTasksBox().clear();
    await getSyncQueueBox().clear();
    await getMetadataBox().clear();
  }
}
