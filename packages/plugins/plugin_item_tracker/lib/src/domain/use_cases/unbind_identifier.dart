import 'package:core_utils/core_utils.dart';

import '../entities/item_event.dart';
import '../entities/physical_identifier.dart';
import '../errors/item_tracker_exception.dart';
import '../repositories/household_item_repository.dart';

/// Quita un identificador de un objeto. El identificador queda libre y se
/// puede asociar de nuevo a cualquier objeto.
class UnbindIdentifier {
  const UnbindIdentifier(this._repository, this._ids, this._clock);

  final HouseholdItemRepository _repository;
  final IdGenerator _ids;
  final Clock _clock;

  Future<PhysicalIdentifier> call(String itemId, {required String identifierId}) async {
    if (await _repository.getById(itemId) == null) {
      throw ItemNotFoundException(itemId);
    }
    final PhysicalIdentifier? identifier = await _repository.getIdentifier(identifierId);
    if (identifier == null || identifier.itemId != itemId) {
      throw IdentifierNotFoundException(identifierId);
    }

    final DateTime now = _clock.nowUtc();
    await _repository.unbindIdentifier(
      identifier.id,
      deletedAt: now,
      event: ItemEvent(
        id: _ids.newId(),
        itemId: itemId,
        kind: ItemEventKind.identifierUnbound,
        title: identifier.type.name,
        description: identifier.rawValue,
        timestamp: now,
      ),
    );
    return identifier;
  }
}
