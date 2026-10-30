import 'package:core_sync/core_sync.dart';
import 'package:core_sync/testing.dart';
import 'package:equatable/equatable.dart';
import 'package:test/test.dart';

/// Participante mínimo de clave-valor sobre [SyncMetadata], para probar la
/// batería y que la fusión por campo y por elemento es conmutativa.
class _KeyValueParticipant implements SyncParticipant {
  final Map<String, _Entity> entities = <String, _Entity>{};

  @override
  Set<String> get collections => <String>{'notes'};

  @override
  Future<List<SyncConflict>> applyRemote(List<ChangeRecord> records) async {
    for (final ChangeRecord record in records) {
      final _Entity current = entities[record.entityId] ?? _Entity(<String, Object?>{}, SyncMetadata.empty);
      final SyncMerge merge = current.metadata.merge(record);
      final Map<String, Object?> values = Map<String, Object?>.of(current.values);
      for (final FieldChange change in merge.winning) {
        if (change is ValueChange) {
          values[change.field] = change.value;
        }
      }
      entities[record.entityId] = _Entity(values, merge.metadata);
    }
    return <SyncConflict>[
      if (entities.length > 1)
        SyncConflict(
          id: 'many-notes',
          collection: 'notes',
          kind: 'many',
          entityIds: entities.keys.toList()..sort(),
          options: <ConflictOption>[ConflictOption('keep')],
          provisionalOptionId: 'keep',
          detectedAt: DateTime.utc(2026),
        ),
    ];
  }

  @override
  Future<void> resolveConflict(SyncConflict conflict, String optionId) async {}

  Map<String, Object?> snapshot() => <String, Object?>{
        for (final MapEntry<String, _Entity> entry in entities.entries)
          entry.key: <Object?>[
            entry.value.values,
            entry.value.metadata.presentElements('tags').toList()..sort(),
            entry.value.metadata.originDeviceId,
          ],
      };
}

class _Entity extends Equatable {
  const _Entity(this.values, this.metadata);

  final Map<String, Object?> values;
  final SyncMetadata metadata;

  @override
  List<Object?> get props => <Object?>[values, metadata];
}

ChangeRecord _note(String deviceId, int seq, int wallTime, String entityId, List<FieldChange> changes) =>
    ChangeRecord(
      opId: '$deviceId-$seq',
      deviceId: deviceId,
      seq: seq,
      collection: 'notes',
      entityId: entityId,
      hlc: Hlc(wallTime: wallTime, counter: 0, deviceId: deviceId),
      changes: changes,
    );

void main() {
  changeLogContract('InMemoryChangeLog', create: InMemoryChangeLog.new);
  syncStateRepositoryContract('InMemorySyncStateRepository', create: InMemorySyncStateRepository.new);
  conflictRepositoryContract('InMemoryConflictRepository', create: InMemoryConflictRepository.new);
  syncCipherContract('FakeSyncCipher', create: FakeSyncCipher.new);

  late InMemorySyncNetwork network;
  late List<InMemorySyncTransport> transports;
  syncTransportContract(
    'InMemorySyncTransport',
    create: () {
      network = InMemorySyncNetwork();
      transports = <InMemorySyncTransport>[network.transport(), network.transport()];
      return (transports[0], transports[1]);
    },
    dispose: () async {
      for (final InMemorySyncTransport transport in transports) {
        await transport.dispose();
      }
    },
  );

  syncParticipantContract<_KeyValueParticipant>(
    '_KeyValueParticipant',
    create: _KeyValueParticipant.new,
    readState: (_KeyValueParticipant participant) async => participant.snapshot(),
    records: <ChangeRecord>[
      _note('a', 1, 10, 'n1', <FieldChange>[ValueChange('title', 'Compras'), ElementChange('tags', 'casa', present: true)]),
      _note('b', 1, 20, 'n1', <FieldChange>[ValueChange('title', 'Compras del mes')]),
      _note('a', 2, 20, 'n1', <FieldChange>[ValueChange('title', 'Compras de la semana')]),
      _note('b', 2, 30, 'n1', <FieldChange>[ElementChange('tags', 'casa', present: false)]),
      _note('a', 3, 25, 'n1', <FieldChange>[ElementChange('tags', 'casa', present: true), ElementChange('tags', 'mes', present: true)]),
      _note('c', 1, 5, 'n2', <FieldChange>[ValueChange('title', 'Tareas'), ValueChange('done', false)]),
      _note('a', 4, 40, 'n2', <FieldChange>[ValueChange('done', true)]),
    ],
  );

  test('InMemoryChangeLog.records devuelve todos los registros ordenados', () async {
    final InMemoryChangeLog log = InMemoryChangeLog();
    final ChangeRecord second = _note('a', 2, 20, 'n1', <FieldChange>[ValueChange('title', 'B')]);
    final ChangeRecord first = _note('a', 1, 10, 'n1', <FieldChange>[ValueChange('title', 'A')]);

    await log.append(<ChangeRecord>[second, first]);

    expect(log.records, <ChangeRecord>[first, second]);
  });

  test('_KeyValueParticipant: gana el campo con mayor HLC y el último cambio de cada elemento', () async {
    final _KeyValueParticipant participant = _KeyValueParticipant();

    await participant.applyRemote(<ChangeRecord>[
      _note('a', 2, 20, 'n1', <FieldChange>[ValueChange('title', 'A')]),
      _note('b', 1, 20, 'n1', <FieldChange>[ValueChange('title', 'B'), ElementChange('tags', 'x', present: true)]),
      _note('a', 1, 10, 'n1', <FieldChange>[ValueChange('title', 'viejo'), ElementChange('tags', 'x', present: false)]),
    ]);
    await participant.resolveConflict(
      SyncConflict(
        id: 'c',
        collection: 'notes',
        kind: 'k',
        entityIds: <String>['n1'],
        options: <ConflictOption>[ConflictOption('o')],
        provisionalOptionId: 'o',
        detectedAt: DateTime.utc(2026),
      ),
      'o',
    );

    expect(participant.entities['n1']!.values, <String, Object?>{'title': 'B'});
    expect(participant.entities['n1']!.metadata.presentElements('tags'), <String>{'x'});
    expect(participant.entities['n1']!.metadata.originDeviceId, 'a');
    expect(participant.entities['n1'], isNot(_Entity(const <String, Object?>{}, SyncMetadata.empty)));
  });
}
