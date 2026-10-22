import 'package:core_hardware/core_hardware.dart';
import 'package:flutter/material.dart';

import 'src/hardware_demo_app.dart';

void main() {
  runApp(
    const HardwareDemoApp(
      cameraScannerFactory: MobileScannerCameraScanner.new,
      nfcScannerFactory: NfcManagerScanner.new,
      permissions: PermissionHandlerPermissions(),
    ),
  );
}
