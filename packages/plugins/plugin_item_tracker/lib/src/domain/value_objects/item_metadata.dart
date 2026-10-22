import 'package:equatable/equatable.dart';

import '../errors/item_tracker_exception.dart';

/// Metadatos dinámicos de un objeto: pares clave/valor validados.
///
/// - Claves en `snake_case`: `^[a-z][a-z0-9_]*$`, hasta [maxKeyLength].
/// - Valores escalares JSON: `String` (hasta [maxStringLength]), `int`,
///   `double` finito o `bool`. Para quitar un dato se elimina la clave.
/// - Como máximo [maxEntries] entradas.
class ItemMetadata extends Equatable {
  static const int maxEntries = 50;
  static const int maxKeyLength = 64;
  static const int maxStringLength = 500;

  static final _keyPattern = RegExp(r'^[a-z][a-z0-9_]*$');

  final Map<String, Object> values;

  const ItemMetadata.empty() : values = const {};

  const ItemMetadata._(this.values);

  /// Valida [values] y lanza [ItemValidationException] (campo `metadata`) si
  /// no cumple las reglas.
  factory ItemMetadata(Map<String, Object?> values) {
    if (values.length > maxEntries) {
      throw ItemValidationException(
        ValidationField.metadata,
        ValidationReason.tooManyEntries,
        detail: '${values.length} > $maxEntries',
      );
    }
    final validated = <String, Object>{};
    for (final MapEntry(:key, :value) in values.entries) {
      if (key.length > maxKeyLength) {
        throw ItemValidationException(ValidationField.metadata, ValidationReason.tooLong, detail: key);
      }
      if (!_keyPattern.hasMatch(key)) {
        throw ItemValidationException(ValidationField.metadata, ValidationReason.invalidFormat, detail: key);
      }
      validated[key] = switch (value) {
        final String text when text.length > maxStringLength =>
          throw ItemValidationException(ValidationField.metadata, ValidationReason.tooLong, detail: key),
        final double number when !number.isFinite =>
          throw ItemValidationException(ValidationField.metadata, ValidationReason.unsupportedValue, detail: key),
        final String text => text,
        final int number => number,
        final double number => number,
        final bool flag => flag,
        _ => throw ItemValidationException(
            ValidationField.metadata,
            ValidationReason.unsupportedValue,
            detail: key,
          ),
      };
    }
    return ItemMetadata._(Map.unmodifiable(validated));
  }

  bool get isEmpty => values.isEmpty;

  @override
  List<Object?> get props => [values];

  @override
  bool get stringify => true;
}
