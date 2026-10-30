/// Errores del motor de sincronización.
sealed class SyncEngineException implements Exception {
  const SyncEngineException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// La operación necesita un hogar y el dispositivo no pertenece a ninguno.
final class NotInHouseholdException extends SyncEngineException {
  const NotInHouseholdException() : super('El dispositivo no pertenece a ningún hogar');
}

/// El dispositivo ya pertenece a otro hogar: hay que salir antes.
final class AlreadyInHouseholdException extends SyncEngineException {
  const AlreadyInHouseholdException(String householdId) : super('El dispositivo ya pertenece al hogar $householdId');
}

/// Solo el dispositivo que creó el hogar puede expulsar a otros.
final class NotHouseholdCreatorException extends SyncEngineException {
  const NotHouseholdCreatorException() : super('Solo el creador del hogar puede expulsar dispositivos');
}

/// El otro dispositivo no demostró conocer la clave del hogar.
final class SyncAuthenticationException extends SyncEngineException {
  const SyncAuthenticationException(super.message);
}

/// El otro dispositivo envió algo que no sigue el protocolo.
final class SyncProtocolException extends SyncEngineException {
  const SyncProtocolException(super.message);
}
