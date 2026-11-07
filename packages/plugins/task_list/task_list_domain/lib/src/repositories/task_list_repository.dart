import '../entities/household_task.dart';
import '../entities/task_category.dart';

/// Repositorio de la lista de tareas: tareas y categorías. Las operaciones
/// que escriben varias entidades son atómicas.
///
/// Los borrados son lógicos (spec §10.4.3): lo borrado no aparece en ninguna
/// consulta ni stream y no vuelve aunque se guarde otra vez con su ID.
abstract interface class TaskListRepository {
  /// Guarda una tarea nueva o reemplaza la que tenga su ID. Si esa tarea se
  /// borró, no hace nada.
  Future<void> saveTask(HouseholdTask task);

  Future<HouseholdTask?> getTask(String id);

  /// Todas las tareas, sin orden garantizado.
  Future<List<HouseholdTask>> getTasks();

  /// Todas las tareas al suscribirse y cada vez que cambian, sin orden
  /// garantizado.
  Stream<List<HouseholdTask>> watchTasks();

  /// Borra las tareas en [deletedAt], en una sola transacción. Los IDs que no
  /// existen se ignoran.
  Future<void> deleteTasks(List<String> ids, {required DateTime deletedAt});

  /// Guarda las categorías nuevas o reemplaza las que tengan su ID, en una
  /// sola transacción (p. ej. al reordenar). Las borradas se ignoran.
  Future<void> saveCategories(List<TaskCategory> categories);

  /// Categorías por `sortOrder`.
  Future<List<TaskCategory>> getCategories();

  /// Como [getCategories], al suscribirse y cada vez que cambian.
  Stream<List<TaskCategory>> watchCategories();

  /// Borra la categoría en [updatedAt] y la quita de las tareas que la tienen
  /// (con ese `updatedAt`), en una sola transacción. Si no existe, no hace
  /// nada.
  Future<void> deleteCategory(String id, {required DateTime updatedAt});

  /// Crea [defaults] solo la primera vez que se llama, aunque el usuario
  /// borre después todas las categorías. Devuelve si las creó.
  Future<bool> seedDefaultCategories(List<TaskCategory> defaults);
}
