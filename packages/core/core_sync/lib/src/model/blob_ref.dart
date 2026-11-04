import 'package:equatable/equatable.dart';

import 'json.dart';

/// Referencia a un binario (p. ej. una foto) por su hash. Reservada para una
/// fase futura: el formato la admite pero nada la transfiere aún.
class BlobRef extends Equatable {
  /// Lanza [ArgumentError] si [sha256] no son 64 caracteres hexadecimales en
  /// minúscula.
  BlobRef(this.sha256) {
    if (!_sha256.hasMatch(sha256)) {
      throw ArgumentError.value(sha256, 'sha256', 'Se esperaban 64 caracteres hexadecimales');
    }
  }

  /// Lee una referencia escrita con [toJson]. Lanza [FormatException] si no
  /// lo es.
  factory BlobRef.fromJson(Object? source) {
    final Map<String, Object?> json = asJsonMap(source);
    return parseJson(source, () => BlobRef(readJson<String>(json, 'sha256')));
  }

  static final RegExp _sha256 = RegExp(r'^[0-9a-f]{64}$');

  final String sha256;

  Map<String, Object?> toJson() => <String, Object?>{'sha256': sha256};

  @override
  List<Object?> get props => <Object?>[sha256];
}
