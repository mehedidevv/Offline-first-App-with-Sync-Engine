import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';
import '../network/connectivity_service.dart';
import '../sync/sync_queue.dart';
import '../sync/sync_engine.dart';
import '../../features/tasks/data/local/task_local_data_source.dart';
import '../../features/tasks/data/remote/task_remote_data_source.dart';
import '../../features/tasks/repository/task_repository.dart';

final GetIt sl = GetIt.instance;

void setupServiceLocator() {
  // Core
  sl.registerLazySingleton<DioClient>(() => DioClient());
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService(dio: sl<DioClient>().dio));
  sl.registerLazySingleton<SyncQueue>(() => SyncQueue());

  // Data Sources
  sl.registerLazySingleton<TaskLocalDataSource>(() => TaskLocalDataSource());
  sl.registerLazySingleton<TaskRemoteDataSource>(() => TaskRemoteDataSource(dioClient: sl<DioClient>()));

  // Repository
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepository(
      localDataSource: sl<TaskLocalDataSource>(),
      remoteDataSource: sl<TaskRemoteDataSource>(),
      syncQueue: sl<SyncQueue>(),
    ),
  );

  // Sync Engine
  sl.registerLazySingleton<SyncEngine>(
    () => SyncEngine(
      syncQueue: sl<SyncQueue>(),
      taskRepository: sl<TaskRepository>(),
      connectivityService: sl<ConnectivityService>(),
    ),
  );
}
