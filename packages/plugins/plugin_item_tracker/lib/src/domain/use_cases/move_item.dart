import 'package:core_utils/core_utils.dart';

import '../entities/household_item.dart';
import '../entities/item_event.dart';
import '../errors/item_tracker_exception.dart';
import '../hierarchy/containment_policy.dart';
import '../hierarchy/item_tree.dart';
import '../repositories/household_item_repository.dart';

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
    final tree = ItemTree(await _repository.getAll());
    final item = tree[itemId] ?? (throw ItemNotFoundException(itemId));
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
    final oldParent = item.parentId == null ? null : tree[item.parentId!];

    final now = _clock.nowUtc();
    final moved = item.copyWith(parentId: () => parentId, updatedAt: now);
    await _repository.moveItem(moved, [
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
