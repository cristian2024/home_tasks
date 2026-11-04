/// Almacén de secretos por clave (Keychain, Keystore…). Los valores son texto:
/// quien guarda bytes los codifica (p. ej. en base64).
///
/// Una clave vacía se rechaza con [ArgumentError].
abstract interface class SecretStore {
  /// Valor guardado en [key], o `null` si no hay ninguno.
  Future<String?> read(String key);

  /// Guarda [value] en [key] y reemplaza el anterior.
  Future<void> write(String key, String value);

  /// Borra [key]. No falla si no existe.
  Future<void> delete(String key);
}
