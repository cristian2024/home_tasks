/// Estado del hardware que necesita un escáner.
enum HardwareStatus {
  /// Presente y activado.
  available,

  /// Presente pero desactivado por el usuario (p. ej. NFC apagado en Ajustes).
  disabled,

  /// El dispositivo no lo tiene (iPad sin NFC, emulador, etc.).
  unsupported,
}
