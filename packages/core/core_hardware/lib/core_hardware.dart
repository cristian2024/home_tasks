/// Abstracciones de hardware (cámara, NFC y permisos) y sus adaptadores.
///
/// Es el único paquete que puede importar `mobile_scanner`, `nfc_manager` o
/// `permission_handler`; la presentación y el dominio consumen solo estos
/// contratos.
library;

export 'src/camera/mobile_scanner_camera_scanner.dart' show MobileScannerCameraScanner;
export 'src/contracts/hardware_permissions.dart';
export 'src/contracts/hardware_status.dart';
export 'src/contracts/identifier_scanner.dart';
export 'src/contracts/physical_scan_result.dart';
export 'src/contracts/scan_exception.dart';
export 'src/nfc/nfc_manager_scanner.dart' show NfcManagerScanner;
export 'src/permissions/permission_handler_permissions.dart' show PermissionHandlerPermissions;
export 'src/validation/scanned_value_sanitizer.dart';
