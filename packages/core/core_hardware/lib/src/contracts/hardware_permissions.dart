enum HardwarePermissionStatus {
  granted,

  /// Denegado, pero se puede volver a pedir.
  denied,

  /// Denegado de forma permanente: solo se puede cambiar desde Ajustes.
  permanentlyDenied,

  /// Bloqueado por el sistema (control parental, MDM).
  restricted,
}

/// Permisos de hardware en tiempo de ejecución. NFC no requiere permiso en
/// tiempo de ejecución en ninguna de las dos plataformas.
abstract interface class HardwarePermissions {
  Future<HardwarePermissionStatus> cameraStatus();

  /// Pide el permiso de cámara si aún se puede pedir y devuelve el resultado.
  Future<HardwarePermissionStatus> requestCamera();

  /// Abre los ajustes de la app. Devuelve `false` si no se pudieron abrir.
  Future<bool> openSettings();
}
