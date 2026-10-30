import 'package:flutter/material.dart';
import 'package:hardware_mobile_scanner/hardware_mobile_scanner.dart';
import 'package:hardware_nfc_manager/hardware_nfc_manager.dart';
import 'package:hardware_permission_handler/hardware_permission_handler.dart';

import 'src/hardware_demo_app.dart';

/// Prueba los adaptadores de hardware en un dispositivo real. Los recibe por
/// constructor, sin `ServiceLocator`, para que la demo sea autocontenida.
void main() {
  runApp(
    const HardwareDemoApp(
      cameraScannerFactory: MobileScannerCameraScanner.new,
      nfcScannerFactory: NfcManagerScanner.new,
      permissions: PermissionHandlerPermissions(),
    ),
  );
}
