import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../shared/widgets/offline_indicator.dart';
import '../../../shared/widgets/sync_status_indicator.dart';
import '../controller/task_bloc.dart';
import '../controller/task_event.dart';
import '../controller/task_state.dart';
import '../model/task_model.dart';
import '../repository/task_repository.dart';

class TaskPage extends StatelessWidget {
  const TaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaskBloc(
        taskRepository: sl<TaskRepository>(),
        syncEngine: sl<SyncEngine>(),
      )..add(const LoadTasks()),
      child: const TaskView(),
    );
  }
}

class TaskView extends StatefulWidget {
  const TaskView({super.key});

  @override
  State<TaskView> createState() => _TaskViewState();
}

class _TaskViewState extends State<TaskView> {
  bool _hasConnection = true;
  String _selectedFilter = 'All'; // 'All', 'Active', 'Completed', 'Pending'

  @override
  void initState() {
    super.initState();
    _hasConnection = sl<ConnectivityService>().hasConnection;
    sl<ConnectivityService>().connectionChange.listen((hasConn) {
      if (mounted) {
        setState(() {
          _hasConnection = hasConn;
        });
        if (hasConn) {
          context.read<TaskBloc>().add(const SyncTasksEvent());
        }
      }
    });
  }

  void _showAddOrEditTaskDialog(BuildContext context, {TaskModel? task}) {
    final titleController = TextEditingController(text: task?.title ?? '');
    final descController = TextEditingController(text: task?.description ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 8,
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  task == null ? Icons.add_task : Icons.edit_note,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                task == null ? 'Create New Task' : 'Edit Task',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Task Title',
                      hintText: 'What needs to be done?',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a task title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Add extra details or notes...',
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 48),
                        child: Icon(Icons.description_outlined),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 2,
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  if (task == null) {
                    context.read<TaskBloc>().add(
                          CreateTaskEvent(
                            title: titleController.text.trim(),
                            description: descController.text.trim(),
                          ),
                        );
                  } else {
                    context.read<TaskBloc>().add(
                          UpdateTaskEvent(
                            task: task.copyWith(
                              title: titleController.text.trim(),
                              description: descController.text.trim(),
                            ),
                          ),
                        );
                  }
                  Navigator.pop(dialogContext);
                }
              },
              child: Text(task == null ? 'Create Task' : 'Save Changes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.cloud_sync, color: theme.colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 14),
            const Text(
              'SyncNest',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          BlocBuilder<TaskBloc, TaskState>(
            builder: (context, state) {
              final isSyncing = state is TaskLoaded && state.isSyncing;
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Center(
                  child: SyncStatusIndicator(
                    isSyncing: isSyncing,
                    onSyncPressed: () {
                      context.read<TaskBloc>().add(const SyncTasksEvent());
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          OfflineIndicator(hasConnection: _hasConnection),
          Expanded(
            child: BlocConsumer<TaskBloc, TaskState>(
              listener: (context, state) {
                if (state is TaskLoaded && state.message != null) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              state.message!,
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: theme.colorScheme.inverseSurface,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is TaskLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is TaskLoaded) {
                  final allTasks = state.tasks;
                  final completedCount = allTasks.where((t) => t.isCompleted).length;
                  final pendingSyncCount = allTasks.where((t) => t.syncStatus != 'synced').length;

                  // Filter tasks based on selection
                  final filteredTasks = allTasks.where((task) {
                    if (_selectedFilter == 'Active') return !task.isCompleted;
                    if (_selectedFilter == 'Completed') return task.isCompleted;
                    if (_selectedFilter == 'Pending') return task.syncStatus != 'synced';
                    return true;
                  }).toList();

                  return Column(
                    children: [
                      // Dashboard Stats Card
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Total', '${allTasks.length}', Icons.list_alt),
                            _buildDivider(),
                            _buildStatItem('Completed', '$completedCount', Icons.task_alt),
                            _buildDivider(),
                            _buildStatItem('Pending Sync', '$pendingSyncCount', Icons.cloud_queue),
                          ],
                        ),
                      ),

                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: ['All', 'Active', 'Completed', 'Pending'].map((filter) {
                            final isSelected = _selectedFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(filter),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedFilter = filter;
                                    });
                                  }
                                },
                                selectedColor: theme.colorScheme.primaryContainer,
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Task List
                      Expanded(
                        child: filteredTasks.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.folder_open, size: 70, color: Colors.grey.shade400),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No tasks found for "$_selectedFilter"',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                                itemCount: filteredTasks.length,
                                itemBuilder: (context, index) {
                                  final task = filteredTasks[index];
                                  Color statusColor;
                                  Color statusBgColor;
                                  IconData statusIcon;

                                  switch (task.syncStatus) {
                                    case 'synced':
                                      statusColor = Colors.green.shade700;
                                      statusBgColor = Colors.green.shade50;
                                      statusIcon = Icons.cloud_done;
                                      break;
                                    case 'pending_create':
                                    case 'pending_update':
                                      statusColor = Colors.amber.shade800;
                                      statusBgColor = Colors.amber.shade50;
                                      statusIcon = Icons.cloud_upload;
                                      break;
                                    case 'pending_delete':
                                      statusColor = Colors.red.shade700;
                                      statusBgColor = Colors.red.shade50;
                                      statusIcon = Icons.delete_outline;
                                      break;
                                    default:
                                      statusColor = Colors.blue.shade700;
                                      statusBgColor = Colors.blue.shade50;
                                      statusIcon = Icons.sync;
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: Dismissible(
                                      key: Key(task.id),
                                      background: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade600,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 24),
                                        child: const Icon(Icons.delete_forever, color: Colors.white, size: 28),
                                      ),
                                      direction: DismissDirection.endToStart,
                                      onDismissed: (_) {
                                        context.read<TaskBloc>().add(DeleteTaskEvent(id: task.id));
                                      },
                                      child: Card(
                                        elevation: 2,
                                        shadowColor: Colors.black.withValues(alpha: 0.08),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(16),
                                          onTap: () => _showAddOrEditTaskDialog(context, task: task),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Transform.scale(
                                                  scale: 1.1,
                                                  child: Checkbox(
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                    value: task.isCompleted,
                                                    onChanged: (val) {
                                                      context.read<TaskBloc>().add(
                                                            UpdateTaskEvent(
                                                              task: task.copyWith(isCompleted: val ?? false),
                                                            ),
                                                          );
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        task.title,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                                          color: task.isCompleted ? Colors.grey.shade500 : theme.colorScheme.onSurface,
                                                        ),
                                                      ),
                                                      if (task.description.isNotEmpty) ...[
                                                        const SizedBox(height: 6),
                                                        Text(
                                                          task.description,
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors.grey.shade600,
                                                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                                          ),
                                                        ),
                                                      ],
                                                      const SizedBox(height: 12),
                                                      Row(
                                                        children: [
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: statusBgColor,
                                                              borderRadius: BorderRadius.circular(20),
                                                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                Icon(statusIcon, size: 12, color: statusColor),
                                                                const SizedBox(width: 4),
                                                                Text(
                                                                  task.syncStatus.replaceAll('_', ' ').toUpperCase(),
                                                                  style: TextStyle(
                                                                    fontSize: 10,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: statusColor,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const Spacer(),
                                                          Text(
                                                            'Rev v${task.localRevision}',
                                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                } else if (state is TaskError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 60, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Something went wrong',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditTaskDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Task', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        elevation: 6,
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 35,
      width: 1,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }
}
