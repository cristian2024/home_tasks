enum ScanErrorCode {
  /// El usuario denegó el permiso necesario (cámara).
  permissionDenied,

  /// El dispositivo no tiene el hardware.
  hardwareUnsupported,

  /// El hardware existe pero está desactivado.
  hardwareDisabled,

  /// El valor leído o a escribir no supera la validación del §8.2.
  invalidValue,

  /// El tag NFC no admite NDEF o es de solo lectura.
  tagNotWritable,

  /// El usuario cerró la sesión de lectura (diálogo nativo de iOS).
  cancelled,

  /// Cualquier otro fallo de la plataforma.
  unknown,
}

/// Error emitido por los escáneres, en `scanStream` o como excepción.
class ScanException implements Exception {
  final ScanErrorCode code;
  final String? message;
  final Object? cause;

  const ScanException(this.code, {this.message, this.cause});

  @override
  String toString() => 'ScanException(${code.name}${message == null ? '' : ': $message'})';
}
