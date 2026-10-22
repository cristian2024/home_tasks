import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';
import 'package:plugin_item_tracker/src/data/mappers/item_data_mapper.dart';

import '../helpers/domain_fixtures.dart';

void main() {
  test('HouseholdItem ida y vuelta, con metadatos JSON (ejemplo del §9.3)', () {
    final original = item(
      description: 'Ubicada en el estante superior.',
      metadata: ItemMetadata({'color_etiqueta': 'Azul', 'peso_kg': 12.5, 'unidades': 3, 'fragil': false}),
      updatedAt: t0.add(const Duration(minutes: 30)),
    );

    final model = ItemDataMapper.toIsarItem(original);

    expect(model.metadataJson, '{"color_etiqueta":"Azul","peso_kg":12.5,"unidades":3,"fragil":false}');
    expect(ItemDataMapper.fromIsarItem(model), original);
  });

  test('PhysicalIdentifier ida y vuelta', () {
    final original = identifier(type: IdentifierType.barcode, rawValue: '049000000443');

    expect(ItemDataMapper.fromIsarIdentifier(ItemDataMapper.toIsarIdentifier(original)), original);
  });

  test('ItemEvent ida y vuelta', () {
    final original = ItemEvent(
      id: 'e1',
      itemId: 'item-1',
      kind: ItemEventKind.identifierBound,
      title: 'nfc',
      description: 'NFC-BED',
      timestamp: t0,
    );

    expect(ItemDataMapper.fromIsarEvent(ItemDataMapper.toIsarEvent(original)), original);
  });

  test('las fechas leídas en hora local se convierten a UTC', () {
    final local = t0.toLocal();
    final itemModel = ItemDataMapper.toIsarItem(item())
      ..createdAt = local
      ..updatedAt = local;
    final identifierModel = ItemDataMapper.toIsarIdentifier(identifier())..boundAt = local;
    final eventModel = ItemDataMapper.toIsarEvent(
      ItemEvent(id: 'e', itemId: 'i', kind: ItemEventKind.note, title: 't', description: '', timestamp: t0),
    )..timestamp = local;

    final mappedItem = ItemDataMapper.fromIsarItem(itemModel);
    expect(mappedItem.createdAt.isUtc && mappedItem.updatedAt.isUtc, isTrue);
    expect(mappedItem.createdAt, t0);
    expect(ItemDataMapper.fromIsarIdentifier(identifierModel).boundAt.isUtc, isTrue);
    expect(ItemDataMapper.fromIsarEvent(eventModel).timestamp.isUtc, isTrue);
  });

  test('las fechas se escriben en UTC aunque lleguen en hora local', () {
    final model = ItemDataMapper.toIsarItem(item(updatedAt: t0.toLocal()));

    expect(model.updatedAt.isUtc, isTrue);
  });
}
