/// Rutas del plugin. Son absolutas y planas para que la app las añada tal
/// cual a su `GoRouter`.
abstract final class TaskListRoutes {
  static const String base = '/task-list';
  static const String create = '$base/task/new';
  static const String editPattern = '$base/task/:id/edit';
  static const String done = '$base/done';
  static const String categories = '$base/categories';

  /// Editar [taskId]. Al guardar hace `pop` con su ID.
  static String edit(String taskId) => '$base/task/${Uri.encodeComponent(taskId)}/edit';
}
