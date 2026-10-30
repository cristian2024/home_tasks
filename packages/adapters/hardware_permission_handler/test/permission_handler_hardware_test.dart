import 'package:core_di/core_di.dart';
import 'package:core_hardware/core_hardware.dart' show HardwarePermissionStatus, HardwarePermissions;
import 'package:flutter_test/flutter_test.dart';
import 'package:hardware_permission_handler/hardware_permission_handler.dart';
import 'package:hardware_permission_handler/src/permission_handler_permissions.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  test('registra PermissionHandlerPermissions como HardwarePermissions', () async {
    final ServiceLocator locator = ServiceLocator();
    addTearDown(locator.reset);

    await const PermissionHandlerHardware().register(locator);

    expect(locator.get<HardwarePermissions>(), isA<PermissionHandlerPermissions>());
  });

  test('los estados de permission_handler se traducen a HardwarePermissionStatus', () {
    expect(mapPermissionStatus(PermissionStatus.granted), HardwarePermissionStatus.granted);
    expect(mapPermissionStatus(PermissionStatus.limited), HardwarePermissionStatus.granted);
    expect(mapPermissionStatus(PermissionStatus.provisional), HardwarePermissionStatus.granted);
    expect(mapPermissionStatus(PermissionStatus.denied), HardwarePermissionStatus.denied);
    expect(
      mapPermissionStatus(PermissionStatus.permanentlyDenied),
      HardwarePermissionStatus.permanentlyDenied,
    );
    expect(mapPermissionStatus(PermissionStatus.restricted), HardwarePermissionStatus.restricted);
  });
}
