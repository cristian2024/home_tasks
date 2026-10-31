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
