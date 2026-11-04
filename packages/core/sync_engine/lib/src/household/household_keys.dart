import 'dart:convert';
import 'dart:typed_data';

import 'package:core_sync/core_sync.dart';

/// Claves derivadas de la clave de un hogar en una época. Cada uso tiene la
/// suya, ligada al hogar y a la época.
class HouseholdKeys {
  HouseholdKeys(this.household, Uint8List key, this._cipher) : _key = Uint8List.fromList(key);

  final Household household;
  final Uint8List _key;
  final SyncCipher _cipher;

  /// Para el desafío entre dos dispositivos.
  Future<Uint8List> authKey() => _derive('auth');

  /// Para cifrar los registros y los mensajes de una sesión.
  Future<Uint8List> recordsKey() => _derive('records');

  /// Lo que se anuncia en la red: un MAC truncado que solo reconocen los
  /// dispositivos del hogar en esta época. Nunca revela el id del hogar.
  Future<String> discoveryId() async {
    final Uint8List mac = await _cipher.mac(_bytes('discovery'), key: await _derive('discovery'));
    return base64Url.encode(mac.sublist(0, 12));
  }

  /// Datos asociados al cifrar un registro: lo ligan al hogar, a la época y a
  /// su posición, para que no se pueda reenviar en otro lugar.
  Uint8List recordAssociatedData(String deviceId, int seq) => _bytes('record|$deviceId|$seq');

  Future<Uint8List> _derive(String purpose) =>
      _cipher.deriveKey(_key, purpose: '$purpose|${household.id}|${household.epoch}');

  Uint8List _bytes(String text) =>
      Uint8List.fromList(utf8.encode('${household.id}|${household.epoch}|$text'));
}
