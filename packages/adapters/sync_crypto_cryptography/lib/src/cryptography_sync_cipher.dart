import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:core_di/core_di.dart';
import 'package:core_sync/core_sync.dart';
import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';

/// Registra [XChaCha20SyncCipher] como `SyncCipher`. Quien compone la app
/// solo lo elige:
///
/// ```dart
/// adapters: <DependencyModule>[CryptographySyncCipher()]
/// ```
class CryptographySyncCipher implements DependencyModule {
  const CryptographySyncCipher();

  @override
  Future<void> register(ServiceLocator services) async =>
      services.registerSingleton<SyncCipher>(XChaCha20SyncCipher());
}

/// [SyncCipher] con el paquete cryptography, en Dart puro:
/// - cifrado: XChaCha20-Poly1305. El resultado es nonce (24 bytes), texto
///   cifrado y MAC (16 bytes);
/// - derivación: HKDF-SHA256 sin sal, con el uso como `info`;
/// - MAC: HMAC-SHA256;
/// - claves, nonces y bytes aleatorios: `Random.secure()`.
class XChaCha20SyncCipher implements SyncCipher {
  static const int _nonceLength = 24;
  static const int _macLength = 16;

  final Random _random = Random.secure();
  final Cipher _aead = const DartXchacha20.poly1305Aead();
  final Hkdf _hkdf = DartHkdf(hmac: DartHmac.sha256(), outputLength: SyncCipher.keyLength);
  final MacAlgorithm _hmac = DartHmac.sha256();

  @override
  Future<Uint8List> newKey() => randomBytes(SyncCipher.keyLength);

  @override
  Future<Uint8List> randomBytes(int length) async {
    if (length < 0) {
      throw ArgumentError.value(length, 'length', 'No puede ser negativa');
    }
    return Uint8List.fromList(List<int>.generate(length, (int _) => _random.nextInt(256)));
  }

  @override
  Future<Uint8List> deriveKey(Uint8List key, {required String purpose}) async {
    _checkKey(key);
    final SecretKeyData derived = await _hkdf.deriveKey(secretKey: SecretKeyData(key), info: utf8.encode(purpose));
    return Uint8List.fromList(derived.bytes);
  }

  @override
  Future<Uint8List> encrypt(Uint8List plaintext, {required Uint8List key, required Uint8List associatedData}) async {
    _checkKey(key);
    final SecretBox box = await _aead.encrypt(plaintext, secretKey: SecretKeyData(key), aad: associatedData);
    return box.concatenation();
  }

  @override
  Future<Uint8List> decrypt(Uint8List ciphertext, {required Uint8List key, required Uint8List associatedData}) async {
    _checkKey(key);
    if (ciphertext.length < _nonceLength + _macLength) {
      throw const SyncCipherException('Mensaje demasiado corto');
    }
    final SecretBox box =
        SecretBox.fromConcatenation(ciphertext, nonceLength: _nonceLength, macLength: _macLength);
    try {
      final List<int> plaintext = await _aead.decrypt(box, secretKey: SecretKeyData(key), aad: associatedData);
      return Uint8List.fromList(plaintext);
    } on SecretBoxAuthenticationError {
      throw const SyncCipherException('Clave o datos asociados distintos, o mensaje alterado');
    }
  }

  @override
  Future<Uint8List> mac(Uint8List data, {required Uint8List key}) async {
    _checkKey(key);
    final Mac result = await _hmac.calculateMac(data, secretKey: SecretKeyData(key));
    return Uint8List.fromList(result.bytes);
  }

  @override
  Future<bool> verifyMac(Uint8List data, Uint8List mac, {required Uint8List key}) async {
    final Uint8List expected = await this.mac(data, key: key);
    if (expected.length != mac.length) {
      return false;
    }
    int difference = 0;
    for (int i = 0; i < expected.length; i++) {
      difference |= expected[i] ^ mac[i];
    }
    return difference == 0;
  }

  void _checkKey(Uint8List key) {
    if (key.length != SyncCipher.keyLength) {
      throw ArgumentError.value(key.length, 'key', 'Se esperaban ${SyncCipher.keyLength} bytes');
    }
  }
}
