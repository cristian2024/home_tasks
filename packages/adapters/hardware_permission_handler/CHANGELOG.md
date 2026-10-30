# Changelog

## 0.1.0 - 2026-10-29

### Añadido

- `PermissionHandlerHardware`: `DependencyModule` que registra `PermissionHandlerPermissions` como `HardwarePermissions` (`core_hardware`). Quien compone la app solo lo elige.
- `PermissionHandlerPermissions`: consulta y pide el permiso de cámara y abre los ajustes de la app con `permission_handler`. Viene de `core_hardware`, que lo eliminará.
