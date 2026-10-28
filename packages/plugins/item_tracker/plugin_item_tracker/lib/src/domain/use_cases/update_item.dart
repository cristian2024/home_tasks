import 'package:core_utils/core_utils.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';

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
    final HouseholdItem? current = await _repository.getById(itemId);
    if (current == null) {
      throw ItemNotFoundException(itemId);
    }

    final String newName = name == null ? current.name : ItemValidator.name(name);
    final String newDescription = description == null ? current.description : ItemValidator.description(description);
    final ItemMetadata newMetadata = metadata == null ? current.metadata : ItemMetadata(metadata);

    final List<String> changedFields = <String>[
      if (newName != current.name) 'name',
      if (newDescription != current.description) 'description',
      if (newMetadata != current.metadata) 'metadata',
    ];
    if (changedFields.isEmpty) {
      return current;
    }

    final DateTime now = _clock.nowUtc();
    final HouseholdItem updated = current.copyWith(
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
