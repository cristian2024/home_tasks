import 'package:core_utils/core_utils.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';

/// Mete un objeto dentro de otro, o lo saca de su contenedor con
/// `parentId: null`. Lo que contiene el objeto se mueve con él.
///
/// Registra `moved` en el objeto, `childRemoved` en el contenedor anterior y
/// `childAdded` en el nuevo. Si el contenedor no cambia, no escribe nada.
class MoveItem {
  const MoveItem(this._repository, this._ids, this._clock, this._policy);

  final HouseholdItemRepository _repository;
  final IdGenerator _ids;
  final Clock _clock;
  final ContainmentPolicy _policy;

  Future<HouseholdItem> call(String itemId, {required String? parentId}) async {
    final ItemTree tree = ItemTree(await _repository.getAll());
    final HouseholdItem item = tree[itemId] ?? (throw ItemNotFoundException(itemId));
    if (item.parentId == parentId) {
      return item;
    }

    HouseholdItem? newParent;
    if (parentId != null) {
      newParent = tree[parentId] ?? (throw ItemNotFoundException(parentId));
      if (parentId == itemId || tree.isInside(parentId, ancestorId: itemId)) {
        throw ItemContainmentCycleException(itemId: itemId, parentId: parentId);
      }
      if (!_policy.allows(parentDepth: tree.depthOf(parentId), subtreeHeight: tree.heightOf(itemId))) {
        throw ItemContainmentTooDeepException(_policy.maxDepth);
      }
    }
    final HouseholdItem? oldParent = item.parentId == null ? null : tree[item.parentId!];

    final DateTime now = _clock.nowUtc();
    final HouseholdItem moved = item.copyWith(parentId: () => parentId, updatedAt: now);
    await _repository.moveItem(moved, <ItemEvent>[
      ItemEvent(
        id: _ids.newId(),
        itemId: itemId,
        kind: ItemEventKind.moved,
        title: newParent?.name ?? '',
        description: newParent?.id ?? '',
        timestamp: now,
      ),
      if (oldParent != null)
        ItemEvent(
          id: _ids.newId(),
          itemId: oldParent.id,
          kind: ItemEventKind.childRemoved,
          title: item.name,
          description: item.id,
          timestamp: now,
        ),
      if (newParent != null)
        ItemEvent(
          id: _ids.newId(),
          itemId: newParent.id,
          kind: ItemEventKind.childAdded,
          title: item.name,
          description: item.id,
          timestamp: now,
        ),
    ]);
    return moved;
  }
}
