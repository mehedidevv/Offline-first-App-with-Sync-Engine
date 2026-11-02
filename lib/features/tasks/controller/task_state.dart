import 'package:equatable/equatable.dart';
import '../model/task_model.dart';

abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {
  const TaskInitial();
}

class TaskLoading extends TaskState {
  const TaskLoading();
}

class TaskLoaded extends TaskState {
  final List<TaskModel> tasks;
  final bool isSyncing;
  final String? message;

  const TaskLoaded({
    required this.tasks,
    this.isSyncing = false,
    this.message,
  });

  TaskLoaded copyWith({
    List<TaskModel>? tasks,
    bool? isSyncing,
    String? message,
  }) {
    return TaskLoaded(
      tasks: tasks ?? this.tasks,
      isSyncing: isSyncing ?? this.isSyncing,
      message: message,
    );
  }

  @override
  List<Object?> get props => [tasks, isSyncing, message];
}

class TaskError extends TaskState {
  final String message;

  const TaskError({required this.message});

  @override
  List<Object?> get props => [message];
}
