# hardware_permission_handler

Adaptador de `core_hardware` para los permisos: consulta y pide el permiso de cámara y abre los ajustes de la app con [`permission_handler`](https://pub.dev/packages/permission_handler).

## Uso

Quien compone la app solo lo elige:

```dart
adapters: <DependencyModule>[PermissionHandlerHardware()]
```

`PermissionHandlerHardware` registra `HardwarePermissions` en el `ServiceLocator` (una sola instancia). Los estados `limited` y `provisional` cuentan como concedidos.

## Configuración nativa

- Android: permiso `CAMERA` en el `AndroidManifest.xml`.
- iOS: `NSCameraUsageDescription` en `Info.plist`.

Consulta la app de ejemplo de `core_hardware`.

## Tests

```sh
flutter test
```
