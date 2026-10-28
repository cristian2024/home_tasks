import 'errors/item_tracker_exception.dart';

/// Reglas de validación de los campos de texto del plugin. Devuelven el valor
/// normalizado o lanzan [ItemValidationException].
abstract final class ItemValidator {
  static const int maxNameLength = 120;
  static const int maxDescriptionLength = 2000;
  static const int maxEventTitleLength = 120;

  /// Igual que el límite del §8.2 para valores escaneados.
  static const int maxIdentifierLength = 2048;

  static final RegExp _controlCharacters = RegExp(r'[\x00-\x1F\x7F]');

  /// Nombre obligatorio, sin espacios sobrantes.
  static String name(String value) =>
      _required(value.trim(), ValidationField.name, maxNameLength);

  static String description(String value) =>
      _optional(value.trim(), ValidationField.description, maxDescriptionLength);

  static String eventTitle(String value) =>
      _required(value.trim(), ValidationField.eventTitle, maxEventTitleLength);

  static String eventDescription(String value) =>
      _optional(value.trim(), ValidationField.eventDescription, maxDescriptionLength);

  /// El valor de un identificador no se recorta: los espacios pueden formar
  /// parte del código. Se rechazan los caracteres de control.
  static String identifierValue(String value) {
    if (value.isEmpty) {
      throw const ItemValidationException(ValidationField.identifierValue, ValidationReason.empty);
    }
    if (value.length > maxIdentifierLength) {
      throw const ItemValidationException(ValidationField.identifierValue, ValidationReason.tooLong);
    }
    if (_controlCharacters.hasMatch(value)) {
      throw const ItemValidationException(ValidationField.identifierValue, ValidationReason.invalidFormat);
    }
    return value;
  }

  static String _required(String value, ValidationField field, int maxLength) {
    if (value.isEmpty) {
      throw ItemValidationException(field, ValidationReason.empty);
    }
    return _optional(value, field, maxLength);
  }

  static String _optional(String value, ValidationField field, int maxLength) {
    if (value.length > maxLength) {
      throw ItemValidationException(field, ValidationReason.tooLong);
    }
    return value;
  }
}
