import 'domain/use_cases/category_use_cases.dart';
import 'domain/use_cases/completion_use_cases.dart';
import 'domain/use_cases/list_queries.dart';
import 'domain/use_cases/task_use_cases.dart';

/// Todo lo que necesitan las pantallas del plugin. El plugin lo registra en
/// su scope de `core_di` durante `initialize()`.
class TaskListDependencies {
  const TaskListDependencies({
    required this.createTask,
    required this.updateTask,
    required this.getTask,
    required this.deleteTasks,
    required this.completeTask,
    required this.undoCompletion,
    required this.reopenTask,
    required this.clearDone,
    required this.createCategory,
    required this.renameCategory,
    required this.countCategoryUsage,
    required this.deleteCategory,
    required this.reorderCategories,
    required this.watchList,
    required this.watchCategories,
    required this.today,
  });

  final CreateTask createTask;
  final UpdateTask updateTask;
  final GetTask getTask;
  final DeleteTasks deleteTasks;
  final CompleteTask completeTask;
  final UndoTaskCompletion undoCompletion;
  final ReopenTask reopenTask;
  final ClearDoneTasks clearDone;
  final CreateTaskCategory createCategory;
  final RenameTaskCategory renameCategory;
  final CountTaskCategoryUsage countCategoryUsage;
  final DeleteTaskCategory deleteCategory;
  final ReorderTaskCategories reorderCategories;
  final WatchTaskList watchList;
  final WatchTaskCategories watchCategories;

  /// El día local de hoy, del `Clock`.
  final DateTime Function() today;
}
