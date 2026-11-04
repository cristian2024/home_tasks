import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:core_sync/core_sync.dart';
import 'package:equatable/equatable.dart';

import '../household/household_keys.dart';
import '../sync_engine_exception.dart';
import 'record_applier.dart';
import 'sync_message.dart';

/// Una sesión de sincronización con otro dispositivo, sobre un canal ya
/// abierto. Los dos lados ejecutan lo mismo:
///
/// 1. `hello` con su nonce;
/// 2. `proof`: MAC de los dos nonces con la clave de autenticación;
/// 3. `vector` cifrado;
/// 4. lotes de `records` con lo que le falta al otro, cada uno cifrado, y
///    `done`;
/// 5. aplica lo recibido hasta el `done` del otro y cierra.
class SyncSession {
  SyncSession({
    required SyncChannel channel,
    required DeviceIdentity device,
    required HouseholdKeys keys,
    required ChangeLog log,
    required RecordApplier applier,
    required SyncCipher cipher,
    this.batchSize = 200,
    this.timeout = const Duration(seconds: 30),
  })  : _channel = channel,
        _device = device,
        _keys = keys,
        _log = log,
        _applier = applier,
        _cipher = cipher;

  /// Versión del protocolo.
  static const int protocol = 1;

  static const int _nonceLength = 16;

  /// Registros por mensaje.
  final int batchSize;

  /// Espera máxima de cada mensaje.
  final Duration timeout;

  final SyncChannel _channel;
  final DeviceIdentity _device;
  final HouseholdKeys _keys;
  final ChangeLog _log;
  final RecordApplier _applier;
  final SyncCipher _cipher;

  /// Ejecuta la sesión y cierra el canal al terminar, también si falla.
  ///
  /// Lanza [SyncAuthenticationException] si el otro no conoce la clave,
  /// [SyncProtocolException] si envía algo inesperado y
  /// [SyncTransportException] si el canal se cierra o no responde.
  Future<SyncSessionResult> run() async {
    final StreamQueue<Uint8List> incoming = StreamQueue<Uint8List>(_channel.messages);
    try {
      final Uint8List nonce = await _cipher.randomBytes(_nonceLength);
      await _send(HelloMessage(protocol: protocol, deviceId: _device.deviceId, deviceName: _device.name, nonce: nonce));
      final HelloMessage hello = await _receive<HelloMessage>(incoming);
      if (hello.protocol != protocol) {
        throw SyncProtocolException('Versión de protocolo ${hello.protocol}; se esperaba $protocol');
      }
      if (hello.deviceId == _device.deviceId) {
        throw const SyncProtocolException('El otro dispositivo tiene el mismo id');
      }
      final _Peers peers = _Peers(_device.deviceId, nonce, hello.deviceId, hello.nonce);

      final Uint8List authKey = await _keys.authKey();
      await _send(ProofMessage(await _cipher.mac(peers.proof(mine: true), key: authKey)));
      final ProofMessage proof = await _receive<ProofMessage>(incoming);
      if (!await _cipher.verifyMac(peers.proof(mine: false), proof.mac, key: authKey)) {
        throw SyncAuthenticationException('${hello.deviceId} no conoce la clave del hogar');
      }

      final Uint8List recordsKey = await _keys.recordsKey();
      final VersionVector local = await _log.vector();
      await _send(VectorMessage(await _cipher.encrypt(
        Uint8List.fromList(utf8.encode(jsonEncode(local.toJson()))),
        key: recordsKey,
        associatedData: peers.vectorData(mine: true),
      )));
      final VersionVector remote = await _decryptVector(await _receive<VectorMessage>(incoming), recordsKey, peers);

      final List<ChangeRecord> missing = await _log.missingFor(remote);
      for (int start = 0; start < missing.length; start += batchSize) {
        final int end = start + batchSize < missing.length ? start + batchSize : missing.length;
        await _send(RecordsMessage(<SealedRecord>[
          for (final ChangeRecord record in missing.sublist(start, end)) await _seal(record, recordsKey),
        ]));
      }
      await _send(const DoneMessage());

      ApplyOutcome outcome = ApplyOutcome.none;
      while (true) {
        final SyncMessage message = await _next(incoming);
        if (message is DoneMessage) {
          break;
        }
        if (message is! RecordsMessage) {
          throw SyncProtocolException('Mensaje inesperado: ${message.runtimeType}');
        }
        outcome += await _applier.apply(<ChangeRecord>[
          for (final SealedRecord sealed in message.records) await _open(sealed, recordsKey),
        ]);
      }
      return SyncSessionResult(
        peer: DeviceIdentity(deviceId: hello.deviceId, name: hello.deviceName),
        remoteVector: remote,
        localVector: local,
        sent: missing.length,
        outcome: outcome,
      );
    } finally {
      unawaited(incoming.cancel(immediate: true));
      await _channel.close();
    }
  }

  Future<void> _send(SyncMessage message) => _channel.send(message.encode());

  Future<SyncMessage> _next(StreamQueue<Uint8List> incoming) async {
    try {
      if (!await incoming.hasNext.timeout(timeout)) {
        throw const SyncTransportException('El otro dispositivo cerró el canal');
      }
      return SyncMessage.decode(await incoming.next);
    } on TimeoutException {
      throw const SyncTransportException('El otro dispositivo no responde');
    }
  }

  Future<T> _receive<T extends SyncMessage>(StreamQueue<Uint8List> incoming) async {
    final SyncMessage message = await _next(incoming);
    if (message is! T) {
      throw SyncProtocolException('Se esperaba $T y llegó ${message.runtimeType}');
    }
    return message;
  }

  Future<VersionVector> _decryptVector(VectorMessage message, Uint8List key, _Peers peers) async {
    try {
      final Uint8List plain =
          await _cipher.decrypt(message.ciphertext, key: key, associatedData: peers.vectorData(mine: false));
      return VersionVector.fromJson(jsonDecode(utf8.decode(plain)));
    } on SyncCipherException catch (error) {
      throw SyncProtocolException('Vector ilegible: ${error.message}');
    } on FormatException catch (error) {
      throw SyncProtocolException('Vector inválido: ${error.message}');
    }
  }

  Future<SealedRecord> _seal(ChangeRecord record, Uint8List key) async => SealedRecord(
        deviceId: record.deviceId,
        seq: record.seq,
        ciphertext: await _cipher.encrypt(
          Uint8List.fromList(utf8.encode(jsonEncode(record.toJson()))),
          key: key,
          associatedData: _keys.recordAssociatedData(record.deviceId, record.seq),
        ),
      );

  Future<ChangeRecord> _open(SealedRecord sealed, Uint8List key) async {
    try {
      final Uint8List plain = await _cipher.decrypt(
        sealed.ciphertext,
        key: key,
        associatedData: _keys.recordAssociatedData(sealed.deviceId, sealed.seq),
      );
      final ChangeRecord record = ChangeRecord.fromJson(jsonDecode(utf8.decode(plain)));
      if (record.deviceId != sealed.deviceId || record.seq != sealed.seq) {
        throw const FormatException('No coincide con sus datos asociados');
      }
      return record;
    } on SyncCipherException catch (error) {
      throw SyncProtocolException('Registro ilegible: ${error.message}');
    } on FormatException catch (error) {
      throw SyncProtocolException('Registro inválido: ${error.message}');
    }
  }
}

/// Los dos lados de una sesión y sus nonces, para construir los datos del
/// desafío y del vector desde cada punto de vista.
class _Peers {
  _Peers(this._mine, this._myNonce, this._theirs, this._theirNonce);

  final String _mine;
  final Uint8List _myNonce;
  final String _theirs;
  final Uint8List _theirNonce;

  Uint8List proof({required bool mine}) => _data('proof', mine: mine);

  Uint8List vectorData({required bool mine}) => _data('vector', mine: mine);

  /// `<uso>|<emisor>|<receptor>` + nonce del emisor + nonce del receptor.
  Uint8List _data(String purpose, {required bool mine}) => Uint8List.fromList(<int>[
        ...utf8.encode(mine ? '$purpose|$_mine|$_theirs' : '$purpose|$_theirs|$_mine'),
        ...(mine ? _myNonce : _theirNonce),
        ...(mine ? _theirNonce : _myNonce),
      ]);
}

/// Resultado de una sesión.
class SyncSessionResult extends Equatable {
  const SyncSessionResult({
    required this.peer,
    required this.remoteVector,
    required this.localVector,
    required this.sent,
    required this.outcome,
  });

  /// El otro dispositivo, como se presentó.
  final DeviceIdentity peer;

  /// Lo que el otro tenía al empezar.
  final VersionVector remoteVector;

  /// Lo que este tenía al empezar. Al terminar, el otro tiene al menos la
  /// unión de los dos vectores.
  final VersionVector localVector;

  /// Registros enviados.
  final int sent;

  /// Lo que se aplicó de lo recibido.
  final ApplyOutcome outcome;

  @override
  List<Object?> get props => <Object?>[peer, remoteVector, localVector, sent, outcome];
}
