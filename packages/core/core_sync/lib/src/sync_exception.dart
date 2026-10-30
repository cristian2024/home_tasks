/// Errores de la sincronización que las implementaciones de los contratos
/// lanzan.
sealed class SyncException implements Exception {
  const SyncException(this.message);

  final String message;
}

/// No se pudo conectar, se cerró el canal o falló la red.
final class SyncTransportException extends SyncException {
  const SyncTransportException(super.message);

  @override
  String toString() => 'SyncTransportException: $message';
}

/// Un mensaje no se pudo descifrar: clave o datos asociados distintos, o
/// mensaje alterado.
final class SyncCipherException extends SyncException {
  const SyncCipherException(super.message);

  @override
  String toString() => 'SyncCipherException: $message';
}
