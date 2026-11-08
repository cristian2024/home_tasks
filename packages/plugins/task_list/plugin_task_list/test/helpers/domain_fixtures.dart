import 'package:core_utils/core_utils.dart';
import 'package:plugin_task_list/plugin_task_list.dart';
import 'package:plugin_task_list/testing.dart';

/// Viernes 6 de noviembre de 2026, a mediodía UTC: el mismo día local en
/// cualquier zona entre UTC-11 y UTC+11.
final DateTime t0 = DateTime.utc(2026, 11, 6, 12);

class TestIds implements IdGenerator {
  int _next = 1;

  @override
  String newId() => 'id-${_next++}';
}

/// Nombre de categoría para los tests: el propio o la clave por defecto.
String testCategoryName(TaskCategory category) => category.name ?? category.defaultKey!;

/// Casos de uso reales sobre un repositorio en memoria.
class TestUseCases {
  final InMemoryTaskListRepository repository = InMemoryTaskListRepository();
  final TestIds ids = TestIds();
  final FixedClock clock = FixedClock(t0);

  CreateTask get createTask => CreateTask(repository, ids, clock);
  UpdateTask get updateTask => UpdateTask(repository, clock);
  GetTask get getTask => GetTask(repository);
  DeleteTasks get deleteTasks => DeleteTasks(repository, clock);
  CompleteTask get completeTask => CompleteTask(repository, clock);
  UndoTaskCompletion get undoCompletion => UndoTaskCompletion(repository, clock);
  ReopenTask get reopenTask => ReopenTask(repository, clock);
  ClearDoneTasks get clearDone => ClearDoneTasks(repository, clock);
  CreateTaskCategory get createCategory => CreateTaskCategory(repository, ids, testCategoryName);
  RenameTaskCategory get renameCategory => RenameTaskCategory(repository, testCategoryName);
  CountTaskCategoryUsage get countUsage => CountTaskCategoryUsage(repository);
  DeleteTaskCategory get deleteCategory => DeleteTaskCategory(repository, clock);
  ReorderTaskCategories get reorder => ReorderTaskCategories(repository);
  EnsureDefaultTaskCategories get ensureDefaults => EnsureDefaultTaskCategories(repository, ids);
  WatchTaskList get watchList => WatchTaskList(repository, clock);
  WatchTaskCategories get watchCategories => WatchTaskCategories(repository);
}
