import 'package:core_utils/core_utils.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';

/// Crea un item pendiente. Valida los textos y que sus categorías existan.
class CreateShoppingItem {
  const CreateShoppingItem(this._repository, this._ids, this._clock);

  final ShoppingListRepository _repository;
  final IdGenerator _ids;
  final Clock _clock;

  Future<ShoppingItem> call({
    required String name,
    String notes = '',
    String quantity = '',
    Urgency urgency = Urgency.normal,
    List<String> categoryIds = const <String>[],
    Recurrence? recurrence,
  }) async {
    final DateTime now = _clock.nowUtc();
    final ShoppingItem item = ShoppingItem(
      id: _ids.newId(),
      name: ShoppingValidator.name(name),
      notes: ShoppingValidator.notes(notes),
      quantity: ShoppingValidator.quantity(quantity),
      urgency: urgency,
      status: ShoppingItemStatus.pending,
      categoryIds: await checkCategories(_repository, categoryIds),
      recurrence: recurrence,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.saveItem(item);
    return item;
  }
}

/// [categoryIds] sin repetir. Lanza [ShoppingCategoryNotFoundException] si
/// alguna no existe.
Future<List<String>> checkCategories(ShoppingListRepository repository, List<String> categoryIds) async {
  final Set<String> unique = categoryIds.toSet();
  if (unique.isEmpty) {
    return const <String>[];
  }
  final Set<String> existing = <String>{
    for (final ShoppingCategory category in await repository.getCategories()) category.id,
  };
  for (final String id in unique) {
    if (!existing.contains(id)) {
      throw ShoppingCategoryNotFoundException(id);
    }
  }
  return List<String>.unmodifiable(unique);
}

/// Edita un item. Si nada cambia no escribe.
class UpdateShoppingItem {
  const UpdateShoppingItem(this._repository, this._clock);

  final ShoppingListRepository _repository;
  final Clock _clock;

  Future<ShoppingItem> call(
    String itemId, {
    String? name,
    String? notes,
    String? quantity,
    Urgency? urgency,
    List<String>? categoryIds,
    Recurrence? Function()? recurrence,
  }) async {
    final ShoppingItem current = await getShoppingItem(_repository, itemId);
    final ShoppingItem changed = current.copyWith(
      name: name == null ? null : ShoppingValidator.name(name),
      notes: notes == null ? null : ShoppingValidator.notes(notes),
      quantity: quantity == null ? null : ShoppingValidator.quantity(quantity),
      urgency: urgency,
      categoryIds: categoryIds == null ? null : await checkCategories(_repository, categoryIds),
      recurrence: recurrence,
    );
    if (changed == current) {
      return current;
    }
    final ShoppingItem updated = changed.copyWith(updatedAt: _clock.nowUtc());
    await _repository.saveItem(updated);
    return updated;
  }
}

/// El item [itemId]. Lanza [ShoppingItemNotFoundException] si no existe.
Future<ShoppingItem> getShoppingItem(ShoppingListRepository repository, String itemId) async =>
    await repository.getItem(itemId) ?? (throw ShoppingItemNotFoundException(itemId));

class GetShoppingItem {
  const GetShoppingItem(this._repository);

  final ShoppingListRepository _repository;

  /// Lanza [ShoppingItemNotFoundException] si no existe.
  Future<ShoppingItem> call(String itemId) => getShoppingItem(_repository, itemId);
}

/// Borra items y su historial.
class DeleteShoppingItems {
  const DeleteShoppingItems(this._repository, [this._clock = const SystemClock()]);

  final ShoppingListRepository _repository;
  final Clock _clock;

  Future<void> call(List<String> itemIds) => _repository.deleteItems(itemIds, deletedAt: _clock.nowUtc());
}

/// Vuelve a crear un item borrado, para «Deshacer». Lo borrado no vuelve con
/// su ID (así un borrado gana a una edición hecha a la vez en otro
/// dispositivo), de modo que se crea uno nuevo con los mismos datos. Las
/// categorías que ya no existen se quitan; el historial de compras no vuelve.
class RestoreShoppingItem {
  const RestoreShoppingItem(this._repository, this._ids, this._clock);

  final ShoppingListRepository _repository;
  final IdGenerator _ids;
  final Clock _clock;

  Future<ShoppingItem> call(ShoppingItem deleted) async {
    final DateTime now = _clock.nowUtc();
    final Set<String> existing = <String>{
      for (final ShoppingCategory category in await _repository.getCategories()) category.id,
    };
    final ShoppingItem restored = ShoppingItem(
      id: _ids.newId(),
      name: deleted.name,
      notes: deleted.notes,
      quantity: deleted.quantity,
      urgency: deleted.urgency,
      status: deleted.status,
      categoryIds: <String>[
        for (final String id in deleted.categoryIds)
          if (existing.contains(id)) id,
      ],
      recurrence: deleted.recurrence,
      lastPurchasedAt: deleted.lastPurchasedAt,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.saveItem(restored);
    return restored;
  }
}

/// Devuelve un item al estado en que estaba (p. ej. al deshacer «volver a
/// pendiente»). Si se borró mientras tanto, no hace nada.
class RevertShoppingItem {
  const RevertShoppingItem(this._repository, this._clock);

  final ShoppingListRepository _repository;
  final Clock _clock;

  Future<void> call(ShoppingItem previous) => _repository.saveItem(previous.copyWith(updatedAt: _clock.nowUtc()));
}
