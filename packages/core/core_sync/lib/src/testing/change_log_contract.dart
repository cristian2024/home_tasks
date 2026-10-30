import 'dart:async';

import 'package:async/async.dart';
import 'package:hlc/hlc.dart';
import 'package:test/test.dart';

import '../contracts/change_log.dart';
import '../model/blob_ref.dart';
import '../model/change_record.dart';
import '../model/field_change.dart';
import '../model/version_vector.dart';

/// Crea un log vacío para un test.
typedef ChangeLogFactory = FutureOr<ChangeLog> Function();

/// Tests de contrato de [ChangeLog]. Toda implementación debe pasarlos.
///
/// ```dart
/// changeLogContract('InMemoryChangeLog', create: InMemoryChangeLog.new);
/// ```
void changeLogContract(String implementation, {required ChangeLogFactory create}) {
  group('ChangeLog ($implementation)', () {
    late ChangeLog log;

    ChangeRecord record(String deviceId, int seq, {String? opId}) => ChangeRecord(
          opId: opId ?? '$deviceId-$seq',
          deviceId: deviceId,
          seq: seq,
          collection: 'items',
          entityId: 'item-$seq',
          hlc: Hlc(wallTime: 1761827400000 + seq, counter: 0, deviceId: deviceId),
          changes: <FieldChange>[
            ValueChange('name', 'Leche $seq'),
            ElementChange('categoryIds', 'dairy', present: true),
          ],
        );

    setUp(() async => log = await create());

    test('empieza vacío', () async {
      expect(await log.vector(), VersionVector.empty);
      expect(await log.missingFor(VersionVector.empty), isEmpty);
    });

    test('guarda los registros tal cual y los devuelve por dispositivo y seq', () async {
      final ChangeRecord withBlob = ChangeRecord(
        opId: 'b-1',
        deviceId: 'b',
        seq: 1,
        collection: 'items',
        entityId: 'item-1',
        hlc: Hlc(wallTime: 1761827400000, counter: 3, deviceId: 'b'),
        changes: <FieldChange>[
          ValueChange('details', <String, Object?>{'quantity': 2, 'tags': <Object?>['a', null], 'ok': true}),
          ElementChange('categoryIds', 'dairy', present: false),
        ],
        blobs: <BlobRef>[BlobRef('a' * 64)],
      );

      await log.append(<ChangeRecord>[record('a', 2), withBlob, record('a', 1)]);

      expect(await log.missingFor(VersionVector.empty), <ChangeRecord>[record('a', 1), record('a', 2), withBlob]);
      expect(await log.vector(), VersionVector(<String, int>{'a': 2, 'b': 1}));
    });

    test('ignora los registros que ya tiene', () async {
      await log.append(<ChangeRecord>[record('a', 1)]);
      await log.append(<ChangeRecord>[record('a', 1), record('a', 2), record('a', 2)]);

      expect(await log.missingFor(VersionVector.empty), <ChangeRecord>[record('a', 1), record('a', 2)]);
    });

    test('el vector se queda en el último seq sin huecos', () async {
      await log.append(<ChangeRecord>[record('a', 1), record('a', 3)]);
      expect(await log.vector(), VersionVector(<String, int>{'a': 1}));

      await log.append(<ChangeRecord>[record('a', 2)]);
      expect(await log.vector(), VersionVector(<String, int>{'a': 3}));
    });

    test('un dispositivo sin el seq 1 vale 0, pero sus registros se envían', () async {
      await log.append(<ChangeRecord>[record('a', 2)]);

      expect(await log.vector(), VersionVector.empty);
      expect(await log.missingFor(VersionVector.empty), <ChangeRecord>[record('a', 2)]);
    });

    test('rechaza, sin guardar nada, un registro que ocupa el seq de otro', () async {
      await log.append(<ChangeRecord>[record('a', 1)]);

      await expectLater(log.append(<ChangeRecord>[record('a', 2), record('a', 1, opId: 'otro')]), throwsArgumentError);
      await expectLater(log.append(<ChangeRecord>[record('b', 1), record('b', 1, opId: 'otro')]), throwsArgumentError);
      expect(await log.missingFor(VersionVector.empty), <ChangeRecord>[record('a', 1)]);
    });

    test('missingFor devuelve lo que el otro vector no incluye, con límite', () async {
      await log.append(<ChangeRecord>[for (int seq = 1; seq <= 3; seq++) ...<ChangeRecord>[record('a', seq), record('b', seq)]]);
      final VersionVector remote = VersionVector(<String, int>{'a': 1, 'b': 3, 'c': 9});

      expect(await log.missingFor(remote), <ChangeRecord>[record('a', 2), record('a', 3)]);
      expect(await log.missingFor(VersionVector.empty, limit: 4),
          <ChangeRecord>[record('a', 1), record('a', 2), record('a', 3), record('b', 1)]);
      expect(await log.missingFor(remote, limit: 10), hasLength(2));
    });

    test('watchVector emite al escuchar y al guardar registros nuevos', () async {
      final StreamQueue<VersionVector> vectors = StreamQueue<VersionVector>(log.watchVector());

      expect(await vectors.next, VersionVector.empty);
      await log.append(<ChangeRecord>[record('a', 1)]);
      await expectLater(vectors, emitsThrough(VersionVector(<String, int>{'a': 1})));
      await vectors.cancel();
    });
  });
}
