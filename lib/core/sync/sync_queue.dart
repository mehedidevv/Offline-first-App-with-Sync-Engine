import 'package:hive/hive.dart';
import '../../features/tasks/model/sync_operation_model.dart';
import '../database/hive_service.dart';

class SyncQueue {
  Box<SyncOperationModel> get _box => HiveService.getSyncQueueBox();

  Future<void> enqueue(SyncOperationModel operation) async {
    // Prevent duplicate pending operation for same entity and type if already queued
    final existingIndex = _box.values.toList().indexWhere(
          (op) => op.entityId == operation.entityId && op.operationType == operation.operationType && op.status == 'pending',
        );

    if (existingIndex != -1) {
      // Update existing operation payload/timestamp instead of duplicating
      final existingKey = _box.keyAt(existingIndex);
      await _box.put(existingKey, operation);
    } else {
      await _box.put(operation.operationId, operation);
    }
  }

  List<SyncOperationModel> getPendingOperations() {
    final now = DateTime.now();
    return _box.values
        .where((op) => op.status == 'pending' && op.nextRetryAt.isBefore(now))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  List<SyncOperationModel> getAllOperations() {
    return _box.values.toList();
  }

  Future<void> updateOperation(SyncOperationModel operation) async {
    await _box.put(operation.operationId, operation);
  }

  Future<void> removeOperation(String operationId) async {
    await _box.delete(operationId);
  }

  Future<void> clearQueue() async {
    await _box.clear();
  }
}
