import 'package:hive/hive.dart';
import '../../../../core/database/hive_service.dart';
import '../../model/task_model.dart';

class TaskLocalDataSource {
  Box<TaskModel> get _box => HiveService.getTasksBox();

  Future<List<TaskModel>> getAllTasks() async {
    return _box.values.where((task) => !task.isDeleted).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<TaskModel?> getTaskById(String id) async {
    return _box.get(id);
  }

  Future<void> saveTask(TaskModel task) async {
    await _box.put(task.id, task);
  }

  Future<void> saveTasks(List<TaskModel> tasks) async {
    final map = {for (var t in tasks) t.id: t};
    await _box.putAll(map);
  }

  Future<void> deleteTask(String id) async {
    final task = _box.get(id);
    if (task != null) {
      final updated = task.copyWith(
        isDeleted: true,
        syncStatus: 'pending_delete',
        updatedAt: DateTime.now(),
        localRevision: task.localRevision + 1,
      );
      await _box.put(id, updated);
    }
  }

  Future<void> hardDeleteTask(String id) async {
    await _box.delete(id);
  }
}
