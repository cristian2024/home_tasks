/// Adaptador de `core_hardware` con `permission_handler`: permiso de cámara y
/// acceso a los ajustes de la app.
///
/// Quien compone la app solo elige [PermissionHandlerHardware]; los plugins
/// piden `HardwarePermissions` al `ServiceLocator`.
library;

export 'src/permission_handler_hardware.dart';
export 'src/permission_handler_permissions.dart' show PermissionHandlerPermissions;
