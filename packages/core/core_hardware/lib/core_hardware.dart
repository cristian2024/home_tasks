/// Contratos de hardware (cámara, NFC y permisos), el resultado de un escaneo,
/// sus errores y la limpieza del valor leído.
///
/// No importa ningún SDK nativo: las implementaciones están en los
/// adaptadores `hardware_*` (`packages/adapters/`). La presentación y el
/// dominio consumen solo estos contratos.
library;

export 'src/contracts/hardware_permissions.dart';
export 'src/contracts/hardware_status.dart';
export 'src/contracts/identifier_scanner.dart';
export 'src/contracts/physical_scan_result.dart';
export 'src/contracts/scan_exception.dart';
export 'src/validation/scanned_value_sanitizer.dart';
