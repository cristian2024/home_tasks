import 'dart:async';

import 'package:core_sync/core_sync.dart';
import 'package:core_sync/testing.dart';
import 'package:test/test.dart';

import '../entities/household_item.dart';
import '../entities/item_event.dart';
import '../entities/physical_identifier.dart';
import '../repositories/household_item_repository.dart';
import '../sync/item_tracker_codec.dart';
import '../sync/item_tracker_resolver.dart';
import '../sync/item_tracker_sync_participant.dart';
import '../value_objects/item_metadata.dart';

/// Lo que necesita [itemTrackerSyncContract]: un repositorio que se
/// sincroniza, su participante y el log donde registra.
class ItemTrackerSyncSubject {
  ItemTrackerSyncSubject({required this.repository, required this.participant, required this.log});

  final HouseholdItemRepository repository;
  final ItemTrackerSyncParticipant participant;
  final ChangeLog log;
}

/// Crea un [ItemTrackerSyncSubject] vacío. Los cambios locales los hace el
/// dispositivo `device-local`, con marcas posteriores a las de
/// [itemTrackerSyncRecords].
typedef ItemTrackerSyncFactory = FutureOr<ItemTrackerSyncSubject> Function();

const int _t0 = 1761827400000;

/// Cambios de tres dispositivos con ediciones concurrentes y un caso de cada
/// conflicto (spec §10.4.4):
/// - `box` renombrada a la vez en A y B: gana B («Caja roja»);
/// - A mete `box` en `drawer` y B, `drawer` en `box`: se revierte el de B
///   (`moveReverted`, `drawer` suelto);
/// - B mete `pen` en `shelf` mientras C borra `shelf`: `pen` queda suelto
///   (`containerDeleted`);
/// - `QR-1` asociado a `pen` en A y a `box` en B: se queda el de A
///   (`identifierBoundTwice`);
/// - `NFC-9` asociado a `shelf` mientras C la borra: queda quitado, sin
///   conflicto.
List<ChangeRecord> itemTrackerSyncRecords() {
  ChangeRecord record(String device, int seq, String collection, String entityId, int at, Map<String, Object?> fields) =>
      ChangeRecord(
        opId: '$device-$seq',
        deviceId: device,
        seq: seq,
        collection: collection,
        entityId: entityId,
        hlc: Hlc(wallTime: _t0 + at, counter: 0, deviceId: device),
        changes: <FieldChange>[
          for (final MapEntry<String, Object?>(:String key, :Object? value) in fields.entries) ValueChange(key, value),
        ],
      );
  Map<String, Object?> created(String name, int at, {String? parentId}) => <String, Object?>{
        ...ItemTrackerCodec.itemFields(_item(name, at, parentId: parentId)),
      }..removeWhere((String _, Object? value) => value == null);
  Map<String, Object?> bound(String rawValue, IdentifierType type, String itemId, int at) =>
      ItemTrackerCodec.identifierFields(
        PhysicalIdentifier(id: '-', rawValue: rawValue, type: type, itemId: itemId, boundAt: _at(at)),
      )..remove(ItemTrackerCodec.deletedAt);
  const String items = ItemTrackerCollections.items;
  const String identifiers = ItemTrackerCollections.identifiers;
  return <ChangeRecord>[
    record('device-a', 1, items, 'box', 1, created('Caja', 1)),
    record('device-a', 2, items, 'drawer', 2, created('Cajón', 2)),
    record('device-a', 3, items, 'pen', 3, created('Boli', 3, parentId: 'box')),
    record('device-a', 4, items, 'box', 10, <String, Object?>{'name': 'Caja azul'}),
    record('device-a', 5, items, 'box', 20, <String, Object?>{'parentId': 'drawer'}),
    record('device-a', 6, identifiers, 'id-a', 30, bound('QR-1', IdentifierType.qr, 'pen', 30)),
    record('device-a', 7, ItemTrackerCollections.events, 'ev-a', 31, ItemTrackerCodec.eventFields(_note('ev-a', 'pen', 31))),
    record('device-b', 1, items, 'box', 11, <String, Object?>{'name': 'Caja roja'}),
    record('device-b', 2, items, 'drawer', 21, <String, Object?>{'parentId': 'box'}),
    record('device-b', 3, identifiers, 'id-b', 32, bound('QR-1', IdentifierType.qr, 'box', 32)),
    record('device-b', 4, items, 'shelf', 40, created('Estante', 40)),
    record('device-b', 5, items, 'pen', 45, <String, Object?>{'parentId': 'shelf'}),
    record('device-b', 6, identifiers, 'id-c', 46, bound('NFC-9', IdentifierType.nfc, 'shelf', 46)),
    record('device-c', 1, items, 'shelf', 50, <String, Object?>{'deletedAt': _at(50).toIso8601String()}),
  ];
}

/// Ids de los objetos de [itemTrackerSyncRecords].
const List<String> itemTrackerSyncItemIds = <String>['box', 'drawer', 'pen', 'shelf'];

/// Lo que se ve de item_tracker a través del repositorio: objetos activos,
/// identificadores activos y eventos de [itemIds]. Comparable con `==`.
Future<Map<String, Object?>> readItemTrackerState(HouseholdItemRepository repository, Iterable<String> itemIds) async {
  final List<HouseholdItem> items = (await repository.getAll())..sort((HouseholdItem a, HouseholdItem b) => a.id.compareTo(b.id));
  return <String, Object?>{
    'items': items,
    for (final String id in itemIds) ...<String, Object?>{
      'identifiers:$id': await repository.watchIdentifiers(id).first,
      'events:$id': await repository.watchEvents(id).first,
    },
  };
}

/// Tests de sincronización de item_tracker. Todo repositorio que se
/// sincroniza debe pasarlos con su participante.
void itemTrackerSyncContract(String implementation, {required ItemTrackerSyncFactory create}) {
  group('item_tracker sincronizado ($implementation)', () {
    late ItemTrackerSyncSubject subject;
    final Map<ItemTrackerSyncParticipant, HouseholdItemRepository> repositories =
        <ItemTrackerSyncParticipant, HouseholdItemRepository>{};

    setUp(() async => subject = await create());

    syncParticipantContract<ItemTrackerSyncParticipant>(
      implementation,
      create: () async {
        final ItemTrackerSyncSubject created = await create();
        repositories[created.participant] = created.repository;
        return created.participant;
      },
      records: itemTrackerSyncRecords(),
      readState: (ItemTrackerSyncParticipant participant) =>
          readItemTrackerState(repositories[participant]!, itemTrackerSyncItemIds),
    );

    test('fusiona por campo y aplica las resoluciones provisionales', () async {
      final List<SyncConflict> conflicts = await subject.participant.applyRemote(itemTrackerSyncRecords());
      final HouseholdItemRepository repository = subject.repository;

      expect((await repository.getById('box'))?.name, 'Caja roja');
      expect((await repository.getById('box'))?.parentId, 'drawer');
      expect((await repository.getById('drawer'))?.parentId, isNull);
      expect((await repository.getById('pen'))?.parentId, isNull);
      expect(await repository.getById('shelf'), isNull);
      expect((await repository.findIdentifier('QR-1', IdentifierType.qr))?.itemId, 'pen');
      expect(await repository.findIdentifier('NFC-9', IdentifierType.nfc), isNull);
      expect(await repository.watchEvents('pen').first, <ItemEvent>[_note('ev-a', 'pen', 31)]);
      expect(conflicts.map((SyncConflict conflict) => conflict.kind), <String>[
        ItemTrackerResolver.containerDeleted,
        ItemTrackerResolver.identifierBoundTwice,
        ItemTrackerResolver.moveReverted,
      ]);
    });

    test('las escrituras locales se registran y otro dispositivo las aplica igual', () async {
      final HouseholdItem item = _item('Llaves', 100);
      await subject.repository.createItem(item, events: <ItemEvent>[_note('ev-1', item.id, 100)]);
      await subject.repository.updateItem(item.copyWith(name: 'Llaves de casa'), _note('ev-2', item.id, 101));
      final ItemTrackerSyncSubject other = await create();

      final List<ChangeRecord> records = await subject.log.missingFor(VersionVector.empty);
      await other.participant.applyRemote(records);

      expect(records.map((ChangeRecord record) => record.seq), <int>[1, 2, 3, 4]);
      expect(await readItemTrackerState(other.repository, <String>[item.id]),
          await readItemTrackerState(subject.repository, <String>[item.id]));
    });

    test('elegir el otro identificador lo vuelve a asociar a su objeto', () async {
      final List<SyncConflict> conflicts = await subject.participant.applyRemote(itemTrackerSyncRecords());
      final SyncConflict conflict =
          conflicts.firstWhere((SyncConflict c) => c.kind == ItemTrackerResolver.identifierBoundTwice);

      await subject.participant.resolveConflict(conflict, conflict.provisionalOptionId);
      expect((await subject.repository.findIdentifier('QR-1', IdentifierType.qr))?.itemId, 'pen');

      await subject.participant.resolveConflict(conflict, '${ItemTrackerResolver.keepPrefix}id-b');
      expect((await subject.repository.findIdentifier('QR-1', IdentifierType.qr))?.itemId, 'box');
    });

    test('confirmar una reversión o un contenedor borrado registra el contenedor efectivo', () async {
      final List<SyncConflict> conflicts = await subject.participant.applyRemote(itemTrackerSyncRecords());
      final VersionVector before = await subject.log.vector();

      for (final SyncConflict conflict in conflicts.where((SyncConflict c) => c.kind != ItemTrackerResolver.identifierBoundTwice)) {
        await subject.participant.resolveConflict(conflict, conflict.provisionalOptionId);
      }

      final List<ChangeRecord> recorded = await subject.log.missingFor(before);
      expect(recorded.map((ChangeRecord record) => record.entityId).toSet(), <String>{'drawer', 'pen'});
      expect(recorded.expand((ChangeRecord record) => record.changes), everyElement(ValueChange('parentId', null)));
    });

    test('borrar el objeto de un contenedor borrado', () async {
      final List<SyncConflict> conflicts = await subject.participant.applyRemote(itemTrackerSyncRecords());
      final SyncConflict conflict = conflicts.firstWhere((SyncConflict c) => c.kind == ItemTrackerResolver.containerDeleted);

      await subject.participant.resolveConflict(conflict, ItemTrackerResolver.deleteOption);

      expect(await subject.repository.getById('pen'), isNull);
    });
  });
}

DateTime _at(int offset) => DateTime.fromMillisecondsSinceEpoch(_t0 + offset, isUtc: true);

HouseholdItem _item(String name, int at, {String? parentId}) => HouseholdItem(
      id: name,
      name: name,
      description: '',
      metadata: const ItemMetadata.empty(),
      createdAt: _at(at),
      updatedAt: _at(at),
      parentId: parentId,
    );

ItemEvent _note(String id, String itemId, int at) =>
    ItemEvent(id: id, itemId: itemId, kind: ItemEventKind.note, title: id, description: '', timestamp: _at(at));
