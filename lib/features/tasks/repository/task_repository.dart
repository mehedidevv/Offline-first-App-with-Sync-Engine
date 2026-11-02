import 'package:uuid/uuid.dart';
import '../../../core/sync/conflict_resolver.dart';
import '../../../core/sync/sync_queue.dart';
import '../data/local/task_local_data_source.dart';
import '../data/remote/task_remote_data_source.dart';
import '../model/sync_operation_model.dart';
import '../model/task_model.dart';

class TaskRepository {
  final TaskLocalDataSource _localDataSource;
  final TaskRemoteDataSource _remoteDataSource;
  final SyncQueue _syncQueue;
  final Uuid _uuid;

  TaskRepository({
    required TaskLocalDataSource localDataSource,
    required TaskRemoteDataSource remoteDataSource,
    required SyncQueue syncQueue,
    Uuid? uuid,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _syncQueue = syncQueue,
        _uuid = uuid ?? const Uuid();

  Future<List<TaskModel>> getTasks() async {
    return await _localDataSource.getAllTasks();
  }

  Future<TaskModel> createTask({
    required String title,
    required String description,
  }) async {
    final now = DateTime.now();
    final task = TaskModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      localRevision: 1,
      serverRevision: 0,
      syncStatus: 'pending_create',
      isDeleted: false,
    );

    // Save locally first (Offline-First source of truth)
    await _localDataSource.saveTask(task);

    // Enqueue sync operation
    final syncOp = SyncOperationModel(
      operationId: _uuid.v4(),
      entityType: 'task',
      entityId: task.id,
      operationType: 'create',
      payload: task.toJson(),
      createdAt: now,
      nextRetryAt: now,
      status: 'pending',
      idempotencyKey: _uuid.v4(),
    );
    await _syncQueue.enqueue(syncOp);

    return task;
  }

  Future<TaskModel> updateTask(TaskModel task) async {
    final now = DateTime.now();
    final updated = task.copyWith(
      updatedAt: now,
      localRevision: task.localRevision + 1,
      syncStatus: 'pending_update',
    );

    await _localDataSource.saveTask(updated);

    final syncOp = SyncOperationModel(
      operationId: _uuid.v4(),
      entityType: 'task',
      entityId: updated.id,
      operationType: 'update',
      payload: updated.toJson(),
      createdAt: now,
      nextRetryAt: now,
      status: 'pending',
      idempotencyKey: _uuid.v4(),
    );
    await _syncQueue.enqueue(syncOp);

    return updated;
  }

  Future<void> deleteTask(String id) async {
    final task = await _localDataSource.getTaskById(id);
    if (task == null) return;

    final now = DateTime.now();
    await _localDataSource.deleteTask(id);

    final syncOp = SyncOperationModel(
      operationId: _uuid.v4(),
      entityType: 'task',
      entityId: id,
      operationType: 'delete',
      payload: {'id': id},
      createdAt: now,
      nextRetryAt: now,
      status: 'pending',
      idempotencyKey: _uuid.v4(),
    );
    await _syncQueue.enqueue(syncOp);
  }

  Future<void> syncOperationToServer(SyncOperationModel op) async {
    final task = await _localDataSource.getTaskById(op.entityId);

    if (op.operationType == 'create') {
      if (task != null) {
        final serverTask = await _remoteDataSource.createTaskRemote(task);
        await _localDataSource.saveTask(serverTask);
      }
    } else if (op.operationType == 'update') {
      if (task != null) {
        final serverTask = await _remoteDataSource.updateTaskRemote(task);
        await _localDataSource.saveTask(serverTask);
      }
    } else if (op.operationType == 'delete') {
      await _remoteDataSource.deleteTaskRemote(op.entityId);
      await _localDataSource.hardDeleteTask(op.entityId);
    }
  }

  Future<void> fetchAndMergeRemoteTasks() async {
    try {
      final remoteTasks = await _remoteDataSource.fetchRemoteTasks();
      for (final remoteTask in remoteTasks) {
        final localTask = await _localDataSource.getTaskById(remoteTask.id);
        if (localTask == null) {
          await _localDataSource.saveTask(remoteTask);
        } else if (localTask.syncStatus == 'synced') {
          // Resolve potential conflicts using ConflictResolver
          final resolved = ConflictResolver.resolveTaskConflict(
            localTask: localTask,
            serverTask: remoteTask,
          );
          await _localDataSource.saveTask(resolved);
        }
      }
    } catch (_) {
      // Ignore network fetch errors during background pull
    }
  }
}
