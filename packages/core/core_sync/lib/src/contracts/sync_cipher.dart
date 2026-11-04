import 'dart:typed_data';

/// Criptografía de la sincronización: cifrado autenticado de cada mensaje,
/// derivación de claves y MAC. Todas las claves son de [keyLength] bytes; con
/// otra longitud se lanza [ArgumentError].
abstract interface class SyncCipher {
  static const int keyLength = 32;

  /// Clave aleatoria nueva (p. ej. la de un hogar o una época).
  Future<Uint8List> newKey();

  /// [length] bytes aleatorios (p. ej. los nonces del desafío).
  Future<Uint8List> randomBytes(int length);

  /// Clave derivada de [key] para un uso ([purpose]). Determinista.
  Future<Uint8List> deriveKey(Uint8List key, {required String purpose});

  /// Cifra [plaintext] y autentica también [associatedData], que no viaja
  /// cifrado. Cada llamada da un resultado distinto.
  Future<Uint8List> encrypt(Uint8List plaintext, {required Uint8List key, required Uint8List associatedData});

  /// Descifra lo que dio [encrypt]. Lanza `SyncCipherException` si la clave o
  /// los datos asociados no coinciden o el mensaje fue alterado.
  Future<Uint8List> decrypt(Uint8List ciphertext, {required Uint8List key, required Uint8List associatedData});

  /// MAC de [data] con [key], de [keyLength] bytes. Determinista.
  Future<Uint8List> mac(Uint8List data, {required Uint8List key});

  /// Si [mac] es el MAC de [data] con [key], comparado en tiempo constante.
  Future<bool> verifyMac(Uint8List data, Uint8List mac, {required Uint8List key});
}
