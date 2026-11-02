import 'package:equatable/equatable.dart';
import '../model/task_model.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class LoadTasks extends TaskEvent {
  const LoadTasks();
}

class CreateTaskEvent extends TaskEvent {
  final String title;
  final String description;

  const CreateTaskEvent({required this.title, required this.description});

  @override
  List<Object?> get props => [title, description];
}

class UpdateTaskEvent extends TaskEvent {
  final TaskModel task;

  const UpdateTaskEvent({required this.task});

  @override
  List<Object?> get props => [task];
}

class DeleteTaskEvent extends TaskEvent {
  final String id;

  const DeleteTaskEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

class SyncTasksEvent extends TaskEvent {
  const SyncTasksEvent();
}
