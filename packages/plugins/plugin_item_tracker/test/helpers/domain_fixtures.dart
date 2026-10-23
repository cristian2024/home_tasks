import 'package:core_utils/core_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';

class MockHouseholdItemRepository extends Mock implements HouseholdItemRepository {}

/// Genera IDs predecibles: id-1, id-2, ...
class SequentialIdGenerator implements IdGenerator {
  SequentialIdGenerator([this._next = 1]);

  int _next;

  @override
  String newId() => 'id-${_next++}';
}

final t0 = DateTime.utc(2026, 10, 21, 14, 30);

HouseholdItem item({
  String id = 'item-1',
  String name = 'Caja A',
  String description = '',
  ItemMetadata metadata = const ItemMetadata.empty(),
  DateTime? updatedAt,
  String? parentId,
}) =>
    HouseholdItem(
      id: id,
      name: name,
      description: description,
      metadata: metadata,
      createdAt: t0,
      updatedAt: updatedAt ?? t0,
      parentId: parentId,
    );

PhysicalIdentifier identifier({
  String rawValue = 'QR-123',
  IdentifierType type = IdentifierType.qr,
  String itemId = 'item-1',
}) =>
    PhysicalIdentifier(id: 'ident-1', rawValue: rawValue, type: type, itemId: itemId, boundAt: t0);

void registerDomainFallbacks() {
  registerFallbackValue(item());
  registerFallbackValue(identifier());
  registerFallbackValue(
    ItemEvent(id: 'e', itemId: 'i', kind: ItemEventKind.note, title: 't', description: '', timestamp: t0),
  );
  registerFallbackValue(IdentifierType.qr);
}

Matcher throwsValidation(ValidationField field, ValidationReason reason) => throwsA(
      isA<ItemValidationException>()
          .having((e) => e.field, 'field', field)
          .having((e) => e.reason, 'reason', reason),
    );
