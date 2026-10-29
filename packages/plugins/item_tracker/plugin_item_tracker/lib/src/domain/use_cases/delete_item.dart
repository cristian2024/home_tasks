import 'package:core_utils/core_utils.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';

/// Qué pasa con lo que contiene un objeto al borrarlo.
enum DeletedContents {
  /// Su contenido directo sale al contenedor del objeto borrado (o queda
  /// suelto si no estaba dentro de ninguno), con todo lo que contiene.
  moveToParent,

  /// Se borra con él, a cualquier profundidad.
  deleteAll,
}

/// Borra un objeto con borrado lógico (spec §10.3). Sus identificadores, y
/// los de lo que se borre con él, quedan libres.
///
/// Registra `childRemoved` en su contenedor. Con
/// [DeletedContents.moveToParent], cada objeto que sale registra `moved` y el
/// contenedor que lo recibe, `childAdded`.
class DeleteItem {
  const DeleteItem(this._repository, this._ids, this._clock);

  final HouseholdItemRepository _repository;
  final IdGenerator _ids;
  final Clock _clock;

  Future<void> call(String itemId, {required DeletedContents contents}) async {
    final ItemTree tree = ItemTree(await _repository.getAll());
    final HouseholdItem item = tree[itemId] ?? (throw ItemNotFoundException(itemId));
    final HouseholdItem? parent = item.parentId == null ? null : tree[item.parentId!];
    final DateTime now = _clock.nowUtc();

    ItemEvent event(String itemId, ItemEventKind kind, HouseholdItem? subject) => ItemEvent(
          id: _ids.newId(),
          itemId: itemId,
          kind: kind,
          title: subject?.name ?? '',
          description: subject?.id ?? '',
          timestamp: now,
        );

    final List<String> deleted = <String>[itemId];
    final List<HouseholdItem> moved = <HouseholdItem>[];
    final List<ItemEvent> events = <ItemEvent>[
      if (parent != null) event(parent.id, ItemEventKind.childRemoved, item),
    ];
    switch (contents) {
      case DeletedContents.deleteAll:
        deleted.addAll(tree.descendantsOf(itemId).map((HouseholdItem descendant) => descendant.id));
      case DeletedContents.moveToParent:
        for (final HouseholdItem child in tree.childrenOf(itemId)) {
          moved.add(child.copyWith(parentId: () => parent?.id, updatedAt: now));
          events.add(event(child.id, ItemEventKind.moved, parent));
          if (parent != null) {
            events.add(event(parent.id, ItemEventKind.childAdded, child));
          }
        }
    }

    await _repository.deleteItems(deleted, deletedAt: now, moved: moved, events: events);
  }
}
