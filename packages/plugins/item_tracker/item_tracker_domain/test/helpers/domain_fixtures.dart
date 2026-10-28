import 'package:item_tracker_domain/item_tracker_domain.dart';
import 'package:test/test.dart';

final DateTime t0 = DateTime.utc(2026, 10, 21, 14, 30);

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

Matcher throwsValidation(ValidationField field, ValidationReason reason) => throwsA(
      isA<ItemValidationException>()
          .having((ItemValidationException e) => e.field, 'field', field)
          .having((ItemValidationException e) => e.reason, 'reason', reason),
    );
