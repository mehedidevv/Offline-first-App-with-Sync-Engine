import 'package:flutter/foundation.dart';
import '../../features/tasks/repository/task_repository.dart';
import '../network/connectivity_service.dart';
import 'retry_policy.dart';
import 'sync_queue.dart';

class SyncEngine {
  final SyncQueue _syncQueue;
  final TaskRepository _taskRepository;
  final ConnectivityService _connectivityService;

  bool _isSyncing = false;

  SyncEngine({
    required SyncQueue syncQueue,
    required TaskRepository taskRepository,
    required ConnectivityService connectivityService,
  })  : _syncQueue = syncQueue,
        _taskRepository = taskRepository,
        _connectivityService = connectivityService;

  bool get isSyncing => _isSyncing;

  Future<void> sync() async {
    if (_isSyncing) return;

    final hasConn = await _connectivityService.checkConnectivityNow();
    if (!hasConn) {
      debugPrint('SyncEngine: Offline. Skipping sync.');
      return;
    }

    _isSyncing = true;
    try {
      final pendingOps = _syncQueue.getPendingOperations();
      if (pendingOps.isEmpty) {
        await _taskRepository.fetchAndMergeRemoteTasks();
        _isSyncing = false;
        return;
      }

      for (final op in pendingOps) {
        try {
          await _syncQueue.updateOperation(op.copyWith(status: 'processing'));

          if (op.entityType == 'task') {
            await _taskRepository.syncOperationToServer(op);
          }

          await _syncQueue.removeOperation(op.operationId);
        } catch (e) {
          debugPrint('SyncEngine: Failed to sync operation ${op.operationId}: $e');
          final newRetryCount = op.retryCount + 1;
          if (RetryPolicy.shouldRetry(newRetryCount, e)) {
            final nextRetry = RetryPolicy.calculateNextRetryTime(newRetryCount);
            await _syncQueue.updateOperation(
              op.copyWith(
                status: 'pending',
                retryCount: newRetryCount,
                nextRetryAt: nextRetry,
              ),
            );
          } else {
            await _syncQueue.updateOperation(
              op.copyWith(
                status: 'failed',
                retryCount: newRetryCount,
              ),
            );
          }
        }
      }

      await _taskRepository.fetchAndMergeRemoteTasks();
    } catch (e) {
      debugPrint('SyncEngine error: $e');
    } finally {
      _isSyncing = false;
    }
  }
}
