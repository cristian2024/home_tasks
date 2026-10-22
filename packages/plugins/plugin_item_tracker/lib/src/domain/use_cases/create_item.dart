import 'package:core_events/core_events.dart';
import 'package:core_utils/core_utils.dart';

import '../entities/household_item.dart';
import '../entities/item_event.dart';
import '../entities/physical_identifier.dart';
import '../errors/item_tracker_exception.dart';
import '../item_validator.dart';
import '../repositories/household_item_repository.dart';
import '../value_objects/item_metadata.dart';

/// Identificador físico que se asocia al crear un objeto.
typedef IdentifierInput = ({String rawValue, IdentifierType type});

/// Crea un objeto, opcionalmente con su primer identificador, registra los
/// eventos técnicos y publica [ItemCreatedCrossEvent].
class CreateItem {
  const CreateItem(this._repository, this._ids, this._clock, this._eventBus);

  final HouseholdItemRepository _repository;
  final IdGenerator _ids;
  final Clock _clock;
  final EventBus _eventBus;

  Future<HouseholdItem> call({
    required String name,
    String description = '',
    Map<String, Object?> metadata = const {},
    IdentifierInput? identifier,
  }) async {
    final item = HouseholdItem(
      id: _ids.newId(),
      name: ItemValidator.name(name),
      description: ItemValidator.description(description),
      metadata: ItemMetadata(metadata),
      createdAt: _clock.nowUtc(),
      updatedAt: _clock.nowUtc(),
    );

    PhysicalIdentifier? bound;
    if (identifier != null) {
      final rawValue = ItemValidator.identifierValue(identifier.rawValue);
      final existing = await _repository.findIdentifier(rawValue, identifier.type);
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
      events: [
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
      ],
    );
    _eventBus.publish(ItemCreatedCrossEvent(itemId: item.id, itemName: item.name));
    return item;
  }
}
