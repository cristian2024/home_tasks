/// Adaptador Isar de la lista de tareas. Quien compone la app solo elige
/// [TaskListIsar]; el plugin pide `TaskListRepository` al `ServiceLocator`
/// sin saber que detrás hay Isar.
library;

export 'src/task_list_isar.dart';
