import 'package:core_utils/core_utils.dart';

import '../entities/item_event.dart';
import '../entities/physical_identifier.dart';
import '../errors/item_tracker_exception.dart';
import '../item_validator.dart';
import '../repositories/household_item_repository.dart';

/// Asocia un identificador físico a un objeto existente (AC-05). Un
/// identificador ya ligado a cualquier objeto se rechaza: nunca se mueve.
class BindIdentifier {
  const BindIdentifier(this._repository, this._ids, this._clock);

  final HouseholdItemRepository _repository;
  final IdGenerator _ids;
  final Clock _clock;

  Future<PhysicalIdentifier> call(String itemId, {required String rawValue, required IdentifierType type}) async {
    final String value = ItemValidator.identifierValue(rawValue);
    if (await _repository.getById(itemId) == null) {
      throw ItemNotFoundException(itemId);
    }
    final PhysicalIdentifier? existing = await _repository.findIdentifier(value, type);
    if (existing != null) {
      throw IdentifierAlreadyBoundException(rawValue: value, type: type, boundItemId: existing.itemId);
    }

    final DateTime now = _clock.nowUtc();
    final PhysicalIdentifier identifier = PhysicalIdentifier(
      id: _ids.newId(),
      rawValue: value,
      type: type,
      itemId: itemId,
      boundAt: now,
    );
    await _repository.bindIdentifier(
      identifier,
      ItemEvent(
        id: _ids.newId(),
        itemId: itemId,
        kind: ItemEventKind.identifierBound,
        title: type.name,
        description: value,
        timestamp: now,
      ),
    );
    return identifier;
  }
}
