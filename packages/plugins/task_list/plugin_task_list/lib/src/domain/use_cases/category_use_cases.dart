import 'package:core_utils/core_utils.dart';
import 'package:task_list_domain/task_list_domain.dart';

/// Nombre visible de una categoría en el idioma actual (las por defecto se
/// traducen por su clave).
typedef TaskCategoryNamer = String Function(TaskCategory category);

/// Lanza [TaskCategoryNameTakenException] si otra categoría (distinta de
/// [exceptId]) ya se llama [name], sin distinguir mayúsculas.
Future<void> _checkNameFree(
  TaskListRepository repository,
  TaskCategoryNamer namer,
  String name, {
  String? exceptId,
}) async {
  if (ListCategories.isNameTaken(await repository.getCategories(), name, nameOf: namer, exceptId: exceptId)) {
    throw TaskCategoryNameTakenException(name);
  }
}

Future<TaskCategory> _category(TaskListRepository repository, String categoryId) async {
  for (final TaskCategory category in await repository.getCategories()) {
    if (category.id == categoryId) {
      return category;
    }
  }
  throw TaskCategoryNotFoundException(categoryId);
}

/// Crea una categoría al final de la lista.
class CreateTaskCategory {
  const CreateTaskCategory(this._repository, this._ids, this._namer);

  final TaskListRepository _repository;
  final IdGenerator _ids;
  final TaskCategoryNamer _namer;

  Future<TaskCategory> call(String name) async {
    final String validName = TaskValidator.categoryName(name);
    await _checkNameFree(_repository, _namer, validName);
    final TaskCategory category = TaskCategory(
      id: _ids.newId(),
      name: validName,
      sortOrder: ListCategories.nextSortOrder(await _repository.getCategories()),
    );
    await _repository.saveCategories(<TaskCategory>[category]);
    return category;
  }
}

class RenameTaskCategory {
  const RenameTaskCategory(this._repository, this._namer);

  final TaskListRepository _repository;
  final TaskCategoryNamer _namer;

  Future<TaskCategory> call(String categoryId, String name) async {
    final TaskCategory current = await _category(_repository, categoryId);
    final String validName = TaskValidator.categoryName(name);
    if (validName == _namer(current)) {
      return current;
    }
    await _checkNameFree(_repository, _namer, validName, exceptId: categoryId);
    final TaskCategory renamed = current.copyWith(name: validName);
    await _repository.saveCategories(<TaskCategory>[renamed]);
    return renamed;
  }
}

/// Cuántas tareas usan una categoría (para avisar antes de borrarla).
class CountTaskCategoryUsage {
  const CountTaskCategoryUsage(this._repository);

  final TaskListRepository _repository;

  Future<int> call(String categoryId) async =>
      (await _repository.getTasks()).where((HouseholdTask task) => task.categoryIds.contains(categoryId)).length;
}

/// Borra una categoría y la quita de sus tareas, que conservan las demás.
class DeleteTaskCategory {
  const DeleteTaskCategory(this._repository, this._clock);

  final TaskListRepository _repository;
  final Clock _clock;

  Future<void> call(String categoryId) async {
    await _category(_repository, categoryId);
    await _repository.deleteCategory(categoryId, updatedAt: _clock.nowUtc());
  }
}

/// Guarda el orden nuevo. [orderedIds] debe tener exactamente los IDs de
/// todas las categorías.
class ReorderTaskCategories {
  const ReorderTaskCategories(this._repository);

  final TaskListRepository _repository;

  Future<void> call(List<String> orderedIds) async =>
      _repository.saveCategories(ListCategories.reordered(await _repository.getCategories(), orderedIds));
}

/// Crea las categorías por defecto la primera vez.
class EnsureDefaultTaskCategories {
  const EnsureDefaultTaskCategories(this._repository, this._ids);

  final TaskListRepository _repository;
  final IdGenerator _ids;

  Future<bool> call() => _repository.seedDefaultCategories(<TaskCategory>[
        for (final DefaultTaskCategory category in DefaultTaskCategory.values)
          TaskCategory(id: _ids.newId(), defaultKey: category.key, sortOrder: category.index),
      ]);
}
