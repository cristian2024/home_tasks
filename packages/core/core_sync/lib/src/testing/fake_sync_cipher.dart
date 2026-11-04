import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../contracts/sync_cipher.dart';
import '../sync_exception.dart';

/// [SyncCipher] de prueba, sin dependencias. Cumple `syncCipherContract`
/// pero **no es seguro**: su cifrado y su MAC se basan en FNV-1a. Solo para
/// tests y apps de ejemplo.
class FakeSyncCipher implements SyncCipher {
  FakeSyncCipher({Random? random}) : _random = random ?? Random();

  static const int _nonceLength = 16;
  static const int _tagLength = 16;

  final Random _random;

  @override
  Future<Uint8List> newKey() => randomBytes(SyncCipher.keyLength);

  @override
  Future<Uint8List> randomBytes(int length) async {
    if (length < 0) {
      throw ArgumentError.value(length, 'length', 'No puede ser negativo');
    }
    return Uint8List.fromList(List<int>.generate(length, (_) => _random.nextInt(256)));
  }

  @override
  Future<Uint8List> deriveKey(Uint8List key, {required String purpose}) async =>
      _expand(<int>[..._checkKey(key), ...utf8.encode('derive:$purpose')], SyncCipher.keyLength);

  @override
  Future<Uint8List> encrypt(Uint8List plaintext, {required Uint8List key, required Uint8List associatedData}) async {
    _checkKey(key);
    final Uint8List nonce = await randomBytes(_nonceLength);
    final Uint8List body = _xor(plaintext, _expand(<int>[...key, ...nonce], plaintext.length));
    return Uint8List.fromList(<int>[...nonce, ...body, ..._tag(key, nonce, associatedData, body)]);
  }

  @override
  Future<Uint8List> decrypt(Uint8List ciphertext, {required Uint8List key, required Uint8List associatedData}) async {
    _checkKey(key);
    if (ciphertext.length < _nonceLength + _tagLength) {
      throw const SyncCipherException('Mensaje demasiado corto');
    }
    final Uint8List nonce = ciphertext.sublist(0, _nonceLength);
    final Uint8List body = ciphertext.sublist(_nonceLength, ciphertext.length - _tagLength);
    final Uint8List tag = ciphertext.sublist(ciphertext.length - _tagLength);
    if (!_equals(tag, _tag(key, nonce, associatedData, body))) {
      throw const SyncCipherException('Autenticación fallida');
    }
    return _xor(body, _expand(<int>[...key, ...nonce], body.length));
  }

  @override
  Future<Uint8List> mac(Uint8List data, {required Uint8List key}) async =>
      _expand(<int>[..._checkKey(key), 0xff, ...data], SyncCipher.keyLength);

  @override
  Future<bool> verifyMac(Uint8List data, Uint8List mac, {required Uint8List key}) async =>
      _equals(mac, await this.mac(data, key: key));

  Uint8List _tag(Uint8List key, Uint8List nonce, Uint8List associatedData, Uint8List body) => _expand(
        <int>[...key, ...nonce, ..._uint32(associatedData.length), ...associatedData, ...body],
        _tagLength,
      );

  static Uint8List _checkKey(Uint8List key) {
    if (key.length != SyncCipher.keyLength) {
      throw ArgumentError.value(key.length, 'key', 'Se esperaban ${SyncCipher.keyLength} bytes');
    }
    return key;
  }

  /// [length] bytes pseudoaleatorios deterministas a partir de [seed].
  static Uint8List _expand(List<int> seed, int length) {
    final int state = _fnv1a(seed, 0x811c9dc5);
    final Uint8List output = Uint8List(length);
    for (int block = 0; block * 4 < length; block++) {
      final int value = _fnv1a(_uint32(block), state);
      for (int i = 0; i < 4 && block * 4 + i < length; i++) {
        output[block * 4 + i] = (value >> (8 * i)) & 0xff;
      }
    }
    return output;
  }

  static int _fnv1a(List<int> bytes, int hash) {
    int value = hash;
    for (final int byte in bytes) {
      value = ((value ^ byte) * 0x01000193) & 0xffffffff;
    }
    return value;
  }

  static List<int> _uint32(int value) =>
      <int>[value & 0xff, (value >> 8) & 0xff, (value >> 16) & 0xff, (value >> 24) & 0xff];

  static Uint8List _xor(Uint8List data, Uint8List stream) =>
      Uint8List.fromList(List<int>.generate(data.length, (int i) => data[i] ^ stream[i]));

  static bool _equals(Uint8List a, Uint8List b) {
    if (a.length != b.length) {
      return false;
    }
    int difference = 0;
    for (int i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }
    return difference == 0;
  }
}
