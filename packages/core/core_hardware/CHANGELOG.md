# Changelog

## 0.2.0 - 2026-10-29

Primera versión con CHANGELOG.

### Añadido

- README del paquete.

### Cambiado

- La app de ejemplo elige los adaptadores de hardware.

### Eliminado

- **Incompatible:** las implementaciones nativas y sus dependencias (`mobile_scanner`, `nfc_manager`, `nfc_manager_ndef`, `permission_handler`). Están en los adaptadores:
  - `MobileScannerCameraScanner` → `hardware_mobile_scanner`;
  - `NfcManagerScanner` → `hardware_nfc_manager`;
  - `PermissionHandlerPermissions` → `hardware_permission_handler`.

### Interno

- Tipos explícitos en todo el paquete y su ejemplo (`always_specify_types`).
