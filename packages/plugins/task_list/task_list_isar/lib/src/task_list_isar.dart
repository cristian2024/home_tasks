import 'package:core_di/core_di.dart';
import 'package:core_sync/core_sync.dart';
import 'package:storage_isar/adapter.dart';
import 'package:task_list_domain/task_list_domain.dart';

import 'models/isar_task.dart';
import 'models/isar_task_category.dart';
import 'models/isar_task_list_flag.dart';
import 'models/isar_task_list_synced.dart';
import 'repositories/isar_task_list_repository.dart';

/// Adaptador Isar de la lista de tareas. Quien compone la app solo lo elige,
/// dentro de `IsarStorage(features: <IsarFeature>[TaskListIsar()])`, también
/// si el plugin está desactivado.
///
/// Con la base abierta registra `TaskListRepository` en el `ServiceLocator` y
/// añade su `TaskListSyncParticipant` a `SyncParticipants`, en el scope raíz:
/// un plugin desactivado sigue recibiendo sus cambios. Si la app no compuso
/// la sincronización, no se registra nada en el log.
class TaskListIsar implements IsarFeature {
  const TaskListIsar();

  @override
  List<CollectionSchema<dynamic>> get schemas => const <CollectionSchema<dynamic>>[
        IsarTaskSchema,
        IsarTaskCategorySchema,
        IsarTaskListFlagSchema,
        IsarTaskListSyncedSchema,
      ];

  @override
  void register(ServiceLocator services, Isar isar) {
    final IsarTaskListRepository repository = IsarTaskListRepository(isar, services: services);
    services.registerSingleton<TaskListRepository>(repository);
    SyncParticipants.of(services).add(TaskListSyncParticipant(store: repository));
  }
}
