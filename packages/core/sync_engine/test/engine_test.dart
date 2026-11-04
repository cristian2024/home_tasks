import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:core_sync/core_sync.dart';
import 'package:core_sync/testing.dart';
import 'package:core_utils/core_utils.dart';
import 'package:sync_engine/src/engine/sync_message.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:sync_engine/testing.dart';
import 'package:test/test.dart';

import 'helpers/household.dart';

/// Participante de la colección `notes` que detecta un conflicto por cada
/// registro de la entidad `conflict`.
class _ConflictingParticipant implements SyncParticipant {
  final List<String> resolved = <String>[];

  @override
  Set<String> get collections => <String>{'notes'};

  @override
  Future<List<SyncConflict>> applyRemote(List<ChangeRecord> records) async => <SyncConflict>[
        for (final ChangeRecord record in records)
          if (record.entityId == 'conflict') conflict,
      ];

  @override
  Future<void> resolveConflict(SyncConflict conflict, String optionId) async => resolved.add(optionId);

  static final SyncConflict conflict = SyncConflict(
    id: 'notes:conflict',
    collection: 'notes',
    kind: 'duplicate',
    entityIds: <String>['conflict'],
    options: <ConflictOption>[ConflictOption('keep-first'), ConflictOption('keep-second')],
    provisionalOptionId: 'keep-first',
    detectedAt: DateTime.utc(2026, 10, 30),
  );
}

/// [ChangeLog] que falla las primeras [failures] escrituras como si otro
/// escritor ocupara el seq.
class _BusyChangeLog extends InMemoryChangeLog {
  _BusyChangeLog(this.failures);

  int failures;

  @override
  Future<void> append(List<ChangeRecord> records) async {
    if (failures > 0) {
      failures--;
      throw ArgumentError('seq ocupado');
    }
    await super.append(records);
  }
}

Future<SyncEndpoint> _endpointOf(SimulatedDevice viewer, SimulatedDevice target) async =>
    (await viewer.transport.watchEndpoints().first).singleWhere((SyncEndpoint e) => e.deviceId == target.deviceId);

void main() {
  group('sesión entre dos dispositivos', () {
    test('cada uno recibe lo que le falta y recuerda al otro', () async {
      final List<SimulatedDevice> devices = await household(2);
      final SimulatedDevice a = devices[0];
      final SimulatedDevice b = devices[1];
      await a.store.put('leche', <String, Object?>{'name': 'Leche'});
      await a.store.setElement('leche', 'tags', 'lácteos', present: true);
      await b.store.put('pan', <String, Object?>{'name': 'Pan'});

      final SyncSessionResult result = await a.engine.syncWith(a.transport, await _endpointOf(a, b));
      await b.settle();

      expect(result.peer, DeviceIdentity(deviceId: b.deviceId, name: 'device-1'));
      expect(result.sent, 2);
      expect(result.outcome.applied, 1);
      expect(result.remoteVector, VersionVector(<String, int>{b.deviceId: 1}));
      expect(result.localVector, VersionVector(<String, int>{a.deviceId: 2}));
      expect(b.store.snapshot(), a.store.snapshot());
      expect(a.store.entities.keys, unorderedEquals(<String>['leche', 'pan']));
      expect(await a.log.vector(), await b.log.vector());
      expect((await a.state.peers()).single.deviceId, b.deviceId);
      expect((await b.state.peers()).single.lastSyncedAt, DateTime.utc(2026, 10, 30, 12));
    });

    test('gossip: C recibe los cambios de A a través de B sin haber visto nunca a A', () async {
      final InMemorySyncNetwork network = InMemorySyncNetwork();
      final List<SimulatedDevice> devices = await household(3, network: network);
      final (SimulatedDevice a, SimulatedDevice b, SimulatedDevice c) = (devices[0], devices[1], devices[2]);
      network.partition(a.deviceId, c.deviceId);
      await a.store.put('leche', <String, Object?>{'name': 'Leche'});

      expect(await a.syncWith(c), isNull);
      expect(await a.syncWith(b), isNotNull);
      expect(await b.syncWith(c), isNotNull);

      expect(c.store.entities['leche']!.values, <String, Object?>{'name': 'Leche'});
      expect(c.store.entities['leche']!.metadata.originDeviceId, a.deviceId);
    });

    test('envía en lotes de batchSize', () async {
      final List<SimulatedDevice> devices = await household(2);
      final (SimulatedDevice a, SimulatedDevice b) = (devices[0], devices[1]);
      for (int i = 0; i < 5; i++) {
        await a.store.put('item-$i', <String, Object?>{'n': i});
      }
      final (SyncChannel opened, SyncChannel accepted) = await _openChannel(a, b);
      final List<int> batches = <int>[];
      final Stream<Uint8List> observed = accepted.messages.map((Uint8List bytes) {
        final SyncMessage message = SyncMessage.decode(bytes);
        if (message is RecordsMessage) {
          batches.add(message.records.length);
        }
        return bytes;
      });

      final Future<SyncSessionResult> sending = _session(a, opened, batchSize: 2).run();
      final Future<SyncSessionResult> receiving = _session(b, _ObservedChannel(accepted, observed)).run();

      expect((await sending).sent, 5);
      expect((await receiving).outcome.applied, 5);
      expect(batches, <int>[2, 2, 1]);
    });
  });

  group('autenticación y protocolo', () {
    test('un dispositivo con otra clave no se autentica', () async {
      final List<SimulatedDevice> devices = await household(3);
      final (SimulatedDevice creator, SimulatedDevice expelled) = (devices[0], devices[2]);
      await creator.households.expel(expelled.deviceId);
      await creator.store.put('secreto', <String, Object?>{'name': 'nuevo'});
      final (SyncChannel opened, SyncChannel accepted) = await _openChannel(expelled, creator);

      final List<Object?> errors = await Future.wait(<Future<Object?>>[
        _session(expelled, opened).run().then<Object?>((_) => null, onError: (Object error) => error),
        _session(creator, accepted).run().then<Object?>((_) => null, onError: (Object error) => error),
      ]);

      expect(errors, everyElement(isA<SyncAuthenticationException>()));
      expect(expelled.store.entities, isEmpty);
    });

    test('rechaza mensajes inesperados, otra versión o el mismo id', () async {
      final List<SimulatedDevice> devices = await household(2);
      final (SimulatedDevice a, SimulatedDevice b) = (devices[0], devices[1]);
      final Uint8List nonce = Uint8List(16);

      Future<void> expectProtocolError(List<SyncMessage> script, {List<Uint8List> raw = const <Uint8List>[]}) async {
        final (SyncChannel opened, SyncChannel peer) = await _openChannel(a, b);
        for (final SyncMessage message in script) {
          await peer.send(message.encode());
        }
        for (final Uint8List bytes in raw) {
          await peer.send(bytes);
        }
        await expectLater(_session(a, opened).run(), throwsA(isA<SyncProtocolException>()));
      }

      await expectProtocolError(const <SyncMessage>[], raw: <Uint8List>[Uint8List.fromList(utf8.encode('x'))]);
      await expectProtocolError(<SyncMessage>[const DoneMessage()]);
      await expectProtocolError(<SyncMessage>[HelloMessage(protocol: 2, deviceId: b.deviceId, deviceName: 'b', nonce: nonce)]);
      await expectProtocolError(<SyncMessage>[HelloMessage(protocol: 1, deviceId: a.deviceId, deviceName: 'a', nonce: nonce)]);
    });

    test('rechaza un vector o un registro alterados aunque el otro conozca la clave', () async {
      final List<SimulatedDevice> devices = await household(2);
      final (SimulatedDevice a, SimulatedDevice b) = (devices[0], devices[1]);
      final HouseholdKeys keys = (await b.households.keys())!;
      final SyncCipher cipher = b.services.get<SyncCipher>();
      final Uint8List recordsKey = await keys.recordsKey();
      final ChangeRecord record = ChangeRecord(
        opId: 'op',
        deviceId: b.deviceId,
        seq: 1,
        collection: 'kv',
        entityId: 'x',
        hlc: Hlc(wallTime: 1, counter: 0, deviceId: b.deviceId),
        changes: <FieldChange>[ValueChange('name', 'x')],
      );

      Future<Uint8List> seal(String json, int seq) => cipher.encrypt(
            Uint8List.fromList(utf8.encode(json)),
            key: recordsKey,
            associatedData: keys.recordAssociatedData(b.deviceId, seq),
          );

      Future<void> expectProtocolError(Future<SyncMessage> Function(_ScriptedPeer peer) afterProof) async {
        final (SyncChannel opened, SyncChannel channel) = await _openChannel(a, b);
        final _ScriptedPeer peer = _ScriptedPeer(channel, b, keys, cipher);
        final Future<SyncSessionResult> session = _session(a, opened).run();
        await peer.handshake();
        await channel.send((await afterProof(peer)).encode());
        await expectLater(session, throwsA(isA<SyncProtocolException>()));
      }

      await expectProtocolError((_) async => VectorMessage(Uint8List(40)));
      await expectProtocolError((_ScriptedPeer peer) async => VectorMessage(await peer.vector('[1]')));
      for (final (int seq, Future<Uint8List> Function() sealed) in <(int, Future<Uint8List> Function())>[
        (1, () async => Uint8List(40)),
        (1, () => seal('{"no": "registro"}', 1)),
        (2, () => seal(jsonEncode(record.toJson()), 2)),
      ]) {
        await expectProtocolError((_ScriptedPeer peer) async {
          await peer.channel.send(VectorMessage(await peer.vector('{}')).encode());
          return RecordsMessage(<SealedRecord>[SealedRecord(deviceId: b.deviceId, seq: seq, ciphertext: await sealed())]);
        });
      }
      await expectProtocolError((_ScriptedPeer peer) async {
        await peer.channel.send(VectorMessage(await peer.vector('{}')).encode());
        return ProofMessage(Uint8List(1));
      });
    });

    test('si el otro cierra o no responde, falla el transporte', () async {
      final List<SimulatedDevice> devices = await household(2);
      final (SimulatedDevice a, SimulatedDevice b) = (devices[0], devices[1]);

      final (SyncChannel closedByPeer, SyncChannel peer) = await _openChannel(a, b);
      await peer.close();
      await expectLater(_session(a, closedByPeer).run(), throwsA(isA<SyncTransportException>()));

      final (SyncChannel silent, SyncChannel _) = await _openChannel(a, b);
      await expectLater(
        _session(a, silent, timeout: const Duration(milliseconds: 20)).run(),
        throwsA(isA<SyncTransportException>()),
      );
    });

    test('sin hogar, syncWith falla y accept cierra el canal', () async {
      final List<SimulatedDevice> devices = await household(2);
      final (SimulatedDevice a, SimulatedDevice b) = (devices[0], devices[1]);
      final SyncEndpoint endpoint = await _endpointOf(a, b);
      final (SyncChannel opened, SyncChannel accepted) = await _openChannel(a, b);
      await a.households.leave();

      await expectLater(a.engine.syncWith(a.transport, endpoint), throwsA(isA<NotInHouseholdException>()));
      await expectLater(a.engine.accept(accepted), throwsA(isA<NotInHouseholdException>()));
      expect(await opened.messages.toList(), isEmpty);
    });
  });

  group('RecordApplier', () {
    test('rechaza las marcas demasiado adelantadas; volverán a llegar', () async {
      final InMemorySyncNetwork network = InMemorySyncNetwork();
      final FixedClock aheadClock = FixedClock(DateTime.utc(2026, 10, 30, 13));
      final List<SimulatedDevice> devices = await household(2, network: network);
      final (SimulatedDevice a, SimulatedDevice b) = (devices[0], devices[1]);
      final HlcClock aheadHlc = HlcClock(deviceId: b.deviceId, clock: aheadClock);
      await LocalRecorder(log: b.log, hlcClock: aheadHlc).record('kv', 'futuro', <FieldChange>[ValueChange('name', 'x')]);

      final SyncSessionResult result = (await a.syncWith(b))!;

      expect(result.outcome.rejected, 1);
      expect(result.outcome.applied, 0);
      expect(await a.log.vector(), VersionVector.empty);
      expect(a.store.entities, isEmpty);
    });

    test('guarda sin aplicar los registros de una colección sin participante', () async {
      final List<SimulatedDevice> devices = await household(2);
      final (SimulatedDevice a, SimulatedDevice b) = (devices[0], devices[1]);
      await LocalRecorder(log: b.log, hlcClock: b.services.get<HlcClock>())
          .record('otra', 'x', <FieldChange>[ValueChange('name', 'x')]);

      await a.syncWith(b);

      expect((await a.log.missingFor(VersionVector.empty)).single.collection, 'otra');
      expect(a.store.entities, isEmpty);
    });

    test('ignora los repetidos y los que ya tiene', () async {
      final List<SimulatedDevice> devices = await household(1);
      final SimulatedDevice a = devices.single;
      final RecordApplier applier = _applier(a);
      final ChangeRecord record = ChangeRecord(
        opId: 'op',
        deviceId: 'other',
        seq: 1,
        collection: 'kv',
        entityId: 'x',
        hlc: Hlc(wallTime: 1, counter: 0, deviceId: 'other'),
        changes: <FieldChange>[ValueChange('name', 'x')],
      );

      expect((await applier.apply(<ChangeRecord>[record, record])).applied, 1);
      expect(await applier.apply(<ChangeRecord>[record]), ApplyOutcome.none);
      expect(ApplyOutcome.none + ApplyOutcome.none, ApplyOutcome.none);
    });
  });

  group('conflictos', () {
    test('se guardan al detectarse, se resuelven y la resolución llega a los demás', () async {
      final List<SimulatedDevice> devices = await household(3);
      final (SimulatedDevice a, SimulatedDevice b, SimulatedDevice c) = (devices[0], devices[1], devices[2]);
      final List<_ConflictingParticipant> participants =
          List<_ConflictingParticipant>.generate(devices.length, (_) => _ConflictingParticipant());
      for (int i = 0; i < devices.length; i++) {
        SyncParticipants.of(devices[i].services).add(participants[i]);
      }
      final LocalRecorder recorder = LocalRecorder(log: c.log, hlcClock: c.services.get<HlcClock>());
      await recorder.record('notes', 'conflict', <FieldChange>[ValueChange('name', 'x')]);

      final SyncSessionResult toA = (await a.syncWith(c))!;
      await b.syncWith(c);

      expect(toA.outcome.conflicts, <SyncConflict>[_ConflictingParticipant.conflict]);
      expect(await a.inbox.open(), <SyncConflict>[_ConflictingParticipant.conflict]);
      expect(await b.inbox.open(), <SyncConflict>[_ConflictingParticipant.conflict]);

      await a.inbox.resolve(_ConflictingParticipant.conflict, 'keep-second');
      expect(participants[0].resolved, <String>['keep-second']);
      expect(await a.inbox.open(), isEmpty);

      await a.syncWith(b);
      expect(await b.inbox.open(), isEmpty);
      expect(
        await b.services.get<ConflictRepository>().get('notes:conflict'),
        _ConflictingParticipant.conflict.resolve('keep-second'),
      );
      expect(participants[1].resolved, isEmpty);
    });

    test('un conflicto ya guardado no se vuelve a abrir', () async {
      final List<SimulatedDevice> devices = await household(1);
      final SimulatedDevice a = devices.single;
      SyncParticipants.of(a.services).add(_ConflictingParticipant());
      await a.services.get<ConflictRepository>().save(_ConflictingParticipant.conflict.resolve('keep-first'));

      final ApplyOutcome outcome = await _applier(a).apply(<ChangeRecord>[_note('other', 1, 'conflict')]);

      expect(outcome.conflicts, isEmpty);
      expect(await a.inbox.open(), isEmpty);
    });

    test('ignora resoluciones de conflictos desconocidos o con opciones que no existen', () async {
      final List<SimulatedDevice> devices = await household(1);
      final SimulatedDevice a = devices.single;
      SyncParticipants.of(a.services).add(_ConflictingParticipant());
      ChangeRecord resolution(int seq, String conflictId, Object? option, {String field = 'resolvedOptionId'}) =>
          ChangeRecord(
            opId: 'r-$seq',
            deviceId: 'other',
            seq: seq,
            collection: RecordApplier.conflictsCollection,
            entityId: conflictId,
            hlc: Hlc(wallTime: seq, counter: 0, deviceId: 'other'),
            changes: <FieldChange>[ValueChange(field, option)],
          );

      await _applier(a).apply(<ChangeRecord>[
        _note('other', 1, 'conflict'),
        resolution(2, 'desconocido', 'keep-first'),
        resolution(3, 'notes:conflict', 'no-existe'),
        resolution(4, 'notes:conflict', 'keep-second', field: 'otro'),
      ]);

      expect(await a.inbox.open(), <SyncConflict>[_ConflictingParticipant.conflict]);
    });

    test('resolveAutomatically confirma la provisional; sin participante falla', () async {
      final List<SimulatedDevice> devices = await household(1);
      final SimulatedDevice a = devices.single;
      final _ConflictingParticipant participant = _ConflictingParticipant();

      await expectLater(a.inbox.resolveAutomatically(_ConflictingParticipant.conflict), throwsStateError);
      await expectLater(a.inbox.resolve(_ConflictingParticipant.conflict, 'x'), throwsArgumentError);

      SyncParticipants.of(a.services).add(participant);
      await a.services.get<ConflictRepository>().save(_ConflictingParticipant.conflict);
      final Future<List<List<SyncConflict>>> open = a.inbox.watchOpen().take(2).toList();
      await a.inbox.resolveAutomatically(_ConflictingParticipant.conflict);

      expect(participant.resolved, <String>['keep-first']);
      expect(await open, <List<SyncConflict>>[<SyncConflict>[_ConflictingParticipant.conflict], <SyncConflict>[]]);
    });
  });

  group('LocalRecorder', () {
    test('usa el siguiente seq propio y reintenta si otro lo ocupa', () async {
      final HlcClock hlcClock = HlcClock(deviceId: 'a', clock: FixedClock(DateTime.utc(2026)));
      final _BusyChangeLog log = _BusyChangeLog(2);
      final LocalRecorder recorder = LocalRecorder(log: log, hlcClock: hlcClock, ids: SequentialIds());

      final ChangeRecord first = await recorder.record('kv', 'x', <FieldChange>[ValueChange('n', 1)]);
      final ChangeRecord second = await recorder.record('kv', 'x', <FieldChange>[ValueChange('n', 2)]);

      expect(<int>[first.seq, second.seq], <int>[1, 2]);
      expect(first.opId, 'id-003');
      expect(log.records, <ChangeRecord>[first, second]);
    });

    test('se rinde tras tres intentos', () async {
      final LocalRecorder recorder = LocalRecorder(
        log: _BusyChangeLog(3),
        hlcClock: HlcClock(deviceId: 'a', clock: FixedClock(DateTime.utc(2026))),
      );

      await expectLater(recorder.record('kv', 'x', <FieldChange>[ValueChange('n', 1)]), throwsArgumentError);
    });
  });
}

ChangeRecord _note(String deviceId, int seq, String entityId) => ChangeRecord(
      opId: '$deviceId-$seq',
      deviceId: deviceId,
      seq: seq,
      collection: 'notes',
      entityId: entityId,
      hlc: Hlc(wallTime: seq, counter: 0, deviceId: deviceId),
      changes: <FieldChange>[ValueChange('name', entityId)],
    );

RecordApplier _applier(SimulatedDevice device) => RecordApplier(
      log: device.log,
      participants: SyncParticipants.of(device.services),
      conflicts: device.services.get<ConflictRepository>(),
      state: device.state,
      hlcClock: device.services.get<HlcClock>(),
    );

SyncSession _session(
  SimulatedDevice device,
  SyncChannel channel, {
  int batchSize = 200,
  Duration timeout = const Duration(seconds: 5),
}) =>
    SyncSession(
      channel: channel,
      device: DeviceIdentity(deviceId: device.deviceId, name: device.name),
      keys: _keysOf(device),
      log: device.log,
      applier: _applier(device),
      cipher: device.services.get<SyncCipher>(),
      batchSize: batchSize,
      timeout: timeout,
    );

final Expando<HouseholdKeys> _keys = Expando<HouseholdKeys>();

HouseholdKeys _keysOf(SimulatedDevice device) => _keys[device]!;

/// Abre un canal de [from] a [to] sin que [to] lo acepte con su motor. Guarda
/// las claves de los dos para construir sesiones a mano.
Future<(SyncChannel, SyncChannel)> _openChannel(SimulatedDevice from, SimulatedDevice to) async {
  for (final SimulatedDevice device in <SimulatedDevice>[from, to]) {
    _keys[device] = (await device.households.keys())!;
  }
  final InMemorySyncNetwork network = InMemorySyncNetwork();
  final InMemorySyncTransport left = network.transport();
  final InMemorySyncTransport right = network.transport();
  await left.start(SyncAdvertisement(discoveryId: 'x', deviceId: from.deviceId, deviceName: from.name));
  await right.start(SyncAdvertisement(discoveryId: 'x', deviceId: to.deviceId, deviceName: to.name));
  final Future<SyncChannel> accepted = right.incoming.first;
  final SyncChannel opened = await left.connect((await left.watchEndpoints().first).single);
  final SyncChannel other = await accepted;
  addTearDown(() async {
    await left.dispose();
    await right.dispose();
  });
  return (opened, other);
}

/// Canal que entrega los mensajes de [observed] (p. ej. con un `map` que los
/// cuenta).
class _ObservedChannel implements SyncChannel {
  _ObservedChannel(this._channel, this.messages);

  final SyncChannel _channel;

  @override
  final Stream<Uint8List> messages;

  @override
  Future<void> send(Uint8List message) => _channel.send(message);

  @override
  Future<void> close() => _channel.close();
}

/// Lado de una sesión escrito a mano, para enviar mensajes alterados tras
/// autenticarse.
class _ScriptedPeer {
  _ScriptedPeer(this.channel, this.device, this.keys, this.cipher);

  final SyncChannel channel;
  final SimulatedDevice device;
  final HouseholdKeys keys;
  final SyncCipher cipher;
  late final StreamIterator<Uint8List> _incoming = StreamIterator<Uint8List>(channel.messages);
  late HelloMessage _hello;
  final Uint8List _nonce = Uint8List(16);

  Future<void> handshake() async {
    await channel.send(HelloMessage(protocol: 1, deviceId: device.deviceId, deviceName: 'b', nonce: _nonce).encode());
    _hello = await _next<HelloMessage>();
    await channel.send(ProofMessage(await cipher.mac(_data('proof', device.deviceId, _hello.deviceId, _nonce, _hello.nonce), key: await keys.authKey())).encode());
    await _next<ProofMessage>();
  }

  Future<Uint8List> vector(String json) async => cipher.encrypt(
        Uint8List.fromList(utf8.encode(json)),
        key: await keys.recordsKey(),
        associatedData: _data('vector', device.deviceId, _hello.deviceId, _nonce, _hello.nonce),
      );

  Future<T> _next<T extends SyncMessage>() async {
    await _incoming.moveNext();
    return SyncMessage.decode(_incoming.current) as T;
  }

  static Uint8List _data(String purpose, String from, String to, Uint8List fromNonce, Uint8List toNonce) =>
      Uint8List.fromList(<int>[...utf8.encode('$purpose|$from|$to'), ...fromNonce, ...toNonce]);
}
