import 'package:core_utils/core_utils.dart';

import '../entities/household_item.dart';
import '../entities/item_event.dart';
import '../errors/item_tracker_exception.dart';
import '../item_validator.dart';
import '../repositories/household_item_repository.dart';
import '../value_objects/item_metadata.dart';

/// Edita un objeto. Si algo cambia, actualiza `updatedAt` y registra un
/// evento técnico con los campos modificados; si no, no escribe nada.
class UpdateItem {
  const UpdateItem(this._repository, this._ids, this._clock);

  final HouseholdItemRepository _repository;
  final IdGenerator _ids;
  final Clock _clock;

  Future<HouseholdItem> call(
    String itemId, {
    String? name,
    String? description,
    Map<String, Object?>? metadata,
  }) async {
    final current = await _repository.getById(itemId);
    if (current == null) {
      throw ItemNotFoundException(itemId);
    }

    final newName = name == null ? current.name : ItemValidator.name(name);
    final newDescription = description == null ? current.description : ItemValidator.description(description);
    final newMetadata = metadata == null ? current.metadata : ItemMetadata(metadata);

    final changedFields = [
      if (newName != current.name) 'name',
      if (newDescription != current.description) 'description',
      if (newMetadata != current.metadata) 'metadata',
    ];
    if (changedFields.isEmpty) {
      return current;
    }

    final now = _clock.nowUtc();
    final updated = current.copyWith(
      name: newName,
      description: newDescription,
      metadata: newMetadata,
      updatedAt: now,
    );
    await _repository.updateItem(
      updated,
      ItemEvent(
        id: _ids.newId(),
        itemId: itemId,
        kind: ItemEventKind.updated,
        title: '',
        description: changedFields.join(','),
        timestamp: now,
      ),
    );
    return updated;
  }
}
