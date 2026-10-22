import '../entities/physical_identifier.dart';

/// Errores de negocio del plugin. Es `sealed` para que la presentación los
/// trate todos de forma exhaustiva.
sealed class ItemTrackerException implements Exception {
  const ItemTrackerException();
}

final class ItemNotFoundException extends ItemTrackerException {
  final String itemId;

  const ItemNotFoundException(this.itemId);

  @override
  String toString() => 'ItemNotFoundException($itemId)';
}

/// El identificador ya está ligado a un objeto ([boundItemId], que puede ser
/// el mismo al que se intentaba asociar). Un identificador nunca se mueve de
/// un objeto a otro.
final class IdentifierAlreadyBoundException extends ItemTrackerException {
  final String rawValue;
  final IdentifierType type;
  final String boundItemId;

  const IdentifierAlreadyBoundException({
    required this.rawValue,
    required this.type,
    required this.boundItemId,
  });

  @override
  String toString() => 'IdentifierAlreadyBoundException(${type.name}:$rawValue -> $boundItemId)';
}

enum ValidationField { name, description, metadata, identifierValue, eventTitle, eventDescription }

enum ValidationReason {
  /// Vacío (tras recortar espacios cuando aplica).
  empty,

  /// Supera la longitud máxima.
  tooLong,

  /// Supera el número máximo de entradas (metadatos).
  tooManyEntries,

  /// Formato no válido (clave de metadato, caracteres de control).
  invalidFormat,

  /// Tipo de valor de metadato no admitido.
  unsupportedValue,
}

final class ItemValidationException extends ItemTrackerException {
  final ValidationField field;
  final ValidationReason reason;

  /// Dato concreto que falló, p. ej. la clave de metadato.
  final String? detail;

  const ItemValidationException(this.field, this.reason, {this.detail});

  @override
  String toString() =>
      'ItemValidationException(${field.name}, ${reason.name}${detail == null ? '' : ', $detail'})';
}
