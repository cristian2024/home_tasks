/// Adaptador de `core_hardware` con `mobile_scanner`: QR y códigos de barras
/// con la cámara.
///
/// Quien compone la app solo elige [MobileScannerHardware]; los plugins piden
/// `CameraIdentifierScanner` al `ServiceLocator`.
library;

export 'src/mobile_scanner_camera_scanner.dart' show MobileScannerCameraScanner;
export 'src/mobile_scanner_hardware.dart';
