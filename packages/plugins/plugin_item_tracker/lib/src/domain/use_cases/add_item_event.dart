import 'package:core_utils/core_utils.dart';

import '../entities/item_event.dart';
import '../errors/item_tracker_exception.dart';
import '../item_validator.dart';
import '../repositories/household_item_repository.dart';

/// Añade una nota del usuario al historial de un objeto.
class AddItemEvent {
  const AddItemEvent(this._repository, this._ids, this._clock);

  final HouseholdItemRepository _repository;
  final IdGenerator _ids;
  final Clock _clock;

  Future<ItemEvent> call(String itemId, {required String title, String description = ''}) async {
    final event = ItemEvent(
      id: _ids.newId(),
      itemId: itemId,
      kind: ItemEventKind.note,
      title: ItemValidator.eventTitle(title),
      description: ItemValidator.eventDescription(description),
      timestamp: _clock.nowUtc(),
    );
    if (await _repository.getById(itemId) == null) {
      throw ItemNotFoundException(itemId);
    }
    await _repository.addEvent(event);
    return event;
  }
}
