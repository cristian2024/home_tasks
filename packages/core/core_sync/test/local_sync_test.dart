import 'package:core_sync/core_sync.dart';
import 'package:core_utils/core_utils.dart';
import 'package:test/test.dart';

final DateTime _t0 = DateTime.utc(2026, 10, 30);

Hlc _hlc(int at, {String device = 'a'}) => Hlc(wallTime: _t0.millisecondsSinceEpoch + at, counter: 0, deviceId: device);

void main() {
  group('FieldDiff', () {
    test('sin versión anterior, solo los campos con valor', () {
      expect(FieldDiff.between(null, const <String, Object?>{'name': 'Leche', 'note': null}), <FieldChange>[
        ValueChange('name', 'Leche'),
      ]);
    });

    test('compara mapas y listas por contenido', () {
      final Map<String, Object?> before = <String, Object?>{
        'metadata': <String, Object?>{'color': 'rojo'},
        'tags': <Object?>['a', 'b'],
      };

      expect(FieldDiff.between(before, <String, Object?>{'metadata': <String, Object?>{'color': 'rojo'}}), isEmpty);
      expect(FieldDiff.between(before, <String, Object?>{'metadata': <String, Object?>{'color': 'azul'}}), hasLength(1));
      expect(FieldDiff.between(before, <String, Object?>{'metadata': <String, Object?>{'talla': 'rojo'}}), hasLength(1));
      expect(FieldDiff.between(before, <String, Object?>{'tags': <Object?>['a', 'b']}), isEmpty);
      expect(FieldDiff.between(before, <String, Object?>{'tags': <Object?>['b', 'a']}), hasLength(1));
      expect(FieldDiff.between(before, <String, Object?>{'tags': <Object?>['a']}), hasLength(1));
    });

    test('un Set es un conjunto: un cambio por elemento añadido o quitado', () {
      expect(
        FieldDiff.between(<String, Object?>{'categoryIds': <Object?>['a', 'b']}, <String, Object?>{
          'categoryIds': <String>{'b', 'c'},
        }),
        <FieldChange>[
          ElementChange('categoryIds', 'c', present: true),
          ElementChange('categoryIds', 'a', present: false),
        ],
      );
      expect(FieldDiff.between(null, <String, Object?>{'categoryIds': <String>{'a'}}), <FieldChange>[
        ElementChange('categoryIds', 'a', present: true),
      ]);
      expect(FieldDiff.between(<String, Object?>{'categoryIds': 'roto'}, <String, Object?>{'categoryIds': <String>{}}), isEmpty);
    });
  });

  group('SyncedEntity', () {
    test('gana el valor de mayor marca, en cualquier orden', () {
      final SyncedEntity empty = SyncedEntity(collection: 'c', id: 'a');
      final List<FieldChange> old = <FieldChange>[ValueChange('name', 'A')];
      final List<FieldChange> recent = <FieldChange>[ValueChange('name', 'B')];

      expect(empty.apply(old, _hlc(1)).apply(recent, _hlc(2)).fields['name'], 'B');
      expect(empty.apply(recent, _hlc(2)).apply(old, _hlc(1)).fields['name'], 'B');
      expect(empty.apply(old, _hlc(1)).apply(recent, _hlc(2)), empty.apply(recent, _hlc(2)).apply(old, _hlc(1)));
    });

    test('un conjunto se guarda como la lista ordenada de sus elementos presentes', () {
      final SyncedEntity entity = SyncedEntity(collection: 'c', id: 'a')
          .apply(<FieldChange>[ElementChange('categoryIds', 'z', present: true)], _hlc(1))
          .apply(<FieldChange>[ElementChange('categoryIds', 'b', present: true)], _hlc(1, device: 'b'))
          .apply(<FieldChange>[ElementChange('categoryIds', 'm', present: true)], _hlc(2))
          .apply(<FieldChange>[ElementChange('categoryIds', 'z', present: false)], _hlc(3));

      expect(entity.fields['categoryIds'], <String>['b', 'm']);
    });

    test('merge fusiona los cambios de un registro', () {
      final ChangeRecord record = ChangeRecord(
        opId: 'op',
        deviceId: 'a',
        seq: 1,
        collection: 'c',
        entityId: 'a',
        hlc: _hlc(1),
        changes: <FieldChange>[ValueChange('name', 'A')],
      );

      expect(SyncedEntity(collection: 'c', id: 'a').merge(record).fields, <String, Object?>{'name': 'A'});
    });
  });

  group('LocalSyncRecorder', () {
    final LocalSyncRecorder recorder = LocalSyncRecorder(hlcClock: HlcClock(deviceId: 'local', clock: FixedClock(_t0)), ids: _Ids());

    test('las escrituras y los cambios se comparan por valor', () {
      expect(
        LocalSyncWrite(collection: 'c', id: 'a', fields: const <String, Object?>{'x': 1}),
        LocalSyncWrite(collection: 'c', id: 'a', fields: const <String, Object?>{'x': 1}),
      );
      expect(LocalSyncChanges(const <ChangeRecord>[], const <SyncedEntity>[]), LocalSyncChanges.none);
      expect(recorder.deviceId, 'local');
    });

    test('sin cambios no genera registros', () {
      final SyncedEntity current = SyncedEntity(collection: 'c', id: 'a').apply(<FieldChange>[ValueChange('name', 'A')], _hlc(1));

      expect(
        recorder.record(<LocalSyncWrite>[
          LocalSyncWrite(collection: 'c', id: 'a', fields: current.fields, current: current),
        ], nextSeq: 1),
        LocalSyncChanges.none,
      );
    });

    test('un registro por entidad cambiada, con la misma marca y seq consecutivos', () {
      final LocalSyncChanges changes = recorder.record(<LocalSyncWrite>[
        LocalSyncWrite(collection: 'c', id: 'a', fields: const <String, Object?>{'name': 'A'}),
        LocalSyncWrite(collection: 'c', id: 'b', fields: <String, Object?>{'name': 'B', 'categoryIds': <String>{'x'}}),
      ], nextSeq: 4);

      expect(changes.records.map((ChangeRecord record) => record.seq), <int>[4, 5]);
      expect(changes.records.map((ChangeRecord record) => record.hlc).toSet(), hasLength(1));
      expect(changes.records.map((ChangeRecord record) => record.deviceId).toSet(), <String>{'local'});
      expect(changes.entities.map((SyncedEntity entity) => entity.fields['name']), <String>['A', 'B']);
      expect(changes.entities.last.fields['categoryIds'], <String>['x']);
    });
  });
}

class _Ids implements IdGenerator {
  int _next = 0;

  @override
  String newId() => 'id-${_next++}';
}
