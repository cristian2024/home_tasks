/// Errores de negocio de la lista de tareas. Es `sealed` para que la
/// presentación los trate todos de forma exhaustiva.
sealed class TaskListException implements Exception {
  const TaskListException();
}

final class TaskNotFoundException extends TaskListException {
  const TaskNotFoundException(this.taskId);

  final String taskId;

  @override
  String toString() => 'TaskNotFoundException($taskId)';
}

final class TaskCategoryNotFoundException extends TaskListException {
  const TaskCategoryNotFoundException(this.categoryId);

  final String categoryId;

  @override
  String toString() => 'TaskCategoryNotFoundException($categoryId)';
}

/// Ya hay una categoría con ese nombre (sin distinguir mayúsculas).
final class TaskCategoryNameTakenException extends TaskListException {
  const TaskCategoryNameTakenException(this.name);

  final String name;

  @override
  String toString() => 'TaskCategoryNameTakenException($name)';
}

enum TaskValidationField { title, categoryName }

enum TaskValidationReason { empty, tooLong }

final class TaskValidationException extends TaskListException {
  const TaskValidationException(this.field, this.reason);

  final TaskValidationField field;
  final TaskValidationReason reason;

  @override
  String toString() => 'TaskValidationException(${field.name}, ${reason.name})';
}
