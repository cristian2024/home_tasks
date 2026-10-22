import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';

import '../helpers/domain_fixtures.dart';

void main() {
  test('HouseholdItem.copyWith conserva id y createdAt', () {
    final updated = item().copyWith(
      name: 'Caja B',
      description: 'd',
      metadata: ItemMetadata({'a': 1}),
      updatedAt: t0.add(const Duration(days: 1)),
    );

    expect(updated.id, 'item-1');
    expect(updated.createdAt, t0);
    expect(updated.name, 'Caja B');
    expect(updated.description, 'd');
    expect(updated.metadata, ItemMetadata({'a': 1}));
    expect(updated.updatedAt, t0.add(const Duration(days: 1)));
    expect(item().copyWith(), item());
    expect(item().toString(), contains('Caja A'));
  });

  test('igualdad por valor de las entidades', () {
    expect(identifier(), identifier());
    expect(identifier(), isNot(identifier(type: IdentifierType.nfc)));
    expect(identifier().toString(), contains('QR-123'));
  });

  test('ItemEvent.isTechnical distingue las notas del usuario', () {
    ItemEvent event(ItemEventKind kind) =>
        ItemEvent(id: 'e', itemId: 'i', kind: kind, title: '', description: '', timestamp: t0);

    expect(event(ItemEventKind.note).isTechnical, isFalse);
    for (final kind in [ItemEventKind.created, ItemEventKind.updated, ItemEventKind.identifierBound]) {
      expect(event(kind).isTechnical, isTrue);
    }
    expect(event(ItemEventKind.note), event(ItemEventKind.note));
    expect(event(ItemEventKind.note).toString(), contains('note'));
  });

  test('las excepciones describen su causa', () {
    expect(const ItemNotFoundException('x').toString(), contains('x'));
    expect(
      const IdentifierAlreadyBoundException(rawValue: 'QR', type: IdentifierType.qr, boundItemId: 'b').toString(),
      contains('qr:QR -> b'),
    );
    expect(
      const ItemValidationException(ValidationField.metadata, ValidationReason.invalidFormat, detail: 'K').toString(),
      contains('K'),
    );
    expect(const ItemValidationException(ValidationField.name, ValidationReason.empty).toString(), isNot(contains(', null')));
  });
}
