import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';
import 'package:plugin_item_tracker/src/data/mappers/item_data_mapper.dart';
import 'package:plugin_item_tracker/src/data/models/isar_household_item.dart';
import 'package:plugin_item_tracker/src/data/models/isar_item_event.dart';
import 'package:plugin_item_tracker/src/data/models/isar_physical_identifier.dart';

import '../helpers/domain_fixtures.dart';

void main() {
  test('HouseholdItem ida y vuelta, con metadatos JSON (ejemplo del §9.3)', () {
    final HouseholdItem original = item(
      description: 'Ubicada en el estante superior.',
      metadata: ItemMetadata(
        <String,
        Object?>{'color_etiqueta': 'Azul', 'peso_kg': 12.5, 'unidades': 3, 'fragil': false},
      ),
      updatedAt: t0.add(const Duration(minutes: 30)),
    );

    final IsarHouseholdItem model = ItemDataMapper.toIsarItem(original);

    expect(model.metadataJson, '{"color_etiqueta":"Azul","peso_kg":12.5,"unidades":3,"fragil":false}');
    expect(ItemDataMapper.fromIsarItem(model), original);
  });

  test('HouseholdItem conserva el contenedor (parentId) en ambos sentidos', () {
    final HouseholdItem original = item(parentId: 'organizer');

    final IsarHouseholdItem model = ItemDataMapper.toIsarItem(original);

    expect(model.parentId, 'organizer');
    expect(ItemDataMapper.fromIsarItem(model), original);
    expect(ItemDataMapper.fromIsarItem(ItemDataMapper.toIsarItem(item())).parentId, isNull);
  });

  test('PhysicalIdentifier ida y vuelta', () {
    final PhysicalIdentifier original = identifier(type: IdentifierType.barcode, rawValue: '049000000443');

    expect(ItemDataMapper.fromIsarIdentifier(ItemDataMapper.toIsarIdentifier(original)), original);
  });

  test('ItemEvent ida y vuelta', () {
    final ItemEvent original = ItemEvent(
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
    final DateTime local = t0.toLocal();
    final IsarHouseholdItem itemModel = ItemDataMapper.toIsarItem(item())
      ..createdAt = local
      ..updatedAt = local;
    final IsarPhysicalIdentifier identifierModel = ItemDataMapper.toIsarIdentifier(identifier())..boundAt = local;
    final IsarItemEvent eventModel = ItemDataMapper.toIsarEvent(
      ItemEvent(id: 'e', itemId: 'i', kind: ItemEventKind.note, title: 't', description: '', timestamp: t0),
    )..timestamp = local;

    final HouseholdItem mappedItem = ItemDataMapper.fromIsarItem(itemModel);
    expect(mappedItem.createdAt.isUtc && mappedItem.updatedAt.isUtc, isTrue);
    expect(mappedItem.createdAt, t0);
    expect(ItemDataMapper.fromIsarIdentifier(identifierModel).boundAt.isUtc, isTrue);
    expect(ItemDataMapper.fromIsarEvent(eventModel).timestamp.isUtc, isTrue);
  });

  test('las fechas se escriben en UTC aunque lleguen en hora local', () {
    final IsarHouseholdItem model = ItemDataMapper.toIsarItem(item(updatedAt: t0.toLocal()));

    expect(model.updatedAt.isUtc, isTrue);
  });
}
