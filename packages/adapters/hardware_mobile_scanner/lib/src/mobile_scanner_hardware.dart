import 'package:core_di/core_di.dart';
import 'package:core_hardware/core_hardware.dart' show CameraIdentifierScanner;

import 'mobile_scanner_camera_scanner.dart';

/// Registra [MobileScannerCameraScanner] como `CameraIdentifierScanner`. Es
/// una factoría: cada `get` devuelve un escáner nuevo, que quien lo pide
/// libera con `dispose()`. Quien compone la app solo lo elige:
///
/// ```dart
/// adapters: <DependencyModule>[MobileScannerHardware()]
/// ```
class MobileScannerHardware implements DependencyModule {
  const MobileScannerHardware();

  @override
  Future<void> register(ServiceLocator services) async =>
      services.registerFactory<CameraIdentifierScanner>(MobileScannerCameraScanner.new);
}
