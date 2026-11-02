import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/sync/sync_engine.dart';
import '../repository/task_repository.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository _taskRepository;
  final SyncEngine _syncEngine;

  TaskBloc({
    required TaskRepository taskRepository,
    required SyncEngine syncEngine,
  })  : _taskRepository = taskRepository,
        _syncEngine = syncEngine,
        super(const TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<CreateTaskEvent>(_onCreateTask);
    on<UpdateTaskEvent>(_onUpdateTask);
    on<DeleteTaskEvent>(_onDeleteTask);
    on<SyncTasksEvent>(_onSyncTasks);
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    emit(const TaskLoading());
    try {
      final tasks = await _taskRepository.getTasks();
      emit(TaskLoaded(tasks: tasks, isSyncing: _syncEngine.isSyncing));
      
      add(const SyncTasksEvent());
    } catch (e) {
      emit(TaskError(message: e.toString()));
    }
  }

  Future<void> _onCreateTask(CreateTaskEvent event, Emitter<TaskState> emit) async {
    final currentState = state;
    if (currentState is TaskLoaded) {
      try {
        await _taskRepository.createTask(
          title: event.title,
          description: event.description,
        );
        final tasks = await _taskRepository.getTasks();
        emit(currentState.copyWith(tasks: tasks, message: 'Task created offline successfully'));
        
        add(const SyncTasksEvent());
      } catch (e) {
        emit(TaskError(message: e.toString()));
      }
    }
  }

  Future<void> _onUpdateTask(UpdateTaskEvent event, Emitter<TaskState> emit) async {
    final currentState = state;
    if (currentState is TaskLoaded) {
      try {
        await _taskRepository.updateTask(event.task);
        final tasks = await _taskRepository.getTasks();
        emit(currentState.copyWith(tasks: tasks, message: 'Task updated offline'));
        
        add(const SyncTasksEvent());
      } catch (e) {
        emit(TaskError(message: e.toString()));
      }
    }
  }

  Future<void> _onDeleteTask(DeleteTaskEvent event, Emitter<TaskState> emit) async {
    final currentState = state;
    if (currentState is TaskLoaded) {
      try {
        await _taskRepository.deleteTask(event.id);
        final tasks = await _taskRepository.getTasks();
        emit(currentState.copyWith(tasks: tasks, message: 'Task deleted offline'));
        
        add(const SyncTasksEvent());
      } catch (e) {
        emit(TaskError(message: e.toString()));
      }
    }
  }

  Future<void> _onSyncTasks(SyncTasksEvent event, Emitter<TaskState> emit) async {
    final currentState = state;
    if (currentState is TaskLoaded) {
      emit(currentState.copyWith(isSyncing: true));
      try {
        await _syncEngine.sync();
        final tasks = await _taskRepository.getTasks();
        emit(currentState.copyWith(tasks: tasks, isSyncing: false, message: 'Synchronization completed'));
      } catch (e) {
        final tasks = await _taskRepository.getTasks();
        emit(currentState.copyWith(tasks: tasks, isSyncing: false, message: 'Sync failed: $e'));
      }
    }
  }
}
