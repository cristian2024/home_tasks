import 'package:core_utils/core_utils.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';

/// Nombre visible de una categoría en el idioma actual (las por defecto se
/// traducen por su clave).
typedef ShoppingCategoryNamer = String Function(ShoppingCategory category);

/// Lanza [ShoppingCategoryNameTakenException] si otra categoría (distinta de
/// [exceptId]) ya se llama [name], sin distinguir mayúsculas.
Future<void> _checkNameFree(
  ShoppingListRepository repository,
  ShoppingCategoryNamer namer,
  String name, {
  String? exceptId,
}) async {
  final String key = ShoppingValidator.normalize(name);
  for (final ShoppingCategory category in await repository.getCategories()) {
    if (category.id != exceptId && ShoppingValidator.normalize(namer(category)) == key) {
      throw ShoppingCategoryNameTakenException(name);
    }
  }
}

/// Crea una categoría al final de la lista.
class CreateShoppingCategory {
  const CreateShoppingCategory(this._repository, this._ids, this._namer);

  final ShoppingListRepository _repository;
  final IdGenerator _ids;
  final ShoppingCategoryNamer _namer;

  Future<ShoppingCategory> call(String name) async {
    final String validName = ShoppingValidator.categoryName(name);
    await _checkNameFree(_repository, _namer, validName);
    final List<ShoppingCategory> categories = await _repository.getCategories();
    final ShoppingCategory category = ShoppingCategory(
      id: _ids.newId(),
      name: validName,
      sortOrder: categories.isEmpty ? 0 : categories.last.sortOrder + 1,
    );
    await _repository.saveCategories(<ShoppingCategory>[category]);
    return category;
  }
}

class RenameShoppingCategory {
  const RenameShoppingCategory(this._repository, this._namer);

  final ShoppingListRepository _repository;
  final ShoppingCategoryNamer _namer;

  Future<ShoppingCategory> call(String categoryId, String name) async {
    final ShoppingCategory current = await _category(_repository, categoryId);
    final String validName = ShoppingValidator.categoryName(name);
    if (validName == _namer(current)) {
      return current;
    }
    await _checkNameFree(_repository, _namer, validName, exceptId: categoryId);
    final ShoppingCategory renamed = current.copyWith(name: validName);
    await _repository.saveCategories(<ShoppingCategory>[renamed]);
    return renamed;
  }
}

Future<ShoppingCategory> _category(ShoppingListRepository repository, String categoryId) async {
  for (final ShoppingCategory category in await repository.getCategories()) {
    if (category.id == categoryId) {
      return category;
    }
  }
  throw ShoppingCategoryNotFoundException(categoryId);
}

/// Cuántos items usan una categoría (para avisar antes de borrarla).
class CountShoppingCategoryUsage {
  const CountShoppingCategoryUsage(this._repository);

  final ShoppingListRepository _repository;

  Future<int> call(String categoryId) async =>
      (await _repository.getItems()).where((ShoppingItem item) => item.categoryIds.contains(categoryId)).length;
}

/// Borra una categoría y la quita de sus items, que conservan las demás.
class DeleteShoppingCategory {
  const DeleteShoppingCategory(this._repository, this._clock);

  final ShoppingListRepository _repository;
  final Clock _clock;

  Future<void> call(String categoryId) async {
    await _category(_repository, categoryId);
    await _repository.deleteCategory(categoryId, updatedAt: _clock.nowUtc());
  }
}

/// Guarda el orden nuevo. [orderedIds] debe tener exactamente los IDs de
/// todas las categorías.
class ReorderShoppingCategories {
  const ReorderShoppingCategories(this._repository);

  final ShoppingListRepository _repository;

  Future<void> call(List<String> orderedIds) async {
    final Map<String, ShoppingCategory> byId = <String, ShoppingCategory>{
      for (final ShoppingCategory category in await _repository.getCategories()) category.id: category,
    };
    if (orderedIds.length != byId.length || !byId.keys.toSet().containsAll(orderedIds)) {
      throw ArgumentError.value(orderedIds, 'orderedIds', 'Debe contener exactamente los IDs de todas las categorías');
    }
    await _repository.saveCategories(<ShoppingCategory>[
      for (int i = 0; i < orderedIds.length; i++) byId[orderedIds[i]]!.copyWith(sortOrder: i),
    ]);
  }
}

/// Crea las categorías por defecto la primera vez.
class EnsureDefaultShoppingCategories {
  const EnsureDefaultShoppingCategories(this._repository, this._ids);

  final ShoppingListRepository _repository;
  final IdGenerator _ids;

  Future<bool> call() => _repository.seedDefaultCategories(<ShoppingCategory>[
        for (final DefaultShoppingCategory category in DefaultShoppingCategory.values)
          ShoppingCategory(id: _ids.newId(), defaultKey: category.key, sortOrder: category.index),
      ]);
}
