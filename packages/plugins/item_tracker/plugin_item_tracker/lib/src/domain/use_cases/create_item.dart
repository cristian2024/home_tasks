import 'package:core_events/core_events.dart';
import 'package:core_utils/core_utils.dart';

import '../entities/household_item.dart';
import '../entities/item_event.dart';
import '../entities/physical_identifier.dart';
import '../errors/item_tracker_exception.dart';
import '../hierarchy/containment_policy.dart';
import '../hierarchy/item_tree.dart';
import '../item_validator.dart';
import '../repositories/household_item_repository.dart';
import '../value_objects/item_metadata.dart';

/// Identificador físico que se asocia al crear un objeto.
typedef IdentifierInput = ({String rawValue, IdentifierType type});

/// Crea un objeto, opcionalmente con su primer identificador y dentro de un
/// contenedor ([parentId]), registra los eventos técnicos y publica
/// [ItemCreatedCrossEvent].
class CreateItem {
  const CreateItem(this._repository, this._ids, this._clock, this._eventBus, [this._policy = const ContainmentPolicy()]);

  final HouseholdItemRepository _repository;
  final IdGenerator _ids;
  final Clock _clock;
  final EventBus _eventBus;
  final ContainmentPolicy _policy;

  Future<HouseholdItem> call({
    required String name,
    String description = '',
    Map<String, Object?> metadata = const <String, Object?>{},
    IdentifierInput? identifier,
    String? parentId,
  }) async {
    HouseholdItem? parent;
    if (parentId != null) {
      final ItemTree tree = ItemTree(await _repository.getAll());
      parent = tree[parentId] ?? (throw ItemNotFoundException(parentId));
      if (!_policy.allows(parentDepth: tree.depthOf(parentId), subtreeHeight: 1)) {
        throw ItemContainmentTooDeepException(_policy.maxDepth);
      }
    }

    final HouseholdItem item = HouseholdItem(
      id: _ids.newId(),
      name: ItemValidator.name(name),
      description: ItemValidator.description(description),
      metadata: ItemMetadata(metadata),
      createdAt: _clock.nowUtc(),
      updatedAt: _clock.nowUtc(),
      parentId: parent?.id,
    );

    PhysicalIdentifier? bound;
    if (identifier != null) {
      final String rawValue = ItemValidator.identifierValue(identifier.rawValue);
      final PhysicalIdentifier? existing = await _repository.findIdentifier(rawValue, identifier.type);
      if (existing != null) {
        throw IdentifierAlreadyBoundException(
          rawValue: rawValue,
          type: identifier.type,
          boundItemId: existing.itemId,
        );
      }
      bound = PhysicalIdentifier(
        id: _ids.newId(),
        rawValue: rawValue,
        type: identifier.type,
        itemId: item.id,
        boundAt: item.createdAt,
      );
    }

    await _repository.createItem(
      item,
      identifier: bound,
      events: <ItemEvent>[
        ItemEvent(
          id: _ids.newId(),
          itemId: item.id,
          kind: ItemEventKind.created,
          title: item.name,
          description: '',
          timestamp: item.createdAt,
        ),
        if (bound != null)
          ItemEvent(
            id: _ids.newId(),
            itemId: item.id,
            kind: ItemEventKind.identifierBound,
            title: bound.type.name,
            description: bound.rawValue,
            timestamp: item.createdAt,
          ),
        if (parent != null)
          ItemEvent(
            id: _ids.newId(),
            itemId: parent.id,
            kind: ItemEventKind.childAdded,
            title: item.name,
            description: item.id,
            timestamp: item.createdAt,
          ),
      ],
    );
    _eventBus.publish(ItemCreatedCrossEvent(itemId: item.id, itemName: item.name));
    return item;
  }
}
