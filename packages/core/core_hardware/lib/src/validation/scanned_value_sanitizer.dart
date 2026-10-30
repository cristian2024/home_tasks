import '../contracts/scan_exception.dart';

/// Reglas de validación del §8.2 para valores leídos o escritos.
abstract final class ScannedValueSanitizer {
  static const int maxLength = 2048;

  static final RegExp _controlCharacters = RegExp(r'[\x00-\x1F\x7F]');

  /// Elimina los caracteres de control y valida la longitud. Lanza
  /// [ScanException] con [ScanErrorCode.invalidValue] si el resultado está
  /// vacío o supera [maxLength] caracteres.
  ///
  /// Las URLs se devuelven como texto literal: nunca se abren.
  static String sanitize(String raw) {
    final String value = raw.replaceAll(_controlCharacters, '');
    if (value.isEmpty) {
      throw const ScanException(ScanErrorCode.invalidValue, message: 'Valor vacío');
    }
    if (value.length > maxLength) {
      throw ScanException(
        ScanErrorCode.invalidValue,
        message: 'El valor supera $maxLength caracteres (${value.length})',
      );
    }
    return value;
  }
}
