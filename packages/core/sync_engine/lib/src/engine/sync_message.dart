import 'dart:convert';
import 'dart:typed_data';

import '../sync_engine_exception.dart';

/// Mensaje del protocolo de una sesión. Viaja como JSON en UTF-8; lo secreto
/// va cifrado dentro.
sealed class SyncMessage {
  const SyncMessage();

  /// Lee un mensaje. Lanza [SyncProtocolException] si no lo es.
  factory SyncMessage.decode(Uint8List bytes) {
    try {
      final Object? json = jsonDecode(utf8.decode(bytes));
      if (json is! Map<String, Object?>) {
        throw const FormatException('Se esperaba un objeto');
      }
      return switch (json['t']) {
        'hello' => HelloMessage(
            protocol: json['v']! as int,
            deviceId: json['device']! as String,
            deviceName: json['name']! as String,
            nonce: _bytes(json['nonce']),
          ),
        'proof' => ProofMessage(_bytes(json['mac'])),
        'vector' => VectorMessage(_bytes(json['data'])),
        'records' => RecordsMessage(<SealedRecord>[
            for (final Map<String, Object?> item in (json['items']! as List<Object?>).cast<Map<String, Object?>>())
              SealedRecord(deviceId: item['d']! as String, seq: item['s']! as int, ciphertext: _bytes(item['c'])),
          ]),
        'done' => const DoneMessage(),
        final Object? type => throw FormatException('Tipo desconocido: $type'),
      };
    } on Object catch (error) {
      throw SyncProtocolException('Mensaje inválido: $error');
    }
  }

  Map<String, Object?> toJson();

  Uint8List encode() => Uint8List.fromList(utf8.encode(jsonEncode(toJson())));

  static Uint8List _bytes(Object? value) => base64.decode(value! as String);
}

/// Primer mensaje: quién es y su nonce para el desafío. Sin cifrar.
final class HelloMessage extends SyncMessage {
  const HelloMessage({required this.protocol, required this.deviceId, required this.deviceName, required this.nonce});

  final int protocol;
  final String deviceId;
  final String deviceName;
  final Uint8List nonce;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        't': 'hello',
        'v': protocol,
        'device': deviceId,
        'name': deviceName,
        'nonce': base64.encode(nonce),
      };
}

/// Prueba de que conoce la clave del hogar: un MAC sobre los dos nonces.
final class ProofMessage extends SyncMessage {
  const ProofMessage(this.mac);

  final Uint8List mac;

  @override
  Map<String, Object?> toJson() => <String, Object?>{'t': 'proof', 'mac': base64.encode(mac)};
}

/// Vector de versiones, cifrado.
final class VectorMessage extends SyncMessage {
  const VectorMessage(this.ciphertext);

  final Uint8List ciphertext;

  @override
  Map<String, Object?> toJson() => <String, Object?>{'t': 'vector', 'data': base64.encode(ciphertext)};
}

/// Un lote de registros, cada uno cifrado por separado.
final class RecordsMessage extends SyncMessage {
  const RecordsMessage(this.records);

  final List<SealedRecord> records;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        't': 'records',
        'items': <Object?>[
          for (final SealedRecord record in records)
            <String, Object?>{'d': record.deviceId, 's': record.seq, 'c': base64.encode(record.ciphertext)},
        ],
      };
}

/// Ya envió todo lo que le faltaba al otro.
final class DoneMessage extends SyncMessage {
  const DoneMessage();

  @override
  Map<String, Object?> toJson() => <String, Object?>{'t': 'done'};
}

/// Registro cifrado. [deviceId] y [seq] van a la vista porque forman parte de
/// los datos asociados del cifrado.
class SealedRecord {
  const SealedRecord({required this.deviceId, required this.seq, required this.ciphertext});

  final String deviceId;
  final int seq;
  final Uint8List ciphertext;
}
