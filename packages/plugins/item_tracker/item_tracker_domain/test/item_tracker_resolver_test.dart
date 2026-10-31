import 'package:core_sync/core_sync.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';
import 'package:test/test.dart';

final DateTime _t0 = DateTime.utc(2026, 10, 30);

Hlc _hlc(int at, {String device = 'a'}) =>
    Hlc(wallTime: _t0.millisecondsSinceEpoch + at, counter: 0, deviceId: device);

HouseholdItem _item(String id, {String? parentId}) => HouseholdItem(
      id: id,
      name: id,
      description: '',
      metadata: const ItemMetadata.empty(),
      createdAt: _t0,
      updatedAt: _t0,
      parentId: parentId,
    );

/// Copia sincronizada de un objeto creado en [at] y, si se da, movido a
/// [movedTo] en [movedAt].
SyncedEntity _synced(String id, {int at = 1, String? parentId, String? movedTo, int? movedAt, int? deletedAt}) {
  SyncedEntity entity = SyncedEntity(collection: ItemTrackerCollections.items, id: id)
      .apply(FieldDiff.between(null, ItemTrackerCodec.itemFields(_item(id, parentId: parentId))), _hlc(at));
  if (movedAt != null) {
    entity = entity.apply(<FieldChange>[ValueChange(ItemTrackerCodec.parentId, movedTo)], _hlc(movedAt));
  }
  if (deletedAt != null) {
    entity = entity.apply(
      <FieldChange>[ValueChange(ItemTrackerCodec.deletedAt, _t0.add(Duration(milliseconds: deletedAt)).toIso8601String())],
      _hlc(deletedAt),
    );
  }
  return entity;
}

SyncedEntity _identifier(String id, String itemId, {required int at, int? deletedAt, String rawValue = 'QR-1'}) {
  final PhysicalIdentifier identifier =
      PhysicalIdentifier(id: id, rawValue: rawValue, type: IdentifierType.qr, itemId: itemId, boundAt: _t0);
  SyncedEntity entity = SyncedEntity(collection: ItemTrackerCollections.identifiers, id: id)
      .apply(FieldDiff.between(null, ItemTrackerCodec.identifierFields(identifier)), _hlc(at));
  if (deletedAt != null) {
    entity = entity.apply(<FieldChange>[ValueChange(ItemTrackerCodec.deletedAt, _t0.toIso8601String())], _hlc(deletedAt));
  }
  return entity;
}

void main() {
  group('ItemTrackerResolver', () {
    test('revierte el movimiento más reciente que supera el máximo de niveles', () {
      const ItemTrackerResolver resolver = ItemTrackerResolver(policy: ContainmentPolicy(maxDepth: 2));

      final ItemTrackerView view = resolver.resolve(<SyncedEntity>[
        _synced('a'),
        _synced('b', movedTo: 'a', movedAt: 5),
        _synced('c', movedTo: 'b', movedAt: 6),
      ], const <SyncedEntity>[]);

      expect(view.items['b']?.item.parentId, 'a');
      expect(view.items['c']?.item.parentId, isNull);
      expect(view.conflicts.single.kind, ItemTrackerResolver.moveReverted);
      expect(view.conflicts.single.entityIds, <String>['c', 'b']);
    });

    test('con la misma marca revierte por id y sube por los contenedores borrados', () {
      final ItemTrackerView view = const ItemTrackerResolver().resolve(<SyncedEntity>[
        _synced('x', parentId: 'y'),
        _synced('y', parentId: 'x'),
        _synced('gone', parentId: 'gone-too', deletedAt: 3),
        _synced('gone-too', parentId: 'gone', deletedAt: 4),
        _synced('child', parentId: 'gone'),
      ], const <SyncedEntity>[]);

      expect(view.items['x']?.item.parentId, 'y');
      expect(view.items['y']?.item.parentId, isNull);
      expect(view.items['child']?.item.parentId, isNull);
      expect(view.items['gone']?.isDeleted, isTrue);
      expect(view.conflicts.map((SyncConflict c) => c.kind),
          <String>[ItemTrackerResolver.containerDeleted, ItemTrackerResolver.moveReverted]);
    });

    test('un contenedor que aún no llegó se respeta y los incompletos no se muestran', () {
      final ItemTrackerView view = const ItemTrackerResolver().resolve(<SyncedEntity>[
        _synced('a', parentId: 'unknown'),
        SyncedEntity(collection: ItemTrackerCollections.items, id: 'partial')
            .apply(<FieldChange>[ValueChange('name', 'Sin fecha')], _hlc(1)),
      ], <SyncedEntity>[
        SyncedEntity(collection: ItemTrackerCollections.identifiers, id: 'partial')
            .apply(<FieldChange>[ValueChange('rawValue', 'QR-9')], _hlc(1)),
      ]);

      expect(view.items.keys, <String>['a']);
      expect(view.items['a']?.item.parentId, 'unknown');
      expect(view.identifiers, isEmpty);
    });

    test('un identificador quitado antes de asociar otro con el mismo valor no genera conflicto', () {
      final ItemTrackerView view = const ItemTrackerResolver().resolve(
        <SyncedEntity>[_synced('a'), _synced('b')],
        <SyncedEntity>[
          _identifier('first', 'a', at: 1, deletedAt: 2),
          _identifier('second', 'b', at: 3),
          _identifier('same-item', 'b', at: 4),
        ],
      );

      expect(view.identifiers['first']?.isActive, isFalse);
      expect(view.identifiers['second']?.isActive, isTrue);
      expect(view.identifiers['same-item']?.isActive, isFalse);
      expect(view.conflicts, isEmpty);
    });

    test('una copia sin marcas (p. ej. migrada a mano) cuenta como la más antigua', () {
      final PhysicalIdentifier old =
          PhysicalIdentifier(id: 'old', rawValue: 'QR-1', type: IdentifierType.qr, itemId: 'a', boundAt: _t0);

      final ItemTrackerView view = const ItemTrackerResolver().resolve(
        <SyncedEntity>[_synced('a'), _synced('b')],
        <SyncedEntity>[
          _identifier('new', 'b', at: 1),
          SyncedEntity(
            collection: ItemTrackerCollections.identifiers,
            id: 'old',
            fields: ItemTrackerCodec.identifierFields(old),
          ),
        ],
      );

      expect(view.identifiers['old']?.isActive, isTrue);
      expect(view.identifiers['new']?.isActive, isFalse);
    });

    test('las vistas se comparan por valor', () {
      final ItemTrackerView view = const ItemTrackerResolver().resolve(<SyncedEntity>[_synced('a')], const <SyncedEntity>[]);

      expect(const ItemTrackerResolver().resolve(<SyncedEntity>[_synced('a')], const <SyncedEntity>[]), view);
      expect(ResolvedItem(_item('a'), deletedAt: _t0), isNot(ResolvedItem(_item('a'))));
      expect(
        ResolvedIdentifier(
          PhysicalIdentifier(id: 'i', rawValue: 'v', type: IdentifierType.nfc, itemId: 'a', boundAt: _t0),
        ).isActive,
        isTrue,
      );
    });
  });

  group('ItemTrackerCodec', () {
    test('lee unos metadatos inválidos como vacíos y un tipo desconocido como incompleto', () {
      final SyncedEntity item = _synced('a').apply(<FieldChange>[ValueChange('metadata', <String, Object?>{'Mal': 1})], _hlc(2));
      final SyncedEntity identifier =
          _identifier('i', 'a', at: 1).apply(<FieldChange>[ValueChange('type', 'laser')], _hlc(2));

      expect(ItemTrackerCodec.itemOf(item)?.metadata, const ItemMetadata.empty());
      expect(ItemTrackerCodec.identifierOf(identifier), isNull);
      expect(ItemTrackerCodec.eventOf(SyncedEntity(collection: ItemTrackerCollections.events, id: 'e')), isNull);
    });
  });

  test('un commit vacío se reconoce y se compara por valor', () {
    expect(ItemTrackerSyncCommit().isEmpty, isTrue);
    expect(ItemTrackerSyncCommit(events: const <ItemEvent>[]), ItemTrackerSyncCommit());
  });
}
