# Changelog

## 0.1.0 - 2026-10-29

### Añadido

- `MobileScannerHardware`: `DependencyModule` que registra `MobileScannerCameraScanner` como factoría de `CameraIdentifierScanner` (`core_hardware`). Quien compone la app solo lo elige.
- `MobileScannerCameraScanner`: escanea QR y códigos de barras con `mobile_scanner`, limpia el valor leído y traduce los errores a `ScanException`. Viene de `core_hardware`, que lo eliminará.
