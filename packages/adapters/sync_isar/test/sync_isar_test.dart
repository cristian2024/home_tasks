import 'package:core_sync/core_sync.dart';
import 'package:core_sync/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage_isar/adapter.dart';
import 'package:sync_isar/src/repositories/isar_change_log.dart';
import 'package:sync_isar/src/repositories/isar_conflict_repository.dart';
import 'package:sync_isar/src/repositories/isar_sync_state_repository.dart';
import 'package:sync_isar/sync_isar.dart';

import 'helpers/sync_storage.dart';

Future<SyncStorage> _open() async {
  final SyncStorage storage = await SyncStorage.open();
  addTearDown(storage.close);
  return storage;
}

ChangeRecord _record(String opId, {String deviceId = 'device-a', int seq = 1}) => ChangeRecord(
      opId: opId,
      deviceId: deviceId,
      seq: seq,
      collection: 'items',
      entityId: 'item-1',
      hlc: Hlc(wallTime: 1761827400000 + seq, counter: 0, deviceId: deviceId),
      changes: <FieldChange>[ValueChange('name', 'Leche')],
    );

void main() {
  setUpAll(() => Isar.initializeIsarCore(download: true));

  changeLogContract('Isar', create: () async => (await _open()).services.get<ChangeLog>());
  syncStateRepositoryContract('Isar', create: () async => (await _open()).services.get<SyncStateRepository>());
  conflictRepositoryContract('Isar', create: () async => (await _open()).services.get<ConflictRepository>());

  group('SyncIsar', () {
    late SyncStorage storage;

    setUp(() async => storage = await _open());

    test('aporta sus colecciones y registra los contratos y el writer', () {
      expect(const SyncIsar().schemas.map((CollectionSchema<dynamic> schema) => schema.name), <String>[
        'IsarSyncChangeRecord',
        'IsarSyncVectorEntry',
        'IsarSyncState',
        'IsarSyncPeer',
        'IsarSyncConflict',
      ]);
      expect(storage.services.get<ChangeLog>(), isA<IsarChangeLog>());
      expect(storage.services.get<SyncStateRepository>(), isA<IsarSyncStateRepository>());
      expect(storage.services.get<ConflictRepository>(), isA<IsarConflictRepository>());
      expect(storage.services.get<IsarChangeLogWriter>(), isA<IsarChangeLogWriter>());
    });
  });

  group('IsarChangeLogWriter', () {
    late SyncStorage storage;
    late IsarChangeLogWriter writer;
    late ChangeLog log;

    setUp(() async {
      storage = await _open();
      writer = storage.services.get<IsarChangeLogWriter>();
      log = storage.services.get<ChangeLog>();
    });

    test('nextSeq da el siguiente seq del dispositivo', () async {
      expect(await writer.nextSeq('device-a'), 1);

      await log.append(<ChangeRecord>[_record('op-1'), _record('op-2', seq: 2)]);

      expect(await writer.nextSeq('device-a'), 3);
      expect(await writer.nextSeq('device-b'), 1);
    });

    test('escribe en la transacción de quien llama: si esta falla, no queda nada', () async {
      await expectLater(
        storage.isar.writeTxn(() async {
          await writer.append(<ChangeRecord>[_record('op-1')]);
          throw StateError('falla la escritura de la entidad');
        }),
        throwsStateError,
      );

      expect(await log.vector(), VersionVector.empty);
      expect(await log.missingFor(VersionVector.empty), isEmpty);
    });

    test('con la transacción terminada, el registro y el vector quedan guardados', () async {
      await storage.isar.writeTxn(() async {
        await writer.append(<ChangeRecord>[_record('op-1', seq: await writer.nextSeq('device-a'))]);
      });

      expect(await log.vector(), VersionVector(<String, int>{'device-a': 1}));
      expect(await log.missingFor(VersionVector.empty), <ChangeRecord>[_record('op-1')]);
    });
  });
}
