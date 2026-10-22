import 'package:meta/meta.dart';
import 'package:permission_handler/permission_handler.dart';

import '../contracts/hardware_permissions.dart';

/// [HardwarePermissions] sobre `permission_handler`.
class PermissionHandlerPermissions implements HardwarePermissions {
  const PermissionHandlerPermissions();

  @override
  Future<HardwarePermissionStatus> cameraStatus() async =>
      mapPermissionStatus(await Permission.camera.status);

  @override
  Future<HardwarePermissionStatus> requestCamera() async =>
      mapPermissionStatus(await Permission.camera.request());

  @override
  Future<bool> openSettings() => openAppSettings();
}

@visibleForTesting
HardwarePermissionStatus mapPermissionStatus(PermissionStatus status) => switch (status) {
      PermissionStatus.granted ||
      PermissionStatus.limited ||
      PermissionStatus.provisional =>
        HardwarePermissionStatus.granted,
      PermissionStatus.denied => HardwarePermissionStatus.denied,
      PermissionStatus.permanentlyDenied => HardwarePermissionStatus.permanentlyDenied,
      PermissionStatus.restricted => HardwarePermissionStatus.restricted,
    };
