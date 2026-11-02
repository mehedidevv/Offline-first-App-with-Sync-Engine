import '../../features/tasks/model/task_model.dart';

class ConflictResolver {
  /// Resolves conflict between local task and server task using Last Write Wins (LWW) and revision checks.
  static TaskModel resolveTaskConflict({
    required TaskModel localTask,
    required TaskModel serverTask,
  }) {
    // If server revision is higher or server updatedAt is newer, server wins by default.
    // However, if local has pending modifications not yet confirmed, we check revisions or timestamps.
    if (serverTask.serverRevision > localTask.serverRevision) {
      // Server wins: adopt server state while preserving sync status as synced
      return serverTask.copyWith(
        syncStatus: 'synced',
        localRevision: serverTask.serverRevision,
        serverRevision: serverTask.serverRevision,
      );
    } else if (localTask.localRevision > serverTask.serverRevision) {
      // Local wins: local changes take precedence, increment local revision and prepare push
      return localTask.copyWith(
        syncStatus: 'pending_update',
        serverRevision: serverTask.serverRevision,
      );
    } else {
      // Fallback to timestamp comparison (LWW)
      if (serverTask.updatedAt.isAfter(localTask.updatedAt)) {
        return serverTask.copyWith(
          syncStatus: 'synced',
          localRevision: serverTask.serverRevision,
          serverRevision: serverTask.serverRevision,
        );
      } else {
        return localTask.copyWith(
          syncStatus: 'pending_update',
        );
      }
    }
  }
}
