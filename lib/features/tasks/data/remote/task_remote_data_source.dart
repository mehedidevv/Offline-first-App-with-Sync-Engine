import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../model/task_model.dart';

class TaskRemoteDataSource {
  final DioClient _dioClient;

  TaskRemoteDataSource({required DioClient dioClient}) : _dioClient = dioClient;

  Future<List<TaskModel>> fetchRemoteTasks() async {
    try {
      final response = await _dioClient.dio.get('/todos?_limit=20');
      final List data = response.data;
      return data.map((json) {
        return TaskModel(
          id: json['id'].toString(),
          title: json['title'] as String,
          description: 'Synced from server todo #${json['id']}',
          isCompleted: json['completed'] as bool,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now(),
          localRevision: 1,
          serverRevision: 1,
          syncStatus: 'synced',
          isDeleted: false,
          lastSyncedAt: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<TaskModel> createTaskRemote(TaskModel task) async {
    try {
      final response = await _dioClient.dio.post(
        '/todos',
        data: {
          'title': task.title,
          'completed': task.isCompleted,
          'userId': 1,
        },
      );
      final data = response.data;
      return task.copyWith(
        id: data['id']?.toString() ?? task.id,
        serverRevision: 1,
        localRevision: task.localRevision,
        syncStatus: 'synced',
        lastSyncedAt: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<TaskModel> updateTaskRemote(TaskModel task) async {
    try {
      await _dioClient.dio.put(
        '/todos/${task.id}',
        data: {
          'title': task.title,
          'completed': task.isCompleted,
        },
      );
      return task.copyWith(
        serverRevision: task.serverRevision + 1,
        syncStatus: 'synced',
        lastSyncedAt: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTaskRemote(String id) async {
    try {
      await _dioClient.dio.delete('/todos/$id');
    } catch (e) {
      rethrow;
    }
  }
}
