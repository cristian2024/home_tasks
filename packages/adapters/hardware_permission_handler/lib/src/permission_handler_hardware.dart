import 'package:core_di/core_di.dart';
import 'package:core_hardware/core_hardware.dart' show HardwarePermissions;

import 'permission_handler_permissions.dart';

/// Registra [PermissionHandlerPermissions] como `HardwarePermissions`. Quien
/// compone la app solo lo elige:
///
/// ```dart
/// adapters: <DependencyModule>[PermissionHandlerHardware()]
/// ```
class PermissionHandlerHardware implements DependencyModule {
  const PermissionHandlerHardware();

  @override
  Future<void> register(ServiceLocator services) async =>
      services.registerSingleton<HardwarePermissions>(const PermissionHandlerPermissions());
}
